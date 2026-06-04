# RNG 调用点全面审计

> 每个 `randomize()` / `rand_range()` / `.shuffle()` 调用点，交叉对照 mod patch 后消费的 RNG 流。
> 生成日期: 2026-06-04

---

## 1. RNG 流总览 (19 实例)

```
landlord_seed (FNV-1a)
├── _bh_rng_spin          持久 — 每 spin 取 1 值派生 reel/effect/scratch
├── _bh_rng_rarity        持久 — 稀有度判定 + forced_rarity_arr shuffle
├── _bh_rng_sym_common    持久 — 普通符号池索引
├── _bh_rng_sym_uncommon  持久 — 罕见符号池索引
├── _bh_rng_sym_rare      持久 — 稀有符号池索引
├── _bh_rng_sym_vrare     持久 — 极稀有符号池索引
├── _bh_rng_itm_common    持久 — 普通物品池索引
├── _bh_rng_itm_uncommon  持久 — 罕见物品池索引
├── _bh_rng_itm_rare      持久 — 稀有物品池索引
├── _bh_rng_itm_vrare     持久 — 极稀有物品池索引
├── _bh_rng_ess_common    持久 — 普通精华池索引
├── _bh_rng_ess_uncommon  持久 — 罕见精华池索引
├── _bh_rng_ess_rare      持久 — 稀有精华池索引
├── _bh_rng_ess_vrare     持久 — 极稀有精华池索引
├── _bh_rng_fineprint     持久 — 房东条款/动态图标
├── _bh_rng_cosmetic      持久 — 音乐/SFX/Tips/命运
├── _bh_rng_reel          每 spin 重建 — reel 洗牌/空位/加符号
├── _bh_rng_effect        每 spin 重建 — 效果触发/值/概率/变换
├── _bh_rng_scratch       每 spin 重建 — 外观动画/抖动/SFX 变化
```

**Godot 全局 RNG** — `seed(landlord_seed)` 在 `_bh_init_rng` 时初始化一次。所有 `randomize()` 被移除后理论上不再被修改，但 **存在未替换的 `rand_range()` / `.shuffle()` 调用**（见第 3 节），会从中消费。

---

## 2. 逐文件逐行调用表

### 图例

| 标记 | 含义 |
|------|------|
| ✅ | 已替换到正确的 PCGRng 流 |
| ⚠️ | 已替换但消费的流可能有问题 |
| 🔴 | **未替换 — 使用 Godot 全局 RNG** |

---

### 2.1 Pop-up.tscn__1.gd → `ChoiceRngPatch.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 993 | `rand_range(0, landlord_fates_data.size()-1)` | `_bh_c_cosmetic_pick(landlord_fates_data)` | **cosmetic** | ✅ |
| 1036 | `rand_range(0, tips.size())` | `_bh_c_cosmetic_pick(tips)` | **cosmetic** | ✅ |
| 1346 | `randomize()` | `# randomize() removed` | — | ✅ |
| 1347 | `var rand_num = rand_range(0, 1)` | `var rand_num = _bh_c_rarity_randf()` | **rarity** | ✅ |
| 1353 | `forced_rarity_arr.shuffle()` | `_bh_c_rarity_shuffle(forced_rarity_arr)` | **rarity** (custom_shuffle → n-1 次 randf) | ✅ |
| 1386 | `randomize()` | `# randomize() removed` | — | ✅ |
| 1390 | `card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]` | `_bh_c_pick_symbol(rarity, card_pool[rarity])` | **sym_common/uncommon/rare/vrare** | ✅ |
| 1394 | `card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]` | `_bh_c_pick_symbol(rarity, card_pool[rarity])` | **sym_common/uncommon/rare/vrare** | ✅ |
| 1401 | `card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]` | `_bh_c_pick_symbol(rarity, card_pool[rarity])` | **sym_common/uncommon/rare/vrare** | ✅ |
| 1427 | `card_pool[rand_range(0, card_pool.size())]` | `_bh_c_pick_item(rarity, card_pool)` | **itm_common/uncommon/rare/vrare** | ✅ |
| ~993 附近 | 6-tab `randomize()` + `rand_range(0, 1) < 0.5` | `_bh_c_cosmetic_randf() < 0.5` | **cosmetic** | ✅ |
| ~其他 | 14-tab `randomize()` + `pool.shuffle()` | `_bh_c_spin_shuffle(pool)` | **spin** | ✅ |
| ~其他 | 7-tab `pool.shuffle()` | `_bh_c_spin_shuffle(pool)` | **spin** | ✅ |
| **2976** | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| **2977** | `if rand_range(0, 1) < 0.5:` | **未替换** | **Godot 全局** | 🔴 |
| **3471** | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| **3472** | `pool.shuffle()` | `_bh_c_spin_shuffle(pool)` (实测已替换) | **spin** | ✅ |

