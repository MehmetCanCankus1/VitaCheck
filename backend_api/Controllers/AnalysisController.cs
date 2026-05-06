using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VitaCheck.API.Data;
using VitaCheck.API.DTOs;
using VitaCheck.API.Models;

namespace VitaCheck.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AnalysisController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AnalysisController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("check-risk")]
        public async Task<IActionResult> CheckRisk([FromBody] OcrDataDto ocrData)
        {
            var user = await _context.Users.FindAsync(ocrData.UserId);
            if (user == null)
            {
                return NotFound(new { message = $"User with ID {ocrData.UserId} not found." });
            }

            bool isSafe = true;
            var warnings = new List<string>();
            int score = 85;

            bool hasCeliac = user.HasCeliacDisease ||
                             (!string.IsNullOrEmpty(user.ChronicDisease) &&
                              (user.ChronicDisease.Contains("Çölyak", StringComparison.OrdinalIgnoreCase) ||
                               user.ChronicDisease.Contains("Gluten", StringComparison.OrdinalIgnoreCase)));

            if (ocrData.HasGluten && hasCeliac)
            {
                isSafe = false;
                score -= 40;
                warnings.Add("Bu ürün glüten içermektedir ve çölyak/glüten hassasiyetiniz için risklidir.");
            }

            if (ocrData.SugarAmount > user.DailySugarLimit)
            {
                isSafe = false;
                score -= 30;
                warnings.Add("Bu ürünün şeker miktarı günlük tüketim sınırınızı aşmaktadır.");
            }

            if (user.HasHighBloodPressure)
            {
                score -= 10;
                warnings.Add("Yüksek tansiyonunuz olduğu için tuz içeriğine dikkat ediniz.");
            }

            if (score < 0) score = 0;

            return Ok(new
            {
                isSafe,
                score,
                warningMessage = string.Join(" ", warnings)
            });
        }

        [HttpPost("save")]
        public async Task<IActionResult> SaveAnalysis([FromBody] Analysis analysis)
        {
            analysis.Date = DateTime.UtcNow;
            _context.Analyses.Add(analysis);
            await _context.SaveChangesAsync();
            return Ok(analysis);
        }

        [HttpGet("history/{userId}")]
        public async Task<IActionResult> GetHistory(int userId)
        {
            var analyses = await _context.Analyses
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.Date)
                .ToListAsync();
            return Ok(analyses);
        }
    }
}