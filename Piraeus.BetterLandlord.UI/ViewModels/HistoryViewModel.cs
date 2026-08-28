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
                _cachedTimeline = null;
                _cachedDetailedTimeline = null;
                _partialTimeline = null;
                RefreshMeta();
                OnPropertyChanged(nameof(TimelineRounds));
                OnPropertyChanged(nameof(DetailedTimelineRounds));
                OnPropertyChanged(nameof(HasDetailedTimelineData));
                OnPropertyChanged(nameof(Summary));
                OnPropertyChanged(nameof(HasData));
                OnPropertyChanged(nameof(HasTimelineData));
                OnPropertyChanged(nameof(RunInfo));

                // Build the detailed timeline off the UI thread while the overview
                // is already visible. Switching modes can then reuse the prepared
                // view models instead of paying the construction cost on click.
                if (_currentRecord is not null)
                    PreloadDetailedTimeline(_currentRecord);
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

    private bool _showDetailedTimeline;
    public bool ShowDetailedTimeline
    {
        get => _showDetailedTimeline;
        set
        {
            if (SetProperty(ref _showDetailedTimeline, value))
            {
                OnPropertyChanged(nameof(IsOverviewTimeline));
                OnPropertyChanged(nameof(IsDetailedTimeline));
            }
        }
    }

    public bool IsOverviewTimeline => !ShowDetailedTimeline;
    public bool IsDetailedTimeline => ShowDetailedTimeline;

    // ---- Computed properties ----

    public bool HasData => CurrentRecord != null;
    public bool HasTimelineData => CurrentRecord?.RentCycles?.Any(cycle => cycle.Spins?.Count > 0) == true;
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

    private List<DetailedTimelineRoundViewModel>? _cachedDetailedTimeline;
    private int _detailedPreloadVersion;
    private List<DetailedTimelineRoundViewModel>? _partialTimeline;
    private int _partialTimelineCount;
    public List<DetailedTimelineRoundViewModel> DetailedTimelineRounds
        => _cachedDetailedTimeline ?? new();

    public bool HasDetailedTimelineData => _cachedDetailedTimeline?.Any(r => r.HasDetailedData) == true;

    private void PreloadDetailedTimeline(RunRecord record)
    {
        var version = Interlocked.Increment(ref _detailedPreloadVersion);
        _partialTimeline = null;
        _partialTimelineCount = 0;

        var cycles = record.RentCycles ?? new List<RentCycle>();
        _ = Task.Run(() =>
        {
            // Build all row VMs on the background thread.
            var allRows = cycles
                .Select(rc => new DetailedTimelineRoundViewModel(rc))
                .ToList();

            // Dispatch rows one by one so each becomes visible immediately.
            for (var i = 0; i < allRows.Count; i++)
            {
                // A newer run may have been selected while we are building.
                if (version != Volatile.Read(ref _detailedPreloadVersion)
                    || !ReferenceEquals(_currentRecord, record))
                    return;

                var row = allRows[i];
                _dispatcher.BeginInvoke(() =>
                {
                    if (version != Volatile.Read(ref _detailedPreloadVersion)
                        || !ReferenceEquals(_currentRecord, record))
                        return;

                    // Append one row and expose it incrementally.
                    if (_partialTimeline == null) _partialTimeline = new List<DetailedTimelineRoundViewModel>();
                    _partialTimeline.Add(row);
                    _partialTimelineCount = _partialTimeline.Count;
                    OnPropertyChanged(nameof(DetailedTimelineRounds));
                    OnPropertyChanged(nameof(HasDetailedTimelineData));
                });
            }

            // Final commit: attach the full list so the cached reference is stable.
            _dispatcher.BeginInvoke(() =>
            {
                if (version == Volatile.Read(ref _detailedPreloadVersion)
                    && ReferenceEquals(_currentRecord, record))
                {
                    _cachedDetailedTimeline = allRows;
                    OnPropertyChanged(nameof(DetailedTimelineRounds));
                    OnPropertyChanged(nameof(HasDetailedTimelineData));
                }
            });
        });
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
        int totalWins = all.Count(r => IsVictoryResult(r.EndedBy));
        WinRateOverall = $"{totalWins * 100.0 / total:F1}%";

        var recent = all.Take(200).ToList();
        WinRate50  = recent.Count >= 50  ? $"{recent.Take(50).Count(r => IsVictoryResult(r.EndedBy)) * 100.0 / Math.Min(50, recent.Count):F1}%" : "";
        WinRate100 = recent.Count >= 100 ? $"{recent.Take(100).Count(r => IsVictoryResult(r.EndedBy)) * 100.0 / Math.Min(100, recent.Count):F1}%" : "";
        WinRate200 = recent.Count >= 200 ? $"{recent.Take(200).Count(r => IsVictoryResult(r.EndedBy)) * 100.0 / Math.Min(200, recent.Count):F1}%" : "";

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

    private static bool IsVictoryResult(string endedBy) => endedBy is "victory" or "endless" or "guillotine";

    private static string FormatEndedBy(string endedBy) => endedBy switch
    {
        "victory"    => "Victory",
        "endless"    => "Endless",
        "guillotine" => "Guillotine",
        "quit"       => "Quit",
        _            => "Defeat"
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
            "victory"    => "Victory",
            "endless"    => "Endless",
            "guillotine" => "Guillotine",
            "quit"       => "Quit",
            _            => "Defeat"
        };
        // total_runs is 0-based in-game; display as 1-based for users
        RunLabel = IsCustomSeed
            ? $"Run #{item.RunNumber} \U0001F512"
            : $"Run #{item.RunNumber}";
        TopSymbols = item.TopSymbols ?? new();
    }
}

