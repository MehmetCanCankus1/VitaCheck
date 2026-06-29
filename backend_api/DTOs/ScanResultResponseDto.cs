using System.Text.Json.Serialization;

namespace VitaCheck.API.DTOs
{
    /// <summary>
    /// POST /api/analysis/scan endpoint'inin Flutter'a döndürdüğü yanıt.
    /// </summary>
    public class ScanResultResponseDto
    {
        [JsonPropertyName("scanId")]
        public int ScanId { get; set; }

        [JsonPropertyName("scannedAt")]
        public DateTime ScannedAt { get; set; }

        [JsonPropertyName("category")]
        public string Category { get; set; } = string.Empty;

        [JsonPropertyName("portionGram")]
        public double PortionGram { get; set; }

        [JsonPropertyName("energyKcal")]
        public double? EnergyKcal { get; set; }

        [JsonPropertyName("fat")]
        public double? Fat { get; set; }

        [JsonPropertyName("saturatedFat")]
        public double? SaturatedFat { get; set; }

        [JsonPropertyName("sugar")]
        public double? Sugar { get; set; }

        [JsonPropertyName("protein")]
        public double? Protein { get; set; }

        [JsonPropertyName("salt")]
        public double? Salt { get; set; }

        [JsonPropertyName("carbohydrate")]
        public double? Carbohydrate { get; set; }

        [JsonPropertyName("fiber")]
        public double? Fiber { get; set; }

        [JsonPropertyName("sodium")]
        public double? Sodium { get; set; }

        [JsonPropertyName("potassium")]
        public double? Potassium { get; set; }

        [JsonPropertyName("calcium")]
        public double? Calcium { get; set; }

        [JsonPropertyName("topRiskScore")]
        public double TopRiskScore { get; set; }

        [JsonPropertyName("topRiskDisease")]
        public string TopRiskDisease { get; set; } = string.Empty;

        [JsonPropertyName("overallRiskLevel")]
        public string OverallRiskLevel { get; set; } = string.Empty;

        [JsonPropertyName("mlRisks")]
        public List<MlRiskItemDto> MlRisks { get; set; } = new();

        [JsonPropertyName("doctorAdvice")]
        public string DoctorAdvice { get; set; } = string.Empty;
    }

    /// <summary>Flutter risk kartı için tek hastalık satırı.</summary>
    public class MlRiskItemDto
    {
        [JsonPropertyName("disease")]
        public string Disease { get; set; } = string.Empty;

        [JsonPropertyName("riskScore")]
        public double RiskScore { get; set; }

        [JsonPropertyName("level")]
        public string Level { get; set; } = string.Empty;
    }

    public class GenerateReportRequestDto
    {
        [JsonPropertyName("userId")]
        public int UserId { get; set; }

        [JsonPropertyName("category")]
        public string Category { get; set; } = string.Empty;

        [JsonPropertyName("portion_g")]
        public double PortionGram { get; set; } = 100.0;

        [JsonPropertyName("100g_nutrients")]
        public Dictionary<string, NutrientValueDto> OcrData { get; set; } = new();

        [JsonPropertyName("diseases")]
        public List<string> Diseases { get; set; } = new();

        [JsonPropertyName("age")]
        public int Age { get; set; }

        [JsonPropertyName("height")]
        public int Height { get; set; }

        [JsonPropertyName("weight")]
        public int Weight { get; set; }
    }
}
