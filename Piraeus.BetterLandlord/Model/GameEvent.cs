using System.Text.Json.Serialization;

namespace Piraeus.BetterLandlord.Model;

public class GameEvent
{
    [JsonPropertyName("event_id")]
    public string EventId { get; set; } = Guid.NewGuid().ToString("N")[..12];

    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = "";

    [JsonPropertyName("type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("payload")]
    public Dictionary<string, object?> Payload { get; set; } = new();

    public GameEvent() { }

    public GameEvent(string runId, string timestamp, EventType type)
    {
        RunId = runId;
        Timestamp = timestamp;
        Type = TypeToString(type);
    }

    public static string TypeToString(EventType type) => type switch
    {
        EventType.RunStart => "run_start",
        EventType.RunEnd => "run_end",
        EventType.RentPaid => "rent_paid",
        EventType.SymbolChoicePresented => "symbol_choice_presented",
        EventType.SymbolChosen => "symbol_chosen",
        EventType.SymbolAdded => "symbol_added",
        EventType.SymbolDestroyed => "symbol_destroyed",
        EventType.SymbolRemoved => "symbol_removed",
        EventType.ItemChoicePresented => "item_choice_presented",
        EventType.ItemChosen => "item_chosen",
        EventType.ItemAdded => "item_added",
        EventType.ItemDestroyed => "item_destroyed",
        EventType.SpinStart => "spin_start",
        EventType.SpinEnd => "spin_end",
        EventType.EffectTriggered => "effect_triggered",
        EventType.BoardState => "board_state",
        _ => "unknown"
    };

    public static EventType StringToType(string s) => s switch
    {
        "run_start" => EventType.RunStart,
        "run_end" => EventType.RunEnd,
        "rent_paid" => EventType.RentPaid,
        "symbol_choice_presented" => EventType.SymbolChoicePresented,
        "symbol_chosen" => EventType.SymbolChosen,
        "symbol_added" => EventType.SymbolAdded,
        "symbol_destroyed" => EventType.SymbolDestroyed,
        "symbol_removed" => EventType.SymbolRemoved,
        "item_choice_presented" => EventType.ItemChoicePresented,
        "item_chosen" => EventType.ItemChosen,
        "item_added" => EventType.ItemAdded,
        "item_destroyed" => EventType.ItemDestroyed,
        "spin_start" => EventType.SpinStart,
        "spin_end" => EventType.SpinEnd,
        "effect_triggered" => EventType.EffectTriggered,
        "board_state" => EventType.BoardState,
        _ => EventType.Unknown
    };
}
