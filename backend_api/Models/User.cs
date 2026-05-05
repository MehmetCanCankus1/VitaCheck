namespace VitaCheck.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; }
        
        // Mehmetcan'ın orijinal alanları
        public string ChronicDisease { get; set; }
        public int DailySugarLimit { get; set; }

        // --- EKLENEN YENİ ALANLAR (Hata vermemesi için Nullable yapıldı) ---
        public bool HasHighBloodPressure { get; set; }
        public bool HasCeliacDisease { get; set; }
        
        // Soru işaretleri (?) eklendi, böylece eski kayıtlarda hata vermeyecek
        public List<string>? Allergies { get; set; } 
        public List<string>? Medications { get; set; } 
        public string? MedicalHistoryNotes { get; set; }
    }
}