public class DetailedTimelineRoundViewModel
{
    public int RoundIndex { get; }
    public int RentRequired { get; }
    public double CoinsAtRent { get; }
    public List<DetailedSpinViewModel> Spins { get; } = new();
    public List<DeckSymbolViewModel> DeckSymbols { get; } = new();
    public List<ChoiceGroupViewModel> EndChoiceGroups { get; } = new();
    public List<DetailedTimelineEventViewModel> TimelineEvents { get; } = new();
    public bool HasEndChoiceGroups => EndChoiceGroups.Count > 0;
    public bool HasDeckSnapshot => DeckSymbols.Count > 0;
    public bool HasDetailedData => TimelineEvents.Count > 0 || HasDeckSnapshot;

    public DetailedTimelineRoundViewModel(RentCycle cycle)
    {
        RoundIndex = cycle.CycleIndex;
        RentRequired = cycle.RentRequired;
        CoinsAtRent = cycle.Spins.Count > 0 ? cycle.Spins.Last().CoinsAfter : 0;

        // Use the first available pre-spin snapshot for this rent cycle.
        // Older runs simply leave this row empty.
        var deckSnapshot = cycle.Spins
            .Select(spin => spin.DeckSymbols)
            .FirstOrDefault(symbols => symbols is { Count: > 0 });
        if (deckSnapshot is not null)
        {
            foreach (var group in deckSnapshot
                         .Where(symbol => !string.IsNullOrWhiteSpace(symbol.Id))
                         .GroupBy(symbol => new
                         {
                             symbol.Id,
                             symbol.TurnsUntilChange,
                             StackValue = symbol.Id is "rabbit" or "wine" ? null : symbol.StackValue
                         })
                         .OrderBy(group => group.Key.Id, StringComparer.Ordinal)
                         .ThenBy(group => group.Key.TurnsUntilChange ?? int.MaxValue)
                         .ThenBy(group => group.Key.StackValue, StringComparer.Ordinal))
            {
                DeckSymbols.Add(new DeckSymbolViewModel(
                    group.Key.Id,
                    group.Count(),
                    group.Key.TurnsUntilChange,
                    group.Key.StackValue));
            }
        }

        foreach (var spin in cycle.Spins)
            Spins.Add(new DetailedSpinViewModel(spin));

        // Older saved runs already contain the selected item and the skipped
        // candidates in end_actions. Reconstruct their three-choice group rather
        // than requiring the later choice_groups projection to be present.
        var knownItemChoices = cycle.Spins
            .SelectMany(s => s.ChoiceGroups ?? new List<ChoiceGroupEntry>())
            .Where(g => g.Kind == "item")
            .Select(g => g.ChoiceIdx)
            .ToHashSet();
        foreach (var actions in (cycle.EndActions ?? new List<ActionEntry>())
                     .Where(a => a.Type == "item" && (a.Action == "added" || a.Action == "skipped"))
                     .GroupBy(a => a.ChoiceIdx)
                     .OrderBy(g => g.Key))
        {
            if (knownItemChoices.Contains(actions.Key)) continue;
            EndChoiceGroups.Add(ChoiceGroupViewModel.FromActions(actions.Key, "item", actions));
        }

        // Avalonia renders the choice/action capsules as one continuous
        // horizontal row. Flatten spin-local events here so WPF does not add a
        // line break between every spin or between the legacy end choices.
        foreach (var spin in Spins)
            TimelineEvents.AddRange(spin.Events);
        foreach (var group in EndChoiceGroups)
            TimelineEvents.Add(DetailedTimelineEventViewModel.FromChoice(group));

        // Some legacy/native records keep non-choice actions in end_actions.
        // They are not part of an item three-choice group, but they are still
        // meaningful timeline events (used, triggered, destroyed, removed).
        // Add them after the reconstructed choices and de-duplicate against
        // spin-local actions for records that contain both projections.
        var actionKeys = Spins
            .SelectMany(spin => spin.Actions)
            .Where(action => action.IsTimelineBadge)
            .Select(ActionKey)
            .ToHashSet(StringComparer.Ordinal);
        foreach (var action in cycle.EndActions ?? new List<ActionEntry>())
        {
            if (action.Action is "added" or "skipped") continue;
            var actionVm = new ActionEventViewModel(action);
            if (!actionVm.IsTimelineBadge || !actionKeys.Add(ActionKey(actionVm))) continue;
            TimelineEvents.Add(DetailedTimelineEventViewModel.FromAction(actionVm));
        }
    }

