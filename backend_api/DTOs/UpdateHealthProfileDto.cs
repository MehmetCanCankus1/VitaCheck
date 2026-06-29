namespace VitaCheck.API.DTOs
{
    public class UpdateHealthProfileDto
    {
        public int Age { get; set; }
        public double Height { get; set; }
        public double Weight { get; set; }
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
    }
}
