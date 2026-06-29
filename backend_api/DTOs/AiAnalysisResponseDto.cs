using System.Text.Json.Serialization;

namespace VitaCheck.API.DTOs
{
    // ── Kök yanıt nesnesi ─────────────────────────────────────────────────────
    public class AiAnalysisResponseDto
    {
        /// <summary>OCR'dan okunan ve porsiyona ölçeklenmiş besin değerleri.</summary>
        [JsonPropertyName("ocr_results")]
        public Dictionary<string, NutrientValueDto> OcrResults { get; set; } = new();

        /// <summary>ML modelinin 10 hastalık için ürettiği risk skorları.</summary>
        [JsonPropertyName("ml_risks")]
        public List<MlRiskDto> MlRisks { get; set; } = new();

        /// <summary>Gemini'nin ürettiği klinik doktor tavsiyesi metni.</summary>
        [JsonPropertyName("doctor_advice")]
        public string DoctorAdvice { get; set; } = string.Empty;

        [JsonPropertyName("top_risk_score")]
        public double TopRiskScore { get; set; }

        [JsonPropertyName("overall_risk_level")]
        public string OverallRiskLevel { get; set; } = string.Empty;
    }

    // ── Tek bir besin değeri (ör: Energy_kcal, Sugar_g …) ────────────────────
    public class NutrientValueDto
    {
        /// <summary>100 gram başına değer.</summary>
        [JsonPropertyName("per_100g")]
        public double? Per100g { get; set; }

        /// <summary>Tüketilen porsiyon başına değer.</summary>
        [JsonPropertyName("per_portion")]
        public double? PerPortion { get; set; }

        /// <summary>Birimi: kcal, kJ, g, mg …</summary>
        [JsonPropertyName("unit")]
        public string Unit { get; set; } = string.Empty;

        /// <summary>OCR güven skoru (0.0 – 1.0).</summary>
        [JsonPropertyName("confidence")]
        public double Confidence { get; set; }
    }

    // ── ML risk satırı ────────────────────────────────────────────────────────
    public class MlRiskDto
    {
        /// <summary>Hastalık adı (ör: "Diyabet", "Hipertansiyon").</summary>
        [JsonPropertyName("disease")]
        public string Disease { get; set; } = string.Empty;

        /// <summary>Risk skoru (0 – 100 arası yüzde).</summary>
        [JsonPropertyName("risk_score")]
        public double RiskScore { get; set; }

        /// <summary>Risk seviyesi: "düşük" | "orta" | "yüksek".</summary>
        [JsonPropertyName("level")]
        public string Level { get; set; } = string.Empty;
    }

    // ── OCR Extract Yanıtı ────────────────────────────────────────────────────
    public class AiExtractOcrResponseDto
    {
        [JsonPropertyName("ocr_results")]
        public Dictionary<string, NutrientValueDto> OcrResults { get; set; } = new();
    }

    // ── Generate Report İstek Modeli ──────────────────────────────────────────
    public class AiGenerateReportRequestDto
    {
        [JsonPropertyName("ocr_data_100g")]
        public Dictionary<string, NutrientValueDto> OcrData100g { get; set; } = new();

        [JsonPropertyName("portion_gram")]
        public double PortionGram { get; set; }

        [JsonPropertyName("category")]
        public string Category { get; set; } = string.Empty;

        [JsonPropertyName("age")]
        public int Age { get; set; }

        [JsonPropertyName("height")]
        public int Height { get; set; }

        [JsonPropertyName("weight")]
        public int Weight { get; set; }

        [JsonPropertyName("diseases")]
        public List<string> Diseases { get; set; } = new();
    }
}
