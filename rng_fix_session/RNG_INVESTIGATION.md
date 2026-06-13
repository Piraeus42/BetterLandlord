# BetterLandlord Mod RNG 只读调查报告

> 日期：2026-06-14 | 分支：master | 调查范围：只读，不修改任何代码

---

## 1. 种子与播种

### 1.1 种子生成代码

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:106-115`

```gdscript
const _BH_SEED_CHARS = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'

func _bh_generate_random_seed() -> String:
    # Use OS entropy (not Godot global randi — seed() captures it to landlord_seed,
    # making randi() deterministic within a session)
    var _entropy = OS.get_unix_time() + OS.get_ticks_msec()
    var _h = _bh_fnv1a(str(_entropy))
    var result: String = ''
    for _i in range(10):
        _h = ((_h * 1103515245) + 12345) & 0x7FFFFFFF
        result += _BH_SEED_CHARS[_h % 34]
    return result
```

**种子来源：** `OS.get_unix_time()` + `OS.get_ticks_msec()` — 时间戳（秒+毫秒），拼接成字符串后经 FNV-1a 哈希，再用 Glibc LCG（`h * 1103515245 + 12345`）迭代 10 次产生 10 个字符（34 字符字母表，排除 I/O）。

**熵量：** Unix时间戳约 31 bit + 毫秒约 10 bit ≈ 约 41 bit 原始熵，经 FNV-1a 压缩到 31 bit，再分散到 10 字符。

**相邻两局的种子：** 随机模式下，每局调用 `OS.get_unix_time() + OS.get_ticks_msec()`，取决于调用间隔。用户也可以输入自定义 10 字符种子。

### 1.2 种子哈希/派生链

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:89-101`

```gdscript
# FNV-1a: any string → 31-bit positive int (deterministic, cross-platform)
func _bh_fnv1a(text: String) -> int:
    var h: int = 2166136261
    for c in text:
        h = (h ^ ord(c)) & MASK_63
        h = (h * 16777619) & MASK_63
    return h & MASK_31

# djb2: int + string → 31-bit positive int (seed derivation)
func _bh_derive_seed(base: int, name: String) -> int:
    var h: int = base & MASK_63
    for c in name:
        h = (((h << 5) + h) ^ ord(c)) & MASK_63
    return h & MASK_31
```

种子层级：
```
10-char seed string → FNV-1a → landlord_seed (31-bit)
                              ├── djb2(name='sym_rarity')    → PCGRng 实例1
                              ├── djb2(name='sym_common')    → PCGRng 实例2
                              ├── ... (共11个持久实例)
                              └── djb2(name='spin_N')        → spin_val (每局)
                                   ├── djb2(name='reel')     → PCGRng 实例N
                                   └── djb2(name='effect')   → PCGRng 实例M
```

### 1.3 播种/重播调用位置（粒度：每局）

**唯一播种点：**

| 位置 | 何时调用 | 作用 |
|---|---|---|
| `RngInfrastructureSourceMod.cs:209` | `_bh_init_rng()` 内，新游戏开始时 | `seed(landlord_seed)` — 同步 Godot 全局 RNG |
| `RngInfrastructureSourceMod.cs:370` | `_bh_restore_rng_state()` 内，继续游戏时 | `seed(_bh_rng_landlord_seed)` — 恢复时同步 |

**调用链：**
1. `TitleSetFloorPatch.cs:29` → `_bh_apply_seed()` → `_bh_init_rng(str(cfg['type']), str(cfg['input']))`
2. `ContinueGamePatch.cs` → `_bh_restore_rng_state()`

**粒度：每个运行会话一次**（`new_game()` 或 `continue_game()` 时），而非每次抽取/每回合。

模组注释掉了原游戏中所有约 63 处 `randomize()` 调用。原游戏在几乎每次 `rand_range()` 前都重新播种（系统熵），模组全部停用。

**相邻两局的种子：** "随机"模式下时间戳相隔通常很短（秒级），但由于种子字符串先经过 `OS.get_unix_time() + OS.get_ticks_msec()` → FNV-1a → LCG 10 字符输出，相邻时间戳产生完全不同的 10 字符字符串。用户也可以指定固定种子实现重放。

---

## 2. PRNG 算法本身

### 2.1 核心实现

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:26-55`

```gdscript
const PCG_DEFAULT_INC: int = 1442695040888963407
const PCG_MULT: int = 6364136223846793005
const MASK_63: int = 0x7FFFFFFFFFFFFFFF  # max positive signed 64-bit
const MASK_31: int = 0x7FFFFFFF

