using Piraeus.BetterLandlord.Storage;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class MigrationRunnerTests : IDisposable
{
    private readonly DirectoryInfo _directory;

    public MigrationRunnerTests()
    {
        _directory = Directory.CreateTempSubdirectory("piraeus-better-landlord-");
        Directory.CreateDirectory(Path.Combine(_directory.FullName, "betterHistory", "runs"));
        Directory.CreateDirectory(Path.Combine(_directory.FullName, "run_logs"));
    }

    [Fact]
    public void LogForRunAlreadyCapturedLiveIsSkipped()
    {
        // The mod recorded the run under 1789065521; the game named its log
        // with run_timestamp one second later.
        WriteRun("1789065521", 565, legacy: false);
        WriteLog("1789065522", 565);

        var result = new MigrationRunner(_directory.FullName).Run();

        Assert.False(File.Exists(RunPath("1789065522")));
        Assert.True(File.Exists(RunPath("1789065521")));
        Assert.Equal(1, result.DuplicatesSkipped);
    }

    [Fact]
    public void LegacyParsedDuplicateOfLiveRunIsRemoved()
    {
        // Pre-fix builds already wrote the duplicate; migration must clean it.
        WriteRun("1789065521", 565, legacy: false);
        WriteRun("1789065522", 565, legacy: true);
        WriteLog("1789065522", 565);

        var result = new MigrationRunner(_directory.FullName).Run();

        Assert.False(File.Exists(RunPath("1789065522")));
        Assert.True(File.Exists(RunPath("1789065521")));
        Assert.Equal(1, result.DuplicatesRemoved);
    }

    [Fact]
    public void NearbyDistinctRunsAreKept()
    {
        // Two different runs a second apart must not be treated as duplicates.
        WriteRun("1789065521", 565, legacy: false);
        WriteRun("1789065522", 566, legacy: true);

        var result = new MigrationRunner(_directory.FullName).Run();

        Assert.True(File.Exists(RunPath("1789065521")));
        Assert.True(File.Exists(RunPath("1789065522")));
        Assert.Equal(0, result.DuplicatesRemoved);
    }

    [Fact]
    public void LogWithoutLiveTwinStillMigrates()
    {
        WriteLog("1789065522", 565);

        var result = new MigrationRunner(_directory.FullName).Run();

        Assert.True(File.Exists(RunPath("1789065522")));
        Assert.Equal(1, result.Migrated + result.MigratedPartial + result.MigratedTruncated);
    }

    private string RunPath(string runId) =>
        Path.Combine(_directory.FullName, "betterHistory", "runs", $"{runId}.json");

    private void WriteRun(string runId, int runNumber, bool legacy)
    {
        var confidence = legacy ? ",\n    \"parse_confidence\": \"complete\"" : "";
        var legacyFlag = legacy ? "true" : "false";
        var json = $$"""
            {
              "history_version": "2.0",
              "run_id": "{{runId}}",
              "is_legacy_log": {{legacyFlag}},
              "meta": {
                "run_number": {{runNumber}},
                "ended_by": "loss",
                "total_spins": 44,
                "final_coins": 352{{confidence}}
              },
              "summary": {},
              "rent_cycles": []
            }
            """;
        File.WriteAllText(RunPath(runId), json);
    }

    private void WriteLog(string runId, int runNumber)
    {
        // LogParser rejects files with <=2 lines and extracts the run number
        // from the STARTING RUN header, so the fixture needs a real skeleton.
        File.WriteAllText(
            Path.Combine(_directory.FullName, "run_logs", $"{runId}.log"),
            $"[9/11/2026 02:38:42] --- STARTING RUN #{runNumber} ---\n" +
            "[9/11/2026 02:38:42] --- v1.2.24 ---\n" +
            "[9/11/2026 02:38:42] --- SPIN #0 ---\n" +
            "[9/11/2026 02:38:43] Currently have 1 coins\n" +
            "[9/11/2026 02:38:45] Coin total is now 5 after spinning\n");
    }

    public void Dispose()
    {
        _directory.Delete(recursive: true);
    }
}
