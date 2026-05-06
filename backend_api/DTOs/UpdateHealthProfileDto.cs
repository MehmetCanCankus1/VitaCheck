namespace VitaCheck.API.DTOs
{
    public class UpdateHealthProfileDto
    {
        // Mehmetcan'ın eski alanları
        public string ChronicDisease { get; set; }
        public int DailySugarLimit { get; set; }

        // Senin arayüzün için eklenen YENİ alanlar
        public bool HasHighBloodPressure { get; set; } 
        public bool HasCeliacDisease { get; set; }     
        public List<string> Allergies { get; set; } = new List<string>(); 
        public List<string> Medications { get; set; } = new List<string>(); 
        public string MedicalHistoryNotes { get; set; } 
    }
}