class PCGRng:
    var state: int  # kept in [0, 2^63) — always non-negative
    var inc: int    # stream id

    func _init(seed_val: int):
        state = seed_val
        inc = (PCG_DEFAULT_INC << 1) | 1
        _step()
        state = (state + PCG_MULT) & MASK_63
        _step()
        _step()

    func _step():
        var old: int = state
        state = ((old * PCG_MULT) + inc) & MASK_63
        return old

    # Returns float in [0, 1)
    func randf() -> float:
        var old: int = _step()
        var x: int = (old >> 18) ^ old
        x = x >> 27
        var rot: int = old >> 59        # PCG32 standard: top 6 bits for rotation
        var result: int = ((x >> rot) | (x << ((-rot) & 31))) & MASK_31
        return float(result) / 2147483648.0
```

**算法类型：** PCG XSH RR（Permuted Congruential Generator, XorShift High / Random Rotation）— PCG 家族的正式成员。

**基 LCG：** 64-bit 状态，乘数 `6364136223846793005`，增量 `1442695040888963407 << 1 | 1`（奇数强制位），模 `2^63`（正有符号 64-bit）。

**输出变换：** 取 old 状态的 high bits → xorshift → 取高 5 bits 作为 rotation amount → 右旋转 32-bit 值 → 掩码到 31-bit → 除以 `2^31`。

### 2.2 randf() 返回值和范围

```gdscript
return float(result) / 2147483648.0
```

- **返回类型：** `float`
- **值域：** `[0.0, 1.0)` — 含 0，不含 1
- **离散值数量：** `2^31 = 2,147,483,648` 种可能值（31-bit 输出）
- **分母：** `2147483648.0 = 2^31`

### 2.3 rand_range() 和 randi_max()

```gdscript
# Returns float in [min_val, max_val)
func rand_range(min_val: float, max_val: float) -> float:
    return min_val + self.randf() * (max_val - min_val)

# Returns int in [0, max_val)
func randi_max(max_val: int) -> int:
    return int(floor(self.randf() * float(max_val)))
```

---

## 3. 原始接口 vs 模组接口对比

### 3.1 原版 Godot 3 的 RNG 接口

原始游戏使用 Godot 3 内置全局函数：

| 函数 | 返回类型 | 值域 | 说明 |
|------|----------|------|------|
| `randomize()` | void | — | 从系统熵重新播种全局 RNG |
| `rand_range(from, to)` | `float` | `[from, to)` | to 不含 |
| `randi()` | `int` | 无符号 32-bit 范围 | **原游戏中未使用** |
| `randf()` | `float` | `[0.0, 1.0)` | **原游戏中未直接使用** |
| `arr.shuffle()` | void | — | Godot 内置 Fisher-Yates |

Godot 3 底层使用 **PCG32**（C++ 实现，32-bit 输出），和模组的 PCG 算法是同一家族。原游戏调用 `randomize()` 约 ~63 次（每次抽取前重新播种），随机性来自系统时间。

### 3.2 模组的返回类型/范围对比

| 接口 | 原版 Godot 3 | 模组 PCGRng | 是否一致 |
|------|-------------|------------|----------|
| `rand_range(a, b)` | `float` in `[a, b)` | `float` in `[a, b)` | ✅ 一致 |
| `randf()` | `float` in `[0, 1)` | `float` in `[0, 1)` | ✅ 一致 |
| `.shuffle()` | Fisher-Yates, Godot 全局 RNG | Fisher-Yates, PCGRng 实例 | ✅ 算法一致 |

### 3.3 不一致项清单

| 项目 | 原版 | 模组 | 位置 |
|------|------|------|------|
| **randf() 精度** | 32-bit 输出 / 2^32 分母 | 31-bit 输出 (MASK_31) / 2^31 分母 | `RngInfrastructureSourceMod.cs:55` |
| **播种时机** | 每次 `rand_range()` 前 `randomize()` (~63处) | 每局一次 `_bh_init_rng()` | 所有 SourceMod |
| **RNG 实例数** | 1 个全局 RNG | 14 个持久 + 5 个 per-spin + 5 个 ephemeral = 最多 24 个独立实例 | `RngInfrastructureSourceMod.cs:121-155` |
| **确定性** | 否（系统熵） | 是（种子派生） | — |
| **`randi()` 处理** | 原游戏不使用 | 模组不支持; 用 `randi_max(n)` 替代 | — |

---

## 4. 值到游戏区间的映射

### 4.1 模组映射点

#### 4.1.1 PCGRng.randi_max() — 取整映射

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:58-59`

