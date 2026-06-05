using System.Text.Json.Serialization;

namespace Piraeus.BetterLandlord.Model;

public class RunMeta
{
    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("run_number")]
    public int RunNumber { get; set; }

    [JsonPropertyName("game_version")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? GameVersion { get; set; }

    [JsonPropertyName("start_time")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? StartTime { get; set; }

    [JsonPropertyName("end_time")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? EndTime { get; set; }

    [JsonPropertyName("ended_by")]
    public string EndedBy { get; set; } = "loss";

    [JsonPropertyName("floor")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? Floor { get; set; }

    [JsonPropertyName("final_coins")]
    public double FinalCoins { get; set; }

    [JsonPropertyName("total_spins")]
    public int TotalSpins { get; set; }

    // ---- Parse metadata ----

    [JsonPropertyName("source_log_file")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? SourceLogFile { get; set; }

    [JsonPropertyName("parser_version")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ParserVersion { get; set; }

    [JsonPropertyName("parse_confidence")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public string? ParseConfidence { get; set; }

    [JsonPropertyName("seed_type")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? SeedType { get; set; }

    [JsonPropertyName("seed_input")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? SeedInput { get; set; }

    [JsonPropertyName("landlord_seed")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int LandlordSeed { get; set; }
}
