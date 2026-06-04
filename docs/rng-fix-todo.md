# RNG 修复待办

> 基于审计和 V1 架构讨论
> 更新: 2026-06-04

---

## 已修复 ✅

| # | Bug | 修复 | 文件 |
|---|-----|------|------|
| 1 | spin_val 从 _bh_rng_spin 取，被额外消费 | `djb2(seed, "spin_N")` | RngInfrastructureSourceMod.cs |
| 2 | forced_rarity shuffle 消费 rarity RNG | 隔离到 `_bh_rng_forced_rarity` | RngInfrastructureSourceMod.cs, ChoiceRngPatch.cs |
| 3 | Boss 音乐 rand_range 未替换 | catch-all regex | ChoiceRngPatch.cs |

---

## 待修复 (Phase 1: 路由)

| # | Bug | 当前 | 目标 | 优先级 |
|---|-----|------|------|--------|
| 4 | add_item 主路径用错 RNG | `_bh_c_pick_symbol` → `_bh_rng_sym_*` | `_bh_c_pick_item` → `_bh_rng_itm_*` | 🔴 紧急 |
| 5 | essence 无专属 RNG | `_bh_c_pick_symbol` default → `_bh_rng_sym_common` | `_bh_rng_ess` | 🔴 紧急 |
| 6 | sym/itm 稀有度共用 RNG | `_bh_rng_rarity` 一个流 | 拆为 `_bh_rng_sym_rarity` + `_bh_rng_itm_rarity` | 🟡 |
| 7 | ess_* ×4 死代码 | 4 个流从未使用 | 合并为 `_bh_rng_ess` ×1 | 🟡 |

---

## 待修复 (Phase 2: Shuffle 分家)

| # | 任务 | 文件 |
|---|------|------|
| 8 | 删除 `_bh_rng_spin` | RngInfrastructureSourceMod.cs |
| 9 | 重写 `_bh_begin_spin_rng()` 派生 6 临时流 | RngInfrastructureSourceMod.cs |
| 10 | `_rrr_shuffle` → `_bh_rng_reel_shuffle` | ReelRngRefSourceMod.cs |
| 11 | `_rer_shuffle` → `_bh_rng_reel_shuffle` | ReelExtraRngSourceMod.cs |
| 12 | `_sir_shuffle` → `_bh_rng_effect_shuffle` | SlotIconRngSourceMod.cs |
| 13 | `_itr_shuffle` → `_bh_rng_effect_shuffle` | ItemRngSourceMod.cs |
| 14 | `_bh_c_spin_shuffle` → `_bh_rng_oil_can` | ChoiceRngPatch.cs |

---

## 已知未修（原理限制）

- 符号池无 shuffle，同批同稀有度第 2/3 个符号受第 1 个选取影响。稀有卡影响极小，暂不修。
