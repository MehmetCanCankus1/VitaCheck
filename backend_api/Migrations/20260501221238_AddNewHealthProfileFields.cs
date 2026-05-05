using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VitaCheck.API.Migrations
{
    /// <inheritdoc />
    public partial class AddNewHealthProfileFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "DailySugarLimit",
                table: "Users",
                type: "integer",
                nullable: false,
                oldClrType: typeof(double),
                oldType: "double precision");

            migrationBuilder.AddColumn<List<string>>(
                name: "Allergies",
                table: "Users",
                type: "text[]",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasCeliacDisease",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasHighBloodPressure",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "MedicalHistoryNotes",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<List<string>>(
                name: "Medications",
                table: "Users",
                type: "text[]",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasCeliacDisease",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasHighBloodPressure",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "MedicalHistoryNotes",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Medications",
                table: "Users");

            migrationBuilder.AlterColumn<double>(
                name: "DailySugarLimit",
                table: "Users",
                type: "double precision",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");
        }
    }
}
