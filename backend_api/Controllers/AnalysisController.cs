using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VitaCheck.API.Data;
using VitaCheck.API.DTOs;
using VitaCheck.API.Models;
using VitaCheck.API.Services;

namespace VitaCheck.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AnalysisController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IAiAnalysisService _aiService;
        private readonly ILogger<AnalysisController> _logger;

        public AnalysisController(
            AppDbContext context,
            IAiAnalysisService aiService,
            ILogger<AnalysisController> logger)
        {
            _context = context;
            _aiService = aiService;
            _logger = logger;
        }

        // ── Eski endpoint (değişmedi) ─────────────────────────────────────────
        [HttpPost("check-risk")]
        public async Task<IActionResult> CheckRisk([FromBody] OcrDataDto ocrData)
        {
            var user = await _context.Users.FindAsync(ocrData.UserId);
            if (user == null)
                return NotFound(new { message = $"User with ID {ocrData.UserId} not found." });

            bool isSafe = true;
            var warnings = new List<string>();

            bool hasCeliac = false; // Çölyak henüz yeni modele eklenmediği için devre dışı

            if (ocrData.HasGluten && hasCeliac)
            {
                isSafe = false;
                warnings.Add("Bu ürün glüten içermektedir ve çölyak/glüten hassasiyetiniz için risklidir.");
            }

            if (ocrData.SugarAmount > user.DailySugarLimit)
            {
                isSafe = false;
                warnings.Add("Bu ürünün şeker miktarı günlük tüketim sınırınızı aşmaktadır.");
            }

            return Ok(new
            {
                isSafe,
                warningMessage = string.Join(" ", warnings)
            });
        }

        // ── 1. OCR Extract Endpoint'i ─────────────────────────────────────────
        [HttpPost("extract-ocr")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> ExtractOcr(IFormFile photo)
        {
            if (photo == null || photo.Length == 0)
                return BadRequest(new { message = "Lütfen geçerli bir fotoğraf gönderin." });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".bmp" };
            var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(ext))
                return BadRequest(new { message = $"Desteklenmeyen dosya formatı: {ext}" });

            try
            {
                await using var stream = photo.OpenReadStream();
                var aiResult = await _aiService.ExtractOcrAsync(stream, photo.FileName);
                return Ok(aiResult);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "AI OCR servisi hatası");
                return StatusCode(502, new { message = $"AI OCR servisi yanıt vermedi: {ex.Message}" });
            }
        }

        // ── 2. AI Rapor Oluşturma Endpoint'i ────────────────────────────────
        [HttpPost("generate-report")]
        public async Task<IActionResult> GenerateReport([FromBody] GenerateReportRequestDto request)
        {
            // 1. Kullanıcıyı veritabanından çek ──────────────────────────────
            var user = await _context.Users.FindAsync(request.UserId);
            if (user == null)
                return NotFound(new { message = $"Kullanıcı bulunamadı (ID: {request.UserId})." });

            // 2. AI Rapor isteğini hazırla ───────────────────────────────────
            var aiReq = new AiGenerateReportRequestDto
            {
                OcrData100g = request.OcrData,
                Category = request.Category,
                PortionGram = request.PortionGram,
                Age = request.Age,
                Height = request.Height,
                Weight = request.Weight,
                Diseases = request.Diseases
            };

            AiAnalysisResponseDto aiResult;
            try
            {
                aiResult = await _aiService.GenerateReportAsync(aiReq);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "AI Rapor servisi hatası (UserId: {UserId})", request.UserId);
                return StatusCode(502, new { message = $"AI analiz servisi yanıt vermedi: {ex.Message}" });
            }

            // 3. ML risk özetini çıkar ────────────────────────────────────────
            double topRiskScore = aiResult.TopRiskScore;
            string overallLevel = string.IsNullOrEmpty(aiResult.OverallRiskLevel) ? "düşük" : aiResult.OverallRiskLevel;
            var topRiskDisease = aiResult.MlRisks
                .OrderByDescending(r => r.RiskScore)
                .FirstOrDefault()?.Disease ?? string.Empty;

            // 4. OCR'dan ana besin değerlerini al (per_portion bazında) ────────
            double? GetNutrient(string key)
            {
                var match = aiResult.OcrResults.FirstOrDefault(x => 
                    string.Equals(x.Key.Replace("_", ""), key.Replace("_", ""), StringComparison.OrdinalIgnoreCase));
                return match.Value?.PerPortion;
            }

            // 5. Veritabanına kaydet ───────────────────────────────────────────
            var scanRecord = new UserScanResult
            {
                UserId          = user.Id,
                ScannedAt       = DateTime.UtcNow,
                Category        = request.Category,
                PortionGram     = request.PortionGram,
                EnergyKcal      = GetNutrient("Energy_kcal"),
                Fat             = GetNutrient("Fat_g"),
                SaturatedFat    = GetNutrient("SaturatedFat_g"),
                Sugar           = GetNutrient("Sugar_g"),
                Protein         = GetNutrient("Protein_g"),
                Salt            = GetNutrient("Salt_g"),
                Carbohydrate    = GetNutrient("Carbohydrate_g"),
                Fiber           = GetNutrient("Fiber_g"),
                Sodium          = GetNutrient("Sodium_mg"),
                Potassium       = GetNutrient("Potassium_mg"),
                Calcium         = GetNutrient("Calcium_mg"),
                TopRiskScore    = topRiskScore,
                TopRiskDisease  = topRiskDisease,
                OverallRiskLevel = overallLevel,
                DoctorAdvice    = aiResult.DoctorAdvice,
                MlRisksJson     = JsonSerializer.Serialize(aiResult.MlRisks),
            };

            _context.UserScanResults.Add(scanRecord);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Tarama kaydedildi. ScanId: {ScanId} | UserId: {UserId} | Risk: {Risk}",
                scanRecord.Id, user.Id, overallLevel);

            // 6. Flutter'a dönüştürülmüş yanıtı döndür ──────────────────────
            var response = new ScanResultResponseDto
            {
                ScanId           = scanRecord.Id,
                ScannedAt        = scanRecord.ScannedAt,
                Category         = scanRecord.Category,
                PortionGram      = scanRecord.PortionGram,
                EnergyKcal       = scanRecord.EnergyKcal,
                Fat              = scanRecord.Fat,
                SaturatedFat     = scanRecord.SaturatedFat,
                Sugar            = scanRecord.Sugar,
                Protein          = scanRecord.Protein,
                Salt             = scanRecord.Salt,
                Carbohydrate     = scanRecord.Carbohydrate,
                Fiber            = scanRecord.Fiber,
                Sodium           = scanRecord.Sodium,
                Potassium        = scanRecord.Potassium,
                Calcium          = scanRecord.Calcium,
                TopRiskScore     = scanRecord.TopRiskScore,
                TopRiskDisease   = scanRecord.TopRiskDisease,
                OverallRiskLevel = scanRecord.OverallRiskLevel,
                DoctorAdvice     = scanRecord.DoctorAdvice,
                MlRisks          = aiResult.MlRisks
                    .Select(r => new MlRiskItemDto
                    {
                        Disease   = r.Disease,
                        RiskScore = r.RiskScore,
                        Level     = r.Level,
                    })
                    .ToList(),
            };

            return Ok(response);
        }

        // ── GET: Kullanıcının tarama geçmişi ─────────────────────────────────
        [HttpGet("history/{userId}")]
        public async Task<IActionResult> GetHistory(int userId, [FromQuery] int limit = 20)
        {
            var records = await _context.UserScanResults
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.ScannedAt)
                .Take(limit)
                .Select(r => new ScanResultResponseDto
                {
                    ScanId           = r.Id,
                    ScannedAt        = r.ScannedAt,
                    Category         = r.Category,
                    PortionGram      = r.PortionGram,
                    EnergyKcal       = r.EnergyKcal,
                    Fat              = r.Fat,
                    SaturatedFat     = r.SaturatedFat,
                    Sugar            = r.Sugar,
                    Protein          = r.Protein,
                    Salt             = r.Salt,
                    Carbohydrate     = r.Carbohydrate,
                    Fiber            = r.Fiber,
                    Sodium           = r.Sodium,
                    Potassium        = r.Potassium,
                    Calcium          = r.Calcium,
                    TopRiskScore     = r.TopRiskScore,
                    TopRiskDisease   = r.TopRiskDisease,
                    OverallRiskLevel = r.OverallRiskLevel,
                    DoctorAdvice     = r.DoctorAdvice,
                    MlRisks          = JsonSerializer
                        .Deserialize<List<MlRiskItemDto>>(r.MlRisksJson) ?? new(),
                })
                .ToListAsync();

            return Ok(records);
        }
    }
}
