using System.Globalization;
using System.Text.RegularExpressions;
using Piraeus.BetterHistoryMod.Model;

namespace Piraeus.BetterHistoryMod.Parser;

public class LogParser
{
    private const string ParserVersion = "2.0";

    // --- Round data ---
    private static readonly int[] BaseRoundCuts = [5, 10, 16, 22, 29, 36, 44, 52, 61, 70, 80, 90];
    private static readonly int[] BaseRents = [25, 50, 100, 150, 225, 300, 350, 425, 575, 625, 675, 777];

    // --- Regex patterns ---
    private static readonly Regex RunStartPat = new(@"^--- STARTING RUN #(\d+) ---$", RegexOptions.Compiled);
    private static readonly Regex VersionPat = new(@"^--- v([\d\.]+) ---$", RegexOptions.Compiled);
    private static readonly Regex SpinStartPat = new(@"^--- SPIN #(\d+) ---$", RegexOptions.Compiled);
    private static readonly Regex CurrentlyHavePat = new(@"^Currently have (-?\d+) coins$", RegexOptions.Compiled);
    private static readonly Regex CoinTotalPat = new(@"^Coin total is now (-?[\d\.eE+-]+) after spinning$", RegexOptions.Compiled);
    private static readonly Regex GainedCoinsPat = new(@"^Gained (-?[\d\.eE+-]+) coins this spin$", RegexOptions.Compiled);
    private static readonly Regex GainedRerollPat = new(@"^Gained (-?[\d\.eE+-]+) reroll tokens this spin$", RegexOptions.Compiled);
    private static readonly Regex GainedRemovalPat = new(@"^Gained (-?[\d\.eE+-]+) removal tokens this spin$", RegexOptions.Compiled);
    private static readonly Regex GainedEssencePat = new(@"^Gained (-?[\d\.eE+-]+) essence tokens this spin$", RegexOptions.Compiled);
    private static readonly Regex AddedSymbolsPat = new(@"^Added symbols: \[(.*)\]$", RegexOptions.Compiled);
    private static readonly Regex SkippedSymbolsPat = new(@"^Skipped symbols$", RegexOptions.Compiled);
    private static readonly Regex AddedItemPat = new(@"^Added item: (.+)$", RegexOptions.Compiled);
    private static readonly Regex SkippedItemsPat = new(@"^Skipped items$", RegexOptions.Compiled);
    private static readonly Regex DestroyedItemPat = new(@"^Destroyed item - (.+)$", RegexOptions.Compiled);
    private static readonly Regex DestroyedSymbolsHdrPat = new(@"^There are (\d+) destroyed symbols:$", RegexOptions.Compiled);
    private static readonly Regex DestroyedItemsHdrPat = new(@"^There are (\d+) destroyed items:$", RegexOptions.Compiled);
    private static readonly Regex DestroyCountersPat = new(@"^Destroy counters - (.+) now has (\d+)$", RegexOptions.Compiled);
    private static readonly Regex FinePrintPat = new(@"^Fine print is: \[(.*)\]$", RegexOptions.Compiled);
    private static readonly Regex ListContentPat = new(@"^\[(.*)\]$", RegexOptions.Compiled);

    public RunRecord Parse(string filePath, string runId)
    {
        var lines = File.ReadAllLines(filePath);
        return ParseLines(lines, runId, Path.GetFileName(filePath));
    }

