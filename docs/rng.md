# RNG 种子系统

> 完全确定性随机数系统。相同种子 = 相同对局。

## 种子输入

标题画面 Seed 按钮: OFF → ON → 输入框出现。不输入 = 随机(10 位 [0-9A-Z]),输入 = 自定义。

## 派生树

```
landlord_seed (FNV-1a hash)
├── spin          → SpinRNG           (每 spin 取 1 值派生临时 Reel+Effect)
├── rarity        → RarityRNG         (三选一稀有度判定)
├── sym_common    → SymbolCommonRNG   (普通符号池序列)
├── sym_uncommon  → SymbolUncommonRNG
├── sym_rare      → SymbolRareRNG
├── sym_vrare     → SymbolVeryRareRNG
├── itm_common    → ItemCommonRNG     (物品池序列 ×4 稀有度)
├── itm_uncommon/uncommon/rare/vrare
├── ess_common    → EssenceCommonRNG  (精华池序列 ×4 稀有度)
├── ess_uncommon/rare/vrare
├── fineprint     → FinePrintRNG      (房东条款/动态图标)
└── cosmetic      → CosmeticRNG       (音乐/SFX/Tips/命运)
```

**分轨效果**: rarity_bonus 改变"抽哪个稀有度"频率 → 某稀有度被多抽几次 → 该稀有度 RNG 被多调用几次 → **但不改变**各稀有度池内序列。稀有度加成物品不会让 fixed seed 的结果乱掉。

## 每 spin 隔离

```
SpinRNG.next() → spin_3_value
  → djb2(spin_3_value, "reel")   → ReelRNG_3   (洗牌/空位/加符号)
  → djb2(spin_3_value, "effect") → EffectRNG_3 (效果触发/值/概率/变换)
```

spin N 加新效果 → 只影响 spin N。spin N+1 重新从 SpinRNG 取值 → 完全独立。

## PCGRng

```gdscript
class PCGRng:
    var state: int  # 64-bit PCG, 保持在 [0, 2^63)
    func randf() -> float: ...         # [0, 1)
    func randi_max(n) -> int: ...      # [0, n)
    func rand_range(min, max): ...     # [min, max)
    func custom_shuffle(arr): ...      # Fisher-Yates
```

## 替换范围

| 文件 | 调用数 | RNG |
|------|:-----:|------|
| Pop-up.tscn::1 | 18 | Rarity + 12 稀有度 + Cosmetic |
| Main.tscn::4 | 12 | ReelRNG_N (每 spin 临时) |
| Reel.tscn::1 | 4 | ReelRNG_N |
| Slot Icon.tscn::1 | 50+ | EffectRNG_N |
| Item.tscn::1 | 20+ | EffectRNG_N |
| Landlord.tscn::9 | 6 | FinePrintRNG |
| Music Player | 2 | CosmeticRNG |
| Options | 4 | CosmeticRNG |

所有 `randomize()` 删除,`rand_range()` 替换,`shuffle()` → `custom_shuffle()`。

## 存储

```json
"meta": { "seed_type": "random", "seed_input": "A3F7K2M9P1", "landlord_seed": 2874653291 }
```

## 三选一调用序列

```
add_cards() 一局 (3 张卡):
  c=0: RarityRNG.randf() → 稀有度阈值
       SeqRNG[rarity].randi_max(pool.size()) → 池内索引
  c=1: 同上
  c=2: 同上
```

## 实现文件

```
RngInfrastructureSourceMod.cs  → PCGRng 类 + 17 实例 + djb2/fnv1a
ChoiceRngSourceMod.cs          → Pop-up 三选一替换
ChoiceRngPatch.cs              → _bh_c_pick_symbol/item helpers
LandlordRngRefSourceMod.cs     → 房东 RNG
ReelRngRefSourceMod.cs         → Reel RNG
SlotIconRngSourceMod.cs        → Effect RNG
ItemRngSourceMod.cs            → Item RNG
CosmeticRngSourceMod.cs        → Cosmetic RNG
TitleSeedSourceMod.cs          → Title 种子 UI
```
