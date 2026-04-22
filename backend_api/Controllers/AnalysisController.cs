using Microsoft.AspNetCore.Mvc;
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

            bool hasCeliac = !string.IsNullOrEmpty(user.ChronicDisease) && 
                             (user.ChronicDisease.Contains("Çölyak", StringComparison.OrdinalIgnoreCase) || 
                              user.ChronicDisease.Contains("Glüten", StringComparison.OrdinalIgnoreCase));

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
                isSafe = isSafe, 
                warningMessage = string.Join(" ", warnings) 
            });
        }
    }
}
