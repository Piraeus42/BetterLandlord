namespace Piraeus.BetterLandlord.Parser;

public class LogScanner
{
    private readonly string _runLogsDir;

    public LogScanner(string userDataDir)
    {
        _runLogsDir = Path.Combine(userDataDir, "run_logs");
    }

    public bool RunLogsExist => Directory.Exists(_runLogsDir);

    public IReadOnlyList<LogFileEntry> Scan()
    {
        if (!RunLogsExist)
            return Array.Empty<LogFileEntry>();

        var entries = new List<LogFileEntry>();
        foreach (var filePath in Directory.GetFiles(_runLogsDir, "*.log"))
        {
            var fileName = Path.GetFileNameWithoutExtension(filePath);
            var fileInfo = new FileInfo(filePath);

            entries.Add(new LogFileEntry
            {
                RunId = fileName,
                FilePath = filePath,
                SizeBytes = fileInfo.Length,
                LastModified = fileInfo.LastWriteTimeUtc
            });
        }

        // Sort by run ID (which is a Unix timestamp), oldest first
        entries.Sort((a, b) => long.TryParse(a.RunId, out var la) && long.TryParse(b.RunId, out var lb)
            ? la.CompareTo(lb)
            : string.CompareOrdinal(a.RunId, b.RunId));

        return entries;
    }
}

public class LogFileEntry
{
    public string RunId { get; set; } = "";
    public string FilePath { get; set; } = "";
    public long SizeBytes { get; set; }
    public DateTime LastModified { get; set; }
}
