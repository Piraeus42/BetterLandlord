读完了。你的"频繁时序问题、状态不稳"不是一堆孤立 bug，是**几个结构性模式**在反复制造同类故障。我按"能解释你已报告症状"和"还没炸但一定会炸"两类排，最重要的在前面。

## 症结一：事件被当状态用，且"消费"early于"投递"（这是丢点击的根因）

`SeedSignalReader.Read()` 每帧跑在**游戏主线程**上。看这段顺序：

```csharp
if (curVal > 0 && curVal != _prevValue)
{
    _prevValue = curVal;        // ← 先把事件消费了
    SeedRequested?.Invoke();    // ← 再投递（可能失败/被丢）
}
```

`_prevValue` 在**投递结果未知前**就推进了。于是只要 push pipe 那一刻没连上（冷启动窗口）或 write 失败，这次点击**已被标记为已处理，永远不会重试**。你看到的"前 5 秒点不动、要点第二下"就是这个——不是按钮卡，是第一次点击的事件被吃掉了。

加 Timer、加轮询都治不了它，因为问题在"消费时机"。正确做法是**只在投递成功后才推进 `_prevValue`**：

```csharp
if (curVal > 0 && curVal != _prevValue)
{
    if (TryPushSeedRequest())   // 返回 true 仅当 write 成功
        _prevValue = curVal;
    // 失败则不推进 → 下一帧 Read 再次看到 curVal > _prevValue → 自动重试
}
```

这样 WPF 一旦连上，下一帧自然补发。冷启动窗口、pipe 抖动全部自愈，不需要 replay 协议。这是把"事件"正确地建模成"状态差"（GDScript 持有最新请求值，C# 持有已投递到的值，二者收敛）。

## 症结二：push 的 Write 在锁外，且可能从两个线程并发写同一个 pipe

```csharp
lock (_pushLock) { server = _pushServer; }  // 锁只保护取引用
if (server == null) return;
server.Write(...);   // ← 在锁外！
server.Flush();
```

`PushToClient` 有**两个调用者**：`OnSeedSignal`（主线程）和 `set_seed` handler（ServerLoop 后台线程）。两条线程可以同时拿到同一个 `server` 引用，在锁外并发 `Write` → 字节交错 → WPF 收到半行损坏 JSON → 解析失败、消息丢失。这是"偶发、难复现"类时序 bug 的典型来源。

修复：把 `Write+Flush` 整段放进 `_pushLock` 内。更稳的是所有 push 走一个 `BlockingCollection<string>` 队列 + 单一发送线程，调用方只入队，永不阻塞。

## 症结三：阻塞 I/O 压在游戏主线程上

接上条——`OnSeedSignal` 在主线程同步 `server.Write + Flush`。如果 WPF 读得慢或 pipe 缓冲满，这个 write 会**阻塞游戏主线程** → 游戏卡顿/假死。GameStateBus reader 本意是轻量读内存，你在它的回调里做了同步管道 I/O。

修复：push 一律 fire-and-forget（入队，由专门线程发）。主线程的 reader 回调里**只比较值、只入队**，零阻塞。症结二的队列方案同时解决这条。

## 症结四：三套并存的信令机制，外加两条死链路

同一件事"让 WPF 做某动作"，现在有三种通道，而且有的是死的：

| 动作              | 通道                                      | 状态                                                        |
| ----------------- | ----------------------------------------- | ----------------------------------------------------------- |
| 开 history        | `ui_requested` 文件 → FlagPollLoop → push | 活                                                          |
| 开 seed           | `_bh_seed_request` → GameStateBus → push  | 活                                                          |
| 开 seed（旧）     | `flag_seed` 文件 → `_seedFlagPath`        | **死：`_seedFlagPath` 声明了但 FlagPollLoop 从不检查它**    |
| `--seed` 启动模式 | App.xaml.cs 的 isSeedMode 分支            | **死：GamePipeServer 的 `LaunchUiProcess` 从不传 `--seed`** |
| seed 状态回传     | push `seed_updated`                       | **半死：WPF `case "seed_updated": break;` 空处理**          |

死链路本身不报错，但它们让任何人（包括你和后端）**读不懂真实控制流**——这正是"状态切换有问题"反复出现却定位不到的元凶。建议：history 也统一走 push（你已经有 push pipe 了），删掉 flag 文件机制、`_seedFlagPath`、`--seed` 分支、`seed_updated` 空 case。一条 GDScript→C#（GameStateBus 状态差）+ 一条 C#→WPF（push 队列），就两条，全双工。

