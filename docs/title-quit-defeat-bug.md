# 双 Bug 分析：Mid-Run 退回主菜单

**日期**: 2026-06-05
**现象**:
- **Bug 1（稳定）**: 中途回主菜单 → WPF 显示 "Defeat"（应为 "Quit"）
- **Bug 2（不稳定）**: 点击 Continue → clipboard error → Continue 失效；重启后消失

---

## Bug 1: Log 标记为 Defeat（稳定复现）

### 场景

```
游戏中 (spin N) → 点 Title → 主菜单 → 开 WPF → 看到 ended_by=loss → "Defeat"
```

### 控制流

```
步骤 1: 游戏中
  _bh_events = [run_start, spin_start#1, ..., spin_end#N]
  _bh_flushed_at_spin = -1

步骤 2: TitlePatch (Prefix on title())
    _bh_events.size() > 0 → true
    _bh_flush()                         ← 直接调，不经过 _bh_end_run
      → 写 JSON: ended_by='loss'        ← _bh_flush() 默认值（无 run_end 事件）
    _bh_dump_raw_events()

步骤 3: WPF 读取 runs/<run_id>.json
    ended_by='loss' → 渲染为 "Defeat"   ← 错误！

步骤 4: 玩家点 New Game → TitleSetFloorPatch
    _bh_end_run("quit")
      → 去抖: spins == _bh_flushed_at_spin? N == -1 → NO → 不拦截
      → 尝试读 $'Reels'/$'Items'       ← Board 在 Title 画面已失效
      → GDScript 错误 → run_end("quit") 未写入
      → 步骤 2 的 JSON 未被覆盖 ❌
```

### 根因

**TitlePatch 是唯一直接调用 `_bh_flush()` 而不经 `_bh_end_run()` 的调用点**，导致：

1. **`_bh_flushed_at_spin` 不更新** — 后续 `_bh_end_run("quit")` 的去抖检查失效
2. **没有 run_end 事件** — `_bh_flush()` 的 `ended_by` 退化为默认值 `'loss'`
3. **`_bh_end_run("quit")` 从 TitleSetFloorPatch 触发时 Board 已空** — 无法补写正确的 run_end

### 为什么旧架构能工作

旧架构用 `_bh_run_ended` 闩锁：
- Mid-run 时 `_bh_run_ended = false`
- TitleSetFloorPatch 的 `_bh_end_run("quit")` **能通过守卫**，正常捕获 board → flush → 写 `ended_by='quit'` → 覆盖 TitlePatch 写的那个 `'loss'` JSON

新架构用 `_bh_flushed_at_spin` 去抖：
- TitlePatch 不设置它
- 去抖失效
- `_bh_end_run("quit")` 在无效 board 状态下执行 → 失败

### 修复

**TitlePatch 改为调用 `_bh_end_run("quit")`**（而非直接 `_bh_flush()`）：

```gdscript
// 现在:
if _bh_events.size() > 0:
    _bh_flush()           // 绕过 _bh_end_run

// 改为:
if _bh_events.size() > 0:
    _bh_end_run("quit")   // 走完整流程：board 快照 + run_end + flush + 去抖标记
```

TitlePatch 是 **Prefix**（在 `title()` 函数体执行前运行），此时 Board **仍然完整**，可以安全捕获快照。同时设置 `_bh_flushed_at_spin`，后续 TitleSetFloorPatch 的第二次 `_bh_end_run("quit")` 被去抖拦截。

---

## Bug 2: Continue 失效 + Clipboard Error（不稳定）

### 场景

```
游戏中途 → Title → 点 Continue → "clip error" → Continue 无效
重启游戏 → 同样操作 → Continue 正常 → 无法复现
```

### Clipboard Error 来源

唯一调用 `OS.get_clipboard()` 的地方是 `_bh_clip_sample()`（`ClipboardMonitorPatch`）：

