using System.Text.Json.Serialization;

namespace Piraeus.BetterLandlord.Model;

/// <summary>Top-level v2.0 history record.</summary>
public class RunRecord
{
    [JsonPropertyName("history_version")]
    public string HistoryVersion { get; set; } = "2.0";

    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("is_legacy_log")]
    public bool IsLegacyLog { get; set; }

    [JsonPropertyName("meta")]
    public RunMeta Meta { get; set; } = new();

    [JsonPropertyName("summary")]
    public RunSummary Summary { get; set; } = new();

    [JsonPropertyName("rent_cycles")]
    public List<RentCycle> RentCycles { get; set; } = new();

    public RunRecord() { }

    public RunRecord(string runId)
    {
        RunId = runId;
        Meta.RunId = runId;
    }
}