## 症结五：Mod.cs 的注释在说谎（直接威胁你的 RNG 确定性工作）

```csharp
_modInterface.RegisterSourceMod(new ItemRngSourceMod());
_modInterface.RegisterSourceMod(new ReelExtraRngSourceMod());
_modInterface.RegisterSourceMod(new LandlordRngRefSourceMod());
_modInterface.RegisterSourceMod(new CosmeticRngSourceMod());
// _modInterface.RegisterSourceMod(new ItemRngSourceMod());
// Reel extras — DISABLED
// _modInterface.RegisterSourceMod(new ReelExtraRngSourceMod());
// FinePrintRNG — DISABLED
// _modInterface.RegisterSourceMod(new LandlordRngRefSourceMod());
// CosmeticRNG — DISABLED
// _modInterface.RegisterSourceMod(new CosmeticRngSourceMod());
```

上面**全部已注册启用**，下面的"DISABLED"注释是过期的、骗人的。你前几轮反复在追"哪些 SourceMod 是活的"来判断 RNG 流隔离——而这里代码和注释直接矛盾。任何依据这段注释做的判断都是错的。立刻清掉假注释，让注册列表成为唯一真相。

## 症结六：两个 SourceMod 往 Main.tscn::1 追加，符号耦合 + `_notification` 冲突风险

`RngInfrastructureSourceMod` 注入的代码里有：

```gdscript
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0 and not _bh_run_ended:
            _bh_end_run("quit")
```

`_bh_events` / `_bh_run_ended` / `_bh_end_run` 都不是这个 SourceMod 定义的——是 `MainScriptSourceMod` 定义的。两个 mod 往同一脚本追加，形成隐式跨 mod 依赖。更危险的是：**如果 `MainScriptSourceMod` 也定义了 `_notification`，你会得到"function already exists"编译错误**（你之前 B1/B3 反复栽的那类）。`_notification` 是 Godot 唯一入口，两处都想用就一定撞。

建议：往 Main.tscn::1 追加的所有内容合并进**一个** SourceMod，或者约定一个"唯一 `_notification` 分发器"，其它逻辑挂成被它调用的 `_bh_*` 函数。RNG 基础设施里塞 run-end 逻辑本身也是职责错位——它应该回到 MainScriptSourceMod。

## 症结七：UI 生命周期挂在 draw() 上（你已经痛过）

`_bh_draw_seed_ui` / `_bh_position_seed_ui` / `_bh_update_seed_visibility` 全靠 `draw()` Postfix 驱动，draw() 不是稳定每帧钩子。你用 Timer 打了补丁（对的方向），但创建、定位、可见性还吊在 draw() 上。`_bh_update_seed_button_text` 还从三处被调（draw 尾、timer、floor 进入），互相冗余。

更干净的模型：注入一个**自带 `_process` 的独立节点**（或复用 Timer 节点把全部刷新逻辑收拢进 timeout 回调），让按钮的创建/定位/可见性/文字都由这一个稳定 tick 源驱动，彻底脱离 draw()。状态权威只留 `seed_config.json` 一个。

---

## 优先级建议

能立刻消掉你报告症状的，是 **一、二、三**：

1. `_prevValue` 改成"投递成功才推进" → 丢点击和冷启动延迟当场消失。
2. push 走单线程队列 + Write 入锁 → 消除并发写损坏和主线程阻塞（二、三一起解决）。

能止住"反复定位不到"的，是 **四、五、六**：删死链路、修假注释、合并 Main 注入。这些不改行为，但让系统**可推理**——你之所以一直在打地鼠，很大程度是因为控制流里有三套机制和一堆谎言注释，没人能一眼看清真相。

我可以先帮你把症结一+二+三合并成一个改动（SeedSignalReader 改 try-push + GamePipeServer 加 push 队列），这是收益最高、风险最低的一刀。要的话我直接给这两个文件的完整改法。先从这个动手，还是你想先清四/五的死代码和假注释让全局变清晰？

ChatGPT 的总诊断方向对：**没有统一真相源，四套机制互相推导 → 时序必然出问题。** 但他有一处关键结论在你这个框架下是错的，先纠正，否则你按他说的重构会撞墙。

## 先纠正一处：json 不能删，它是唯一的 C#→GDScript 通道

