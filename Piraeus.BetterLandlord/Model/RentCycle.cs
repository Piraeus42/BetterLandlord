using System.Text.Json.Serialization;

namespace Piraeus.BetterLandlord.Model;

public class RentCycle
{
    [JsonPropertyName("cycle_index")]
    public int CycleIndex { get; set; }

    [JsonPropertyName("rent_required")]
    public int RentRequired { get; set; }

    [JsonPropertyName("spins_in_cycle")]
    public int SpinsInCycle { get; set; }

    [JsonPropertyName("spins")]
    public List<SpinEntry> Spins { get; set; } = new();

    [JsonPropertyName("end_actions")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    [JsonConverter(typeof(SingleOrArrayConverter<ActionEntry>))]
    public List<ActionEntry> EndActions { get; set; } = new();

    [JsonPropertyName("rent_payment")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public RentPaymentResult? RentPayment { get; set; }
}

public class SpinEntry
{
    [JsonPropertyName("spin_num")]
    public int SpinNum { get; set; }

    [JsonPropertyName("coins_before")]
    public double CoinsBefore { get; set; }

    [JsonPropertyName("coins_after")]
    public double CoinsAfter { get; set; }

    [JsonPropertyName("coin_change")]
    public double CoinChange { get; set; }

    [JsonPropertyName("reroll_change")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public long RerollChange { get; set; }

    [JsonPropertyName("removal_change")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public long RemovalChange { get; set; }

    [JsonPropertyName("essence_change")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public long EssenceChange { get; set; }

    [JsonPropertyName("main_symbol")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? MainSymbol { get; set; }

    [JsonPropertyName("skipped_options")]
    public List<string> SkippedOptions { get; set; } = new();

    // Structured selection data for the detailed history view.  Existing history
    // records simply deserialize to an empty list.
    [JsonPropertyName("choice_groups")]
    public List<ChoiceGroupEntry> ChoiceGroups { get; set; } = new();

    [JsonPropertyName("extra_actions")]
    [JsonConverter(typeof(SingleOrArrayConverter<ActionEntry>))]
    public List<ActionEntry> ExtraActions { get; set; } = new();

    // Snapshot of the symbol deck immediately before this spin. Newer runs
    // populate it from the native deck; older runs deserialize to an empty list.
    [JsonPropertyName("deck_symbols")]
    public List<BoardSymbolEntry> DeckSymbols { get; set; } = new();

    [JsonPropertyName("boss_info")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public BossInfo? BossInfo { get; set; }
}

public class ChoiceGroupEntry
{
    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "symbol";

    [JsonPropertyName("options")]
    public List<string> Options { get; set; } = new();

    [JsonPropertyName("selected")]
    public List<string> Selected { get; set; } = new();

    [JsonPropertyName("choice_idx")]
    public int ChoiceIdx { get; set; }

    // "selected", "skipped", or null while the game is still resolving.
    [JsonPropertyName("result")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Result { get; set; }

    [JsonPropertyName("rerolled")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public bool Rerolled { get; set; }
}

public class BoardSymbolEntry
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("turns_until_change")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? TurnsUntilChange { get; set; }

    [JsonPropertyName("stack_value")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? StackValue { get; set; }

    // Reserved for compatibility with collaborator records.
    [JsonPropertyName("value")]
    public double Value { get; set; }
}

public class ActionEntry
{
    [JsonPropertyName("action")]
    public string Action { get; set; } = "added";

    [JsonPropertyName("type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("source")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Source { get; set; }

    [JsonPropertyName("choice_idx")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int ChoiceIdx { get; set; }

    // Links a post-choice action (for example consuming a one-shot item) to
    // the choice group that immediately preceded it.
    [JsonPropertyName("after_choice_idx")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? AfterChoiceIdx { get; set; }

    [JsonPropertyName("remaining")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? Remaining { get; set; }

    [JsonPropertyName("new_count")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? NewCount { get; set; }
}

public class BossInfo
{
    [JsonPropertyName("boss_hp_before")]
    public int BossHpBefore { get; set; }

    [JsonPropertyName("boss_hp_after")]
    public int BossHpAfter { get; set; }

    [JsonPropertyName("damage_dealt")]
    public int DamageDealt { get; set; }
}

public class RentPaymentResult
{
    [JsonPropertyName("paid_successfully")]
    public bool PaidSuccessfully { get; set; }

    [JsonPropertyName("coins_left_after_pay")]
    public double CoinsLeftAfterPay { get; set; }
}