    public RunRecord ParseLines(string[] lines, string runId, string sourceLogFile)
    {
        if (lines.Length == 0)
            return CreateEmpty(runId, sourceLogFile, "corrupted");

        if (lines.Length <= 2)
            return CreateEmpty(runId, sourceLogFile, "partial");

        var record = new RunRecord(runId) { IsLegacyLog = true };
        record.Meta.SourceLogFile = sourceLogFile;
        record.Meta.ParserVersion = ParserVersion;

        // --- Accumulators ---
        var allSpins = new List<SpinFrame>();
        SpinFrame? cur = null;
        var pendingAdditions = new List<ActionEntry>();
        var pendingSkipSymbols = new List<string>();
        var pendingSkipItems = new List<string>();
        var symbolAccum = new Dictionary<string, int>();
        var itemAccum = new Dictionary<string, int>();
        var destroyedSymbolAccum = new Dictionary<string, int>();
        var destroyedItemAccum = new Dictionary<string, int>();
        var finePrintList = new List<string>();
        double finalCoins = 0;
        bool ended = false;
        bool inSpinBody = false; // true between SpinStart and CoinTotal (effect phase)
        bool expectDestroyedSymbolList = false;
        bool expectDestroyedItemList = false;

        // --- Parse lines ---
        foreach (var rawLine in lines)
        {
            if (string.IsNullOrWhiteSpace(rawLine)) continue;

            var line = new LogLine(rawLine);
            if (!line.IsValid) continue;

            // Header
            if (RunStartPat.IsMatch(line.Content))
            {
                var m = RunStartPat.Match(line.Content);
                record.Meta.RunNumber = int.Parse(m.Groups[1].Value);
                record.Meta.StartTime = NormalizeTimestamp(line.Timestamp);
                continue;
            }

            if (VersionPat.IsMatch(line.Content))
            {
                record.Meta.GameVersion = VersionPat.Match(line.Content).Groups[1].Value;
                continue;
            }

            // Spin start — finalize PREVIOUS spin, flush pending into IT (spin→choice)
            if (SpinStartPat.IsMatch(line.Content))
            {
                // Flush pending into the OLD spin (being finalized)
                // Choice made after spin N belongs to spin N, takes effect in spin N+1
                if (cur != null)
                {
                    if (pendingAdditions.Count > 0)
                    {
                        int choiceIdx = -1;
                        for (int pi = 0; pi < pendingAdditions.Count; pi++)
                        {
                            if (pendingAdditions[pi].Source == "choice" && pendingAdditions[pi].Type == "symbol")
                            {
                                cur.MainSymbol = pendingAdditions[pi].Id;
                                choiceIdx = pi;
                                break;
                            }
                        }
                        for (int i = 0; i < pendingAdditions.Count; i++)
                        {
                            if (i == choiceIdx) continue;
                            cur.ExtraActions.Add(pendingAdditions[i]);
                        }
                        pendingAdditions.Clear();
                    }
                    if (pendingSkipSymbols.Count > 0)
                    {
                        cur.SkippedOptions.AddRange(pendingSkipSymbols);
                        pendingSkipSymbols.Clear();
                    }
                    if (pendingSkipItems.Count > 0)
                    {
                        cur.SkippedOptions.AddRange(pendingSkipItems);
                        pendingSkipItems.Clear();
                    }
                    allSpins.Add(cur);
                }

                var spinNum = int.Parse(SpinStartPat.Match(line.Content).Groups[1].Value);
                cur = new SpinFrame { SpinNum = spinNum };
                inSpinBody = true;
                continue;
            }

            // Spin body — only captured when cur is active
            if (cur != null)
            {
                if (CurrentlyHavePat.IsMatch(line.Content))
                {
                    cur.CoinsBefore = ParseDouble(CurrentlyHavePat.Match(line.Content).Groups[1].Value);
                    continue;
                }

                if (CoinTotalPat.IsMatch(line.Content))
                {
                    cur.CoinsAfter = ParseDouble(CoinTotalPat.Match(line.Content).Groups[1].Value);
                    cur.CoinChange = cur.CoinsAfter - cur.CoinsBefore;
                    finalCoins = cur.CoinsAfter;
                    inSpinBody = false; // exiting spin body, entering choice phase
                    continue;
                }

                if (GainedCoinsPat.IsMatch(line.Content))
                {
                    cur.GainedCoins = ParseDouble(GainedCoinsPat.Match(line.Content).Groups[1].Value);
                    continue;
                }

                if (GainedRerollPat.IsMatch(line.Content))
                {
                    cur.GainedReroll = (long)ParseDouble(GainedRerollPat.Match(line.Content).Groups[1].Value);
                    continue;
                }

                if (GainedRemovalPat.IsMatch(line.Content))
                {
                    cur.GainedRemoval = (long)ParseDouble(GainedRemovalPat.Match(line.Content).Groups[1].Value);
                    continue;
                }

                if (GainedEssencePat.IsMatch(line.Content))
                {
                    cur.GainedEssence = (long)ParseDouble(GainedEssencePat.Match(line.Content).Groups[1].Value);
                    continue;
                }

                if (DestroyedSymbolsHdrPat.IsMatch(line.Content))
                {
                    expectDestroyedSymbolList = true;
                    continue;
                }

                if (DestroyedItemsHdrPat.IsMatch(line.Content))
                {
                    expectDestroyedItemList = true;
                    continue;
                }

                if (FinePrintPat.IsMatch(line.Content))
                {
                    var fpItems = ParseCommaList(FinePrintPat.Match(line.Content).Groups[1].Value);
                    foreach (var fpi in fpItems)
                        if (!string.IsNullOrEmpty(fpi) && !finePrintList.Contains(fpi))
                            finePrintList.Add(fpi);
                    continue;
                }
            }

            // Destroyed symbol/item list lines (after their headers).
            // NOTE: these are CUMULATIVE per-spin lists from the game, so we
            // only record items that weren't already seen in a prior spin.
            if (expectDestroyedSymbolList && ListContentPat.IsMatch(line.Content))
            {
                var items = ParseCommaList(ListContentPat.Match(line.Content).Groups[1].Value);
                foreach (var it in items)
                {
                    bool isNew = !destroyedSymbolAccum.ContainsKey(it);
                    destroyedSymbolAccum[it] = destroyedSymbolAccum.GetValueOrDefault(it) + 1;
                    if (cur != null && isNew)
                        cur.ExtraActions.Add(new ActionEntry { Action = "destroyed", Type = "symbol", Id = it });
                }
                expectDestroyedSymbolList = false;
                continue;
            }

            if (expectDestroyedItemList && ListContentPat.IsMatch(line.Content))
            {
                var items = ParseCommaList(ListContentPat.Match(line.Content).Groups[1].Value);
                foreach (var it in items)
                {
                    bool isNew = !destroyedItemAccum.ContainsKey(it);
                    destroyedItemAccum[it] = destroyedItemAccum.GetValueOrDefault(it) + 1;
                    if (cur != null && isNew)
                        cur.ExtraActions.Add(new ActionEntry { Action = "destroyed", Type = "item", Id = it });
                }
                expectDestroyedItemList = false;
                continue;
            }

            // Effect-triggered Added symbols (during spin body) → extra_actions only.
            if (inSpinBody && AddedSymbolsPat.IsMatch(line.Content))
            {
                var symbols = ParseCommaList(AddedSymbolsPat.Match(line.Content).Groups[1].Value);
                foreach (var s in symbols)
                {
                    symbolAccum.TryGetValue(s, out var c);
                    symbolAccum[s] = c + 1;
                    if (cur != null)
                        cur.ExtraActions.Add(new ActionEntry { Action = "added", Type = "symbol", Id = s, Source = "symbol_effect" });
                }
                continue;
            }

            // Post-spin choices: only capture when NOT in spin body (after CoinTotal).
            if (!inSpinBody && AddedSymbolsPat.IsMatch(line.Content))
            {
                var symbols = ParseCommaList(AddedSymbolsPat.Match(line.Content).Groups[1].Value);
                foreach (var s in symbols)
                {
                    pendingAdditions.Add(new ActionEntry { Action = "added", Type = "symbol", Id = s, Source = "choice" });
                    symbolAccum.TryGetValue(s, out var c);
                    symbolAccum[s] = c + 1;
                }
                continue;
            }

            // Only capture skips when cur is active (post-spin choice phase).
            // Before the first spin, Skipped items/symbols lines are from
            // initial setup and should not be attached to any spin.
            if (cur != null && !inSpinBody && SkippedSymbolsPat.IsMatch(line.Content))
            {
                pendingSkipSymbols.Add("(symbols)");
                continue;
            }

            if (inSpinBody && AddedItemPat.IsMatch(line.Content))
            {
                var itemName = AddedItemPat.Match(line.Content).Groups[1].Value.Trim();
                itemAccum.TryGetValue(itemName, out var c);
                itemAccum[itemName] = c + 1;
                if (cur != null)
                    cur.ExtraActions.Add(new ActionEntry { Action = "added", Type = "item", Id = itemName, Source = "item_effect" });
                continue;
            }

            if (!inSpinBody && AddedItemPat.IsMatch(line.Content))
            {
                var itemName = AddedItemPat.Match(line.Content).Groups[1].Value.Trim();
                pendingAdditions.Add(new ActionEntry { Action = "added", Type = "item", Id = itemName, Source = "choice" });
                itemAccum.TryGetValue(itemName, out var c);
                itemAccum[itemName] = c + 1;
                continue;
            }

            if (cur != null && !inSpinBody && SkippedItemsPat.IsMatch(line.Content))
            {
                pendingSkipItems.Add("(items)");
                continue;
            }

            if (DestroyedItemPat.IsMatch(line.Content))
            {
                var itemName = ParseDestroyedItemName(DestroyedItemPat.Match(line.Content).Groups[1].Value);
                destroyedItemAccum.TryGetValue(itemName, out var c);
                destroyedItemAccum[itemName] = c + 1;
                itemAccum.TryGetValue(itemName, out var ic);
                if (ic > 0) itemAccum[itemName] = ic - 1;
                if (cur != null)
                    cur.ExtraActions.Add(new ActionEntry { Action = "destroyed", Type = "item", Id = itemName });
                continue;
            }

            if (DestroyCountersPat.IsMatch(line.Content))
            {
                var m = DestroyCountersPat.Match(line.Content);
                var counterName = m.Groups[1].Value.Trim();
                var newCount = int.Parse(m.Groups[2].Value);
                if (cur != null)
                    cur.ExtraActions.Add(new ActionEntry { Action = "counter", Type = "item", Id = counterName, NewCount = newCount });
                continue;
            }

            // End markers
            if (line.Content == "VICTORY")
            {
                record.Meta.EndedBy = "victory";
                record.Meta.EndTime = NormalizeTimestamp(line.Timestamp);
                ended = true;
                continue;
            }

            if (line.Content == "GAME OVER")
            {
                record.Meta.EndedBy = "loss";
                record.Meta.EndTime = NormalizeTimestamp(line.Timestamp);
                ended = true;
            }
        }

        // Flush pending into final spin BEFORE adding it
        if (cur != null)
        {
            if (pendingAdditions.Count > 0)
            {
                int choiceIdx = -1;
                for (int pi = 0; pi < pendingAdditions.Count; pi++)
                {
                    if (pendingAdditions[pi].Source == "choice" && pendingAdditions[pi].Type == "symbol")
                    {
                        cur.MainSymbol = pendingAdditions[pi].Id;
                        choiceIdx = pi;
                        break;
                    }
                }
                for (int i = 0; i < pendingAdditions.Count; i++)
                {
                    if (i == choiceIdx) continue;
                    cur.ExtraActions.Add(pendingAdditions[i]);
                }
                pendingAdditions.Clear();
            }
            allSpins.Add(cur);
        }

        // Remove ghost spin_num=0 entries (game engine initialisation).
        // spin_num=0 preserved (spin→choice model)

        // --- Build rent_cycles ---
        record.RentCycles = BuildRentCycles(allSpins, ended, record.Meta.EndedBy);

        // --- Extract choice items into cycle end_actions ---
        ExtractEndActions(record.RentCycles);

        // --- Build meta ---
        record.Meta.TotalSpins = allSpins.Count;
        record.Meta.FinalCoins = finalCoins;
        record.Meta.ParseConfidence = ended ? "complete" :
            allSpins.Count > 0 ? "truncated" : "partial";

        // Accumulate token totals
        long totalReroll = 0, totalRemoval = 0, totalEssence = 0;
        foreach (var sp in allSpins)
        {
            totalReroll += sp.GainedReroll;
            totalRemoval += sp.GainedRemoval;
            totalEssence += sp.GainedEssence;
        }

        // --- Build summary ---
        record.Summary = BuildSummary(symbolAccum, itemAccum,
            destroyedSymbolAccum, destroyedItemAccum, finePrintList,
            totalReroll, totalRemoval, totalEssence);

        return record;
    }