ChatGPT 说"别让 Godot 读 json，运行时只认一个内存变量，GamePipeServer 持有唯一真相源，所有人读它"。这在单进程里成立，但你这是**跨进程**，而且你的框架通道是单向的：

- GDScript → C#：GameStateBus（只读 GDScript 内存）
- C# → WPF：push pipe
- WPF → C#：request pipe
- **C# → GDScript：没有直接通道，只有文件**

GDScript（按钮 + RNG）**没法读 C# 内存**。seed 值要从 WPF（经 C#）回到游戏的 RNG，**唯一的路就是 json 文件**。所以 `_bh_get_seed_config()` 读 json 是必需且正确的。

正确结论不是"删 json"，而是：**让 json 成为唯一真相源——单一写者（C#），多个读者（按钮 + RNG），且永不被删、原子写。** 你之前"进 floor 删 json""半读到坏 JSON 闪 OFF"都是违反了这条。

## 必须区分两件被混在一起的事

你和 ChatGPT 都把它们揉成了"一个状态机"，但它们性质不同，要分开做robust：

|                             | 性质     | 通道                  | 真相源           |
| --------------------------- | -------- | --------------------- | ---------------- |
| **A. "点了按钮，开窗"**     | 瞬时信号 | GDScript→C#→WPF       | 收敛计数器       |
| **B. "当前种子配置是什么"** | 持久状态 | C#写 json，GDScript读 | seed_config.json |

A 是命令，B 是配置。把 A 做成**收敛状态**（不是 fire-and-forget 事件），把 B 收敛到**单写者 json**。这才是真正消除时序问题的模型。

---

# 实施书

## 目标架构：两条通道 + 收敛状态

```
信号 A（开窗）:  GDScript 单调计数器 _bh_*_request_seq
                 → GameStateBus 每帧读
                 → C# pending counter
                 → push 线程：pending != acked 时发送，成功才 acked
                 → WPF
   关键性质：投递成功才 acked。WPF 冷启动/重连后自动补发。丢不掉。

状态 B（种子）:  WPF set_seed → request pipe
                 → C# 原子写 seed_config.json （唯一写者）
                 → GDScript 单一 Timer 读 json → 按钮显示
                 → new_game 读同一 json → RNG
   关键性质：json 是唯一真相源，单写者，原子写，永不删。
```

push 全部由**一个线程**发送 → 无并发写。reader 回调**只更新 long、零 I/O** → 不阻塞主线程。

---

## 改动 A：SeedSignalReader.cs — 收敛计数器，双信号

```csharp
using GDWeave.GameState;
using GDWeave.NativeInterop;

namespace Piraeus.BetterHistoryMod.Ipc;

public class SeedSignalReader : IGameStateReader
{
    private long _prevSeed;
    private long _prevHistory;

    // 主线程每帧调用这两个回调，回调里只更新 long，绝不阻塞
    public Action<long>? OnSeedSeq;
    public Action<long>? OnHistorySeq;

    public void Read(EngineObjectReader reader, IntPtr sceneTree, GameStateSnapshot snap)
    {
        var node = reader.FindNode("Main/Title");
        if (node == IntPtr.Zero) return;

        long seed = ToLong(EngineObjectReader.ReadScriptProp(node, "_bh_seed_request_seq"));
        long hist = ToLong(EngineObjectReader.ReadScriptProp(node, "_bh_history_request_seq"));

        // 只在变化时通知；忽略 0（GDScript reload 会把变量重置为 0，避免幽灵触发）
        if (seed != _prevSeed) { _prevSeed = seed; if (seed > 0) OnSeedSeq?.Invoke(seed); }
        if (hist != _prevHistory) { _prevHistory = hist; if (hist > 0) OnHistorySeq?.Invoke(hist); }
    }

    private static long ToLong(object? v) => v switch
    {
        long l => l,
        int i => i,
        _ => 0
    };
}
```

## 改动 B：GamePipeServer.cs — pending/acked + 单线程 push + 原子写，删 flag 机制

替换 push 相关全部逻辑：

