namespace VitaCheck.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty; // Eklendi
        public string Password { get; set; } = string.Empty; // Eklendi
        public int Age { get; set; } // Eklendi
        public double Height { get; set; } // Eklendi
        public double Weight { get; set; } // Eklendi
        public double DailySugarLimit { get; set; }
        public bool HasDiabetes { get; set; }
        public bool HasObesity { get; set; }
        public bool HasHypertension { get; set; }
        public bool HasHyperlipidemia { get; set; }
        public bool HasCardiovascularRisk { get; set; }
        public bool HasKidneyDiseaseRisk { get; set; }
        public bool HasMetabolicSyndromeRisk { get; set; }
        public bool HasFattyLiverRisk { get; set; }
        public bool HasProteinEnergyDeficiency { get; set; }
        public bool HasMineralImbalance { get; set; }
        public string? ProfilePhoto { get; set; }
        public int WaterCount { get; set; }
        public DateTime LastWaterDate { get; set; } = DateTime.UtcNow;
    }
}