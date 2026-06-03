using System.Text.Json.Serialization;

namespace Piraeus.BetterHistoryMod.Model;

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
    public long CoinsBefore { get; set; }

    [JsonPropertyName("coins_after")]
    public long CoinsAfter { get; set; }

    [JsonPropertyName("coin_change")]
    public long CoinChange { get; set; }

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

    [JsonPropertyName("extra_actions")]
    [JsonConverter(typeof(SingleOrArrayConverter<ActionEntry>))]
    public List<ActionEntry> ExtraActions { get; set; } = new();

    [JsonPropertyName("boss_info")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public BossInfo? BossInfo { get; set; }
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
    public long CoinsLeftAfterPay { get; set; }
}
