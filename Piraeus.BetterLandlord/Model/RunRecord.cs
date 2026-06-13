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

    /// <summary>
    /// Migrate old-format DPT data from symbols[] entries into the new dpt_summary array.
    /// Idempotent — no-op if dpt_summary already has entries.
    /// Only reads memory, never writes to disk.
    ///
    /// Old format (pre-v2): DPT fields (total_value, turns_present, turns_contributing,
    /// dpt_actual, dpt_effective) were written on each symbol badge-variant entry,
    /// with the same base-ID DPT duplicated across variants (gen 1) or on one variant (gen 2).
    /// To handle both: for each base symbol ID, take the entry with the MAX total_value
    /// (gen 1: all variants have same total_value, pick any; gen 2: only one variant &gt; 0).
    /// </summary>
    public void MigrateDptIfNeeded()
    {
        var s = Summary;
        if (s == null) return;
        if (s.DptSummary.Count > 0) return; // already migrated or new-format

        var syms = s.Symbols;
        if (syms == null || syms.Count == 0) return;

        // Check if any symbol entry carries old-format DPT data
        bool hasDpt = false;
        foreach (var sym in syms)
        {
            if (sym.TotalValue > 0 || sym.TurnsPresent > 0)
            {
                hasDpt = true;
                break;
            }
        }
        if (!hasDpt) return;

        // Group by base ID, keep the entry with max TotalValue per group
        var best = new Dictionary<string, SymbolInSummary>();
        foreach (var sym in syms)
        {
            if (string.IsNullOrEmpty(sym.Id)) continue;
            if (best.TryGetValue(sym.Id, out var cur))
            {
                if (sym.TotalValue > cur.TotalValue)
                    best[sym.Id] = sym;
            }
            else
            {
                best[sym.Id] = sym;
            }
        }

        // Build dpt_summary from the best entry per base ID
        foreach (var kv in best)
        {
            var sym = kv.Value;
            if (sym.TotalValue <= 0 && sym.TurnsPresent <= 0) continue;
            s.DptSummary.Add(new DptEntry
            {
                Id = sym.Id,
                TotalValue = sym.TotalValue,
                TurnsPresent = sym.TurnsPresent,
                TurnsContributing = sym.TurnsContributing,
                DptActual = sym.DptActual,
                DptEffective = sym.DptEffective,
                Departed = false  // old format couldn't track departed symbols
            });
        }
    }
}