```gdscript
func randi_max(max_val: int) -> int:
    return int(floor(self.randf() * float(max_val)))
```

- 映射方式：`randf()` 的 float `[0, 1)` 乘以 `max_val`，再 `floor` 取整
- 目标范围：`[0, max_val-1]`
- **取模偏置存在：** 源范围 `2^31 = 2,147,483,648`，当 `max_val` 不能整除 `2^31` 时有偏置
- **无拒绝采样**

被以下位置调用：
- `pick(arr)` (`RngInfrastructureSourceMod.cs:69`)
- `_bh_c_pick_symbol()` (`ChoiceRngPatch.cs:62`)
- 所有 `_*_randi_max(n)` 包装器（`SlotIconRngSourceMod.cs:46,56`、`ReelRngRefSourceMod.cs:28` 等）

#### 4.1.2 PCGRng.custom_shuffle() — Fisher-Yates 索引

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:72-78`

```gdscript
func custom_shuffle(arr: Array):
    var n: int = arr.size()
    for i in range(n - 1, 0, -1):
        var j: int = int(floor(self.randf() * float(i + 1)))
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
```

- 交换索引 j 的范围：`[0, i]`（含两端）
- 映射方式：`int(floor(randf() * (i+1)))`
- **取模偏置存在：** 每个 i 的目标宽度 `i+1` 不一定整除 `2^31`，且随 i 递减而变化
- **无拒绝采样**

#### 4.1.3 原版 rand_range 替换

原版 `floor(rand_range(0, arr.size()))`（约 35 处）被替换为模组的 `randi_max()` 或 `pick()`。两者使用相同的 `floor(randf() * N)` 映射。
不同在于：原版的 `randf()` 分母是 2^32，模组的是 2^31。

#### 4.1.4 概率值检查

```gdscript
# 原版: if rand_range(0, 1) < r_chances.very_rare:
# 模组: if rand_num < r_chances.very_rare:
# 其中 rand_num = _bh_c_rarity_randf() 返回 float [0, 1)
```

**文件：** `game_source_code/Pop-up.tscn__1.gd:1373-1380`（原版）、`ChoiceRngPatch.cs:219`（替换点）

浮点比较，无取模偏置。但 `2^31` vs `2^32` 精度差别意味着阈值边界可能有 1 个离散值的差异。

#### 4.1.5 百分比检查 `rand_range(0, 100)`

原版约 20 处使用 `rand_range(0, 100) < value` 做百分比概率。模组替换为 `_bh_rng_effect.randf() * 100.0 < value` 或 `_bh_rng_effect.rand_range(0, 100)`。

- 映射方式：`randf() * 100` 产生 `[0, 100)` 的 float，与阈值比较
- **取模偏置存在：** 分母 `2^31` 不能整除 100
- **无拒绝采样**

#### 4.1.6 随机种子生成符 `_h % 34`

**文件：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:114`

```gdscript
result += _BH_SEED_CHARS[_h % 34]
```

- 源范围：31-bit LCG 输出
- 目标范围：`[0, 33]`（34 字符字母表）
- **取模偏置存在：** `2^31 / 34 ≈ 63161283.76`，不整除
- **无拒绝采样**

#### 4.1.7 Fallback 选取 `idx % pool.size()`

**文件：** `Piraeus.BetterLandlord/Patches/ChoiceRngPatch.cs:128`

```gdscript
return pool[((idx % pool.size()) + pool.size()) % pool.size()]
```

- idx 是 31-bit djb2 哈希值
- GDScript 安全正取模（`%` 可能返回负值）
- **取模偏置存在：** 当 `pool.size()` 不能整除 `2^31` 时
- **无拒绝采样**

### 4.2 取模偏置汇总

| 位置 | 源范围 | 目标范围 | 有无拒绝采样 |
|------|--------|----------|------------|
| `RngInfrastructureSourceMod.cs:59` → `randi_max(N)` | `2^31` | `[0, N-1]` | 无 |
| `RngInfrastructureSourceMod.cs:75` → `custom_shuffle` 内 `randf()* (i+1)` | `2^31` | `[0, i]` | 无 |
| `RngInfrastructureSourceMod.cs:114` → `_h % 34` | `2^31` | `[0, 33]` | 无 |
| `ChoiceRngPatch.cs:128` → `idx % pool.size()` | `2^31` (djb2) | `[0, pool.size()-1]` | 无 |
| `ChoiceRngPatch.cs:170` → 同上 (essence) | `2^31` (djb2) | `[0, pool.size()-1]` | 无 |

