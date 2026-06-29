using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VitaCheck.API.Data;
using VitaCheck.API.Models;
using VitaCheck.API.DTOs;

namespace VitaCheck.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Users
        [HttpGet]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
        {
            return await _context.Users.ToListAsync();
        }

        // GET: api/Users/5
        [HttpGet("{id}")]
        public async Task<ActionResult<User>> GetUser(int id)
        {
            var user = await _context.Users.FindAsync(id);

            if (user == null)
            {
                return NotFound(new { message = $"User with ID {id} not found." });
            }

            // Lazy Reset: Gün değişmişse su sayacını sıfırla
            if (user.LastWaterDate.Date < DateTime.UtcNow.Date)
            {
                user.WaterCount = 0;
                user.LastWaterDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return user;
        }

        // POST: api/Users
        [HttpPost]
        public async Task<ActionResult<User>> PostUser(User user)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Email == user.Email);
            if (userExists)
            {
                return BadRequest(new { message = "Bu e-posta adresi ile zaten bir hesap mevcut." });
            }

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(user);
        }

        // PUT: api/Users/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutUser(int id, User user)
        {
            if (id != user.Id)
            {
                return BadRequest(new { message = "User ID mismatch." });
            }

            _context.Entry(user).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserExists(id))
                {
                    return NotFound(new { message = $"User with ID {id} not found." });
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: api/Users/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = $"User with ID {id} not found." });
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/Users/5/health-profile
        [HttpPut("{id}/health-profile")]
        public async Task<IActionResult> UpdateHealthProfile(int id, [FromBody] UpdateHealthProfileDto healthProfileDto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = $"User with ID {id} not found." });
            }

            user.Age = healthProfileDto.Age;
            user.Height = healthProfileDto.Height;
            user.Weight = healthProfileDto.Weight;
            user.DailySugarLimit = healthProfileDto.DailySugarLimit;

            user.HasDiabetes = healthProfileDto.HasDiabetes;
            user.HasObesity = healthProfileDto.HasObesity;
            user.HasHypertension = healthProfileDto.HasHypertension;
            user.HasHyperlipidemia = healthProfileDto.HasHyperlipidemia;
            user.HasCardiovascularRisk = healthProfileDto.HasCardiovascularRisk;
            user.HasKidneyDiseaseRisk = healthProfileDto.HasKidneyDiseaseRisk;
            user.HasMetabolicSyndromeRisk = healthProfileDto.HasMetabolicSyndromeRisk;
            user.HasFattyLiverRisk = healthProfileDto.HasFattyLiverRisk;
            user.HasProteinEnergyDeficiency = healthProfileDto.HasProteinEnergyDeficiency;
            user.HasMineralImbalance = healthProfileDto.HasMineralImbalance;

            await _context.SaveChangesAsync();

            return Ok(user);
        }

        // POST: api/Users/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] UserLoginDto loginDto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == loginDto.Email && u.Password == loginDto.Password);

            if (user == null)
            {
                return NotFound(new { message = "E-posta veya şifre hatalı." });
            }

            return Ok(user);
        }

        // POST: api/Users/update-credentials
        [HttpPost("update-credentials")]
        public async Task<IActionResult> UpdateCredentials([FromBody] UpdateCredentialsDto dto)
        {
            var user = await _context.Users.FindAsync(dto.UserId);
            if (user == null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı." });
            }

            user.Name = dto.Name;

            if (!string.IsNullOrEmpty(dto.NewPassword))
            {
                if (user.Password != dto.OldPassword)
                {
                    return BadRequest(new { message = "Eski şifrenizi yanlış girdiniz." });
                }
                user.Password = dto.NewPassword;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Profil başarıyla güncellendi" });
        }

        // POST: api/Users/update-photo
        [HttpPost("update-photo")]
        public async Task<IActionResult> UpdatePhoto([FromBody] UpdatePhotoDto dto)
        {
            var user = await _context.Users.FindAsync(dto.UserId);
            if (user == null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı." });
            }

            user.ProfilePhoto = dto.PhotoBase64;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Fotoğraf başarıyla güncellendi" });
        }

        // GET: api/Users/5/water-today
        [HttpGet("{userId}/water-today")]
        public async Task<IActionResult> GetWaterToday(int userId)
        {
            var today = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
            var record = await _context.WaterIntakes
                .FirstOrDefaultAsync(w => w.UserId == userId && w.Date.Date == today);

            return Ok(new { count = record?.Count ?? 0 });
        }

        // POST: api/Users/update-water
        [HttpPost("update-water")]
        public async Task<IActionResult> UpdateWater([FromBody] UpdateWaterDto dto)
        {
            var today = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
            var record = await _context.WaterIntakes
                .FirstOrDefaultAsync(w => w.UserId == dto.UserId && w.Date.Date == today);

            if (record != null)
            {
                record.Count = dto.Count;
            }
            else
            {
                record = new WaterIntake
                {
                    UserId = dto.UserId,
                    Count = dto.Count,
                    Date = today
                };
                _context.WaterIntakes.Add(record);
            }

            // User modelindeki WaterCount ve LastWaterDate'i de güncelle
            var user = await _context.Users.FindAsync(dto.UserId);
            if (user != null)
            {
                user.WaterCount = dto.Count;
                user.LastWaterDate = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Su miktarı güncellendi.", count = record.Count });
        }

        private bool UserExists(int id)
        {
            return _context.Users.Any(e => e.Id == id);
        }
    }
}
