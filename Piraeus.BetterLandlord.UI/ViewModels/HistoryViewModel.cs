using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Windows;
using System.Windows.Threading;
using Piraeus.BetterLandlord.UI.Ipc;
using Piraeus.BetterLandlord.Ipc;
using Piraeus.BetterLandlord.Model;

namespace Piraeus.BetterLandlord.UI.ViewModels;

public class HistoryViewModel : INotifyPropertyChanged
{
    private readonly UiPipeClient _pipeClient;
    private readonly Dispatcher _dispatcher;

    public HistoryViewModel(UiPipeClient pipeClient)
    {
        _pipeClient = pipeClient;
        _dispatcher = Application.Current.Dispatcher;

        _pipeClient.OnMessageReceived += OnPipeMessage;
        _pipeClient.OnConnectionChanged += OnConnectionChanged;
        _pipeClient.OnError += OnPipeError;
    }

    // ---- Observable properties ----

    public ObservableCollection<RunListItemViewModel> Runs { get; } = new();

    private RunListItemViewModel? _selectedRun;
    public RunListItemViewModel? SelectedRun
    {
        get => _selectedRun;
        set
        {
            if (SetProperty(ref _selectedRun, value) && value != null)
            {
                _pipeClient.SendGetRun(value.RunId);
            }
        }
    }

    private RunRecord? _currentRecord;
    public RunRecord? CurrentRecord
    {
        get => _currentRecord;
        set
        {
            if (SetProperty(ref _currentRecord, value))
            {
                _currentRecord?.MigrateDptIfNeeded();
                RefreshMeta();
                OnPropertyChanged(nameof(TimelineRounds));
                OnPropertyChanged(nameof(Summary));
                OnPropertyChanged(nameof(HasData));
                OnPropertyChanged(nameof(RunInfo));
            }
        }
    }

    public string MetaCoins { get; private set; } = "";
    public string MetaDate { get; private set; } = "";
    public string MetaResult { get; private set; } = "";
    public string MetaSeed { get; private set; } = "";
    public string MetaSeedType { get; private set; } = "";
    public bool HasMeta => !string.IsNullOrEmpty(MetaCoins);
    public bool HasSeed => !string.IsNullOrEmpty(MetaSeed);

    // DPT ranking
    public ObservableCollection<DptRankEntry> DptRanking { get; } = new();
    public double MaxRankValue { get; private set; } = 1;
    public string RankModeLabel { get; private set; } = "Total Value";

    private enum DptMode { TotalValue, DptActual, DptEffective }
    private DptMode _rankMode = DptMode.TotalValue;

    private void RefreshMeta()
    {
        var m = _currentRecord?.Meta;
        if (m == null)
        {
            MetaCoins = "";
            MetaDate = "";
            MetaResult = "";
            MetaSeed = "";
            MetaSeedType = "";
        }
        else
        {
            MetaCoins = $"{m.FinalCoins} coins";
            MetaResult = FormatEndedBy(m.EndedBy);
            MetaDate = m.StartTime ?? "";
            if (MetaDate.Length >= 16) MetaDate = MetaDate[..16].Replace('T', ' ');
            MetaSeed = m.SeedInput ?? "";
            MetaSeedType = m.SeedType ?? "";
        }
        OnPropertyChanged(nameof(MetaCoins));
        OnPropertyChanged(nameof(MetaDate));
        OnPropertyChanged(nameof(MetaResult));
        OnPropertyChanged(nameof(MetaSeed));
        OnPropertyChanged(nameof(MetaSeedType));
        OnPropertyChanged(nameof(HasMeta));
        OnPropertyChanged(nameof(HasSeed));
        RefreshRanking();
    }

