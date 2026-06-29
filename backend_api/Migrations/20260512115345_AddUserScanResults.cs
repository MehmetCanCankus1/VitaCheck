using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace VitaCheck.API.Migrations
{
    /// <inheritdoc />
    public partial class AddUserScanResults : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserScanResults",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    ScannedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    PortionGram = table.Column<double>(type: "double precision", nullable: false),
                    EnergyKcal = table.Column<double>(type: "double precision", nullable: true),
                    Fat = table.Column<double>(type: "double precision", nullable: true),
                    Sugar = table.Column<double>(type: "double precision", nullable: true),
                    Protein = table.Column<double>(type: "double precision", nullable: true),
                    Salt = table.Column<double>(type: "double precision", nullable: true),
                    Carbohydrate = table.Column<double>(type: "double precision", nullable: true),
                    TopRiskScore = table.Column<double>(type: "double precision", nullable: false),
                    TopRiskDisease = table.Column<string>(type: "text", nullable: false),
                    OverallRiskLevel = table.Column<string>(type: "text", nullable: false),
                    DoctorAdvice = table.Column<string>(type: "text", nullable: false),
                    MlRisksJson = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserScanResults", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserScanResults_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserScanResults_UserId",
                table: "UserScanResults",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserScanResults");
        }
    }
}