    // =====================================================================
    // Rent cycle builder
    // =====================================================================

    private static List<RentCycle> BuildRentCycles(List<SpinFrame> allSpins,
        bool ended, string endedBy)
    {
        var cycles = new List<RentCycle>();
        if (allSpins.Count == 0) return cycles;

        int roundIdx = 0;
        var cycleSpins = new List<SpinFrame>();

        foreach (var spin in allSpins)
        {
            // Cut check BEFORE adding: SpinNum is 0-based (= popup.spins),
            // so the boundary spin (popup.spins == cut) belongs to the next cycle.
            if (spin.SpinNum >= RoundCut(roundIdx) && cycleSpins.Count > 0)
            {
                while (spin.SpinNum >= RoundCut(roundIdx))
                    roundIdx++;

                cycles.Add(FinalizeCycle(cycleSpins, roundIdx - 1));
                cycleSpins.Clear();
            }
            cycleSpins.Add(spin);
        }

        // Final (possibly incomplete) cycle
        if (cycleSpins.Count > 0)
            cycles.Add(FinalizeCycle(cycleSpins, roundIdx));

        // Fix up rent_payment for the final cycle
        if (cycles.Count > 0)
        {
            var lastCycle = cycles.Last();
            if (ended)
            {
                lastCycle.RentPayment = new RentPaymentResult
                {
                    PaidSuccessfully = endedBy == "victory",
                    CoinsLeftAfterPay = endedBy == "victory"
                        ? (lastCycle.Spins.Last().CoinsAfter - lastCycle.RentRequired)
                        : 0
                };
            }
            else
            {
                // Truncated log — we don't know
                lastCycle.RentPayment = null;
            }
        }

        return cycles;
    }