**原版 Godot 同样存在取模偏置**（2^32 分母，同样无拒绝采样），只是精度差一倍。

---

## 5. 随机流的拆分情况

### 5.1 原游戏的 RNG 消费点

原游戏只有一个全局 RNG。每次 `randomize()` 重新播种后再 `rand_range()`。所有消费点共享同一条全局 RNG 流，按调用时间顺序交替取值。消费点包括：

- **符号选择** (add_tile)：稀有度决定 + 符号从池中选取（`Pop-up.tscn__1.gd:1346-1406`）
- **物品选择** (add_item)：稀有度决定 + 物品选取（`Pop-up.tscn__1.gd:1410-1427`）
- **卷轴洗牌** (shuffle_tiles)：卷轴上的符号顺序（`Main.tscn__4.gd:413-438`）
- **卷轴放置** (add_tile)：新符号放到哪个卷轴位置（`Main.tscn__4.gd:714-741`）
- **符号效果**：约 50+ 处概率检查/类型转换/取值（`Slot Icon.tscn__1.gd`）
- **物品效果**：约 20+ 处（`Item.tscn__1.gd`）
- **地主细则**：细则选取、图标、文本（`Landlord.tscn__9.gd:183-360`）
- **装饰性**：音乐、纹理、提示、抖动（3 个文件）
- **卷轴实例**：空位选取（`Reel.tscn__1.gd:617-698`）

### 5.2 模组的 RNG 流架构

模组将所有 RNG 消费点拆分到 **19 个独立 PCGRng 实例**：

**持久流（跨局存活，`_bh_init_rng()` 创建）：**

| 变量 | 种子维度 | 服务对象 |
|------|----------|----------|
| `_bh_rng_sym_rarity` | `djb2(seed, 'sym_rarity')` | 符号稀有度骰（add_tile 路径） |
| `_bh_rng_sym_common` | `djb2(seed, 'sym_common')` | 普通符号池选取 |
| `_bh_rng_sym_uncommon` | `djb2(seed, 'sym_uncommon')` | 非普通符号池选取 |
| `_bh_rng_sym_rare` | `djb2(seed, 'sym_rare')` | 稀有符号池选取 |
| `_bh_rng_sym_vrare` | `djb2(seed, 'sym_vrare')` | 极稀有符号池选取 |
| `_bh_rng_fineprint` | `djb2(seed, 'fineprint')` | 地主细则/命运 |
| `_bh_rng_cosmetic` | `djb2(seed, 'cosmetic')` | 装饰（音乐/纹理/提示/50/50） |
| `_bh_rng_forced_rarity` | `djb2(seed, 'forced_rarity')` | 强制稀有度数组洗牌 |
| `_bh_rng_scratch` | `djb2(seed, 'scratch')` | 装饰动画（SFX/抖动） |
| `_bh_rng_reel` (初始) | `djb2(seed, 'reel_init')` | 占位（每局被覆盖） |
| `_bh_rng_effect` (初始) | `djb2(seed, 'effect_init')` | 占位（每局被覆盖） |

**每局流（每局 `_bh_begin_spin_rng()` 重新创建）：**

| 变量 | 种子维度 | 服务对象 |
|------|----------|----------|
| `_bh_rng_reel` | `djb2(spin_val, 'reel')` | 卷轴符号位置 |
| `_bh_rng_reel_shuffle` | `djb2(spin_val, 'reel_shuffle')` | 卷轴池洗牌 |
| `_bh_rng_effect` | `djb2(spin_val, 'effect')` | 符号/物品效果RNG |
| `_bh_rng_effect_shuffle` | `djb2(spin_val, 'effect_shuffle')` | 效果数组洗牌 |
| `_bh_rng_oil_can` | `djb2(spin_val, 'oil_can')` | Oil Can 道具 |

**临时流（按需创建，用完即弃）：**

| 种子模式 | 用途 |
|----------|------|
| `itemseq_{rarity}_{round}_{event}` | 物品序列洗牌 |
| `essenceseq_{round}_{event}` | 精华序列洗牌 |
| `itmrarity_{round}_{counter}` | 每卡稀有度骰 |
| `itemfb_{rarity}_{event}_{cursor}` | 物品 Fallback |
| `essfb_{event}_{cursor}` | 精华 Fallback |

### 5.3 关键发现

