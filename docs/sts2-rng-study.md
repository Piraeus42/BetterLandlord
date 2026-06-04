# Slay the Spire 2 RNG 设计学习

> 偷师对象: `D:\SlayTheSpire2\StS2\src\Core\`
> 对照问题: `docs/rng-fix-todo.md`
> 生成: 2026-06-04

---

## 1. StS2 整体架构

### 1.1 三层 RNG 结构

```
StringSeed ("A3F7K2M9P1")
    │
    ├── RunRngSet  (对局级)
    │   ├── Seed = GetDeterministicHashCode(StringSeed)
    │   ├── UpFront           = Rng(Seed, "up_front")           → 地图生成/事件
    │   ├── Shuffle           = Rng(Seed, "shuffle")            → 卡组洗牌
    │   ├── UnknownMapPoint   = Rng(Seed, "unknown_map_point")  → 未知地图点
    │   ├── CombatCardGeneration = Rng(Seed, "combat_card_generation") → 战斗内卡牌生成
    │   ├── CombatCardSelection  = Rng(Seed, "combat_card_selection")  → 战斗内卡牌选取
    │   ├── CombatPotionGeneration → ...
    │   ├── CombatEnergyCosts      → ...
    │   ├── CombatTargets          → ...
    │   ├── MonsterAi              → ...
    │   ├── Niche                  → 小众用途
    │   ├── CombatOrbs             → 充能球
    │   └── TreasureRoomRelics     → 宝箱遗物
    │
    └── PlayerRngSet (玩家级, 多人游戏中每人独立)
        ├── Seed = (从对局 seed 派生)
        ├── Rewards         = Rng(Seed, "rewards")        → 奖励卡牌抽取 ⭐
        ├── Shops           = Rng(Seed, "shops")          → 商店生成
        └── Transformations = Rng(Seed, "transformations") → 卡牌变换
```

### 1.2 RNG 实例化方式

```csharp
// Rng.cs
public class Rng
{
    public int Counter { get; private set; }  // 已消费次数
    public uint Seed { get; }

    // 从 seed + name 派生 — name 是唯一的区分器
    public Rng(uint seed, string name)
        : this(seed + (uint)StringHelper.GetDeterministicHashCode(name))
    { }

    // 每次调用都 Counter++
    public int NextInt(int maxExclusive) { Counter++; return _random.Next(maxExclusive); }
    public float NextFloat() { Counter++; return (float)_random.NextDouble(); }

    // 从列表随机选一项
    public T? NextItem<T>(IEnumerable<T> items) {
        int index = NextInt(0, items.Count());
        return items.ElementAt(index);
    }