    private static string ActionKey(ActionEventViewModel action)
        => string.Join("|", action.ActionKind, action.IconId,
            action.AfterChoiceIdx?.ToString() ?? "");
}

public sealed class DeckSymbolViewModel
{
    public string IconId { get; }
    public int Count { get; }
    public string CountText => Count > 1 ? Count.ToString() : "";
    public bool HasCount => Count > 1;
    public int? TurnsUntilChange { get; }
    public bool HasTurnsUntilChange => TurnsUntilChange.HasValue;
    public string TurnsText => TurnsUntilChange?.ToString() ?? "";
    public string? StackValue { get; }
    public bool HasStackValue => !string.IsNullOrWhiteSpace(StackValue);
    public double CellWidth => HasTurnsUntilChange && HasStackValue ? 31 :
        HasTurnsUntilChange || HasStackValue ? 21 : 17;
    public string Tooltip
    {
        get
        {
            var parts = new List<string>();
            if (Count > 1) parts.Add($"数量 {Count}");
            if (TurnsUntilChange is int turns) parts.Add($"剩余 {turns} Spin");
            if (HasStackValue) parts.Add($"数值 {StackValue}");
            return parts.Count == 0 ? IconId : string.Join("，", parts);
        }
    }

    public DeckSymbolViewModel(string iconId, int count, int? turnsUntilChange, string? stackValue)
    {
        IconId = iconId;
        Count = count;
        TurnsUntilChange = turnsUntilChange;
        StackValue = stackValue;
    }
}

public class DetailedSpinViewModel
{
    public int SpinNum { get; }
    public string CoinsText { get; }
    public string CoinChangeText { get; }
    public List<ChoiceGroupViewModel> ChoiceGroups { get; } = new();
    public List<ActionEventViewModel> Actions { get; } = new();
    public List<DetailedTimelineEventViewModel> Events { get; } = new();
    public bool HasChoiceGroups => ChoiceGroups.Count > 0;
    public bool HasActions => Actions.Count > 0;
    public bool HasDetailedData => HasChoiceGroups || HasActions;
    public string EmptyText => "此 Spin 没有详细选择记录";