    private static RentCycle FinalizeCycle(List<SpinFrame> spins, int roundIdx)
    {
        var cycle = new RentCycle
        {
            CycleIndex = roundIdx + 1,
            RentRequired = RentForRound(roundIdx),
            SpinsInCycle = spins.Count,
            Spins = spins.Select(sf => sf.ToSpinEntry()).ToList()
        };

        // For non-final cycles, estimate rent payment
        var lastSpin = spins.Last();
        cycle.RentPayment = new RentPaymentResult
        {
            PaidSuccessfully = true,
            CoinsLeftAfterPay = Math.Max(0, lastSpin.CoinsAfter - cycle.RentRequired)
        };

        return cycle;
    }

    private static int RoundCut(int roundIdx)
    {
        if (roundIdx < 0) return 0;
        if (roundIdx < BaseRoundCuts.Length)
            return BaseRoundCuts[roundIdx];
        return BaseRoundCuts[^1] + (roundIdx - BaseRoundCuts.Length + 1) * 10;
    }

    private static int RentForRound(int roundIdx)
    {
        if (roundIdx < 0) return 0;
        if (roundIdx < BaseRents.Length)
            return BaseRents[roundIdx];
        return 500 + (roundIdx - 11) * 500;
    }

    // =====================================================================
    // Summary builder
    // =====================================================================

