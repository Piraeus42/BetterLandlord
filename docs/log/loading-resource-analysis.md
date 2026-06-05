# "Loading resource" 日志时间线分析

**日期**: 2026-06-05
**SlotWeave 版本**: 2.0.17.0
**Godot 版本**: 3.4.4.stable.custom_build.419e713a2

---

## 1. 结论摘要

`Loading resource: res://Localization.*.translation` **是 Godot 引擎的原生日志**，在 `ProjectSettings::setup()` 阶段自动加载项目配置中指定的翻译资源时输出。它们**不是 mod emit 的**，mod 也无法在代码层面 emit 这些行。

但这些日志**之所以现在出现在用户视野中**，高度可能与最近 commit 引入的两个新 `ISourceMod` 目标（`Coins.tscn::1` + `Items.tscn::1`）触发的 SlotWeave `[RELOAD]` 调试日志洪流有关——大量新增的 `[DBG] [RELOAD]` 行让控制台输出大幅膨胀，用户注意到了之前一直存在但被忽略的引擎日志。

---

## 2. 完整时间线

| 时间 | 来源 | 事件 | 说明 |
|------|------|------|------|
| 14:50:41 | **SlotWeave** | `This is SlotWeave 2.0.17.0` | 框架启动 |
| 14:50:41 | **SlotWeave** | `Loading mod Piraeus.BetterLandlord` | 发现并加载 mod DLL |
| 14:50:42 | **Mod (C#)** | `[BetterLandlord] initializing...` | `Mod.cs` 构造函数开始 |
| 14:50:42 | **Mod (C#)** | Migration done: 0 migrated, 120 skipped | `RunMigration()` 完成 |
| 14:50:42 | **Mod (C#)** | `Registered reader: SeedSignalReader` | GameStateBus reader 注册 |
| 14:50:42 | **Mod (C#)** | `[Push] Waiting for WPF...` | 启动 WPF UI 进程 |
| 14:50:42 | **Mod (C#)** | `[PipeServer] Started` | IPC 管道服务器启动 |
| 14:50:42 | **SlotWeave** | `Registered [Patch] res://...::... from ...` ×16 | 所有 `[Patch]` 类注册完成 |
| 14:50:42 | **SlotWeave** | `Loaded 1 mods` | 框架就绪 |
| 14:50:43 | **Mod (C#)** | `[Push] WPF connected` | WPF UI 连上管道 |
| 14:50:43 | **SlotWeave** | `GDScript::reload found at 0x...` | ⚡ 在 Godot 引擎二进制中定位 `GDScript::reload` 函数 |
| 14:50:43 | **SlotWeave** | `[x64dbg] bp GDScript::reload = 0x...` | ⚡ 设置 x64dbg 断点，拦截所有脚本编译 |
| 14:50:43 | **SlotWeave** | `[x64dbg] bp crash_site (RVA 0x15F07DA) = 0x...` | ⚡ 设置崩溃监控断点 |
| 14:50:43 | **Mod (C#)** | `[PipeServer] Client connected` | WPF 握手完成 |
| 14:50:43 | **Mod (C#)** | `OS singleton not yet available` | Godot 引擎尚未启动，OS 单例不可用 |
| 14:50:43 | **Mod (C#)** | `[PipeServer] Got: get_run_list` | WPF 请求历史数据 |
| 14:50:43 | **Mod (C#)** | `Hooking SceneTree::idle` + `GameStateBus initialized` | 挂载 idle hook |
| 14:50:43 | **Mod (C#)** | `[PipeServer] Sending 129 runs` | 发送历史记录到 WPF |
| 14:50:43 | **Godot** | `Godot Engine v3.4.4.stable.custom_build` | Godot 引擎启动 |
| 14:50:43 | **Godot** | `Using GLES2 video driver` | 渲染器初始化 |
| 14:50:43 | **Godot** | `OpenGL ES Batching: ON` + OPTIONS | OpenGL 渲染配置 |
| 14:50:43 | **Godot** | `WASAPI: ...` | Windows 音频系统初始化 |
| **14:50:43** | **Godot** | **`Loading resource: res://Localization.*.translation` ×20** | **🎯 ProjectSettings 自动加载翻译资源** |
| 14:50:43 | **Godot** | `CORE API HASH: 0` / `EDITOR API HASH: 0` | GDScript 子系统初始化（无缓存 hash） |
| 14:50:43 | **Godot** | `Loading resource: res://Utils.gdc` | 工具类加载 |
| 14:50:43 | **Godot** | `Loading resource: res://Main.tscn` | 主场景开始加载 |
| 14:50:43 | **Godot** | `Loading resource: res://Pop-up.tscn` | Pop-up 场景加载 |
| 14:50:43 | **SlotWeave** | `[RELOAD] #1 Popup Scroll Bar.tscn::1` | 第1个脚本被 GDScript::reload 钩子拦截 |
| 14:50:43~44 | **SlotWeave** | `[RELOAD] #2~#37` | 后续 36 个脚本的编译拦截 |
| 14:50:44 | **Godot** | `Loading resource: res://icons/*.png` ×~500 | 图标纹理资源加载 |
| 14:50:44 | **Godot** | `ERROR: Condition "!data.grouped.has..."` ×20 | ⚠️ Godot 引擎报错：`Node::remove_from_group` 重复移除 |
| 14:50:46 | **Godot** | `Loading resource: res://music/Banana Beats.ogg` | 背景音乐加载 |
| 14:50:46 | **Mod (C#)** | `OS singleton at 0x...` / `SceneTree at 0x...` | 引擎就绪，内存地址可用 |
| 14:50:46 | **Mod (C#)** | `EngineObjectReader initialized` + `GameStateBus lazy-init` | 运行时数据读取器就绪 |
| 14:50:52~57 | **Mod (C#)** | `Frame 300/600: 1 readers, snapshot keys` | 游戏运行中，帧回调正常 |

---

## 3. 关键发现

### 3.1 "Loading resource" 加载时机

翻译资源在 Godot 启动的第 **3 阶段**加载（在音频初始化之后、GDScript 子系统初始化之后、主场景加载之前）。这是 Godot 引擎的固定启动顺序，对应 `ProjectSettings::setup()` → auto-load resources 的逻辑。

**此时所有 mod 的 `ISourceMod` patch 尚未执行**——`[RELOAD]` 事件 #1 发生在翻译加载之后约 300ms。这意味着源文件修改不可能影响翻译加载时机。

### 3.2 最近改动触发的可见差异

对比新旧代码的 `[RELOAD]` modified 脚本数：

| 文件 | 旧状态 | 新状态 | 影响 |
|------|--------|--------|------|
| `Coins.tscn::1` | ❌ 不 patch | ✅ `GuillotineTriggerSourceMod` | **新增** — `[RELOAD] #26 modified` |
| `Items.tscn::1` | ❌ 不 patch | ✅ `GuillotineTriggerSourceMod` | **新增** — `[RELOAD] #21 modified` |
| `Slot Icon.tscn::1` | ✅ patch（无事件注入） | ✅ patch（+2处事件注入） | 已有目标，只是替换逻辑变了 |

这些新增的 `[DBG] [RELOAD] ... source modified, written back` 日志行让控制台输出量显著增加，导致用户更容易注意到之前被忽略的 Godot 引擎日志。

### 3.3 `CORE API HASH: 0` / `EDITOR API HASH: 0`

这两行来自 `GDScriptLanguage::init()`，hash 为 0 表示没有缓存的 GDScript API hash（首次运行或缓存被清理）。这是 Godot 自定义构建版本的**正常输出**（release 版本通常不打印），说明这个 Godot 构建启用了调试输出。

### 3.4 `remove_from_group` ERROR ×20

```
ERROR: Condition "!data.grouped.has(p_identifier)" is true.
   at: Node::remove_from_group (scene\main\node.cpp:1634)
```

这是 Godot 引擎级别的错误：某处代码对不在 group 中的节点调用 `remove_from_group()`。这发生在场景加载完成后（图标加载完毕、音乐加载前）。**这可能是 mod 代码的副作用**——如果 `MainScriptSourceMod`、`TitleSeedSourceMod` 或任何 patch 在场景初始化期间操作了节点的 group 成员关系，就可能触发此错误。需要单独排查。

---

## 4. mod 代码层面的排查结论

### 4.1 不相关
- `GuillotineTriggerSourceMod.cs` — 只注入 `_bh_end_run("victory")` 调用，不涉及资源加载或 group 操作
- `SlotIconRngSourceMod.cs` — 事件注入 + RNG 替换，不涉及资源加载
- `MainScriptSourceMod.cs` — 添加 `_bh_*` 方法定义 + 数据追踪变量，不触发资源加载

### 4.2 需要关注
- **`remove_from_group` ERROR ×20**: 建议排查 `MainScriptSourceMod`、`TitleSeedSourceMod` 中是否有对场景节点的 `remove_from_group()` 调用。可以在 `_bh_start_run()` 或 `_ready` patch 中加点自查。
- **SlotWeave `[DBG]` 日志级别**: 大量 `[DBG]` 行显示当前 SlotWeave 运行在 Debug 日志级别。如果之前是 Release 级别，这些行（包括 `[RELOAD]` 跟踪）都不会出现，控制台会更干净。

---

## 5. 建议

1. **翻译加载日志无害** — 无需处理，这是 Godot 正常行为
2. **`remove_from_group` ERROR** — 建议排查这是否是已有问题还是新引入的
3. **减少控制台噪音** — 如果 SlotWeave 支持配置日志级别，调高到 `INF` 可以隐藏 `[DBG] [RELOAD]` 行
4. **对比验证** — 用 `git stash` 回到旧 commit，看同样的 SlotWeave 2.0.17.0 是否也输出翻译加载日志，即可一锤定音
