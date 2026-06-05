using System.Text.Json.Serialization;

namespace Piraeus.BetterLandlord.Model;

public class RunSummary
{
    [JsonPropertyName("status_bar")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public StatusBarSummary? StatusBar { get; set; }

    [JsonPropertyName("symbols")]
    public List<SymbolInSummary> Symbols { get; set; } = new();

    [JsonPropertyName("items")]
    public List<ItemInSummary> Items { get; set; } = new();

    [JsonPropertyName("destroyed_symbols")]
    public List<DestroyedEntry> DestroyedSymbols { get; set; } = new();

    [JsonPropertyName("destroyed_items")]
    public List<DestroyedEntry> DestroyedItems { get; set; } = new();

    [JsonPropertyName("removed_symbols")]
    public List<DestroyedEntry> RemovedSymbols { get; set; } = new();

    [JsonPropertyName("landlord_fine_print")]
    public List<FinePrintEntry> LandlordFinePrint { get; set; } = new();
}

public class StatusBarSummary
{
    [JsonPropertyName("payments_settled")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? PaymentsSettled { get; set; }

    [JsonPropertyName("total_payments")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? TotalPayments { get; set; }

    [JsonPropertyName("reroll_tokens")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public long? RerollTokens { get; set; }

    [JsonPropertyName("removal_tokens")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public long? RemovalTokens { get; set; }

    [JsonPropertyName("essence_tokens")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public long? EssenceTokens { get; set; }
}

public class SymbolInSummary
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("count")]
    public int Count { get; set; } = 1;

    [JsonPropertyName("saved_value")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int SavedValue { get; set; }

    [JsonPropertyName("rarity")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Rarity { get; set; }

    [JsonPropertyName("item_count")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int ItemCount { get; set; }

    [JsonPropertyName("badge_text")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? BadgeTextValue { get; set; }

    [JsonPropertyName("badge_mult")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? BadgeMultValue { get; set; }

    [JsonPropertyName("badge_bonus")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? BadgeBonusValue { get; set; }

    [JsonPropertyName("estimated_value_contribution")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? EstimatedValueContribution { get; set; }

    [JsonIgnore]
    public bool HasBadge => !string.IsNullOrEmpty(BadgeTextValue)
                         || !string.IsNullOrEmpty(BadgeBonusValue)
                         || !string.IsNullOrEmpty(BadgeMultValue);

    [JsonIgnore]
    public string BadgeText
    {
        get
        {
            // child 1 (primary counter) takes priority, then child 3 (bonus), then child 2 (mult)
            if (!string.IsNullOrEmpty(BadgeTextValue)) return BadgeTextValue;
            if (!string.IsNullOrEmpty(BadgeBonusValue)) return BadgeBonusValue;
            if (!string.IsNullOrEmpty(BadgeMultValue)) return BadgeMultValue;
            return "";
        }
    }

    [JsonIgnore]
    public string? BadgeTextSecondary =>
        !string.IsNullOrEmpty(BadgeTextValue) && !string.IsNullOrEmpty(BadgeBonusValue) ? BadgeBonusValue : null;

    // DPT fields
    [JsonPropertyName("total_value")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public double TotalValue { get; set; }

    [JsonPropertyName("turns_present")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int TurnsPresent { get; set; }

    [JsonPropertyName("turns_contributing")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int TurnsContributing { get; set; }

    [JsonPropertyName("dpt_actual")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public double DptActual { get; set; }

    [JsonPropertyName("dpt_effective")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public double DptEffective { get; set; }

    [JsonIgnore]
    public string DptDisplay => TotalValue > 0
        ? $"{TotalValue} coins · {DptActual:F1}/spin · {DptEffective:F1}/有效"
        : "";
}

public class ItemInSummary
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("item_count")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int ItemCount { get; set; }

    [JsonPropertyName("saved_value")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int SavedValue { get; set; }

    [JsonPropertyName("rarity")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Rarity { get; set; }

    [JsonIgnore]
    public bool HasBadge => ItemCount > 1 || SavedValue > 0;

    [JsonIgnore]
    public string BadgeText => ItemCount > 1 ? ItemCount.ToString() : SavedValue.ToString();
}

public class DestroyedEntry
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("count")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? Count { get; set; }
}

public class FinePrintEntry
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("description")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Description { get; set; }
}