1. **玩家和对手 RNG 是分开的流：** 玩家的符号/物品选取走 `_bh_rng_sym_*` / `_bh_item_seq`，对手（地主）的细则走 `_bh_rng_fineprint`。两者从同一个 `landlord_seed` 派生，但使用不同的 djb2 name string，各自独立推进。

2. **物品稀有度骰与物品选取使用完全不同且独立的种子：**
   - 稀有度骰：`itmrarity_{round}_{counter}` — 每个卡位有独立的临时 PCGRng
   - 物品选取：`itemseq_{rarity}_{round}_{event}` — 每事件每稀有度一个独立洗牌序列
   - 原版两者共享同一条全局 RNG 流的连续输出（但中间有 `randomize()` 隔开）

3. **装饰性 RNG 与游戏性 RNG 完全隔离：** 屏幕抖动/音效用 `_bh_rng_scratch`，不影响任何游戏性结果。

4. **精华流与物品流完全解耦：** 精华用 `_bh_essence_seq` / `_bh_essence_cursor` / `_bh_essence_pick_event`，物品用 `_bh_item_*`，互不触碰。

5. **所有流的种子都追溯到同一个 `landlord_seed`：** 给定同一个种子字符串，整局游戏完全确定。

---

## 6. 洗牌与发牌

### 6.1 洗牌算法

**模组 Fisher-Yates：** `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs:72-78`

```gdscript
func custom_shuffle(arr: Array):
    var n: int = arr.size()
    for i in range(n - 1, 0, -1):
        var j: int = int(floor(self.randf() * float(i + 1)))
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
```

- 标准 Durstenfeld 变种（从末尾向前迭代）
- j 范围：`[0, i]`，通过 `int(floor(randf() * (i+1)))` 得到
- 由模组完全重写的——原版使用 Godot 内置 `Array.shuffle()`
- 非均匀偏置：j 的计算使用 `2^31` 精度，理论上有取模偏置（与第 4 节相同分析）

**原版 `shuffle_tiles()` 中的洗牌：** `game_source_code/Main.tscn__4.gd:388-446`

```gdscript
randomize()
pool.shuffle()       # 原版 → 模组替换为 _rrr_shuffle(pool)
...
empties.shuffle()    # 原版 → 模组替换为 _rrr_shuffle(empties)
```

### 6.2 取随机索引的代码

Fisher-Yates 中取 j 的代码：

```gdscript
var j: int = int(floor(self.randf() * float(i + 1)))
```

- `randf()` 返回 `[0, 1)`，乘以 `i+1` 得 `[0, i+1)`，floor 后得 `[0, i]`
- 对于 i = n-1（第一次迭代）：`[0, n-1]` ✅
- 对于 i = 0（最后一次迭代）：`randf() * 1` → `[0, 1)` → floor = `0` ✅

### 6.3 起手发牌的代码路径

起手发牌走 `add_cards()` 函数（`game_source_code/Pop-up.tscn__1.gd:1223-1465`）：

1. 第一回合 `times_rent_paid == 0`，`rarity_chances` 全为 0
2. `add_event("add_tile", {"forced_rarity": []})` — 空强制稀有度
3. 进入 `add_cards()` → 模组注入 `_bh_begin_item_pick_event()` 在循环之前
4. 因为 `forced_rarity` 为空且 `chances` 全为 0，稀有度全部 fall through 到 `"common"`
5. 符号从 `card_pool["common"]` 中由 `_bh_c_pick_symbol()` 选取
6. 这些符号选取消耗 `_bh_rng_sym_common` 流的前几个输出

**种子流消耗顺序：**
- 起手符号稀有度骰：消耗 `_bh_rng_sym_rarity`
- 起手符号选取：消耗 `_bh_rng_sym_common`
- 起手物品（第一回合后的 add_item）：触发 `_bh_item_rarity_randf()`（独立临时RNG）+ `_bh_c_pick_item()`（预洗牌序列的 cursor 推进）

### 6.4 skip-owned 机制

**文件：** `Piraeus.BetterLandlord/Patches/ChoiceRngPatch.cs:70-109`

```gdscript
func _bh_c_pick_item(rarity, pool):
    # ... 过滤已拥有/最近销毁的物品 ...
    if _main._bh_item_seq.has(rarity):
        var seq = _main._bh_item_seq[rarity]
        var n = seq.size()
        if n > 0:
            var i = _main._bh_item_cursor.get(rarity, 0)
            while i < n:
                var cand = seq[i]
                i += 1
                if _filtered.has(cand):
                    _main._bh_item_cursor[rarity] = i
                    return cand
            _main._bh_item_cursor[rarity] = n
    var fb = _bh_item_fallback(rarity, pool)
    return fb
```