```gdscript
// MainScriptSourceMod.cs — 每 1 秒从 _process 触发
func _bh_clip_sample():
    if not OS.is_debug_build():   // ← 刚加的 guard
        ...
    var clip = OS.get_clipboard() // ← 这里触发的 ERROR
```

错误信息 `ERROR: Unable to open clipboard. at: os_windows.cpp:1712` 来自 Godot 引擎的 `OS_Windows::get_clipboard()`。Windows 上 `OpenClipboard(NULL)` 失败的原因是**另一个进程持有剪贴板锁**。

### 为什么不稳定（重启后消失）

```
Session 1:  某个进程持有 clipboard → _bh_clip_sample() → ERROR
            ↓
            用户在控制台看到 "clip error"
            ↓
            用户把它和 Continue 失败关联 ← 可能只是时间巧合

Session 2:  clipboard 空闲 → 无 ERROR → Continue 正常
```

剪贴板冲突是**本质上的竞态条件**——取决于当时哪个进程在使用剪贴板（浏览器扩展、远程桌面、输入法、其他 mod 等）。

### Continue 真正失败的原因推测

Clipboard error 本身**不会导致 Continue 失败**（`OS.get_clipboard()` 失败时返回空字符串并继续执行）。如果 Continue 确实失效了，可能的原因：

**推测 A — Godot 自定义构建的错误处理**: 用户运行的是 `custom_build` 版 Godot。如果这个构建启用了 `DEV_ENABLED` 或配置了 error handler，引擎级 ERROR 可能弹出对话框或触发断点，阻塞主线程，打断 Continue 流程。

**推测 B — 时间巧合**: Clipboard error 的发生时间和 Continue 点击刚好重合。用户在控制台看到 `ERROR`，以为是 Continue 导致的。实际 Continue 可能因为游戏自身的 save 文件问题而失败（与 mod 无关）。

**推测 C — `_bh_restore_rng_state()` 指纹不匹配**: Continue 时 `_bh_restore_rng_state()` 的指纹校验访问 `$'Pop-up Sprite/Pop-up'.spins` 和 `$'Coins'.coins`。如果在 Continue 过程中这些节点的初始化有微妙的时序差异（取决于 CPU 负载/磁盘 I/O），可能导致 fingerprint mismatch → RNG 不恢复 → 游戏行为异常。

但 `_bh_restore_rng_state` 返回 false 不会阻止 Continue 本身——它只是不恢复 mod RNG。游戏本身按 Godot 原生 RNG 继续。

### 结论

**Bug 2 的核心问题很可能是 clipboard 竞态 + 用户观察到的时间关联**。因为我们刚实施的 Debug/Release 分离让 `_bh_clip_sample` 在 Release 构建中直接 return（检查 `OS.is_debug_build()`），clipboard 不再被读取，Bug 2 的环境条件被消除了。

### 建议

1. **立即修 Bug 1**: 改 TitlePatch（见上）
2. **Bug 2 观察**: 修完 Bug 1 后，在 Release 构建中继续观察。如果 `OS.is_debug_build()` 在你的 Godot 构建返回 `false`，clipboard monitor 已被禁用，Bug 2 不会再触发
3. **如果想彻底去掉 clipboard monitor**: 可以直接删掉 `ClipboardMonitorPatch` 和相关代码——它是一个调试工具，不是功能需求

---

## 两个 Bug 的独立性

```
Bug 1 (稳定)            Bug 2 (不稳定)
───────────            ───────────
根因: TitlePatch       根因: _bh_clip_sample()
直接调 _bh_flush()     调用 OS.get_clipboard()
→ 去抖标记不更新        → Windows clipboard 竞态
→ ended_by='loss'      → 引擎 ERROR 输出
                                          │
                       Continue 失效（如果真实存在）
                       → 可能是 Godot custom_build 的错误处理
                       → 也可能是时间巧合的误判
                       
两个 Bug 没有因果关系，恰好同时出现。
```
