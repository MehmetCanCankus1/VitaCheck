namespace VitaCheck.API.DTOs
{
    public class UserHealthProfile
    {
        public int Age { get; set; }
        public double Height { get; set; }
        public double Weight { get; set; }
        public string ChronicDisease { get; set; } = string.Empty;
        public double DailySugarLimit { get; set; }
    }
}