    // =====================================================================
    // End actions extractor: move choice items from spin.extra_actions
    // to cycle.end_actions (matching GDScript Phase 2.5).
    // =====================================================================

    private static void ExtractEndActions(List<RentCycle> cycles)
    {
        foreach (var cycle in cycles)
        {
            var endActions = new List<ActionEntry>();
            foreach (var spin in cycle.Spins)
            {
                var remaining = new List<ActionEntry>();
                foreach (var act in spin.ExtraActions)
                {
                    if (act.Action == "added" && act.Type == "item")
                        endActions.Add(act);
                    else
                        remaining.Add(act);
                }
                spin.ExtraActions = remaining;
            }
            cycle.EndActions = endActions;
        }
    }

    // =====================================================================
    // Summary builder
    // =====================================================================

    private static RunSummary BuildSummary(
        Dictionary<string, int> symbolAccum,
        Dictionary<string, int> itemAccum,
        Dictionary<string, int> destroyedSymbolAccum,
        Dictionary<string, int> destroyedItemAccum,
        List<string> finePrintList,
        long totalReroll, long totalRemoval, long totalEssence)
    {
        // Subtract destroyed symbols from accumulator (destroyed items already handled)
        foreach (var kv in destroyedSymbolAccum)
        {
            if (symbolAccum.TryGetValue(kv.Key, out var c))
                symbolAccum[kv.Key] = Math.Max(0, c - kv.Value);
        }

        return new RunSummary
        {
            StatusBar = new StatusBarSummary
            {
                RerollTokens = totalReroll,
                RemovalTokens = totalRemoval,
                EssenceTokens = totalEssence
            },
            Symbols = symbolAccum
                .Where(kv => kv.Value > 0)
                .Select(kv => new SymbolInSummary { Id = kv.Key, Count = kv.Value })
                .ToList(),
            Items = itemAccum
                .Where(kv => kv.Value > 0)
                .Select(kv => new ItemInSummary { Id = kv.Key })
                .ToList(),
            DestroyedSymbols = destroyedSymbolAccum
                .Select(kv => new DestroyedEntry { Id = kv.Key, Count = kv.Value })
                .ToList(),
            DestroyedItems = destroyedItemAccum
                .Select(kv => new DestroyedEntry { Id = kv.Key, Count = kv.Value })
                .ToList(),
            LandlordFinePrint = finePrintList
                .Select(fp => new FinePrintEntry { Id = fp })
                .ToList()
        };
    }

