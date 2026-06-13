using SlotWeave;
using Piraeus.BetterLandlord.Ipc;
using Piraeus.BetterLandlord.Patches;
using Piraeus.BetterLandlord.Storage;

namespace Piraeus.BetterLandlord;

public class Mod : IMod
{
    private readonly IModInterface _modInterface;
    private GamePipeServer? _pipeServer;

    public Mod(IModInterface modInterface)
    {
        _modInterface = modInterface;
        _modInterface.Logger.Information("[BetterLandlord] initializing...");

        // ISourceMod: event capture helpers on Main node (Main.tscn::1)
        _modInterface.RegisterSourceMod(new MainScriptSourceMod());

        // ISourceMod: RNG infrastructure (PCGRng class, init_rng) on Main node
        _modInterface.RegisterSourceMod(new RngInfrastructureSourceMod());

        // ISourceMod: Choice RNG replacements in Pop-up
        _modInterface.RegisterSourceMod(new ChoiceRngSourceMod());

        // ReelRNG: inject wrappers only (no full-file Regex — regex on this
        // heavily-instantiated script triggers GDScript reload crash)
        _modInterface.RegisterSourceMod(new ReelRngRefSourceMod());

        _modInterface.RegisterSourceMod(new SlotIconRngSourceMod());
        _modInterface.RegisterSourceMod(new HoverIconRemovalSourceMod());
        _modInterface.RegisterSourceMod(new ItemRngSourceMod());
        _modInterface.RegisterSourceMod(new ReelExtraRngSourceMod());
        _modInterface.RegisterSourceMod(new LandlordRngRefSourceMod());
        _modInterface.RegisterSourceMod(new CosmeticRngSourceMod());

        // ISourceMod: clipboard preservation (TTButton clears clipboard for TTS)
        _modInterface.RegisterSourceMod(new ClipboardPreserveMod());

        // ISourceMod: guillotine end-run trigger at Coins/Items trigger point
        // (replaces GuillotineEndPatch — fires before animation, board intact)
        _modInterface.RegisterSourceMod(new GuillotineTriggerSourceMod());

        // ISourceMod: seed UI on Title node (Main.tscn::6)
        _modInterface.RegisterSourceMod(new TitleSeedSourceMod());

        // ISourceMod: IPC toggle helpers on Title node (Main.tscn::6)
        _modInterface.RegisterSourceMod(new TitleToggleSourceMod());

        // ISourceMod: seed-exclusion guards on Stats node (Stats.tscn::1)
        _modInterface.RegisterSourceMod(new SeededStatsSourceMod());

        // [Patch] classes are auto-discovered by SlotWeave:
        // ReadyPatch, TitlePatch, SpinPatch, WriteLogPatch,
        // ResolveEventPatch, HistoryButtonPatch, SeededAchievementPatch

        // Run legacy log migration on startup
        RunMigration();

        // Initialize and start the IPC pipe server.
        var userDataDir = GetUserDataDir();
        var modDir = Path.GetDirectoryName(typeof(Mod).Assembly.Location)
                     ?? Path.Combine(_modInterface.GameDir, "SlotWeave", "mods", "Piraeus.BetterLandlord");
        var store = new HistoryStore(userDataDir);

        // Rebuild lightweight manifest (fast — uses JsonDocument, not full deserialization)
        store.RebuildManifest();

        _pipeServer = new GamePipeServer(store, userDataDir, modDir, _modInterface.Logger);

        // Register GameStateBus reader for seed request signal (GDScript → C#, ~16ms latency)
        _modInterface.RegisterGameStateReader(_pipeServer.SeedReader);

        _pipeServer.Start();
    }

    private void RunMigration()
    {
        try
        {
            var userDataDir = GetUserDataDir();
            var runner = new MigrationRunner(userDataDir);
            var result = runner.Run();

            _modInterface.Logger.Information(
                "[BetterLandlord] Migration done: {Migrated} complete + {Truncated} truncated + {Partial} partial " +
                "({Skipped} skipped, {Empty} empty, {Corrupted} corrupted, {Failed} failed) — history db at {Dir}",
                result.Migrated, result.MigratedTruncated, result.MigratedPartial,
                result.Skipped, result.EmptyFiles, result.Corrupted, result.Failed,
                runner.HistoryDir);
        }
        catch (Exception ex)
        {
            _modInterface.Logger.Error("[BetterLandlord] Migration failed: {Error}", ex.Message);
        }
    }

    private static string GetUserDataDir()
    {
        var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        return Path.Combine(appData, "Godot", "app_userdata", "Luck be a Landlord");
    }

    public void Dispose()
    {
        if (_pipeServer != null)
        {
            _modInterface.UnregisterGameStateReader(_pipeServer.SeedReader);
            _pipeServer.Dispose();
        }
        _modInterface.Logger.Information("[BetterLandlord] unloaded.");
    }
}