    // Fisher-Yates shuffle
    public void Shuffle<T>(IList<T> list) {
        for (int i = list.Count - 1; i > 0; i--) {
            int j = NextInt(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    // 保存/恢复: 只记 Counter, FastForward 回放
    public void FastForwardCounter(int target) {
        while (Counter < target) { Counter++; _random.Next(); }
    }
}
```

**关键:** `seed + hash(name)` 保证每个 RNG 流从 seed 唯一派生，不依赖其他 RNG 的消费状态。

---

## 2. 对照我们的问题

### 2.1 问题 #1: Spin RNG 不唯一 → StS2 方案

**我们的问题:**
```
_bh_rng_spin (持久流)
  ├── _bh_begin_spin_rng(): randi_max() → spin_val → 派生 reel/effect/scratch
  └── _bh_c_spin_shuffle(): custom_shuffle() ← 偷取值
→ spin N 的 spin_val 取决于之前发生了多少次 shuffle
```

**StS2 方案:**
```
每个 RNG 类型直接从 seed + name 派生，互不依赖。
不存在"从一个 RNG 取随机值去 seed 另一个 RNG"的模式。

例如 Deck Shuffle 是一个独立的 RunRngType.Shuffle:
  Rng(Seed, "shuffle") — 完全独立，不受任何其他流程影响
```

**启示:** 把"每 spin 的 reel/effect/scratch 种子"改成从 landlord_seed + spin_num 直接派生：
```
_bh_rng_reel_N = PCGRng.new(djb2(landlord_seed, "reel_" + str(spin_num)))
```
这样 spin N 的 reel RNG 永远一致，无论之前发生了什么。

---

### 2.2 问题 #2: Rarity Shuffle 污染 Rarity RNG → StS2 方案

**我们的问题:**
```
_bh_rng_rarity 被两个地方消费:
  1. _bh_c_rarity_randf() — 稀有度阈值判定 (每卡 1 次)
  2. _bh_c_rarity_shuffle() — 打乱 forced_rarity 数组 (Fisher-Yates, n-1 次)
→ 有 forced_rarity 时多消费 2 次，后续稀有度判定全部错位
```

**StS2 方案:**
```
稀有度判定和洗牌使用不同的 RNG:
  - 稀有度: PlayerRng.Rewards (RollForRarity)
  - 洗牌:   RunRng.Shuffle (专门独立)
```

**启示:** 我们的 `forced_rarity_arr.shuffle()` 应该用一个独立 RNG（比如新派生一个 `djb2(landlord_seed, "forced_rarity_shuffle")`），不与 `_bh_rng_rarity` 共享。

---

### 2.3 问题 #3/#3.5: 池变异 → StS2 方案

**我们的问题:**
```
add_cards():
  card_pool = rarity_database["symbols"].duplicate(true)  // 固定顺序
  for c in 0..2:
    rarity = rarity_randf()
    symbol = card_pool[rarity][randi_max(pool.size)]  // 随机下标
    card_pool[rarity].erase(symbol)  // 变异池 — 后续下标错位

跨批次: sym_common[K] 面对不同大小的池 (K 是批内第 1/2/3 个 common)
```

**StS2 方案 (CardFactory.CreateForReward):**
```csharp
List<CardModel> blacklist = new List<CardModel>();
for (int i = 0; i < cardCount; i++)
{
    // 1. 从完整池中排除已选 (不做 erase, 用 filter)
    var options = GetPossibleCards(player).Except(blacklist);
    
    // 2. 稀有度判定 — 用 Rewards RNG
    rarity = RollForRarity(player, odds, source, allowedRarities, force);
    
    // 3. 按稀有度过滤
    var items = options.Where(c => c.Rarity == rarity);
    
    // 4. 随机选取 — 用同一个 Rewards RNG
    card = rng.NextItem(items);  // = items.ElementAt(rng.NextInt(items.Count()))
    
    // 5. 加入黑名单 (不修改原始池)
    blacklist.Add(card.CanonicalInstance);
}
```

**StS2 模式的核心:**
1. **不 mutate 池** — 用 `blacklist` 排除已选项，原始池不变
2. **每次重新 filter** — `items` 是每次从完整池 + blacklist filter 生成的
3. **稀有度判定和符号选取用同一个 RNG** — 不按稀有度分流，所有卡牌奖励共享 `PlayerRng.Rewards`
4. **`NextItem` 替代 `randi_max` + 下标** — 抽象层级更高

**启示:**
- 如果我们也用 blacklist 代替 `erase()`，同批同稀有度的第二次选取就不会被"擦掉不同元素导致下标错位"影响
- `NextItem(FilteredPool)` 每次都面对明确、可重现的池 → `sym_common[K]` 的映射对池大小依赖更强，但池的**结构**可预测（因为是 filter 而非 mutation）

但注意：StS2 的做法仍然有一个问题：**稀有度判定和卡牌选取共享同一个 RNG**。如果稀有度判定变了（比如 odds 变了），后续卡牌选取的值也会偏移。不过 StS2 的 odds 在同一局中是确定的（由 CardRarityOddsType 和玩家状态决定）。

---

## 3. 还有价值的 StS2 模式

### 3.1 Counter 保存/恢复

```csharp
// 保存
var save = new SerializableRunRngSet { Seed = seed };
foreach (var (type, rng) in _rngs) {
    save.Counters[type] = rng.Counter;  // 只记消费次数
}

// 恢复
Rng rng = new Rng(seed, name);
rng.FastForwardCounter(savedCounter);  // 回放到保存时的位置
```

**优点:** 不需要保存 RNG 内部状态，只需要 Counter。极简。

**对照:** 我们保存了 PCG 的 `(state, inc)` 对。Counter 方式更简单，但要求 RNG 是简单的序列（System.Random 或 PCG 都满足）。

### 3.2 StableShuffle — 跨平台确定性

```csharp
public static List<T> StableShuffle<T>(this List<T> list, Rng rng) where T : IComparable<T>
{
    List<T> sorted = list.ToList();
    sorted.Sort();           // 先按自然顺序排序
    for (int i = 0; i < list.Count; i++)
        list[i] = sorted[i]; // 源列表也改成排序后的顺序
    return list.UnstableShuffle(rng);  // 再做 Fisher-Yates
}
```

**目的:** 确保无论 list 构建时的顺序如何（可能受 hash 顺序、OS 等影响），`StableShuffle` 的结果是确定的。先排序消除了输入顺序的差异。

**启示:** 如果我们担心 `rarity_database["symbols"]` 的迭代顺序在不同环境/版本间不同，可以在每次 shuffle 前先 `sort()`。

### 3.3 测试注入

```csharp
// TestRngInjector.cs — 测试时可以覆盖 RNG 输出
List<CardModel> list = TestRngInjector.ConsumeCombatCardGenerationOverride();
if (list != null) return list;
```

**启示:** 我们的设计也应该在关键 RNG 消费点留 injector 接口，方便测试"如果我选 X 符号会发生什么"。

---

## 4. 针对我们问题的修复策略

| 问题 | StS2 方案 | 我们的适用性 |
|------|----------|------------|
| #1 Spin RNG 不唯一 | seed + hash(name) 直接派生所有 RNG | ✅ 完全适用: `djb2(landlord_seed, "reel_3")` |
| #2 Rarity Shuffle 污染 | 独立 RNG 类型 | ✅ 完全适用: 新增 `_bh_rng_forced_rarity` |
| #3 池变异 | blacklist + filter 替代 erase | ✅ 完全适用: 改 `erase()` 为 `blacklist` |
| #3.5 跨批池大小 | 每次重新 filter 完整池 | ⚠️ 部分适用: filter 保证同批内一致，但跨批大小依赖 RNG 消费次数 |

### 关于 #3.5 的深入思考

StS2 的做法并未完全解决"第 K 个 common 符号是否固定"的问题，因为：

```
StS2 的 Rewards RNG 消费:
  卡1: RollForRarity(rng) → NextInt → 稀有度判定
       NextItem(rng) → NextInt → 卡牌选取
  卡2: RollForRarity(rng) → NextInt → 稀有度判定
       NextItem(rng) → NextInt → 卡牌选取
  卡3: RollForRarity(rng) → NextInt → 稀有度判定
       NextItem(rng) → NextInt → 卡牌选取

每张卡消费 2 次 Rewards RNG ← 固定
```

因为 StS2 **每张卡都固定消费 2 次 Rewards RNG**（稀有度 + 选择），所以不存在"因为稀有度不同导致 RNG 消费次数不同"的问题。

**这是关键差异**: 我们的设计中，`_bh_rng_rarity` 和 `_bh_rng_sym_*` 是分离的。如果这批没有 common，`_bh_rng_sym_common` 就不消费。StS2 的 `Rewards` RNG 每张卡都消费，不论稀有度。

**最优方案可能反而是:** 为符号奖励单独一个 RNG（不按稀有度分），每卡固定消费，就像 StS2 的 `Rewards` RNG 一样。这样"第 N 张奖励卡"永远得到相同的随机值。
