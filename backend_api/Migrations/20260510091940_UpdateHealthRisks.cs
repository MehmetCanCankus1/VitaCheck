using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VitaCheck.API.Migrations
{
    /// <inheritdoc />
    public partial class UpdateHealthRisks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ChronicDisease",
                table: "Users");

            migrationBuilder.AddColumn<bool>(
                name: "HasCardiovascularRisk",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasDiabetes",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasFattyLiverRisk",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasHyperlipidemia",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasHypertension",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasKidneyDiseaseRisk",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasMetabolicSyndromeRisk",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasMineralImbalance",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasObesity",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasProteinEnergyDeficiency",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HasCardiovascularRisk",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasDiabetes",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasFattyLiverRisk",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasHyperlipidemia",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasHypertension",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasKidneyDiseaseRisk",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasMetabolicSyndromeRisk",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasMineralImbalance",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasObesity",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasProteinEnergyDeficiency",
                table: "Users");

            migrationBuilder.AddColumn<string>(
                name: "ChronicDisease",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");
        }
    }
}