```csharp
// ── 收敛状态：reader 更新 pending，push 线程更新 acked ──
private long _pendingSeedSeq, _ackedSeedSeq;
private long _pendingHistorySeq, _ackedHistorySeq;
private readonly AutoResetEvent _pushWake = new(false);

// reader 回调（主线程）— 只更新值 + 唤醒，零 I/O、零阻塞
public void SignalSeedSeq(long seq)
{
    Interlocked.Exchange(ref _pendingSeedSeq, seq);
    _pushWake.Set();
}
public void SignalHistorySeq(long seq)
{
    Interlocked.Exchange(ref _pendingHistorySeq, seq);
    _pushWake.Set();
}

// 唯一的 push 发送线程 — 所有 Write 都在这里，无并发
private void PushLoop()
{
    while (!_cts.IsCancellationRequested)
    {
        NamedPipeServerStream? server = null;
        try
        {
            server = new NamedPipeServerStream(PushPipeName, PipeDirection.Out, 1,
                PipeTransmissionMode.Byte, PipeOptions.None);

            _logger.Information("[Push] Waiting for WPF...");
            server.WaitForConnection();
            _logger.Information("[Push] WPF connected");

            // 连上后立即进入收敛循环：pending != acked 就发，发成功才 ack
            // 这一步天然实现冷启动/重连后的自动补发
            while (!_cts.IsCancellationRequested && server.IsConnected)
            {
                long ps = Interlocked.Read(ref _pendingSeedSeq);
                if (ps != _ackedSeedSeq)
                {
                    if (!TryWrite(server, "{\"type\":\"seed_request\"}")) break;
                    _ackedSeedSeq = ps;
                    _logger.Information("[Push] seed_request delivered (seq={Seq})", ps);
                }

                long ph = Interlocked.Read(ref _pendingHistorySeq);
                if (ph != _ackedHistorySf (!TryWrite(server, "{\"type\":\"show_history  _ackedHistorySeq = ph;
                    _logger.Information("[Push] show_history delivered (seq={Seq})", ph);
                }

                _pushWake.WaitOne(250); // 新信号或超时唤醒
            }
        }
        catch (Exception ex) { _logger.Information("[Push] {Msg}", ex.Message); }
        finally { try { server?.Dispose(); } catch { } }

        if (!_cts.IsCancellationRequested) Thread.Sleep(200);
    }
}

private bool TryWrite(NamedPipeServerStream s, string msg)
{
    try
    {
        var b = System.Text.Encoding.UTF8.GetBytes(msg + "\n");
        s.Write(b, 0, b.Length);
        s.Flush();
        return true;
    }
    catch { return false; }
}
```

删除：`PushToClient`、`_pushServer`、`_pushLock`、`_pushBroken`、`FlagPollLoop`、`_flagPollThread`、`_flagFilePath`、`_seedFlagPath`、`OnSeedSignal`。

`Start()` 改为：

```csharp
public void Start()
{
    _serverThread = new Thread(ServerLoop) { Name = "BH-PipeServer", IsBackground = true };
    _serverThread.Start();

    _pushThread = new Thread(PushLoop) { Name = "BH-PushServer", IsBackground = true };
    _pushThread.Start();

    SeedReader.OnSeedSeq = SignalSeedSeq;
    SeedReader.OnHistorySeq = SignalHistorySeq;

    LaunchUiProcess();   // mod 加载即预热 WPF，冷启动藏进菜单导航期
    _logger.Information("[PipeServer] Started");
}
```

set_seed handler 改**原子写**，并**删掉那条跨线程 push**（按钮读 json，不需要 push）：

```csharp
case PipeProtocol.TypeSetSeed:
    var setSeed = PipeProtocol.Deserialize<SetSeedMessage>(req);
    if (setSeed != null)
    {
        var seedPath = Path.Combine(_store.HistoryDir, "seed_config.json");
        var seedType = string.IsNullOrEmpty(setSeed.Input) ? "random" : "custom";
        var json = System.Text.Json.JsonSerializer.Serialize(new {
            type = seedType, input = setSeed.Input,
            updated_at = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss")
        });
        // 原子写：写 .tmp 再 rename，杜绝 GDScript 读到半写文件 → 闪 OFF
        var tmp = seedPath + ".tmp";
        File.WriteAllText(tmp, json);
        File.Move(tmp, seedPath, overwrite: true);
        _logger.Information("[PipeServer] Seed saved: {Seed}", setSeed.Input);
        // 不再 push seed_updated —— 按钮通过 json 自己刷新
    }
    response = PipeProtocol.Serialize(new { status = "ok" });
    break;
```

`Dispose()` 解订阅：