- 在同一事件内 cursor 单调前进
- 事件边界（每次 `add_cards` 调用）重建序列并重置 cursor
- 当玩家拥有某稀有度的所有物品时：**序列耗尽，进入 Fallback**
- Fallback 代码（`ChoiceRngPatch.cs:115-129`）：用 `(landlord_seed, 'itemfb_{rarity}_{event}_{cursor}')` 的 djb2 哈希做确定性选取

---

## 7. 调度 / 调控机制

### 7.1 无 Pity Timer / 保底

**搜索范围：** 所有 `.gd` 和 `.cs` 文件
**结论：** 代码库中**不存在**任何形式的：
- 连败补偿 / 保底（pity timer）
- 坏运气保护（bad luck protection）
- 起手重抽（mulligan / redraw logic tied to outcome quality）
- 基于连续失败/成功次数的概率调整

### 7.2 难度缩放（rarity_chances）

**文件：** `game_source_code/Main.tscn__1.gd:2945-2959`、`game_source_code/Pop-up.tscn__1.gd:2768-2821`

游戏有基于租金支付次数（`times_rent_paid`）的稀有度概率梯度：

| 租金次数 | 符号 Uncommon | 符号 Rare | 符号 Very Rare | 物品 Uncommon | 物品 Rare | 物品 Very Rare |
|---------|-------------|----------|---------------|-------------|---------|--------------|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1 | 0.10 | 0 | 0 | 0 | 0 | 0 |
| 2 | 0.20 | 0.01 | 0 | 0.10 | 0 | 0 |
| 3 | 0.25 | 0.01 | 0 | 0.20 | 0.025 | 0 |
| 4 | 0.29 | 0.015 | 0.005 | 0.25 | 0.025 | 0 |
| 5 | 0.30 | 0.015 | 0.005 | 0.30 | 0.0375 | 0.0125 |
| 6+ | 0.30 | 0.015 | 0.005 | 0.375 | 0.05 | 0.015 |

这是**纯进度驱动**的难度设计。模组完整保留此逻辑——`rand_num` 的阈值比较行为不变。

### 7.3 forced_rarity 机制（预定稀有度）

**文件：** `game_source_code/Pop-up.tscn__1.gd:1349-1385`

物品/事件可以携带 `extra_values.forced_rarity` 来覆盖随机稀有度选择。这不是 pity 系统，而是预定的游戏机制（如 booster pack 给 3 张 common）。

模组完整保留此机制：
- `ChoiceRngPatch.cs:28-31` — 对于 essence-forced 邮件，`_bh_c_rarity_randf()` 直接返回 0.0，不消耗 RNG
- `ChoiceRngPatch.cs:40-49` — `_bh_c_rarity_shuffle()` 使用 `_bh_rng_forced_rarity` 洗牌；essence 数组 `['essence','essence','essence']` 直接 no-op
- `RngInfrastructureSourceMod.cs:455-459` — `_bh_begin_item_pick_event()` 将 essence-forced 邮件路由到精华流

### 7.4 Comfy Pillow（消耗品保底，非 Pity）

**文件：** `game_source_code/Pop-up.tscn__1.gd:1261-1271,3504-3512`

Comfy Pillow 是一个消耗型道具，玩家主动使用后将 `forced_rarity` 设为 `["rare", ...]`。这是玩家驱动的保底，不依赖随机结果历史。模组完整保留。

### 7.5 Reroll Token（玩家主动重抽）

**文件：** `game_source_code/Pop-up.tscn__1.gd:1127-1128`

Reroll Token 是玩家主动消耗道具来重新生成卡片。模组保留行为（`ResolveEventPatch.cs:40-41` 记录为 pass-through）。

### 7.6 可能的隐性调度

**rarity_bonuses：** `game_source_code/Pop-up.tscn__1.gd:1460` — 物品效果可修改稀有度概率乘数。这是通过随机获取物品间接依赖 RNG 的。模组保留。

**hex_of_emptiness_trigger：** 触发后阻止符号选择。依赖 RNG 的比较（`rand_range(0, 100) < value`）。模组改用 `_bh_rng_effect`，分布形状不变。

### 7.7 结论

会影响 RNG 分布变化的机制：仅 `rarity_chances` 和 `rarity_bonuses` 涉及将 `randf()` 与浮点阈值比较。因为模组的 `randf()` 分布形状（均匀 [0, 1)）与原版一致，这些检查的行为不变。

