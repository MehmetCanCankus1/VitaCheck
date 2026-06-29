using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VitaCheck.API.Migrations
{
    /// <inheritdoc />
    public partial class AddLazyWaterReset : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastWaterDate",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "WaterCount",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastWaterDate",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "WaterCount",
                table: "Users");
        }
    }
}