> **🔴 2977**: `start_bossfight()` 中 Boss 战斗音乐二选一。`randomize()` 被 regex 移除，但 `rand_range(0,1)` 保留为 Godot 原生调用。
> **3472**: Oil Can 物品符号洗牌 — 实测 patched 版本中已被替换为 `_bh_c_spin_shuffle(pool)`，使用 **spin RNG**。

---

### 2.2 Main.tscn__4.gd → `ReelRngRefSourceMod.cs` + `ReelShufflePatch.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 413 | `randomize()` | `# randomize() removed` + ReelShufflePatch | — | ✅ |
| 414 | `pool.shuffle()` | `_rrr_shuffle(pool)` | **reel** | ✅ |
| 438 | `empties.shuffle()` | `_rrr_shuffle(empties)` | **reel** | ✅ |
| 714 | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| 728 | `rand_range(0, visible_possibles.size())` | `_rrr_rand_range(...)` | **reel** | ✅ |
| 730 | `rand_range(0, possibles.size())` | `_rrr_rand_range(...)` | **reel** | ✅ |
| 738 | `rand_range(0, possibles.size())` | `_rrr_rand_range(...)` | **reel** | ✅ |
| 741 | `rand_range(0, possibles.size())` | `_rrr_rand_range(...)` | **reel** | ✅ |

> `ReelRngRefSourceMod` 用 regex 替换所有 `rand_range(` → `_rrr_rand_range(` 和所有 `*.shuffle()` → `_rrr_shuffle(*)`。`ReelShufflePatch` 额外处理 `shuffle_tiles()` 中的特定模式。

---

### 2.3 Reel.tscn__1.gd → `ReelExtraRngSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 616 | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| 617 | `arr[floor(rand_range(0, arr.size()))]` | `_rer_rand_range(...)` | **reel** | ✅ |
| 657 | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| 679 | `rand_range(0, visible_empties.size())` | `_rer_rand_range(...)` | **reel** | ✅ |
| 698 | `rand_range(0, empty_positions.size())` | `_rer_rand_range(...)` | **reel** | ✅ |
| 所有 `*.shuffle()` | regex 替换 | `_rer_shuffle(*)` | **reel** | ✅ |

---

### 2.4 Slot Icon.tscn__1.gd → `SlotIconRngSourceMod.cs`

此文件包含 50+ 个 RNG 调用点。SlotIconRngSourceMod 的分类策略：
- `rand_range(` → `_sir_rand_range(` → **effect RNG**
- `*.shuffle()` → `_sir_shuffle(*)` → **effect RNG**
- SFX 相关: `str(floor(rand_range(0, sfx_total_num)))` → `str(_scr_randi_max(sfx_total_num))` → **scratch RNG**
- Shake 动画: `floor(rand_range(-1, 2))` → `floor(_scr_rand_range(-1, 2))` → **scratch RNG**

