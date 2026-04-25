namespace VitaCheck.API.DTOs
{
    public class UpdateHealthProfileDto
    {
        public string ChronicDisease { get; set; } = string.Empty;
        public double DailySugarLimit { get; set; }
    }
}
