# IME 输入法导致种子输入异常 Bug Report

> 2026-06-03 · 已修复

## 症状

输入英文空格作为种子,期望随机种子,实际产出定制种子(中文字符)。

### 实测记录 (runs 85-88,全部使用空格输入)

| Run | seed_type | seed_input | spins | 预期 | 实际 |
|-----|-----------|------------|-------|:--:|:--:|
| 85 | custom | 啊士 | 5 | random | custom ✗ |
| 86 | random | JFNP8PY10H | 7 | random | random ✓ |
| 87 | random | BWV85QP214 | 3 | random | random ✓ |
| 88 | random | HQFGKAXAVA | 5 | random | random ✓ |

JSON 原始内容确认:
```json
{"seed_type": "custom", "seed_input": "啊士"}
```

## 根因

**中文输入法(IME)的空格键语义冲突**。

### IME 工作原理

```
英文模式:  按[空格] → 输入字符 0x20 (空格)
中文模式:  按[a] → IME进入组合状态,候选框: 啊阿吖...
          按[空格] → IME确认第一个候选字 → 输出"啊"
```

Run 85: IME 处于待确认状态(可能之前误触了字母键) → 用户按空格 → IME 确认为"啊士" → 非空文本 → custom seed
Run 86-88: IME 退出组合状态 → 空格是纯空格 → `strip_edges` 后为空 → random

### 控制流关键路径

```
用户输入空格 → LineEdit.text = "啊士" (IME确认)
     │
     ▼
_bh_get_seed_config()                          ← TitleSeedSourceMod
     │ var text = _bh_seed_input.text.strip_edges()
     │ # "啊士".strip_edges() = "啊士"  (非空!)
     │ if text.length() > 0:
     │     return {'type': 'custom', 'input': "啊士"}
     ▼
_bh_apply_seed()                               ← TitleSetFloorPatch (new_game prefix)
     │ var cfg = title._bh_get_seed_config()
     │ _bh_init_rng(cfg.type, cfg.input)
     ▼
_bh_init_rng("custom", "啊士")                  ← RngInfrastructureSourceMod
     │ seed_input = "啊士"
     │ seed_input = seed_input.strip_edges()    ← 仍然非空
     │ seed_type == 'custom' and seed_input != ''
     │ → _bh_rng_seed_input = "啊士"
     │ → landlord_seed = _bh_fnv1a("啊士")
     ▼
meta.seed_type = "custom"
meta.seed_input = "啊士"
```

### 旧代码的缺口

```gdscript
# TitleSeedSourceMod._bh_get_seed_config (修复前)
func _bh_get_seed_config():
    if _bh_seed_enabled and _bh_seed_input != null and is_instance_valid(_bh_seed_input):
        var text = _bh_seed_input.text.strip_edges()   # ← 只能去ASCII空格
        if text.length() > 0:                           # ← IME产物通过!
            text = text.replace('O', '0').replace('I', '1')
            return {'type': 'custom', 'input': text}    # ← 中文字被当定制种子
    return {'type': 'random', 'input': ''}
```

**`strip_edges()` 不去非 ASCII 空格** (如 U+00A0 不间断空格、U+3000 全角空格)。但本案中空格根本没机会出现 — IME 在空格到达 LineEdit 之前就拦截了。

## 修复

在 `_bh_get_seed_config` 增加 ASCII 可打印字符校验。非 ASCII 输入(IME 产物/CJK/emoji)视为误触 → 回退 random:

```gdscript
# TitleSeedSourceMod._bh_get_seed_config (修复后)
func _bh_get_seed_config():
    if _bh_seed_enabled and _bh_seed_input != null and is_instance_valid(_bh_seed_input):
        var text = _bh_seed_input.text.strip_edges()
        if text.length() > 0:
            # Reject non-ASCII (IME artifacts)
            var _ascii = true
            for _ch in text:
                if ord(_ch) > 127:
                    _ascii = false
                    break
            if _ascii:
                text = text.replace('O', '0').replace('I', '1')
                return {'type': 'custom', 'input': text}
    return {'type': 'random', 'input': ''}
```

## 相关文件

- `TitleSeedSourceMod.cs` — `_bh_get_seed_config` (修复位置)
- `RngInfrastructureSourceMod.cs` — `_bh_init_rng` (种子消费点,双层规范化)
- `TitleSetFloorPatch.cs` — `_bh_apply_seed` (new_game 时的种子应用)
