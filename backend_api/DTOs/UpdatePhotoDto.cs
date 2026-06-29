namespace VitaCheck.API.DTOs
{
    public class UpdatePhotoDto
    {
        public int UserId { get; set; }
        public string PhotoBase64 { get; set; } = string.Empty;
    }
}