---

## 8. 清单式总结

以下是所有发现的"模组的 RNG 行为与原版不一致"或"映射可能有偏"的具体位置：

### A. 精确度和范围差异

| # | 问题 | 文件:行号 |
|---|------|----------|
| A1 | randf() 使用 31-bit 输出 (MASK_31)，分母 `2^31`，非 Godot 的 32-bit 精度 | `RngInfrastructureSourceMod.cs:55` |
| A2 | 原版所有 `randomize()` 被注释掉（~63 处），播种粒度从"每次抽取前"变为"每局一次" | 所有 `*SourceMod.cs` 文件 |
| A3 | 原版 `card_pool[rand_range(0, card_pool.size())]`（无 floor，GDScript 自动 floor）替换为 `_bh_c_pick_item()`（skip-owned shuffle 序列） | `ChoiceRngPatch.cs:225` → 原版 `Pop-up.tscn__1.gd:1427` |
| A4 | 原版 `landlord_fates_data[floor(rand_range(0, X - 1))]` 替换为 `_bh_c_cosmetic_pick()`（修了原版 off-by-one bug，`-1` 排除了最后一个元素） | `ChoiceRngPatch.cs:224` → 原版 `Pop-up.tscn__1.gd:993` |

### B. 多消费者共用一条流的原始情况被拆散

| # | 问题 | 文件:行号 |
|---|------|----------|
| B1 | 原版：`rand_range(0, 1)` 稀有度骰和 `card_pool[rand_range(0, N)]` 物品选取共享同一条全局 RNG 流。模组：稀有度骰用独立临时 PCGRng (`itmrarity_{round}_{counter}`)，物品选取用预洗牌序列 (`itemseq_{rarity}_{round}_{event}`) | `RngInfrastructureSourceMod.cs:485-491` vs `433-441` |
| B2 | 原版：`randomize()` 在稀有度骰（行 1346）和物品选取（行 1386）之间重播 → 两者不共享 RNG 状态。模组：两者同样独立 | `game_source_code/Pop-up.tscn__1.gd:1346,1386` |
| B3 | 符号效果 RNG（~50 处）和物品效果 RNG（~20 处）原版共享全局 RNG；模组拆分：效果概率走 `_bh_rng_effect`，效果洗牌走 `_bh_rng_effect_shuffle`，卷轴效果走 `_bh_rng_reel` | 多个 SourceMod |
| B4 | 符号稀有度骰：add_tile 路径用 `_bh_rng_sym_rarity`（持久流），add_item 路径用 `_bh_item_rarity_randf()`（临时流）。原版两者共享同一全局流 | `ChoiceRngPatch.cs:21-38` |
| B5 | 原版 19 个不同的 GameScene 文件中所有 `rand_range()` 都共用一个全局 RNG。模组将不同场景路由到不同 PCGRng 实例 | 所有 SourceMod 文件 |

### C. 取模偏置（modulo bias）位置

| # | 问题 | 文件:行号 |
|---|------|----------|
| C1 | `randi_max(N)` = `int(floor(randf() * N))`，无拒绝采样，N 不整除 `2^31` 时有偏置 | `RngInfrastructureSourceMod.cs:59` |
| C2 | `custom_shuffle` 内 `int(floor(randf() * (i+1)))`，每个 i 的目标范围不同，无拒绝采样 | `RngInfrastructureSourceMod.cs:75` |
| C3 | 种子生成 `_h % 34`，34 不整除 `2^31` | `RngInfrastructureSourceMod.cs:114` |
| C4 | Fallback 选取 `idx % pool.size()`，无拒绝采样 | `ChoiceRngPatch.cs:128`、`:170` |
| C5 | 所有 `randf() * 100.0 < percent` 的百分比检查，100 不整除 `2^31` | 多个文件 |
| C6 | 原版所有 `floor(rand_range(0, N))` 同样存在取模偏置（分母 `2^32`），但无拒绝采样 | `game_source_code/` 各处 |

### D. 架构性结构变化

