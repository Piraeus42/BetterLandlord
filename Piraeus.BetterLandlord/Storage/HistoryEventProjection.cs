using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using Piraeus.BetterLandlord.Model;

namespace Piraeus.BetterLandlord.Storage;

/// <summary>
/// Rehydrates detailed action badges for records produced before the projection
/// lived in MainScriptSourceMod. The append-only event JSONL is the primary
/// source; the native run log is a compatibility fallback for essence effects
/// that the old writer never emitted as structured events.
/// </summary>
internal static class HistoryEventProjection
{
    private static readonly Regex EssenceEffectPattern = new(
        @"^\[(?<timestamp>[^\]]+)\].*item_to_destroy:(?<id>[A-Za-z0-9_-]+)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public static void Rehydrate(RunRecord record, string eventsPath, string runLogPath)
    {
        var spins = record.RentCycles
            .SelectMany(cycle => cycle.Spins)
            .ToDictionary(spin => spin.SpinNum);
        if (spins.Count == 0) return;

        var spinStarts = new List<(DateTime Timestamp, SpinEntry Spin)>();
        var matchedActions = new HashSet<ActionEntry>();
        var hasStructuredEssenceEvents = false;
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

                    if (type == "essence_triggered") hasStructuredEssenceEvents = true;
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

        // Older WriteLogPatch versions did not emit essence_triggered for
        // Effect lines containing item_to_destroy. Only use this fallback when
        // structured essence events are absent, avoiding duplicates after an
        // updated game run has been recorded.
        if (!hasStructuredEssenceEvents && spinStarts.Count > 0 && File.Exists(runLogPath))
            RehydrateEssenceEffects(spinStarts, runLogPath, matchedActions);
    }

    private static void RehydrateEssenceEffects(
        IReadOnlyList<(DateTime Timestamp, SpinEntry Spin)> spinStarts,
        string runLogPath,
        HashSet<ActionEntry> matchedActions)
    {
        foreach (var line in File.ReadLines(runLogPath))
        {
            var match = EssenceEffectPattern.Match(line);
            if (!match.Success || !DateTime.TryParse(
                    match.Groups["timestamp"].Value,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AllowWhiteSpaces,
                    out var timestamp))
                continue;

            SpinEntry? target = null;
            foreach (var start in spinStarts)
            {
                if (start.Timestamp > timestamp) break;
                target = start.Spin;
            }
            if (target == null) continue;

            AddAction(target, new ActionEntry
            {
                Action = "triggered",
                Type = "essence",
                Id = match.Groups["id"].Value,
                Source = "effect",
                AfterChoiceIdx = LastChoiceIdx(target)
            }, matchedActions);
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
