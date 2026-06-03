using System.Text.Json;
using System.Text.Json.Serialization;
using Piraeus.BetterHistoryMod.Model;

namespace Piraeus.BetterHistoryMod.Storage;

public class HistoryStore
{
    private readonly string _historyDir;
    private readonly string _manifestPath;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    public HistoryStore(string userDataDir)
    {
        _historyDir = Path.Combine(userDataDir, "betterHistory");
        _manifestPath = Path.Combine(_historyDir, "manifest.json");
    }

    public void EnsureDirectories()
    {
        Directory.CreateDirectory(_historyDir);
        Directory.CreateDirectory(Path.Combine(_historyDir, "runs"));
    }

    public bool HasHistory(string runId)
    {
        return File.Exists(GetRunPath(runId));
    }

    public RunRecord? Load(string runId)
    {
        var path = GetRunPath(runId);
        if (!File.Exists(path)) return null;

        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<RunRecord>(json, JsonOptions);
    }

    public void Save(RunRecord record)
    {
        EnsureDirectories();
        var path = GetRunPath(record.RunId);
        var json = JsonSerializer.Serialize(record, JsonOptions);
        File.WriteAllText(path, json);
        UpdateManifestEntry(record);
    }

    /// <summary>
    /// Rebuild the manifest by scanning all run JSONs.
    /// Uses JsonDocument for lightweight field extraction — no full RunRecord deserialization.
    /// </summary>
    public void RebuildManifest()
    {
        var runsDir = Path.Combine(_historyDir, "runs");
        if (!Directory.Exists(runsDir)) return;

        var entries = new List<ManifestEntry>();
        foreach (var file in Directory.GetFiles(runsDir, "*.json"))
        {
            try
            {
                var runId = Path.GetFileNameWithoutExtension(file);
                if (string.IsNullOrEmpty(runId)) continue;

                var json = File.ReadAllText(file);
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;

                var meta = root.TryGetProperty("meta", out var m) ? m : default;
                entries.Add(new ManifestEntry
                {
                    RunId = runId,
                    RunNumber = meta.TryGetProperty("run_number", out var rn) ? rn.GetInt32() : 0,
                    EndedBy = meta.TryGetProperty("ended_by", out var eb) ? eb.GetString() ?? "loss" : "loss",
                    Floor = meta.TryGetProperty("floor", out var fl) && fl.ValueKind != JsonValueKind.Null ? fl.GetInt32() : null,
                    FinalCoins = meta.TryGetProperty("final_coins", out var fc) ? fc.GetDouble() : 0,
                    TotalSpins = meta.TryGetProperty("total_spins", out var ts) ? ts.GetInt32() : 0,
                    StartTime = meta.TryGetProperty("start_time", out var st) && st.ValueKind != JsonValueKind.Null ? st.GetString() : null,
                    TopSymbols = ExtractTopSymbols(doc)
                });
            }
            catch { /* skip corrupted files */ }
        }

        entries.Sort((a, b) => string.CompareOrdinal(b.RunId, a.RunId));

        var manifest = new HistoryManifest
        {
            UpdatedAt = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss"),
            TotalRuns = entries.Count,
            Entries = entries
        };
        var manifestJson = JsonSerializer.Serialize(manifest, JsonOptions);
        File.WriteAllText(_manifestPath, manifestJson);
    }

    /// <summary>Add or update a single run's entry in the manifest (for live saves).</summary>
    private void UpdateManifestEntry(RunRecord record)
    {
        var manifest = LoadManifest();
        if (manifest == null) return;

        var existing = manifest.Entries.Find(e => e.RunId == record.RunId);
        if (existing != null)
        {
            existing.RunNumber = record.Meta.RunNumber;
            existing.EndedBy = record.Meta.EndedBy;
            existing.Floor = record.Meta.Floor;
            existing.FinalCoins = record.Meta.FinalCoins;
            existing.TotalSpins = record.Meta.TotalSpins;
            existing.StartTime = record.Meta.StartTime;
        }
        else
        {
            manifest.Entries.Insert(0, new ManifestEntry
            {
                RunId = record.RunId,
                RunNumber = record.Meta.RunNumber,
                EndedBy = record.Meta.EndedBy,
                Floor = record.Meta.Floor,
                FinalCoins = record.Meta.FinalCoins,
                TotalSpins = record.Meta.TotalSpins,
                StartTime = record.Meta.StartTime
            });
            manifest.TotalRuns = manifest.Entries.Count;
        }

        manifest.UpdatedAt = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss");
        var json = JsonSerializer.Serialize(manifest, JsonOptions);
        File.WriteAllText(_manifestPath, json);
    }

    public ManifestEntryList? LoadManifestEntries()
    {
        var manifest = LoadManifest();
        return manifest != null
            ? new ManifestEntryList { Entries = manifest.Entries, UpdatedAt = manifest.UpdatedAt }
            : null;
    }

    /// <summary>Extract top 3 symbol IDs from summary.symbols sorted by total_value. Returns null if no data.</summary>
    public static List<string>? ExtractTopSymbols(JsonDocument doc)
    {
        var root = doc.RootElement;
        if (!root.TryGetProperty("summary", out var summary)) return null;
        if (!summary.TryGetProperty("symbols", out var syms) || syms.ValueKind != System.Text.Json.JsonValueKind.Array) return null;

        var ranked = new List<(string id, double value)>();
        foreach (var s in syms.EnumerateArray())
        {
            var id = s.TryGetProperty("id", out var idEl) ? idEl.GetString() ?? "" : "";
            var val = s.TryGetProperty("total_value", out var tv) && tv.ValueKind != System.Text.Json.JsonValueKind.Null ? tv.GetDouble() : 0;
            if (!string.IsNullOrEmpty(id) && val > 0)
                ranked.Add((id, val));
        }
        if (ranked.Count == 0) return null;

        ranked.Sort((a, b) => b.value.CompareTo(a.value));
        return ranked.Take(3).Select(r => r.id).ToList();
    }

    public HistoryManifest? LoadManifest()
    {
        if (!File.Exists(_manifestPath)) return null;
        var json = File.ReadAllText(_manifestPath);
        return JsonSerializer.Deserialize<HistoryManifest>(json, JsonOptions);
    }

    public IReadOnlyList<string> GetExistingHistoryIds()
    {
        var runsDir = Path.Combine(_historyDir, "runs");
        if (!Directory.Exists(runsDir)) return Array.Empty<string>();

        return Directory.GetFiles(runsDir, "*.json")
            .Select(f => Path.GetFileNameWithoutExtension(f) ?? "")
            .Where(n => n != "")
            .ToList();
    }

    private string GetRunPath(string runId) =>
        Path.Combine(_historyDir, "runs", $"{runId}.json");

    public string HistoryDir => _historyDir;
}

public class HistoryManifest
{
    [JsonPropertyName("updated_at")]
    public string UpdatedAt { get; set; } = "";

    [JsonPropertyName("total_runs")]
    public int TotalRuns { get; set; }

    [JsonPropertyName("entries")]
    public List<ManifestEntry> Entries { get; set; } = new();
}

public class ManifestEntryList
{
    public string UpdatedAt { get; set; } = "";
    public List<ManifestEntry> Entries { get; set; } = new();
}

public class ManifestEntry
{
    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("run_number")]
    public int RunNumber { get; set; }

    [JsonPropertyName("ended_by")]
    public string EndedBy { get; set; } = "loss";

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
