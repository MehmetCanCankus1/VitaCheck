namespace VitaCheck.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string ChronicDisease { get; set; } = string.Empty;
        public int DailySugarLimit { get; set; }
        public bool HasHighBloodPressure { get; set; }
        public bool HasCeliacDisease { get; set; }
        public List<string>? Allergies { get; set; }
        public List<string>? Medications { get; set; }
        public string? MedicalHistoryNotes { get; set; }
    }
}