| 行号 | 类型 | 消费流 | 状态 |
|------|------|--------|------|
| 745 | SFX 随机音效 | **scratch** | ✅ |
| 874 | shake 动画 offset (×2) | **scratch** | ✅ |
| 914 | `randomize()` | — | ✅ |
| 917 | 纹理随机选择 | **effect** | ✅ |
| 935 | `randomize()` | — | ✅ |
| 938 | 纹理随机选择 | **effect** | ✅ |
| 1709 | `randomize()` | — | ✅ |
| 1710 | `rand_range(minimum, maximum)` 值计算 | **effect** | ✅ |
| 1884 | `randomize()` | — | ✅ |
| 1885 | `rand_range(minimum, maximum)` 值计算 | **effect** | ✅ |
| 2205 | 从 destroyed_symbols 随机选 | **effect** | ✅ |
| 2212 | `randomize()` | — | ✅ |
| 2213 | `rand_range(0, 1)` 概率判断 | **effect** | ✅ |
| 2259 | 从 possible_symbols 随机选 | **effect** | ✅ |
| 2365 | `randomize()` | — | ✅ |
| 2367 | 从 item_pool 随机选物品 | **effect** | ✅ |
| 2372 | 从 rarity_database items 随机选 | **effect** | ✅ |
| 2741 | `randomize()` | — | ✅ |
| 2742 | `rand_range(0, 1)` 概率判断 | **effect** | ✅ |
| 2787 | 从 possible_symbols 随机选 | **effect** | ✅ |
| 2794 | 从 possible_symbols 随机选 | **effect** | ✅ |
| 3030 | `randomize()` | — | ✅ |
| 3031 | 从 arr 随机选 | **effect** | ✅ |
| 3035 | `randomize()` | — | ✅ |
| 3036 | 从 dir_arr 随机选方向 | **effect** | ✅ |
| 3350 | `randomize()` | — | ✅ |
| 3367 | `rand_range(0, 100)` 概率判定 | **effect** | ✅ |
| 3706 | `randomize()` | — | ✅ |
| 3715 | `rand_range(0, 100)` 概率判定 | **effect** | ✅ |
| 4744 | `randomize()` | — | ✅ |
| 4745 | `rand_range(values[0], values[1]+1)` d3/d5 骰子 | **effect** | ✅ |
| 4768 | `randomize()` | — | ✅ |
| 4769 | `rand_range(0, 100)` seed→fertilizer_essence | **effect** | ✅ |
| 4771 | `randomize()` | — | ✅ |
| 4772 | `rand_range(0, 100)` seed→rare plant | **effect** | ✅ |
| 4774 | `randomize()` | — | ✅ |
| 4775 | `rand_range(0, 100)` seed→uncommon plant | **effect** | ✅ |
| 4777 | `randomize()` | — | ✅ |
| 4778 | `rand_range(0, 100)` seed→any plant | **effect** | ✅ |
| 4857 | `randomize()` | — | ✅ |
| 4858 | `rand_range(0, 100)` bear→honey | **effect** | ✅ |
| 4925 | `randomize()` | — | ✅ |
| 4926 | `rand_range(0, 100)` spirit→spirit | **effect** | ✅ |
| 5026 | `randomize()` | — | ✅ |
| 5027 | `rand_range(0, 100)` chicken→egg | **effect** | ✅ |
| 5028 | `randomize()` | — | ✅ |
| 5029 | `rand_range(0, 100)` chicken→golden_egg | **effect** | ✅ |
| 5032 | `randomize()` | — | ✅ |
| 5033 | `rand_range(0, 100)` egg→chicken | **effect** | ✅ |
| 5037 | `randomize()` | — | ✅ |
| 5038 | `rand_range(0, 100)` egg→chick | **effect** | ✅ |
| 5096 | `randomize()` | — | ✅ |
| 5097 | `rand_range(0, 100)` 概率减去 value_bonus | **effect** | ✅ |
| 5110 | `randomize()` | — | ✅ |
| 5111 | 从 possible_icons 随机选要摧毁的 | **effect** | ✅ |
| 5113 | `randomize()` | — | ✅ |
| 5114 | `rand_range(0, 100)` 概率变换类型 | **effect** | ✅ |
| 5126 | `randomize()` | — | ✅ |
| 5127 | `rand_range(0, 100)` hex_of_emptiness | **effect** | ✅ |
| 5139 | `randomize()` | — | ✅ |
| 5140 | `rand_range(0, 100)` 啤酒→booze | **effect** | ✅ |
| 5221 | `randomize()` | — | ✅ |
| 5222 | `rand_range(0, 100)` golden egg | **effect** | ✅ |
| 5256 | `randomize()` | — | ✅ |
| 5257 | `possible_icons.shuffle()` | `_sir_shuffle(possible_icons)` | **effect** | ✅ |
| 5260 | `randomize()` | — | ✅ |
| 5261 | `rand_range(0, 100)` 吸干效果 | **effect** | ✅ |
| 5421 | `randomize()` | — | ✅ |
| 5422 | `rand_range(0, 100)` oyster→pearl | **effect** | ✅ |
| 5432 | `randomize()` | — | ✅ |
| 5433 | `rand_range(1, 9)` 方向 | **effect** | ✅ |
| 5437 | `randomize()` | — | ✅ |
| 5438 | `rand_range(0, 7)` 方向数组 | **effect** | ✅ |
| 5514 | `randomize()` | — | ✅ |
| 5515 | `rand_range(0, 100)` hex_of_hoarding | **effect** | ✅ |
| 5522 | `randomize()` | — | ✅ |
| 5523 | `rand_range(0, 100)` 产生 coin | **effect** | ✅ |
| 5525 | `randomize()` | — | ✅ |
| 5526 | `rand_range(0, 100)` cat→milk | **effect** | ✅ |
| 5737 | `randomize()` | — | ✅ |
| 5738 | 从 possible_icons 随机选要摧毁的 | **effect** | ✅ |
| 5740 | `randomize()` | — | ✅ |
| 5753 | `randomize()` | — | ✅ |
| 5754 | 从 possible_icons 随机选相邻符号 | **effect** | ✅ |
| 5756 | `randomize()` | — | ✅ |

