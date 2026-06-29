using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VitaCheck.API.Migrations
{
    /// <inheritdoc />
    public partial class AddNewNutrientFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Calcium",
                table: "UserScanResults",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Fiber",
                table: "UserScanResults",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Potassium",
                table: "UserScanResults",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "SaturatedFat",
                table: "UserScanResults",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Sodium",
                table: "UserScanResults",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Calcium",
                table: "UserScanResults");

            migrationBuilder.DropColumn(
                name: "Fiber",
                table: "UserScanResults");

            migrationBuilder.DropColumn(
                name: "Potassium",
                table: "UserScanResults");

            migrationBuilder.DropColumn(
                name: "SaturatedFat",
                table: "UserScanResults");

            migrationBuilder.DropColumn(
                name: "Sodium",
                table: "UserScanResults");
        }
    }
}