```csharp
public void Dispose()
{
    SeedReader.OnSeedSeq = null;
    SeedReader.OnHistorySeq = null;
    _cts.Cancel();
    _pushWake.Set();   // 唤醒 push 线程让它退出
    _cts.Dispose();
}
```

## 改动 C：TitleSeedSourceMod（GDScript）— 计数器 + 单 Timer + 缓存读

```gdscript
var _bh_custom_seed_btn = null
var _bh_seed_btn_created = false
var _bh_seed_request_seq = 0       # 单调计数器，替代 timestamp
var _bh_history_request_seq = 0    # 历史按钮也走这里（替代 ui_requested 文件）
var _bh_seed_timer = null
var _bh_last_seed_state = {'active': false, 'input': ''}  # 缓存，防瞬时读失败闪烁

func _bh_read_seed_config():
    var file = File.new()
    var path = "user://betterHistory/seed_config.json"
    if file.file_exists(path):
        if file.open(path, File.READ) == OK:
            var text = file.get_as_text()
            file.close()
            var parsed = JSON.parse(text)
            if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
                var cfg = parsed.result
                if cfg.get('type', '') == 'custom':
                    var input = str(cfg.get('input', ''))
                    if input.length() > 0:
                        _bh_last_seed_state = {'active': true, 'input': input}
                        return _bh_last_seed_state
                _bh_last_seed_state = {'active': false, 'input': ''}
                return _bh_last_seed_state
    # 文件不存在或解析失败：返回上次已知状态，不闪烁
    return _bh_last_seed_state

# 按钮点击 —— 只递增计数器（不再用 timestamp）
func _bh_open_custom_seed():
    _bh_seed_request_seq += 1

# 单一 UI tick 源：创建一次后，可见性/文字/位置全在这里更新
func _bh_on_seed_timer():
    if not _bh_seed_btn_created or _bh_custom_seed_btn == null:
        return
    # 可见性
    var on_floor = $"/root/Main".current_menu_path == "floor_menu"
    _bh_custom_seed_btn.visible = on_floor
    if not on_floor:
        return
    # 位置
    var opt = $"/root/Main/Options Sprite/Options"
    _bh_custom_seed_btn.rect_position = Vector2(opt.resolution_x / 2 + 80, opt.resolution_y - 70)
    _bh_custom_seed_btn.rect_size = Vector2(160, 30)
    _bh_custom_seed_btn.rect_scale = Vector2(1.1, 1.1)
    # 文字（唯一写者）
    var cfg = _bh_read_seed_config()
    var want = 'Seed: ON' if cfg.active else 'Seed: OFF'
    if _bh_custom_seed_btn.text != want:
        _bh_custom_seed_btn.text = want
        if cfg.active:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.4, 1.0, 0.5, 1))
        else:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))
        _bh_custom_seed_btn.update()

# draw() Postfix 只做一次性 bootstrap（创建按钮 + 启动 Timer）
func _bh_draw_seed_ui():
    if _bh_seed_btn_created:
        return
    _bh_custom_seed_btn = Button.new()
    _bh_custom_seed_btn.name = 'BHCustomSeed'
    _bh_custom_seed_btn.text = 'Seed: OFF'
    # ... (StyleBox 设置保持原样) ...
    _bh_custom_seed_btn.connect('pressed', self, '_bh_open_custom_seed')
    add_child(_bh_custom_seed_btn)

    _bh_seed_timer = Timer.new()
    _bh_seed_timer.name = 'BHSeedTimer'
    _bh_seed_timer.wait_time = 0.3
    _bh_seed_timer.one_shot = false
    _bh_seed_timer.connect('timeout', self, '_bh_on_seed_timer')
    add_child(_bh_seed_timer)
    _bh_seed_timer.start()

    _bh_seed_btn_created = true

func _bh_get_seed_config():
    var cfg = _bh_read_seed_config()
    if cfg.active:
        return {'type': 'custom', 'input': cfg.input.replace('O','0').replace('I','1')}
    return {'type': 'random', 'input': ''}
```

删除：`_bh_update_seed_button_text`、`_bh_position_seed_ui`、`_bh_update_seed_visibility`、`_bh_prev_on_floor`，以及 `_bh_update_seed_visibility` 里那两个没用的 `var file`/`var path`。

`TitleDrawSeedPatch.Postfix` 简化为只调一个：

```csharp
if $"/root/Main/Title".has_method("_bh_draw_seed_ui"):
    $"/root/Main/Title"._bh_draw_seed_ui()
```

