using System.Text.Json;
using Piraeus.BetterLandlord.Parser;

namespace Piraeus.BetterLandlord.Storage;

public class MigrationRunner
{
    // The game names its run log after run_timestamp, which the mod's run_id
    // (taken moments earlier, in new_game's prefix) can trail by a second.
    // Neighbour records within this window are treated as the same run.
    private static readonly int[] NeighborOffsets = { -2, -1, 1, 2 };

    private readonly LogScanner _scanner;
    private readonly LogParser _parser;
    private readonly HistoryStore _store;

    public MigrationRunner(string userDataDir)
    {
        _scanner = new LogScanner(userDataDir);
        _parser = new LogParser();
        _store = new HistoryStore(userDataDir);
    }

    public MigrationResult Run()
    {
        var result = new MigrationResult();

        if (!_scanner.RunLogsExist)
            return result;

        _store.EnsureDirectories();
        var existingIds = new HashSet<string>(_store.GetExistingHistoryIds());
        var runMeta = LoadExistingRunMeta(existingIds);
        var logEntries = _scanner.Scan();

        RemoveLegacyDuplicates(existingIds, runMeta, result);

        foreach (var entry in logEntries)
        {
            // Skip if already migrated
            if (existingIds.Contains(entry.RunId))
            {
                result.Skipped++;
                continue;
            }

            try
            {
                // Skip empty files (0 bytes)
                if (entry.SizeBytes == 0)
                {
                    result.EmptyFiles++;
                    continue;
                }

                var record = _parser.Parse(entry.FilePath, entry.RunId);

                // A near-timestamp record that already captured the same
                // run_number means this log belongs to a run recorded live by
                // the mod. Re-parsing it would only add a duplicate entry with
                // no DPT or seed data.
                if (AlreadyCaptured(record, entry.RunId, runMeta))
                {
                    result.DuplicatesSkipped++;
                    continue;
                }

                _store.Save(record);

                switch (record.Meta.ParseConfidence)
                {
                    case "complete":
                        result.Migrated++;
                        break;
                    case "truncated":
                        result.MigratedTruncated++;
                        break;
                    case "partial":
                        result.MigratedPartial++;
                        break;
                    case "corrupted":
                        result.Corrupted++;
                        break;
                    default:
                        result.Migrated++;
                        break;
                }
            }
            catch (Exception)
            {
                result.Failed++;
            }
        }

        // Build lightweight manifest from all run JSONs
        _store.RebuildManifest();

        return result;
    }

    public HistoryStore Store => _store;
    public string HistoryDir => _store.HistoryDir;

    private sealed class ExistingRunMeta
    {
        public int RunNumber;
        public bool IsLogParsed;
    }

    private Dictionary<long, (string Id, ExistingRunMeta Meta)> LoadExistingRunMeta(HashSet<string> existingIds)
    {
        var meta = new Dictionary<long, (string, ExistingRunMeta)>();
        var runsDir = Path.Combine(_store.HistoryDir, "runs");
        foreach (var id in existingIds)
        {
            if (!long.TryParse(id, out var numeric))
                continue;

            try
            {
                var json = File.ReadAllText(Path.Combine(runsDir, id + ".json"));
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                if (!root.TryGetProperty("meta", out var m) || m.ValueKind != JsonValueKind.Object)
                    continue;

                var entry = new ExistingRunMeta
                {
                    RunNumber = m.TryGetProperty("run_number", out var rn) && rn.ValueKind == JsonValueKind.Number
                        ? rn.GetInt32()
                        : 0,
                    IsLogParsed = m.TryGetProperty("parse_confidence", out var pc) && pc.ValueKind == JsonValueKind.String
                };
                meta[numeric] = (id, entry);
            }
            catch (Exception)
            {
                // Unreadable files keep their id but contribute no dedupe metadata.
            }
        }
        return meta;
    }

    private static bool AlreadyCaptured(
        Model.RunRecord record,
        string runId,
        Dictionary<long, (string Id, ExistingRunMeta Meta)> runMeta)
    {
        if (record.Meta.RunNumber <= 0 || !long.TryParse(runId, out var numeric))
            return false;

        foreach (var offset in NeighborOffsets)
        {
            if (runMeta.TryGetValue(numeric + offset, out var neighbor)
                && neighbor.Meta.RunNumber == record.Meta.RunNumber)
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// Removes log-parsed duplicates written by earlier builds: when the
    /// game's run_timestamp trailed the mod's run_id by a second, the scan
    /// created a second record for the same run (no DPT/seed data, marked by
    /// parse_confidence). The live-captured twin wins.
    /// </summary>
    private void RemoveLegacyDuplicates(
        HashSet<string> existingIds,
        Dictionary<long, (string Id, ExistingRunMeta Meta)> runMeta,
        MigrationResult result)
    {
        var toDelete = new List<string>();
        foreach (var pair in runMeta)
        {
            var entry = pair.Value.Meta;
            if (!entry.IsLogParsed || entry.RunNumber <= 0)
                continue;

            foreach (var offset in NeighborOffsets)
            {
                if (runMeta.TryGetValue(pair.Key + offset, out var neighbor)
                    && !neighbor.Meta.IsLogParsed
                    && neighbor.Meta.RunNumber == entry.RunNumber)
                {
                    toDelete.Add(pair.Value.Id);
                    break;
                }
            }
        }

        foreach (var id in toDelete)
        {
            _store.Delete(id);
            existingIds.Remove(id);
        }
        result.DuplicatesRemoved = toDelete.Count;
    }
}

public class MigrationResult
{
    public int Migrated { get; set; }
    public int MigratedTruncated { get; set; }
    public int MigratedPartial { get; set; }
    public int Corrupted { get; set; }
    public int EmptyFiles { get; set; }
    public int Skipped { get; set; }
    public int Failed { get; set; }
    public int DuplicatesSkipped { get; set; }
    public int DuplicatesRemoved { get; set; }

    public int TotalProcessed => Migrated + MigratedTruncated + MigratedPartial + Corrupted + EmptyFiles + Failed;
    public int TotalMigrated => Migrated + MigratedTruncated + MigratedPartial;
}
