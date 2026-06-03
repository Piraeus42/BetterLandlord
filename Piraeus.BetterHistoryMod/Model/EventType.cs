namespace Piraeus.BetterHistoryMod.Model;

public enum EventType
{
    // --- Run lifecycle ---
    RunStart,
    RunEnd,

    // --- Economy ---
    RentPaid,

    // --- Symbols ---
    SymbolChoicePresented,   // 三选一展示
    SymbolChosen,            // 选中一个（含跳过信息）
    SymbolAdded,             // 实际加入棋盘
    SymbolDestroyed,
    SymbolRemoved,

    // --- Items ---
    ItemChoicePresented,
    ItemChosen,
    ItemAdded,
    ItemDestroyed,

    // --- Spin ---
    SpinStart,
    SpinEnd,

    // --- Effects ---
    EffectTriggered,

    // --- Board state ---
    BoardState,

    // --- Fallback ---
    Unknown
}
