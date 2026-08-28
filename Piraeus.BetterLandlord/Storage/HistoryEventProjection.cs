using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using Piraeus.BetterLandlord.Model;

namespace Piraeus.BetterLandlord.Storage;

/// <summary>
/// Rehydrates detailed action badges for records produced before the projection
/// lived in MainScriptSourceMod. The append-only event JSONL is the primary
/// source; the native run log is used only to reconcile authoritative item
/// destruction lines for records that predate structured action events.
/// </summary>
internal static class HistoryEventProjection
{
    private static readonly Regex DestroyedItemPattern = new(
        @"^\[(?<timestamp>[^\]]+)\]\s*Destroyed item - (?<id>[A-Za-z0-9_-]+)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public static void Rehydrate(RunRecord record, string eventsPath, string runLogPath)
    {
        var spins = record.RentCycles
            .SelectMany(cycle => cycle.Spins)
            .ToDictionary(spin => spin.SpinNum);
        if (spins.Count == 0) return;

        var spinStarts = new List<(DateTime Timestamp, SpinEntry Spin)>();
        var matchedActions = new HashSet<ActionEntry>();
        if (File.Exists(eventsPath))
        {
            foreach (var line in File.ReadLines(eventsPath))
            {
                try
                {
                    using var doc = JsonDocument.Parse(line);
                    var root = doc.RootElement;
                    var type = root.TryGetProperty("type", out var typeElement)
                        ? typeElement.GetString() ?? ""
                        : "";
                    var payload = root.TryGetProperty("payload", out var payloadElement)
                        ? payloadElement
                        : default;

                    if (type == "spin_start" && TryGetInt(payload, "spin_num", out var spinNum) &&
                        spins.TryGetValue(spinNum, out var spin))
                    {
                        if (TryGetTimestamp(root, out var timestamp))
                            spinStarts.Add((timestamp, spin));
                        continue;
                    }

                    if (type == "deck_snapshot" && TryGetInt(payload, "spin_num", out var deckSpinNum) &&
                        spins.TryGetValue(deckSpinNum, out var deckSpin) &&
                        payload.TryGetProperty("symbols", out var deckSymbols) &&
                        deckSymbols.ValueKind == JsonValueKind.Array)
                    {
                        deckSpin.DeckSymbols ??= new();
                        deckSpin.DeckSymbols.Clear();
                        foreach (var symbolElement in deckSymbols.EnumerateArray())
                        {
                            if (symbolElement.ValueKind != JsonValueKind.Object ||
                                !TryGetString(symbolElement, "id", out var symbolId) ||
                                string.IsNullOrWhiteSpace(symbolId))
                                continue;

                            int? turnsUntilChange = null;
                            if (TryGetInt(symbolElement, "turns_until_change", out var turns))
                                turnsUntilChange = turns;
                            string? stackValue = TryGetString(symbolElement, "stack_value", out var stack)
                                ? stack : null;
                            deckSpin.DeckSymbols.Add(new BoardSymbolEntry
                            {
                                Id = symbolId,
                                TurnsUntilChange = turnsUntilChange,
                                StackValue = stackValue
                            });
                        }
                        continue;
                    }
                    if (type is not ("item_used" or "essence_triggered" or
                        "item_destroyed" or "symbol_destroyed" or "symbol_removed"))
                        continue;

                    var idProperty = type is "symbol_destroyed" or "symbol_removed" ? "symbol" : "item";
                    if (!TryGetString(payload, idProperty, out var id) || string.IsNullOrWhiteSpace(id))
                        continue;

                    var target = spinStarts.Count > 0 ? spinStarts[^1].Spin : null;
                    if (target == null && spins.Count == 1) target = spins.Values.First();
                    if (target == null) continue;

                    AddAction(target, new ActionEntry
                    {
                        Action = type switch
                        {
                            "item_used" => "used",
                            "essence_triggered" => "triggered",
                            "item_destroyed" or "symbol_destroyed" => "destroyed",
                            "symbol_removed" => "removed",
                            _ => ""
                        },
                        Type = type is "symbol_destroyed" or "symbol_removed"
                            ? "symbol"
                            : type == "essence_triggered" ? "essence" : "item",
                        Id = id,
                        Source = TryGetString(payload, "source", out var source) ? source : null,
                        AfterChoiceIdx = LastChoiceIdx(target)
                    }, matchedActions);
                }
                catch (JsonException)
                {
                    // A partially written recovery line must not prevent the UI
                    // from loading the completed run JSON.
                }
            }
        }

        // item_to_destroy in an Effect line is descriptive metadata, not proof
        // that an essence existed or was consumed. Reconcile the structured
        // actions against the authoritative native "Destroyed item - ..." lines
        // so both current and legacy records avoid phantom essence triggers.
        if (spinStarts.Count > 0 && File.Exists(runLogPath))
            ReconcileDestroyedItems(record, spinStarts, runLogPath);
    }

    private static void ReconcileDestroyedItems(
        RunRecord record,
        IReadOnlyList<(DateTime Timestamp, SpinEntry Spin)> spinStarts,
        string runLogPath)
    {
        var destroyedBySpin = new Dictionary<SpinEntry, Dictionary<string, int>>();
        foreach (var line in File.ReadLines(runLogPath))
        {
            var match = DestroyedItemPattern.Match(line);
            if (!match.Success || !DateTime.TryParse(
                    match.Groups["timestamp"].Value,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AllowWhiteSpaces,
                    out var timestamp))
                continue;

            var target = FindSpin(spinStarts, timestamp);
            if (target == null) continue;

            if (!destroyedBySpin.TryGetValue(target, out var items))
                destroyedBySpin[target] = items = new(StringComparer.Ordinal);
            var id = match.Groups["id"].Value;
            items[id] = items.GetValueOrDefault(id) + 1;
        }

        foreach (var spin in record.RentCycles.SelectMany(cycle => cycle.Spins))
        {
            // These came from the old item_to_destroy parser. Since that field
            // is only a possible effect target, discard it before rebuilding the
            // verified actions below.
            spin.ExtraActions.RemoveAll(action =>
                string.Equals(action.Source, "effect", StringComparison.Ordinal) &&
                ((action.Action == "destroyed" && action.Type == "item") ||
                 (action.Action == "triggered" && action.Type == "essence")));

            if (!destroyedBySpin.TryGetValue(spin, out var items))
                continue;

            foreach (var (id, count) in items)
            {
                EnsureActionCount(spin, "destroyed", "item", id, "consumed", count);
                if (id.EndsWith("_essence", StringComparison.Ordinal))
                    EnsureActionCount(spin, "triggered", "essence", id, "consumed", count);
                else
                    EnsureActionCount(spin, "used", "item", id, "consumed", count);
            }
        }
    }

    private static SpinEntry? FindSpin(
        IReadOnlyList<(DateTime Timestamp, SpinEntry Spin)> spinStarts,
        DateTime timestamp)
    {
        SpinEntry? target = null;
        foreach (var start in spinStarts.OrderBy(start => start.Timestamp))
        {
            if (start.Timestamp > timestamp) break;
            target = start.Spin;
        }
        return target;
    }

    private static void EnsureActionCount(
        SpinEntry spin,
        string action,
        string type,
        string id,
        string source,
        int expectedCount)
    {
        var existingCount = spin.ExtraActions.Count(candidate =>
            candidate.Action == action && candidate.Type == type && candidate.Id == id);
        for (var i = existingCount; i < expectedCount; i++)
        {
            spin.ExtraActions.Add(new ActionEntry
            {
                Action = action,
                Type = type,
                Id = id,
                Source = source,
                AfterChoiceIdx = LastChoiceIdx(spin)
            });
        }
    }

    private static void AddAction(SpinEntry spin, ActionEntry action, HashSet<ActionEntry> matchedActions)
    {
        if (string.IsNullOrWhiteSpace(action.Action) || string.IsNullOrWhiteSpace(action.Id)) return;
        var existing = spin.ExtraActions.FirstOrDefault(candidate =>
            !matchedActions.Contains(candidate) &&
            candidate.Action == action.Action &&
            candidate.Type == action.Type &&
            candidate.Id == action.Id);
        if (existing != null)
        {
            // Older projected JSON often kept the action but omitted its
            // anchoring metadata. Enrich it instead of creating a duplicate.
            existing.Source ??= action.Source;
            existing.AfterChoiceIdx ??= action.AfterChoiceIdx;
            matchedActions.Add(existing);
            return;
        }
        spin.ExtraActions.Add(action);
        matchedActions.Add(action);
    }

    private static int? LastChoiceIdx(SpinEntry spin)
        => spin.ChoiceGroups is { Count: > 0 }
            ? spin.ChoiceGroups[^1].ChoiceIdx
            : null;

    private static bool TryGetTimestamp(JsonElement root, out DateTime timestamp)
    {
        timestamp = default;
        return root.TryGetProperty("timestamp", out var element) &&
               DateTime.TryParse(element.GetString(), CultureInfo.InvariantCulture,
                   DateTimeStyles.AssumeLocal, out timestamp);
    }

    private static bool TryGetString(JsonElement element, string name, out string value)
    {
        value = "";
        return element.ValueKind == JsonValueKind.Object &&
               element.TryGetProperty(name, out var property) &&
               property.ValueKind == JsonValueKind.String &&
               !string.IsNullOrWhiteSpace(value = property.GetString() ?? "");
    }

    private static bool TryGetInt(JsonElement element, string name, out int value)
    {
        value = 0;
        return element.ValueKind == JsonValueKind.Object &&
               element.TryGetProperty(name, out var property) &&
               property.TryGetInt32(out value);
    }
}
