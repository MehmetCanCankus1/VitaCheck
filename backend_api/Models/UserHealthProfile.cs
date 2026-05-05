namespace backend_api.Models
{
    public class UserHealthProfile
    {
        // Yüksek Tansiyon (Tuz Kontrolü) - Ekranda Switch (Aç/Kapat) olduğu için bool
        public bool HasHighBloodPressure { get; set; } 
        
        // Çölyak Hastalığı - Ekranda Switch olduğu için bool
        public bool HasCeliacDisease { get; set; }     
        
        // Alerjik Olduğu Gıdalar - Ekranda çoklu seçim (Chip) olduğu için Liste
        public List<string> Allergies { get; set; } = new List<string>(); 
        
        // İlaç Kullanımı - Ekranda eklenebilir liste olduğu için Liste
        public List<string> Medications { get; set; } = new List<string>(); 
        
        // Hastalık Geçmişi Notları - Ekranda geniş metin kutusu olduğu için string
        public string MedicalHistoryNotes { get; set; } 
    }
}