    public DetailedSpinViewModel(SpinEntry spin)
    {
        SpinNum = spin.SpinNum;
        CoinsText = $"{spin.CoinsBefore} → {spin.CoinsAfter}";
        CoinChangeText = spin.CoinChange >= 0 ? $"+{spin.CoinChange}" : $"{spin.CoinChange}";

        if (spin.ChoiceGroups is { Count: > 0 })
        {
            foreach (var group in spin.ChoiceGroups)
                ChoiceGroups.Add(new ChoiceGroupViewModel(group));
        }
        else
        {
            // Pre-detailed history has the ordinary choice result: main_symbol
            // plus skipped_options. That is enough to render its three choices.
            var legacyOptions = (spin.SkippedOptions ?? new List<string>())
                .Where(option => !string.IsNullOrWhiteSpace(option) && !option.StartsWith("("))
                .Distinct(StringComparer.Ordinal)
                .ToList();
            if (!string.IsNullOrEmpty(spin.MainSymbol))
            {
                if (!legacyOptions.Contains(spin.MainSymbol, StringComparer.Ordinal))
                    legacyOptions.Insert(0, spin.MainSymbol);
                ChoiceGroups.Add(ChoiceGroupViewModel.FromLegacy(
                    "symbol", legacyOptions, spin.MainSymbol, "selected"));
            }
            else if (legacyOptions.Count > 0)
            {
                ChoiceGroups.Add(ChoiceGroupViewModel.FromLegacy(
                    "choice", legacyOptions, null, "skipped"));
            }
        }

        foreach (var action in spin.ExtraActions ?? new List<ActionEntry>())
            Actions.Add(new ActionEventViewModel(action));

        // Match the compact Avalonia timeline ordering: unanchored actions,
        // choice group, reroll marker, then actions caused by that choice.
        var groups = ChoiceGroups.OrderBy(group => group.ChoiceIdx).ToList();
        var visibleActions = Actions.Where(action => action.IsTimelineBadge).ToList();
        foreach (var action in visibleActions.Where(action => action.AfterChoiceIdx is null))
            Events.Add(DetailedTimelineEventViewModel.FromAction(action));

        foreach (var group in groups)
        {
            Events.Add(DetailedTimelineEventViewModel.FromChoice(group));
            if (group.IsRerolled)
                Events.Add(DetailedTimelineEventViewModel.FromReroll());
            foreach (var action in visibleActions.Where(action => action.AfterChoiceIdx == group.ChoiceIdx))
                Events.Add(DetailedTimelineEventViewModel.FromAction(action));
        }

        foreach (var action in visibleActions.Where(action => action.AfterChoiceIdx is not null
                     && !groups.Any(group => group.ChoiceIdx == action.AfterChoiceIdx)))
            Events.Add(DetailedTimelineEventViewModel.FromAction(action));
    }
}

public class DetailedTimelineEventViewModel
{
    public ChoiceGroupViewModel? ChoiceGroup { get; }
    public ActionEventViewModel? Action { get; }
    public bool IsChoice => ChoiceGroup is not null;
    public bool IsAction => Action is not null;
    public bool IsReroll { get; }
    public string RerollText => IsReroll ? "重掷" : "";

    private DetailedTimelineEventViewModel(ChoiceGroupViewModel? choiceGroup = null,
        ActionEventViewModel? action = null, bool isReroll = false)
    {
        ChoiceGroup = choiceGroup;
        Action = action;
        IsReroll = isReroll;
    }

    public static DetailedTimelineEventViewModel FromChoice(ChoiceGroupViewModel group) => new(choiceGroup: group);
    public static DetailedTimelineEventViewModel FromAction(ActionEventViewModel action) => new(action: action);
    public static DetailedTimelineEventViewModel FromReroll() => new(isReroll: true);
}

public class ChoiceGroupViewModel
{
    public int ChoiceIdx { get; }
    public string KindText { get; }
    public string ResultText { get; }
    public bool IsRerolled { get; }
    public string RerollText => IsRerolled ? "已重抽" : "";
    public List<ChoiceOptionViewModel> Options { get; } = new();

