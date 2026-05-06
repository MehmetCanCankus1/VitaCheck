namespace VitaCheck.API.Models
{
    public class Analysis
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public double SugarAmount { get; set; }
        public bool HasGluten { get; set; }
        public bool IsSafe { get; set; }
        public string WarningMessage { get; set; } = string.Empty;
        public int Score { get; set; }
        public DateTime Date { get; set; } = DateTime.UtcNow;
    }
}