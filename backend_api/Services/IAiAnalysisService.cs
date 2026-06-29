using VitaCheck.API.DTOs;

namespace VitaCheck.API.Services
{
    public interface IAiAnalysisService
    {
        Task<AiExtractOcrResponseDto> ExtractOcrAsync(
            Stream imageStream,
            string fileName);

        Task<AiAnalysisResponseDto> GenerateReportAsync(AiGenerateReportRequestDto request);
    }
}