> 📊 **Slot Icon 合计**: ~55 个 `randomize()` + ~55 个 `rand_range()` + 1 个 `.shuffle()` = **约 111 次 RNG 调用/每 spin**

---

### 2.5 Item.tscn__1.gd → `ItemRngSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 539 | `randomize()` | `# randomize() removed` | — | ✅ |
| 540 | `rand_range(minimum, maximum)` | `_itr_rand_range(...)` | **effect** | ✅ |
| 693 | `randomize()` | removed | — | ✅ |
| 694 | `rand_range(minimum, maximum)` | `_itr_rand_range(...)` | **effect** | ✅ |
| 966 | `rand_range(0, destroyed_symbols.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 968 | `randomize()` | removed | — | ✅ |
| 969 | `rand_range(0, 1)` | `_itr_rand_range(...)` | **effect** | ✅ |
| 1012 | `rand_range(0, possible_symbols.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 1045 | `randomize()` | removed | — | ✅ |
| 1047 | `rand_range(0, item_pool.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 2374 | `rand_range(0, destroyed_symbols.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 2376 | `randomize()` | removed | — | ✅ |
| 2378 | `rand_range(0, group_db.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 2397 | `randomize()` | removed | — | ✅ |
| 2399 | `rand_range(0, item_pool.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 2522 | `randomize()` | removed | — | ✅ |
| 2524 | `rand_range(0, group_db.size())` | `_itr_rand_range(...)` | **effect** | ✅ |
| 2698 | `randomize()` | removed | — | ✅ |
| 2700 | `rand_range(d3_min, d3_max)` d3 骰子 | `_itr_rand_range(...)` | **effect** | ✅ |
| 2701 | `randomize()` | removed | — | ✅ |
| 2703 | `rand_range(d5_min, d5_max)` d5 骰子 | `_itr_rand_range(...)` | **effect** | ✅ |
| 3128 | `randomize()` | removed | — | ✅ |
| 3129 | `rand_range(0, 100)` void→void_party | `_itr_rand_range(...)` | **effect** | ✅ |
| 3131 | `randomize()` | removed | — | ✅ |
| 3132 | `rand_range(0, 100)` box→mobius_strip | `_itr_rand_range(...)` | **effect** | ✅ |
| 所有 `*.shuffle()` | regex 替换 | `_itr_shuffle(*)` | **effect** | ✅ |

> 📊 **Item 合计**: ~11 个 `randomize()` + ~15 个 `rand_range()` + N `.shuffle()` = **~26+ 次 RNG 调用/每 spin**

---

### 2.6 Landlord.tscn__9.gd → `LandlordRngRefSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 154 | `rand_range(-1, 2)` shake X | `_lfr_rand_range(-1, 2)` | **fineprint** | ✅ |
| 155 | `rand_range(-1, 2)` shake Y | `_lfr_rand_range(-1, 2)` | **fineprint** | ✅ |
| 183 | `rand_range(0, 1) < 0.33` hit SFX | `_lfr_rand_range(0, 1)` | **fineprint** | ✅ |
| 185 | `rand_range(0, 1) < 0.66` hit SFX | `_lfr_rand_range(0, 1)` | **fineprint** | ✅ |
| 249 | `rand_range(0, fp_arr.size())` fine print 选择 | `_lfr_rand_range(...)` | **fineprint** | ✅ |
| 331 | `rand_range(0, possible_icons.size())` 动态图标 | `_lfr_rand_range(...)` | **fineprint** | ✅ |
| 358 | `rand_range(0, group_db.items[...].size())` | `_lfr_rand_range(...)` | **fineprint** | ✅ |
| 360 | `rand_range(0, group_db.symbols[...].size())` | `_lfr_rand_range(...)` | **fineprint** | ✅ |
| 所有 `*.shuffle()` | regex 替换 | `_lfr_shuffle(*)` | **fineprint** | ✅ |

---

### 2.7 Main.tscn__1.gd → `CosmeticRngSourceMod.cs` + `RngInfrastructureSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 865 | `rand_range(0, textures.size())` | `_bh_rng_cosmetic.pick(textures)` | **cosmetic** | ✅ |
| 1801 | `randomize()` | `# randomize() removed` (regex) | — | ✅ |
| 1802 | `if rand_range(0, 1) < 0.5:` | `if _bh_rng_cosmetic.randf() < 0.5:` | **cosmetic** | ✅ |
| (injected) | `_bh_init_rng()` / `_bh_begin_spin_rng()` 等 | (注入的 PCGRng 基础架构) | — | ✅ |

---

### 2.8 Music Player.tscn__1.gd → `CosmeticRngSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 73 | `randomize()` | `# randomize() removed` | — | ✅ |
| 74 | `rand_range(0, music_arr.size())` 随机音乐 | `_csr_rand_range(...)` | **cosmetic** | ✅ |

---

### 2.9 Options.tscn__1.gd → `CosmeticRngSourceMod.cs`

| 行号 | 原始调用 | Mod 替换后 | 消费流 | 状态 |
|------|---------|-----------|--------|------|
| 2725 | `randomize()` | `# randomize() removed` | — | ✅ |
| 2726 | `if rand_range(0, 1) < 0.5:` | `_csr_rand_range(...)` | **cosmetic** | ✅ |
| 2740 | `randomize()` | `# randomize() removed` | — | ✅ |
| 2741 | `if rand_range(0, 1) < 0.5:` | `_csr_rand_range(...)` | **cosmetic** | ✅ |

---

## 3. 🔴 未替换的调用点 (Godot 全局 RNG 泄漏)

| 文件 | 行号 | 调用 | 上下文 | 风险 |
|------|------|------|--------|------|
| Pop-up.tscn__1.gd | **2977** | `rand_range(0, 1)` | `start_bossfight()` Boss 战音乐二选一 | 🟡 低 (仅 cosmetic) |

> **2977 是唯一确认的未替换调用**：`start_bossfight()` 中的 `randomize()` 被 regex 移除，但后续 `rand_range(0, 1)` 因不在任何特定匹配模式中而保持为 Godot 原生调用。只影响 Boss 战斗音乐选择（Landlocked vs Mad for Money），不影响 gameplay。
>
> 虽然 `randomize()` 已移除，Godot 全局 RNG 在 `_bh_init_rng()` 时被 `seed(landlord_seed)` 初始化，所以理论上它也是确定的。但它与 PCGRng 流是**完全独立的轨道**。

---

## 4. 控制流图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         游戏启动 (Title → New Game)                       │
│                                                                         │
│  _bh_init_rng(seed_type, seed_input)                                    │
│  ├── FNV-1a(seed_input) → landlord_seed                                 │
│  ├── 创建 19 个 PCGRng 实例 (各用 djb2(landlord_seed, name) 派生)        │
│  └── seed(landlord_seed) → 捕获 Godot 全局 RNG                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         每 Spin 循环                                      │
│                                                                         │
│  SpinPatch.PrefixCode()                                                 │
│  ├── _bh_begin_spin_rng()                                               │
│  │   └── _bh_rng_spin.randi_max() ─── 消费 1 次 spin RNG                │
│  │       ├── djb2(val, "reel")   → _bh_rng_reel    (新建)               │
│  │       ├── djb2(val, "effect") → _bh_rng_effect  (新建)               │
│  │       └── djb2(val, "scratch")→ _bh_rng_scratch (新建)               │
│  │                                                                      │
│  ▼ spin() 执行                                                          │
│  │                                                                      │
│  ├── shuffle_tiles()                                                    │
│  │   ├── randomize() → removed                                          │
│  │   ├── pool.shuffle()    → _rrr_shuffle(pool)    → reel              │
│  │   └── empties.shuffle() → _rrr_shuffle(empties) → reel              │
│  │                                                                      │
│  ├── add_tile() / add_tba_symbols()                                     │
│  │   ├── rand_range() → _rrr_rand_range()  → reel (选 reel/空位)       │
│  │   └── rand_range() → _rer_rand_range()  → reel (Reel.tscn)          │
│  │                                                                      │
│  ├── add_effects() / check_effects() [每帧循环直到 stable]               │
│  │   ├── Slot Icon: ~55 rand_range() → _sir_rand_range() → effect      │
│  │   ├── Slot Icon: SFX/animation      → _scr_rand_range() → scratch   │
│  │   ├── Slot Icon: possible_icons.shuffle() → _sir_shuffle() → effect │
│  │   ├── Item:      ~15 rand_range()   → _itr_rand_range() → effect    │
│  │   └── Item:      N × .shuffle()     → _itr_shuffle()    → effect    │
│  │                                                                      │
│  ├── check_values() → 无 RNG 调用                                       │
│  │                                                                      │
│  ▼ spin 结束, 进入选择阶段                                              │
│  │                                                                      │
│  ├── Landlord 伤害/fine print                                           │
│  │   ├── take_damage(): ~4 rand_range() → _lfr_rand_range() → fineprint│
│  │   └── add_fine_print(): ~4 rand_range() → _lfr_rand_range()→fineprint│
│  │                                                                      │
│  ├── add_cards(f_rarities) [符号/物品三选一]                             │
│  │   ├── c=0:                                                           │
│  │   │   ├── randomize() → removed                                      │
│  │   │   ├── _bh_c_rarity_randf()           → rarity                   │
│  │   │   ├── [forced] _bh_c_rarity_shuffle() → rarity (custom_shuffle)  │
│  │   │   ├── randomize() → removed                                      │
│  │   │   └── _bh_c_pick_symbol(rarity, pool) → sym_common/unc/rare/vrare│
│  │   ├── c=1:                                                           │
│  │   │   ├── _bh_c_rarity_randf()           → rarity                   │
│  │   │   └── _bh_c_pick_symbol(rarity, pool) → sym_*                   │
│  │   ├── c=2:                                                           │
│  │   │   ├── _bh_c_rarity_randf()           → rarity                   │
│  │   │   └── _bh_c_pick_symbol(rarity, pool) → sym_*                   │
│  │   └── 池副作用: card_pool[rarity].erase(picked) — 影响同批后续索引   │
│  │                                                                      │
│  ├── resolve_event(choice) [玩家选择后]                                  │
│  │   ├── Oil Can prompt:                                                │
│  │   │   ├── randomize() → removed                                      │
│  │   │   └── pool.shuffle() → _bh_c_spin_shuffle(pool) → spin          │
│  │   └── Boss Fight:                                                   │
│  │       └── rand_range(0,1) → 🔴 未替换 → Godot 全局 RNG               │
│  │                                                                      │
│  ├── Pop-up 内的其他 RNG:                                               │
│  │   ├── 命运数字: _bh_c_cosmetic_pick()  → cosmetic                    │
│  │   ├── Tips:     _bh_c_cosmetic_pick()  → cosmetic                    │
│  │   ├── Boss 音乐:_bh_c_cosmetic_randf() → cosmetic                    │
│  │   └── Deck pool.shuffle() → _bh_c_spin_shuffle() → spin             │
│  │                                                                      │
│  ▼ 回到 spin() ──────────────────────────────────────────────────────→  │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      Cosmetic / 非 Spin 路径                              │
│                                                                         │
│  Music Player: rand_range() → _csr_rand_range() → cosmetic              │
│  Options:      rand_range() → _csr_rand_range() → cosmetic              │
│  Title Screen: rand_range() → _bh_rng_cosmetic.pick() → cosmetic       │
│  Boss Fight 音乐: 🔴 rand_range(0,1) → Godot 全局 RNG                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. 各流消费次数汇总 (典型 1 spin + 1 次三选一)

| RNG 流 | 每 Spin 消费次数 (近似) | 主要消费来源 |
|--------|----------------------|-------------|
| **spin** | 1 (`_bh_begin_spin_rng`) + 0~2 (popup deck shuffle) | `_bh_begin_spin_rng`, `_bh_c_spin_shuffle` |
| **rarity** | 3 (三选一) + 0~2 (forced shuffle) | `_bh_c_rarity_randf`, `_bh_c_rarity_shuffle` |
| **sym_common** | 0~3 | `_bh_c_pick_symbol("common", ...)` |
| **sym_uncommon** | 0~3 | `_bh_c_pick_symbol("uncommon", ...)` |
| **sym_rare** | 0~3 | `_bh_c_pick_symbol("rare", ...)` |
| **sym_vrare** | 0~3 | `_bh_c_pick_symbol("very_rare", ...)` |
| **itm_common** | 0~3 (物品选择时) | `_bh_c_pick_item(...)` |
| **itm_uncommon** | 0~3 | `_bh_c_pick_item(...)` |
| **itm_rare** | 0~3 | `_bh_c_pick_item(...)` |
| **itm_vrare** | 0~3 | `_bh_c_pick_item(...)` |
| **ess_*** | 0 | (精华路径未追踪到此文档) |
| **reel** | ~10-20 | shuffle_tiles, add_tile, Reel.tscn |
| **effect** | ~70-90 | Slot Icon (~55) + Item (~15) + shuffle |
| **scratch** | ~2-5 | SFX, shake 动画 |
| **fineprint** | ~8-15 | Landlord take_damage, add_fine_print |
| **cosmetic** | 0~5 | 音乐, Tips, 命运, Boss 音乐 |
| **Godot 全局** | 🔴 0~1 (Boss 音乐) | 未替换调用 |

---

## 6. 关键发现

### 6.1 符号流"序列"被打乱的根本原因

RNG 流消费是确定的，但 `add_cards()` 中 `_bh_c_pick_symbol()` 返回的是**数组索引**，不是固定序列的下一个元素。同一批 3 张卡中，已选符号被 `erase()` 后：

```
卡1: sym_rare.randi_max(N)   → index=V1 → pool[V1]=X  → erase(X) → pool size=N-1
卡3: sym_rare.randi_max(N-1) → index=V2 → pool'[V2]=Y  (pool' ≠ pool)
```

相同种子下 V1、V2 是确定的，但 pool' 的内容取决于 X 是哪个符号（erase 移除不同位置的元素，剩余元素索引位移不同）。**RNG 值相同，池不同 → 结果不同。**

### 6.2 跨批次累积发散

同批内选了不同符号 → 进入游戏盘面的符号不同 → `can_add_highlander()` / `essences_unlocked` 状态不同 → 下次 `add_cards()` 池构造时 `erase("highlander")` / `erase("essence_capsule")` 不同 → 初始池就不同 → 累积发散。

### 6.3 未替换调用

- **Pop-up:2977** (Boss 音乐) — 唯一确认的泄漏，使用 Godot 全局 RNG，仅影响 Boss 战音乐选择，不影响 gameplay
- Oil Can 的 `pool.shuffle()` (Pop-up:3472) — 实测 patched 版本中已被正确替换为 `_bh_c_spin_shuffle(pool)` → spin RNG

### 6.4 Spin RNG 多重消费

`_bh_rng_spin` 在三个地方被消费：
1. `_bh_begin_spin_rng()`: 每次 spin 开始时 `randi_max()` 派生 reel/effect/scratch
2. `_bh_c_spin_shuffle()`: Pop-up deck 中的 `.shuffle()` 调用
3. `_bh_c_spin_shuffle()`: Oil Can 物品触发时的符号洗牌

这意味着 **spin RNG 的消费次数取决于运行时状态**（deck 模式是否触发、是否有 Oil Can 物品）。
