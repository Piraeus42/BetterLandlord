# JSON Schema v2.0

## 顶层

```json
{
  "history_version": "2.0",
  "run_id": "1780405902",
  "is_legacy_log": false,
  "meta": { ... },
  "summary": { ... },
  "rent_cycles": [ ... ]
}
```

- `is_legacy_log`: `true` = 从旧 log 解析, `false` = live mod 产出

## meta

```json
{
  "run_number": 83,
  "ended_by": "victory" | "loss" | "quit",
  "final_coins": 1943,
  "total_spins": 102,
  "floor": 20,
  "seed_type": "random" | "custom",
  "seed_input": "A3F7K2M9P1",
  "landlord_seed": 2874653291,
  "start_time": "2026-06-02T21:11:42",
  "end_time": "2026-06-02T21:23:56"
}
```

## summary

```json
{
  "symbols": [{
    "id": "diver", "count": 1,
    "total_value": 145,
    "turns_present": 60, "turns_contributing": 42,
    "dpt_actual": 2.4, "dpt_effective": 3.5,
    "saved_value": 0, "item_count": 0,
    "badge_text": null,       // child1 主计数器(game-rendered)
    "badge_bonus": "+3",      // child3 加成(game-rendered)
    "badge_mult": null        // child2 乘数(game-rendered)
  }],
  "items": [{
    "id": "lunchbox", "item_count": 2, "saved_value": 0
  }],
  "destroyed_symbols": [{ "id": "dud", "count": 3 }],
  "destroyed_items": [{ "id": "symbol_bomb", "count": 1 }],
  "removed_symbols": [{ "id": "anchor", "count": 2 }],
  "landlord_fine_print": [{ "id": "4", "description": "..." }],
  "status_bar": {
    "reroll_tokens": 3, "removal_tokens": 1, "essence_tokens": 2
  }
}
```

- `badge_*`: 游戏 `update_value_text()` 渲染的显示字符串。为空时不渲染角标
- `saved_value` / `item_count`: 棋盘快照值(旧字段,`_bh_end_run` 读取)

## rent_cycles[]

```json
[{
  "cycle_index": 1,
  "rent_required": 25,
  "spins_in_cycle": 5,
  "spins": [ ... ],
  "end_actions": [ ... ],
  "rent_payment": { "paid_successfully": true, "coins_left_after_pay": 10 }
}]
```

### spins[]

```json
{
  "spin_num": 1,
  "coins_before": 5, "coins_after": 12, "coin_change": 7,
  "reroll_change": 0, "removal_change": 0, "essence_change": 0,
  "main_symbol": "bee",
  "skipped_options": ["cat", "dog"],
  "extra_actions": [
    { "action": "added", "type": "item", "id": "lunchbox", "source": "choice" },
    { "action": "destroyed", "type": "item", "id": "urn" }
  ],
  "boss_info": { "boss_hp_before": 750, "boss_hp_after": 600, "damage_dealt": 150 }
}
```

### end_actions[]

```json
[
  { "action": "added", "type": "item", "id": "frying_pan", "source": "choice", "choice_idx": 0 },
  { "action": "skipped", "type": "item", "id": "shedding_season", "choice_idx": 0 }
]
```

- `choice_idx`: 同一次 choice 的 added+skipped 共享此值,UI 用其分组
- `action`: `"added"` | `"skipped"` | `"destroyed"` | `"removed"` | `"counter"`
- Phase 2.5 从 `extra_actions` 提取 type=item 且 action∈{added,skipped} 的条目

## Godot 兼容注意事项

- `end_actions` 和 `extra_actions` 的单元素数组可能被 Godot 3 序列化为 `{}` 而非 `[{}]`
- C# 侧用 `SingleOrArrayConverter<T>` 兼容两种格式
- `is_legacy_log: true` 的 JSON 由 LogParser 从旧 run.log 产生,缺少 `choice_idx`/`badge_*`/`end_actions` 等 live 专有字段
