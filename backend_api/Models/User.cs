namespace VitaCheck.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ChronicDisease { get; set; } = string.Empty;
        public double DailySugarLimit { get; set; }
    }
}
