using System.Globalization;
using System.Net.Http.Headers;
using System.Text.Json;
using VitaCheck.API.DTOs;

namespace VitaCheck.API.Services
{
    public class AiAnalysisService : IAiAnalysisService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<AiAnalysisService> _logger;

        // Python FastAPI sunucusunun adresi
        private const string AiServiceExtractUrl = "http://localhost:8001/extract-ocr";
        private const string AiServiceReportUrl = "http://localhost:8001/generate-report";

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
        };

        public AiAnalysisService(HttpClient httpClient, ILogger<AiAnalysisService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<AiExtractOcrResponseDto> ExtractOcrAsync(Stream imageStream, string fileName)
        {
            using var content = new MultipartFormDataContent();

            var imageContent = new StreamContent(imageStream);
            imageContent.Headers.ContentType = new MediaTypeHeaderValue(ResolveContentType(fileName));
            content.Add(imageContent, "file", fileName);

            HttpResponseMessage response;
            try
            {
                _logger.LogInformation("AI servisine OCR isteği gönderiliyor: {Url} | Dosya: {File}", AiServiceExtractUrl, fileName);
                response = await _httpClient.PostAsync(AiServiceExtractUrl, content);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "AI servisine bağlanılamadı ({Url}). Python sunucusu çalışıyor mu?", AiServiceExtractUrl);
                throw new InvalidOperationException("AI OCR servisine ulaşılamadı. Lütfen Python sunucusunun çalıştığını doğrulayın.", ex);
            }

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("AI servisi hata döndürdü. Status: {StatusCode} | Body: {Body}", (int)response.StatusCode, errorBody);
                throw new InvalidOperationException($"AI servisi {(int)response.StatusCode} hatası döndürdü: {errorBody}");
            }

            var responseBody = await response.Content.ReadAsStringAsync();
            try
            {
                var result = JsonSerializer.Deserialize<AiExtractOcrResponseDto>(responseBody, _jsonOptions);
                if (result is null) throw new JsonException("Deserialize sonucu null döndü.");
                
                _logger.LogInformation("OCR çıkarma tamamlandı. Bulunan alan: {Count}", result.OcrResults.Count);
                return result;
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "AI yanıtı parse edilemedi. Ham yanıt: {Body}", responseBody);
                throw new InvalidOperationException("AI servisinden gelen OCR yanıtı işlenemedi.", ex);
            }
        }

        public async Task<AiAnalysisResponseDto> GenerateReportAsync(AiGenerateReportRequestDto request)
        {
            var jsonContent = new StringContent(JsonSerializer.Serialize(request, _jsonOptions), System.Text.Encoding.UTF8, "application/json");

            HttpResponseMessage response;
            try
            {
                _logger.LogInformation("AI servisine Rapor isteği gönderiliyor: {Url}", AiServiceReportUrl);
                response = await _httpClient.PostAsync(AiServiceReportUrl, jsonContent);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "AI servisine bağlanılamadı ({Url}). Python sunucusu çalışıyor mu?", AiServiceReportUrl);
                throw new InvalidOperationException("AI Rapor servisine ulaşılamadı. Lütfen Python sunucusunun çalıştığını doğrulayın.", ex);
            }

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("AI servisi hata döndürdü. Status: {StatusCode} | Body: {Body}", (int)response.StatusCode, errorBody);
                throw new InvalidOperationException($"AI servisi {(int)response.StatusCode} hatası döndürdü: {errorBody}");
            }

            var responseBody = await response.Content.ReadAsStringAsync();
            try
            {
                var result = JsonSerializer.Deserialize<AiAnalysisResponseDto>(responseBody, _jsonOptions);
                if (result is null) throw new JsonException("Deserialize sonucu null döndü.");
                
                _logger.LogInformation("Rapor oluşturma tamamlandı. ML Risk: {RiskCount}", result.MlRisks.Count);
                return result;
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "AI yanıtı parse edilemedi. Ham yanıt: {Body}", responseBody);
                throw new InvalidOperationException("AI servisinden gelen Rapor yanıtı işlenemedi.", ex);
            }
        }

        // ── Yardımcı: dosya uzantısından Content-Type belirle ─────────────────
        private static string ResolveContentType(string fileName)
        {
            return Path.GetExtension(fileName).ToLowerInvariant() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png"            => "image/png",
                ".webp"           => "image/webp",
                ".bmp"            => "image/bmp",
                _                 => "application/octet-stream",
            };
        }
    }
}
