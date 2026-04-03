namespace VitaCheck.API.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public double SugarAmount { get; set; }
        public bool HasGluten { get; set; }
    }
}
