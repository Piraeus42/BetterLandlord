# RNG 架构 V1

> 初始架构文档 — 设计目标、演进背景、完整方案、实施清单
> 日期: 2026-06-04

---

## 1. 设计目标

1. **稀有卡不容易歪种** — 传奇/稀有级别的符号在相同种子下，出现顺序基本固定
2. **前 20 选不容易歪种** — 前期构筑锚点稳定
3. **物品不容易歪种** — 符号/物品/精华各有独立 RNG 流
4. **随机数流完全解耦** — 每个域 shuffle 和数值判定分家，互不干扰

---

## 2. 演进背景

### V0 已修复的 Bug

| Bug | 问题 | 修复 |
|-----|------|------|
| Spin RNG 偏移 | `_bh_begin_spin_rng()` 从 `_bh_rng_spin.randi_max()` 取值，被 Deck/Oil Can 额外消费 | 改为 `djb2(seed, "spin_N")` |
| Rarity Shuffle 污染 | `forced_rarity_arr.shuffle()` 和稀有度判定共用 `_bh_rng_rarity` | 隔离到 `_bh_rng_forced_rarity` |
| Boss 音乐泄漏 | `rand_range(0,1)` 未替换 | catch-all regex |

### V0→V1 新发现的 Bug

| Bug | 问题 | 影响 |
|-----|------|------|
| #4 物品吃符号 RNG | `add_item` 主路径走 `_bh_c_pick_symbol` → `_bh_rng_sym_*` | `_bh_rng_itm_*` 完全闲置 |
| #5 精华吃 common RNG | essence 落到 `_bh_c_pick_symbol` default 分支 | essence 消费 `_bh_rng_sym_common` |
| #6 sym/itm 稀有度未解耦 | `_bh_rng_rarity` 一个流服务符号+物品 | 不同 r_chances/bonuses/池可用性共用一个流 |
| #7 ess_* ×4 死代码 | `_bh_rng_ess_common/uncommon/rare/vrare` 从未使用 | 精华不分稀有度 |

---

## 3. V1 完整架构

### 3.1 持久流（17 个）

```
landlord_seed = FNV-1a(seed_input)
│
├── sym_rarity     → _bh_rng_sym_rarity      符号稀有度判定
├── itm_rarity     → _bh_rng_itm_rarity      物品稀有度判定
│
├── sym_common     → _bh_rng_sym_common      符号·普通
├── sym_uncommon   → _bh_rng_sym_uncommon    符号·罕见
├── sym_rare       → _bh_rng_sym_rare        符号·稀有
├── sym_vrare      → _bh_rng_sym_vrare       符号·传说
│
├── itm_common     → _bh_rng_itm_common      物品·普通
├── itm_uncommon   → _bh_rng_itm_uncommon    物品·罕见
├── itm_rare       → _bh_rng_itm_rare        物品·稀有
├── itm_vrare      → _bh_rng_itm_vrare       物品·传说
│
├── ess            → _bh_rng_ess             精华 (不分稀有度)
│
├── forced_rarity  → _bh_rng_forced_rarity   强制稀有度 shuffle
├── fineprint      → _bh_rng_fineprint       房东条款 / 动态图标
├── cosmetic       → _bh_rng_cosmetic        音乐 / Tips / 命运
│
│  删除: _bh_rng_spin, _bh_rng_rarity,
│         _bh_rng_ess_common/uncommon/rare/vrare ×4
```

### 3.2 临时流（6 个，每 spin 派生）

```
spin_val = djb2(landlord_seed, "spin_" + str(spin_num))
│
├── reel           → _bh_rng_reel            add_tile / 选 reel / 选空位
├── reel_shuffle   → _bh_rng_reel_shuffle    shuffle_tiles / Reel shuffle
├── effect         → _bh_rng_effect          效果触发 / 概率 / 值变化
├── effect_shuffle → _bh_rng_effect_shuffle  选目标 / 选图标 / 物品效果 shuffle
├── scratch        → _bh_rng_scratch         SFX / 抖动动画
└── oil_can        → _bh_rng_oil_can         Oil Can 符号洗牌
```

**总计: 17 持久 + 6 临时 = 23 个**

### 3.3 RNG 路由方案

核心修改：在 Pop-up 注入一个运行时路由函数，根据 `emails[0].type` 派发到正确的 RNG 流。

```gdscript
func _bh_c_rarity_randf():
    var _popup = $"/root/Main/Pop-up Sprite/Pop-up"
    if _popup != null and _popup.emails.size() > 0:
        var _type = _popup.emails[0].type
        if _type == "add_item" or _type == "add_item_prompt":
            return $"/root/Main"._bh_rng_itm_rarity.randf()
    return $"/root/Main"._bh_rng_sym_rarity.randf()

func _bh_c_pick_from_pool(rarity, pool):
    var _popup = $"/root/Main/Pop-up Sprite/Pop-up"
    if _popup != null and _popup.emails.size() > 0:
        var _type = _popup.emails[0].type
        if _type == "add_item" or _type == "add_item_prompt":
            return _bh_c_pick_item(rarity, pool)
    return _bh_c_pick_symbol(rarity, pool)
```

