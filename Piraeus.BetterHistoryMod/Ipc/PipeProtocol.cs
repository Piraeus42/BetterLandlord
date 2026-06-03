using System.Text.Json;
using System.Text.Json.Serialization;
using Piraeus.BetterHistoryMod.Model;

namespace Piraeus.BetterHistoryMod.Ipc;

/// <summary>
/// Shared IPC message types and serialization helpers.
/// Used by both GamePipeServer (game side) and UiPipeClient (UI side).
/// </summary>
public static class PipeProtocol
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
        WriteIndented = false
    };

    // ---- Message type constants ----

    public const string TypeRunList = "run_list";
    public const string TypeRunData = "run_data";
    public const string TypeError = "error";
    public const string TypeGetRunList = "get_run_list";
    public const string TypeGetRun = "get_run";
    public const string TypeSetSeed = "set_seed";
    public const string TypeClose = "close";

    // ---- Serialization ----

    public static string Serialize<T>(T message) =>
        JsonSerializer.Serialize(message, JsonOptions);

    public static T? Deserialize<T>(string json) =>
        JsonSerializer.Deserialize<T>(json, JsonOptions);

    /// <summary>Peek the "type" field without full deserialization.</summary>
    public static string? PeekType(string json)
    {
        try
        {
            var doc = JsonDocument.Parse(json);
            return doc.RootElement.TryGetProperty("type", out var typeEl) ? typeEl.GetString() : null;
        }
        catch
        {
            return null;
        }
    }
}

// ---- Game → UI messages ----

public class RunListMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeRunList;

    [JsonPropertyName("runs")]
    public List<RunListItem> Runs { get; set; } = new();
}

public class RunListItem
{
    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("run_number")]
    public int RunNumber { get; set; }

    [JsonPropertyName("ended_by")]
    public string EndedBy { get; set; } = "unknown";

    [JsonPropertyName("floor")]
    public int? Floor { get; set; }

    [JsonPropertyName("final_coins")]
    public double FinalCoins { get; set; }

    [JsonPropertyName("total_spins")]
    public int TotalSpins { get; set; }

    [JsonPropertyName("start_time")]
    public string? StartTime { get; set; }

    [JsonPropertyName("top_symbols")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<string>? TopSymbols { get; set; }
}

public class RunDataMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeRunData;

    [JsonPropertyName("record")]
    public RunRecord? Record { get; set; }
}

public class ErrorMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeError;

    [JsonPropertyName("message")]
    public string Message { get; set; } = "";
}

// ---- UI → Game messages ----

public class SetSeedMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeSetSeed;

    [JsonPropertyName("input")]
    public string Input { get; set; } = "";
}

public class GetRunListMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeGetRunList;
}

public class GetRunMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeGetRun;

    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";
}

public class CloseMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeClose;
}
