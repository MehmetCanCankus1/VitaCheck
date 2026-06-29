namespace VitaCheck.API.Models
{
    /// <summary>
    /// Kullanıcının kamera ile taradığı ürün analizinin veritabanı kaydı.
    /// Her POST /api/analysis/scan isteği bir satır oluşturur.
    /// </summary>
    public class UserScanResult
    {
        public int Id { get; set; }

        // ── İlişki ────────────────────────────────────────────────────────────
        public int UserId { get; set; }
        public User User { get; set; } = null!;

        // ── Tarama Bilgisi ────────────────────────────────────────────────────
        public DateTime ScannedAt { get; set; } = DateTime.UtcNow;
        public string Category { get; set; } = string.Empty;
        public double PortionGram { get; set; }

        // ── OCR Özet (Flutter kartında gösterilecek ana değerler) ─────────────
        public double? EnergyKcal { get; set; }
        public double? Fat { get; set; }
        public double? SaturatedFat { get; set; }
        public double? Sugar { get; set; }
        public double? Protein { get; set; }
        public double? Salt { get; set; }
        public double? Carbohydrate { get; set; }
        public double? Fiber { get; set; }
        public double? Sodium { get; set; }
        public double? Potassium { get; set; }
        public double? Calcium { get; set; }

        // ── ML Risk Özeti ─────────────────────────────────────────────────────
        /// <summary>En yüksek risk skoru (0-100 arası).</summary>
        public double TopRiskScore { get; set; }

        /// <summary>En yüksek riskli hastalık adı.</summary>
        public string TopRiskDisease { get; set; } = string.Empty;

        /// <summary>Genel risk seviyesi: "düşük" | "orta" | "yüksek"</summary>
        public string OverallRiskLevel { get; set; } = string.Empty;

        // ── Doktor Tavsiyesi ──────────────────────────────────────────────────
        public string DoctorAdvice { get; set; } = string.Empty;

        // ── Ham ML Sonuçları (JSON olarak saklanır) ───────────────────────────
        /// <summary>Tüm 10 hastalık risk skorları, JSON dizisi olarak.</summary>
        public string MlRisksJson { get; set; } = "[]";
    }
}