| # | 问题 | 文件:行号 |
|---|------|----------|
| D1 | 模组将物品选取从"在线 RNG 消费"改为"预洗牌序列 + cursor 推进"（skip-owned），同一事件内 cursor 只前进不后退 | `ChoiceRngPatch.cs:70-109` |
| D2 | 临时 PCGRng 实例（`_bh_build_item_seqs`、`_bh_item_rarity_randf`）每次都新建——消耗的不是持久 RNG 状态，而是种子派生 | `RngInfrastructureSourceMod.cs:439,489` |
| D3 | 每局 `_bh_begin_spin_rng()` 完全从种子+局号重建 reel/effect RNG，与 Deck 模式/Oil Can 等跨局事件无关 | `RngInfrastructureSourceMod.cs:215-233` |
| D4 | 保存/恢复覆盖 19 个 PCGRng 实例的 (state, inc) 对，但 item/essence 序列不持久化（恢复时重建） | `RngInfrastructureSourceMod.cs:364-367` |
| D5 | `seed(landlord_seed)` 同步 Godot 全局 RNG 作为 fallback，但所有已知 `rand_range()` 已被替换 | `RngInfrastructureSourceMod.cs:209,370` |

### E. 原版 bug 被修复

| # | 问题 | 文件:行号 |
|---|------|----------|
| E1 | `landlord_fates_data[floor(rand_range(0, X.size() - 1))]` — `-1` 排除了数组最后一个元素。模组替换为 `pick()`，包含全部元素 | `ChoiceRngPatch.cs:224` → `Pop-up.tscn__1.gd:993` |

---

## 引用文件完整清单

### 模组 C# 源文件
- `Piraeus.BetterLandlord/Patches/RngInfrastructureSourceMod.cs` — PCGRng 类、哈希函数、种子生成、所有 RNG 实例、保存/恢复
- `Piraeus.BetterLandlord/Patches/ChoiceRngPatch.cs` — Pop-up 选择 RNG 替换（稀有度、符号、物品、精华、装饰）
- `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs` — 事件捕获助手、`_bh_is_seeded()`、`_bh_end_run()`
- `Piraeus.BetterLandlord/Patches/SlotIconRngSourceMod.cs` — Slot Icon 效果/scratch RNG 路由
- `Piraeus.BetterLandlord/Patches/ItemRngSourceMod.cs` — Item 效果 RNG 路由
- `Piraeus.BetterLandlord/Patches/ReelRngRefSourceMod.cs` — Main.tscn::4 卷轴 RNG 路由
- `Piraeus.BetterLandlord/Patches/ReelExtraRngSourceMod.cs` — Reel.tscn::1 卷轴 RNG 路由
- `Piraeus.BetterLandlord/Patches/ReelShufflePatch.cs` — shuffle_tiles() 替换
- `Piraeus.BetterLandlord/Patches/LandlordRngRefSourceMod.cs` — Landlord.tscn::9 细则 RNG 路由
- `Piraeus.BetterLandlord/Patches/LandlordFinePrintPatch.cs` — 细则直通
- `Piraeus.BetterLandlord/Patches/CosmeticRngSourceMod.cs` — 装饰 RNG 路由（音乐、纹理、提示）
- `Piraeus.BetterLandlord/Patches/SpinPatch.cs` — 每局 RNG 初始化触发
- `Piraeus.BetterLandlord/Patches/SaveGamePatch.cs` — RNG 状态保存 hook
- `Piraeus.BetterLandlord/Patches/ContinueGamePatch.cs` — RNG 状态恢复 hook
- `Piraeus.BetterLandlord/Patches/TitleSetFloorPatch.cs` — 新游戏种子应用
- `Piraeus.BetterLandlord/Patches/TitleSeedSourceMod.cs` — 种子 UI
- `Piraeus.BetterLandlord/Patches/SeededStatsSourceMod.cs` — 种子统计守卫
- `Piraeus.BetterLandlord/Patches/SeededAchievementPatch.cs` — 种子成就守卫
- `Piraeus.BetterLandlord/Mod.cs` — SourceMod 注册顺序

### 原版游戏源码（关键文件）
- `game_source_code/Main.tscn__1.gd` — rarity_chances 定义、rarity_database
- `game_source_code/Main.tscn__4.gd` — shuffle_tiles()、add_tile()、卷轴操作
- `game_source_code/Pop-up.tscn__1.gd` — add_cards()、发牌、选择逻辑
- `game_source_code/Slot Icon.tscn__1.gd` — 符号效果 RNG 消费（~50 处）
- `game_source_code/Item.tscn__1.gd` — 物品效果 RNG 消费（~20 处）
- `game_source_code/Landlord.tscn__9.gd` — 地主细则
- `game_source_code/Reel.tscn__1.gd` — 卷轴实例 RNG
- `game_source_code/Music Player.tscn__1.gd` — 音乐选择
- `game_source_code/Options.tscn__1.gd` — 选项菜单 50/50 分支