```
最终路由:

add_tile:
  稀有度 → _bh_rng_sym_rarity
  池选取 → _bh_rng_sym_common/uncommon/rare/vrare

add_item:
  稀有度 → _bh_rng_itm_rarity
  池选取 → _bh_rng_itm_common/uncommon/rare/vrare

essence (在 add_item 内):
  稀有度 → forced_rarity 指定 (不消耗 RNG)
  池选取 → _bh_rng_ess
```

### 3.4 `_bh_c_pick_item` 补 essence 分支

```gdscript
func _bh_c_pick_item(rarity, pool):
    match rarity:
        "common":    return pool[_bh_rng_itm_common.randi_max(pool.size())]
        "uncommon":  return pool[_bh_rng_itm_uncommon.randi_max(pool.size())]
        "rare":      return pool[_bh_rng_itm_rare.randi_max(pool.size())]
        "very_rare": return pool[_bh_rng_itm_vrare.randi_max(pool.size())]
        "essence":   return pool[_bh_rng_ess.randi_max(pool.size())]
        _:           return pool[_bh_rng_itm_common.randi_max(pool.size())]
```

### 3.5 Shuffle 路由表（不变）

| 调用 | 消费者 | 流 |
|------|--------|-----|
| `_rrr_shuffle` | shuffle_tiles | `_bh_rng_reel_shuffle` |
| `_rer_shuffle` | Reel shuffle | `_bh_rng_reel_shuffle` |
| `_sir_shuffle` | Slot Icon | `_bh_rng_effect_shuffle` |
| `_itr_shuffle` | Item 效果 | `_bh_rng_effect_shuffle` |
| `_bh_c_spin_shuffle` | Oil Can | `_bh_rng_oil_can` |
| `_lfr_shuffle` | Landlord | `_bh_rng_fineprint` |
| `_bh_c_rarity_shuffle` | forced_rarity | `_bh_rng_forced_rarity` |

---

## 4. 实施清单

### Phase 1: 路由修复 (紧急)

- [ ] 拆分 `_bh_rng_rarity` → `_bh_rng_sym_rarity` + `_bh_rng_itm_rarity`
- [ ] 合并 `_bh_rng_ess_*` ×4 → `_bh_rng_ess` ×1
- [ ] 重写 `_bh_c_rarity_randf()` 为运行时路由
- [ ] 新增 `_bh_c_pick_from_pool()` 路由函数
- [ ] `_bh_c_pick_item()` 加 `"essence"` 分支
- [ ] ChoiceRngPatch 中 `_bh_c_pick_symbol(...)` → `_bh_c_pick_from_pool(...)`
- [ ] 更新 `_bh_init_rng` / `_bh_save_rng_state` / `_bh_restore_rng_state`

### Phase 2: Shuffle 分家 (V1 核心)

- [ ] 删除 `_bh_rng_spin`
- [ ] 重写 `_bh_begin_spin_rng()` 派生全部 6 个临时流
- [ ] `_rrr_shuffle` → `_bh_rng_reel_shuffle`
- [ ] `_rer_shuffle` → `_bh_rng_reel_shuffle`
- [ ] `_sir_shuffle` → `_bh_rng_effect_shuffle`
- [ ] `_itr_shuffle` → `_bh_rng_effect_shuffle`
- [ ] `_bh_c_spin_shuffle` → `_bh_rng_oil_can`

### Phase 3: 清查验证

- [ ] 全量 diff patched vs original 确认无残留 Godot RNG 调用
- [ ] 编译 + 冒烟测试

---

## 5. 讨论记录摘要

### 物品序列化尝试（已放弃）

曾讨论将物品改为"遗物序列模式"（游戏启动时 shuffle 生成固定序列，运行时 pop）。最终决定保留现有架构，原因：
- 三选一中未选的两个要"放回"，与固定 pop 序列语义矛盾
- 肉鸽设计允许种子在合理范围内歪种

### StS2 调研

见 `docs/sts2-rng-study.md`。吸收：seed+hash(name) 直接派生。不适用：统一 RNG 不分稀有度。

### 符号池 shuffle 问题（已知未修）

符号池无 shuffle，`randi_max(size)` + `erase` 导致同批同稀有度第 2、3 个符号的映射受第 1 个影响。在稀有度序列波动时（k=3,2,3 vs k=2,2,2），同一 `sym_common[K]` 面对不同大小池。这是原理层面的限制，稀有卡由于出现频率低影响极小。暂不修复。