删掉 `FloorMenuSeedPatch`（可见性现在由 Timer 处理）。

## 改动 D：历史按钮改走计数器

历史按钮当前写 `ui_requested` 文件（在 `TitleToggleSourceMod` / `HistoryButtonPatch` 里，你没贴）。改成：

```gdscript
func _bh_toggle_ui():
    _bh_history_request_seq += 1
```

删掉写 `ui_requested` 文件那行。reader 已经在读 `_bh_history_request_seq`，C# 自动 push `show_history`。

> 把 `TitleToggleSourceMod.cs` / `HistoryButtonPatch.cs` 发我，我对着改精确的那一行。

## 改动 E：Mod.cs — 删假注释 + 解订阅

注册块清掉所有矛盾的 "DISABLED" 注释和重复行，让它成为唯一真相。`Dispose`：

```csharp
public void Dispose()
{
    if (_pipeServer != null)
    {
        _modInterface.UnregisterGameStateReader(_pipeServer.SeedReader);
        _pipeServer.Dispose();
    }
    _modInterface.Logger.Information("[BetterHistoryMod] unloaded.");
}
```

## 改动 F：App.xaml.cs — 删 `--seed` 死分支

`LaunchUiProcess` 从不传 `--seed`，整个 isSeedMode 分支是死代码：

```csharp
protected override void OnStartup(StartupEventArgs e)
{
    for (int i = 0; i < e.Args.Length; i++)
        if (e.Args[i] == "--data-dir" && i + 1 < e.Args.Length)
            DataDir = e.Args[i + 1];

    base.OnStartup(e);
    // ... 异常处理保持 ...

    ShutdownMode = ShutdownMode.OnExplicitShutdown;
    var mainWindow = new MainWindow();
    MainWindow = mainWindow;
    mainWindow.ConnectPipe();   // 常驻，不 Show
}
```

`SeedDialog` 的 `--seed` 独立启动路径删掉；它现在只由 MainWindow 收到 push 后弹出。

## 改动 G：WPF MainWindow — 删 seed_updated 死 case

```csharp
case "seed_request":  ShowSeedDialog(); break;
case "show_history":  ShowFromTray();   break;
// seed_updated / push_connected 删除
```

---

## 删除清单（让系统可推理）

- `flag_seed` 文件 + `_seedFlagPath`
- `ui_requested` 文件 + `_flagFilePath` + `FlagPollLoop` + `_flagPollThread`
- `PushToClient` / `_pushServer` / `_pushLock` / `_pushBroken`（被 PushLoop 单线程取代）
- App.xaml.cs `--seed` / isSeedMode
- WPF `seed_updated`、`push_connected` case
- GDScript `_bh_update_seed_button_text` / `_bh_position_seed_ui` / `_bh_update_seed_visibility` / `_bh_prev_on_floor`
- `FloorMenuSeedPatch`
- set_seed handler 里的 seed_updated push
- Mod.cs 全部假 "DISABLED" 注释

剩下：**一条 GDScript→C#（GameStateBus 收敛计数器）+ 一条 C#→WPF（单线程 push）+ 一个真相源（seed_config.json，单写者原子写）**。

---

## 验证协议

1. **冷启动丢点击**：游戏一进 floor menu 立刻狂点 seed 按钮（WPF 还没连）→ WPF 连上后必须弹出 dialog（pending!=acked 自动补发）。点 N 次只弹一次。
2. **闪 OFF**：设种子后反复进出 floor menu → 按钮稳定 ON，不闪。
3. **WPF 杀掉重启**：任务管理器杀 WPF，点 history 按钮 → WPF 重启并自动连上 push → 窗口出现。
4. **状态一致性**：设种子 X → 按钮 ON → 开新 run → 验证 RNG 用的是 X（同 seed 两局一致）。
5. **并发写**：连续快速 set_seed 多次 → GDScript 读到的 json 始终是完整合法 JSON（原子写保证）。
6. **热重载**（若 GDWeave 支持）：reload mod → 不重复弹窗（解订阅 + 忽略 seq=0 保证）。

---

要我先落地哪一块？建议顺序：**B + A 一起改**（push 收敛模型，收益最高、当场消掉丢点击和冷启动），再 **C**（GDScript 单 tick），最后 D/E/F/G 清死代码。把 `TitleToggleSourceMod.cs` 和 `HistoryButtonPatch.cs` 发我，我把 D 那条精确接上。