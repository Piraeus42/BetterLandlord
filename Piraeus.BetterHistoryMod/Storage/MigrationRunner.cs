using Piraeus.BetterHistoryMod.Parser;

namespace Piraeus.BetterHistoryMod.Storage;

public class MigrationRunner
{
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
        var logEntries = _scanner.Scan();

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

    public int TotalProcessed => Migrated + MigratedTruncated + MigratedPartial + Corrupted + EmptyFiles + Failed;
    public int TotalMigrated => Migrated + MigratedTruncated + MigratedPartial;
}