    public void RefreshRanking()
    {
        DptRanking.Clear();
        var dpt = _currentRecord?.Summary?.DptSummary;
        if (dpt == null || dpt.Count == 0) return;

        double GetValue(DptEntry d) => _rankMode switch
        {
            DptMode.TotalValue => d.TotalValue,
            DptMode.DptActual => d.DptActual,
            DptMode.DptEffective => d.DptEffective,
            _ => d.TotalValue
        };

        var ranked = dpt
            .OrderByDescending(GetValue)
            .Take(10)
            .ToList();

        MaxRankValue = ranked.Count > 0 ? GetValue(ranked[0]) : 1;
        if (MaxRankValue <= 0) MaxRankValue = 1;

        const double barMaxPx = 120;
        int rank = 1;
        foreach (var d in ranked)
        {
            var val = GetValue(d);
            DptRanking.Add(new DptRankEntry
            {
                Rank = rank++,
                IconId = d.Id,
                Name = d.Id,
                Count = 0,  // DPT is per-base, no badge count
                Departed = d.Departed,
                Value = val,
                BarWidthPx = val / MaxRankValue * barMaxPx,
                DetailText = _rankMode switch
                {
                    DptMode.TotalValue => $"{d.TotalValue} coins · {d.TurnsContributing} spins on grid",
                    DptMode.DptActual => $"{d.DptActual:F1}/spin · {d.TurnsPresent} turns present",
                    DptMode.DptEffective => $"{d.DptEffective:F1}/spin · {d.TurnsContributing} spins on grid",
                    _ => ""
                }
            });
        }

        OnPropertyChanged(nameof(DptRanking));
        OnPropertyChanged(nameof(MaxRankValue));
        OnPropertyChanged(nameof(RankModeLabel));
    }

    public void CycleRankMode(int direction = 1)
    {
        var modes = new[] { DptMode.TotalValue, DptMode.DptActual, DptMode.DptEffective };
        var labels = new[] { "Total Value", "DPT (实际)", "DPT (有效)" };
        var idx = Array.IndexOf(modes, _rankMode);
        if (idx < 0) idx = 0;
        idx = (idx + direction + modes.Length) % modes.Length;
        _rankMode = modes[idx];
        RankModeLabel = labels[idx];
        RefreshRanking();
    }

    private bool _isConnected;
    public bool IsConnected
    {
        get => _isConnected;
        set => SetProperty(ref _isConnected, value);
    }

    private string _statusText = "Waiting for game connection...";
    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public bool HasWinRateStats => !string.IsNullOrEmpty(WinRate50);
    public bool HasWinRate50 => !string.IsNullOrEmpty(WinRate50);
    public bool HasWinRate100 => !string.IsNullOrEmpty(WinRate100);
    public bool HasWinRate200 => !string.IsNullOrEmpty(WinRate200);

    private string _winRate50 = "";
    public string WinRate50 { get => _winRate50; set { SetProperty(ref _winRate50, value); OnPropertyChanged(nameof(HasWinRate50)); } }

    private string _winRate100 = "";
    public string WinRate100 { get => _winRate100; set { SetProperty(ref _winRate100, value); OnPropertyChanged(nameof(HasWinRate100)); } }

    private string _winRate200 = "";
    public string WinRate200 { get => _winRate200; set { SetProperty(ref _winRate200, value); OnPropertyChanged(nameof(HasWinRate200)); } }

    private string _winRateOverall = "";
    public string WinRateOverall { get => _winRateOverall; set => SetProperty(ref _winRateOverall, value); }

    private bool _showSummary;
    public bool ShowSummary
    {
        get => _showSummary;
        set => SetProperty(ref _showSummary, value);
    }

    // ---- Computed properties ----

    public bool HasData => CurrentRecord != null;
    public string RunInfo => CurrentRecord?.Meta != null
        ? $"Run #{CurrentRecord.Meta.RunNumber}{(CurrentRecord.Meta.SeedType == "custom" ? " \U0001F512" : "")} — {FormatEndedBy(CurrentRecord.Meta.EndedBy)} (Floor {CurrentRecord.Meta.Floor ?? 0})"
        : "";

    public RunSummary? Summary => CurrentRecord?.Summary;

    // Cache the timeline to avoid rebuilding on every binding refresh
    private List<TimelineRoundViewModel>? _cachedTimeline;
    public List<TimelineRoundViewModel> TimelineRounds
    {
        get
        {
            if (_currentRecord?.RentCycles == null)
                return _cachedTimeline ?? new();
            _cachedTimeline = _currentRecord.RentCycles
                .Select(rc => new TimelineRoundViewModel(rc))
                .ToList();
            return _cachedTimeline;
        }
    }

    // ---- Pipe message handlers (called from background thread) ----

