using Piraeus.BetterLandlord.Storage;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class HistoryStoreTests : IDisposable
{
    private readonly DirectoryInfo _directory;

    public HistoryStoreTests()
    {
        _directory = Directory.CreateTempSubdirectory("piraeus-better-landlord-");
        Directory.CreateDirectory(Path.Combine(_directory.FullName, "betterHistory", "runs"));
    }

    [Fact]
    public void RunListEntriesAreSortedAndCachedByVersion()
    {
        var store = new HistoryStore(_directory.FullName);
        WriteRun("0001", 1, "quit");
        WriteRun("0002", 2, "victory");

        var first = store.GetRunListEntries();
        var second = store.GetRunListEntries();

        Assert.Equal(new[] { "0002", "0001" }, first.Select(entry => entry.RunId).ToArray());
        Assert.Equal("victory", first[0].EndedBy);
        Assert.Equal(new[] { "apple", "gem" }, first[0].TopSymbols);

        Assert.Same(first[0], second[0]);
        Assert.Same(first[1], second[1]);
    }

    [Fact]
    public void RunListEntriesRefreshWhenFileVersionChanges()
    {
        var store = new HistoryStore(_directory.FullName);
        WriteRun("0001", 1, "quit");

        Assert.Equal("quit", store.GetRunListEntries().Single().EndedBy);

        WriteRun("0001", 1, "victory");

        Assert.Equal("victory", store.GetRunListEntries().Single().EndedBy);
    }

    [Fact]
    public void CorruptRunKeepsPreviousCachedSummaryVisible()
    {
        var store = new HistoryStore(_directory.FullName);
        WriteRun("0001", 1, "quit");

        var first = store.GetRunListEntries();
        File.WriteAllText(
            Path.Combine(_directory.FullName, "betterHistory", "runs", "0001.json"),
            "{ invalid json");

        var second = store.GetRunListEntries();

        Assert.Single(second);
        Assert.Same(first[0], second[0]);
    }

    [Fact]
    public void RemovingRunsDirectoryClearsRunListCache()
    {
        var store = new HistoryStore(_directory.FullName);
        WriteRun("0001", 1, "quit");

        Assert.Single(store.GetRunListEntries());
        Directory.Delete(Path.Combine(_directory.FullName, "betterHistory"), true);

        Assert.Empty(store.GetRunListEntries());
    }

    private void WriteRun(string runId, int runNumber, string endedBy)
    {
        var json = $$"""
            {
              "meta": {
                "run_id": "{{runId}}",
                "run_number": {{runNumber}},
                "ended_by": "{{endedBy}}",
                "floor": {{runNumber}},
                "final_coins": 120.5,
                "total_spins": 20,
                "start_time": "2026-08-30T10:00:00"
              },
              "summary": {
                "dpt_summary": [
                  { "id": "apple", "total_value": 12 },
                  { "id": "gem", "total_value": 7 }
                ]
              }
            }
            """;
        File.WriteAllText(
            Path.Combine(_directory.FullName, "betterHistory", "runs", $"{runId}.json"),
            json);
    }

    public void Dispose()
    {
        _directory.Delete(recursive: true);
    }
}
