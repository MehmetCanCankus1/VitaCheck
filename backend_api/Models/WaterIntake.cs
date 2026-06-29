using System;

namespace VitaCheck.API.Models
{
    public class WaterIntake
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int Count { get; set; }
        public DateTime Date { get; set; }
    }
}