    private void OnPipeMessage(string json)
    {
        // Capture json to local for async dispatch
        var jsonCopy = json;
        _dispatcher.BeginInvoke(() =>
        {
            try
            {
                var type = PeekType(jsonCopy);
                switch (type)
                {
                    case "run_list":
                        var listMsg = JsonSerializer.Deserialize<RunListMessage>(jsonCopy, JsonOptions);
                        if (listMsg?.Runs != null)
                        {
                            Runs.Clear();
                            foreach (var r in listMsg.Runs)
                                Runs.Add(new RunListItemViewModel(r));
                            StatusText = $"Connected — {Runs.Count} runs loaded";
                            UpdateWinRateStats();
                        }
                        break;

                    case "run_data":
                        var dataMsg = JsonSerializer.Deserialize<RunDataMessage>(jsonCopy, JsonOptions);
                        if (dataMsg?.Record != null)
                        {
                            CurrentRecord = dataMsg.Record;
                            ShowSummary = false;
                            StatusText = $"Loaded: Run #{dataMsg.Record.Meta.RunNumber}";
                        }
                        break;

                    case "error":
                        var errMsg = JsonSerializer.Deserialize<ErrorMsgWrapper>(jsonCopy, JsonOptions);
                        StatusText = $"Error: {errMsg?.Message ?? "unknown"}";
                        break;
                }
            }
            catch (Exception ex)
            {
                StatusText = $"Parse error: {ex.Message}";
            }
        });
    }

    private void OnConnectionChanged(bool connected)
    {
        _dispatcher.BeginInvoke(() =>
        {
            try
            {
                IsConnected = connected;
                if (connected)
                {
                    // Server sends run_list automatically on connect — no need to request
                    StatusText = "Connected — waiting for data...";
                }
                else
                {
                    StatusText = "Disconnected — reconnecting...";
                }
            }
            catch (Exception ex)
            {
                StatusText = $"Error: {ex.Message}";
            }
        });
    }

    private void OnPipeError(string error)
    {
        _dispatcher.BeginInvoke(() =>
        {
            StatusText = $"Pipe error: {error}";
        });
    }

    public void RefreshRunList()
    {
        _pipeClient.SendGetRunList();
        StatusText = "Refreshing...";
    }

    private void UpdateWinRateStats()
    {
        if (Runs.Count == 0)
        {
            WinRate50 = WinRate100 = WinRate200 = WinRateOverall = "";
            OnPropertyChanged(nameof(HasWinRateStats));
            return;
        }

        // Exclude custom-seeded runs from win-rate calculation
        var all = Runs.Where(r => r.SeedType != "custom").ToList();
        int total = all.Count;
        if (total == 0)
        {
            WinRate50 = WinRate100 = WinRate200 = WinRateOverall = "";
            OnPropertyChanged(nameof(HasWinRateStats));
            return;
        }
        int totalWins = all.Count(r => r.EndedBy == "victory");
        WinRateOverall = $"{totalWins * 100.0 / total:F1}%";

        var recent = all.Take(200).ToList();
        WinRate50  = recent.Count >= 50  ? $"{recent.Take(50).Count(r => r.EndedBy == "victory") * 100.0 / Math.Min(50, recent.Count):F1}%" : "";
        WinRate100 = recent.Count >= 100 ? $"{recent.Take(100).Count(r => r.EndedBy == "victory") * 100.0 / Math.Min(100, recent.Count):F1}%" : "";
        WinRate200 = recent.Count >= 200 ? $"{recent.Take(200).Count(r => r.EndedBy == "victory") * 100.0 / Math.Min(200, recent.Count):F1}%" : "";

        OnPropertyChanged(nameof(HasWinRateStats));
    }

    public void ToggleSummary()
    {
        ShowSummary = !ShowSummary;
    }

    private static string PeekType(string json)
    {
        try
        {
            var doc = JsonDocument.Parse(json);
            return doc.RootElement.TryGetProperty("type", out var t) ? t.GetString() ?? "" : "";
        }
        catch { return ""; }
    }

    private static string FormatEndedBy(string endedBy) => endedBy switch
    {
        "victory" => "Victory",
        "quit"    => "Quit",
        _         => "Defeat"
    };

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true
    };

    // ---- INotifyPropertyChanged ----

    public event PropertyChangedEventHandler? PropertyChanged;

    private bool SetProperty<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}

// ---- ViewModel wrapper types ----

public class RunListItemViewModel
{
    public string RunId { get; private set; }
    public int RunNumber { get; private set; }
    public string EndedBy { get; private set; }
    public int? Floor { get; private set; }
    public double FinalCoins { get; private set; }
    public int TotalSpins { get; private set; }
    public string ResultText { get; private set; } = "";
    public string FloorText { get; private set; } = "";
    public string RunLabel { get; private set; } = "";
    public List<string> TopSymbols { get; private set; } = new();
    public bool HasTopSymbols => TopSymbols.Count > 0;

