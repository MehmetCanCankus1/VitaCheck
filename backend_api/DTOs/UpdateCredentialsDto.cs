namespace VitaCheck.API.DTOs
{
    public class UpdateCredentialsDto
    {
        public int UserId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? OldPassword { get; set; }
        public string? NewPassword { get; set; }
    }
}