    public ChoiceGroupViewModel(ChoiceGroupEntry group)
        : this(group.ChoiceIdx, group.Kind, group.Options, group.Selected, group.Result, group.Rerolled)
    {
    }

    private ChoiceGroupViewModel(int choiceIdx, string kind, IEnumerable<string>? options,
        IEnumerable<string>? selected, string? result, bool rerolled = false)
    {
        ChoiceIdx = choiceIdx;
        KindText = kind switch
        {
            "item" => "物品三选一",
            "symbol" => "符号三选一",
            _ => "三选一"
        };
        IsRerolled = rerolled;
        ResultText = result switch
        {
            "selected" => "已选择",
            "skipped" => "已跳过",
            _ => "未完成"
        };

        var selectedSet = new HashSet<string>(selected ?? Enumerable.Empty<string>(), StringComparer.Ordinal);
        foreach (var option in (options ?? Enumerable.Empty<string>())
                     .Where(option => !string.IsNullOrWhiteSpace(option))
                     .Distinct(StringComparer.Ordinal))
        {
            var isSelected = selectedSet.Contains(option);
            Options.Add(new ChoiceOptionViewModel
            {
                IconId = option,
                IsSelected = isSelected,
                IsSkipped = result == "skipped" || (result == "selected" && !isSelected),
                StateText = isSelected ? "已选择" : result == "skipped" ? "跳过" : "未选择"
            });
        }
    }

    public static ChoiceGroupViewModel FromLegacy(string kind, IEnumerable<string> options,
        string? selected, string result) => new(0, kind, options,
        string.IsNullOrEmpty(selected) ? Enumerable.Empty<string>() : new[] { selected }, result);

    public static ChoiceGroupViewModel FromActions(int choiceIdx, string kind,
        IEnumerable<ActionEntry> actions)
    {
        var list = actions.ToList();
        var selected = list.FirstOrDefault(action => action.Action == "added")?.Id;
        var options = list.Select(action => action.Id);
        return new ChoiceGroupViewModel(choiceIdx, kind, options,
            string.IsNullOrEmpty(selected) ? Enumerable.Empty<string>() : new[] { selected },
            string.IsNullOrEmpty(selected) ? "skipped" : "selected");
    }
}

public class ChoiceOptionViewModel
{
    public string IconId { get; init; } = "";
    public bool IsSelected { get; init; }
    public bool IsSkipped { get; init; }
    public string StateText { get; init; } = "";
}

public class ActionEventViewModel
{
    public string IconId { get; } = "";
    public string ActionKind { get; } = "";
    public string ActionText { get; } = "";
    public string BadgeText { get; } = "";
    public string DetailText { get; } = "";
    public int? AfterChoiceIdx { get; }
    public bool IsTimelineBadge => ActionKind is "used" or "triggered" or "destroyed" or "removed";

    public ActionEventViewModel(ActionEntry action)
    {
        IconId = action.Id ?? "";
        ActionKind = action.Action ?? "";
        AfterChoiceIdx = action.AfterChoiceIdx;
        ActionText = ActionKind switch
        {
            "added" => "加入牌组",
            "used" => "物品使用",
            "triggered" => "精华触发",
            "destroyed" => "物品销毁",
            "removed" => "移除",
            "counter" => "计数变化",
            "skipped" => "未选择",
            _ => ActionKind
        };
        BadgeText = ActionKind switch
        {
            "used" => "使用",
            "triggered" => "触发",
            "destroyed" => "销毁",
            "removed" => "移除",
            _ => ActionText
        };

        var details = new List<string>();
        if (!string.IsNullOrEmpty(action.Source))
            details.Add($"来源：{action.Source}");
        if (action.Remaining.HasValue)
            details.Add($"剩余 {action.Remaining.Value}");
        if (action.NewCount.HasValue)
            details.Add($"次数 {action.NewCount.Value}");
        if (action.AfterChoiceIdx.HasValue)
            details.Add($"选择 #{action.AfterChoiceIdx.Value + 1} 后");
        DetailText = string.Join(" · ", details);
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