    public string? SeedType { get; private set; }
    public bool IsCustomSeed => SeedType == "custom";

    public RunListItemViewModel(RunListItem item)
    {
        RunId = item.RunId;
        RunNumber = item.RunNumber;
        EndedBy = item.EndedBy;
        Floor = item.Floor;
        FinalCoins = item.FinalCoins;
        TotalSpins = item.TotalSpins;
        SeedType = item.SeedType;
        ResultText = item.EndedBy switch
        {
            "victory" => "Victory",
            "quit"    => "Quit",
            _         => "Defeat"
        };
        // total_runs is 0-based in-game; display as 1-based for users
        RunLabel = IsCustomSeed
            ? $"Run #{item.RunNumber} \U0001F512"
            : $"Run #{item.RunNumber}";
        TopSymbols = item.TopSymbols ?? new();
    }
}

public class TimelineRoundViewModel
{
    public int RoundIndex { get; private set; }
    public int RentRequired { get; private set; }
    public double CoinsAtRent { get; private set; }
    public List<SpinCellViewModel> Spins { get; private set; } = new();
    public List<EndActionGroupViewModel> EndActionGroups { get; private set; } = new();
    public bool HasEndActions => EndActionGroups.Count > 0;

    public TimelineRoundViewModel(RentCycle cycle)
    {
        RoundIndex = cycle.CycleIndex;
        RentRequired = cycle.RentRequired;
        CoinsAtRent = cycle.Spins.Count > 0 ? cycle.Spins.Last().CoinsAfter : 0;

        foreach (var spin in cycle.Spins)
            Spins.Add(new SpinCellViewModel(spin));

        if (cycle.EndActions != null && cycle.EndActions.Count > 0)
        {
            // Group by choice_idx — items from the same choice share tooltip
            var groups = cycle.EndActions
                .Where(a => !string.IsNullOrEmpty(a.Id))
                .GroupBy(a => a.ChoiceIdx)
                .OrderBy(g => g.Key);

            foreach (var grp in groups)
            {
                var added = grp.FirstOrDefault(a => a.Action == "added");
                var skipped = grp.Where(a => a.Action == "skipped").ToList();

                if (added == null) continue; // skip skips without a took (shouldn't happen)

                var tt = new List<TipAction>();
                tt.Add(new TipAction { Label = "Took:", Icon = null });
                tt.Add(new TipAction
                {
                    Label = added.Source != null ? $"{added.Id} ({added.Source})" : added.Id,
                    Icon = added.Id,
                    Kind = "added"
                });

                if (skipped.Count > 0)
                {
                    tt.Add(new TipAction { Label = "Skipped:", Icon = null });
                    foreach (var sk in skipped)
                        tt.Add(new TipAction
                        {
                            Label = sk.Id,
                            Icon = sk.Id,
                            Kind = "skipped"
                        });
                }

                EndActionGroups.Add(new EndActionGroupViewModel
                {
                    TookIcon = added.Id,
                    TookLabel = added.Source != null ? $"{added.Id} ({added.Source})" : added.Id,
                    TooltipActions = tt
                });
            }
        }
    }
}

public class EndActionGroupViewModel
{
    public string TookIcon { get; set; } = "";
    public string TookLabel { get; set; } = "";
    public List<TipAction> TooltipActions { get; set; } = new();
}

public class SpinCellViewModel
{
    public int SpinNum { get; private set; }
    public string MainSymbol { get; private set; } = "";
    public double CoinsBefore { get; private set; }
    public double CoinsAfter { get; private set; }
    public double CoinChange { get; private set; }
    public string CoinChangeText { get; private set; } = "";
    public bool HasChange => CoinChange != 0;
    public bool HasSymbol => !string.IsNullOrEmpty(MainSymbol);
    public string TooltipText { get; private set; } = "";
    public List<string> IconNames { get; private set; } = new();
    public bool HasIcons => IconNames.Count > 0;
    public bool HasExtras => TooltipActions.Count > 1; // more than just coin info
    public List<TipAction> TooltipActions { get; private set; } = new();