    // =====================================================================
    // =====================================================================
    // Internal spin frame (mutable builder)
    // =====================================================================

    private class SpinFrame
    {
        public int SpinNum;
        public double CoinsBefore;
        public double CoinsAfter;
        public double CoinChange;
        public double GainedCoins;
        public long GainedReroll;
        public long GainedRemoval;
        public long GainedEssence;
        public string? MainSymbol;
        public List<string> SkippedOptions = new();
        public List<ActionEntry> ExtraActions = new();

        public SpinEntry ToSpinEntry()
        {
            return new SpinEntry
            {
                SpinNum = SpinNum,
                CoinsBefore = CoinsBefore,
                CoinsAfter = CoinsAfter,
                CoinChange = CoinChange,
                RerollChange = GainedReroll,
                RemovalChange = GainedRemoval,
                EssenceChange = GainedEssence,
                MainSymbol = MainSymbol,
                SkippedOptions = SkippedOptions,
                ExtraActions = ExtraActions
            };
        }
    }

    // =====================================================================
    // Static helpers
    // =====================================================================

    private static RunRecord CreateEmpty(string runId, string sourceLogFile, string confidence)
    {
        return new RunRecord(runId)
        {
            IsLegacyLog = true,
            Meta = new RunMeta
            {
                RunId = runId,
                SourceLogFile = sourceLogFile,
                ParserVersion = ParserVersion,
                ParseConfidence = confidence,
                EndedBy = confidence == "corrupted" ? "corrupted" : "loss"
            }
        };
    }

    private static string NormalizeTimestamp(string raw)
    {
        if (DateTime.TryParseExact(raw, "M/d/yyyy HH:mm:ss",
                CultureInfo.InvariantCulture, DateTimeStyles.None, out var dt))
            return dt.ToString("yyyy-MM-ddTHH:mm:ss");
        return raw;
    }

    private static List<string> ParseCommaList(string content)
    {
        if (string.IsNullOrWhiteSpace(content)) return new List<string>();
        return content.Split(',')
            .Select(s => CleanSymbolName(s.Trim()))
            .Where(s => !string.IsNullOrEmpty(s))
            .ToList();
    }

    private static string CleanSymbolName(string raw)
    {
        var parenIdx = raw.IndexOf('(');
        return parenIdx > 0 ? raw[..parenIdx].Trim() : raw.Trim();
    }

    private static string ParseDestroyedItemName(string raw)
    {
        var commaIdx = raw.IndexOf(',');
        return commaIdx > 0 ? raw[..commaIdx].Trim() : raw.Trim();
    }

    private static double ParseDouble(string raw)
    {
        if (double.TryParse(raw, NumberStyles.Float,
                CultureInfo.InvariantCulture, out var d))
            return d;
        return 0;
    }
}
