namespace VitaCheck.API.DTOs
{
    public class OcrDataDto
    {
        public int UserId { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public double SugarAmount { get; set; }
        public bool HasGluten { get; set; }
    }
}