    public SpinCellViewModel(SpinEntry spin)
    {
        SpinNum = spin.SpinNum;
        MainSymbol = spin.MainSymbol ?? "";
        CoinsBefore = spin.CoinsBefore;
        CoinsAfter = spin.CoinsAfter;
        CoinChange = spin.CoinChange;
        CoinChangeText = CoinChange >= 0 ? $"+{CoinChange}" : $"{CoinChange}";

        // Build icon list for cell display
        if (!string.IsNullOrEmpty(spin.MainSymbol))
            IconNames.Add(spin.MainSymbol);
        foreach (var act in spin.ExtraActions)
        {
            if (act.Action == "added" && !string.IsNullOrEmpty(act.Id))
                IconNames.Add(act.Id);
        }

        // Build tooltip data with icons
        TooltipActions.Add(new TipAction { Label = $"#{SpinNum}  {CoinsBefore}→{CoinsAfter} ({CoinChangeText})", Icon = null });
        if (spin.MainSymbol != null)
        {
            TooltipActions.Add(new TipAction { Label = "Took:", Icon = null });
            TooltipActions.Add(new TipAction { Label = spin.MainSymbol, Icon = spin.MainSymbol, Kind = "symbol" });
        }
        foreach (var act in spin.ExtraActions)
        {
            var label = act.Action switch
            {
                "added" => act.Id + (act.Source != null ? $" ({act.Source})" : ""),
                "destroyed" => $"Destroyed: {act.Id}" + (act.Remaining != null ? $" ({act.Remaining} left)" : ""),
                "removed" => $"Removed: {act.Id}",
                "counter" => $"Counter: {act.Id}" + (act.NewCount != null ? $" ({act.NewCount} uses)" : ""),
                _ => $"{act.Action}: {act.Id}"
            };
            TooltipActions.Add(new TipAction { Label = label, Icon = act.Id, Kind = act.Action });
        }
        if (spin.SkippedOptions.Count > 0)
        {
            TooltipActions.Add(new TipAction { Label = "Skipped:", Icon = null });
            foreach (var sk in spin.SkippedOptions)
                TooltipActions.Add(new TipAction { Label = sk, Icon = sk, Kind = "skipped" });
        }
        if (spin.BossInfo != null)
            TooltipActions.Add(new TipAction { Label = $"Boss: {spin.BossInfo.BossHpBefore}→{spin.BossInfo.BossHpAfter} (-{spin.BossInfo.DamageDealt})", Icon = null });

        // Keep plain text for fallback
        var tt = new List<string>();
        tt.Add($"Spin #{SpinNum}");
        tt.Add($"Coins: {CoinsBefore} → {CoinsAfter} ({CoinChangeText})");

        if (spin.MainSymbol != null)
            tt.Add($"Main symbol: {spin.MainSymbol}");

        foreach (var act in spin.ExtraActions)
        {
            var desc = act.Action switch
            {
                "added" => $"Added: {act.Id}" + (act.Source != null ? $" ({act.Source})" : ""),
                "destroyed" => $"Destroyed: {act.Id}" + (act.Remaining != null ? $" ({act.Remaining} left)" : ""),
                "removed" => $"Removed: {act.Id}",
                "counter" => $"Counter: {act.Id}" + (act.NewCount != null ? $" ({act.NewCount} uses)" : ""),
                _ => $"{act.Action}: {act.Id}"
            };
            tt.Add(desc);
        }

        if (spin.SkippedOptions.Count > 0)
            tt.Add($"Skipped: {string.Join(", ", spin.SkippedOptions)}");

        if (spin.BossInfo != null)
        {
            var bi = spin.BossInfo;
            tt.Add($"Boss HP: {bi.BossHpBefore} → {bi.BossHpAfter} (-{bi.DamageDealt})");
        }

        TooltipText = string.Join("\n", tt);
    }

}

public class TipAction
{
    public string Label { get; set; } = "";
    public string? Icon { get; set; }
    public string Kind { get; set; } = "";
}

public class DptRankEntry
{
    public int Rank { get; set; }
    public string IconId { get; set; } = "";
    public string Name { get; set; } = "";
    public int Count { get; set; }
    public double Value { get; set; }
    public double BarWidthPx { get; set; }
    public string DetailText { get; set; } = "";
    public bool Departed { get; set; }
    public string ValueDisplay => Value >= 10 ? $"{Value:F0}" : $"{Value:F1}";
}

public class ErrorMsgWrapper
{
    public string Type { get; set; } = "";
    public string Message { get; set; } = "";
}
