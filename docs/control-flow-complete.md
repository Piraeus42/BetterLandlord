# BetterHistoryMod — 完整控制流 (游戏原生 + Mod 植入点)

## 路径 A: 游戏冷启动 → 主菜单

```
Main._ready()                                  ┃ Main.tscn::1:324
  ├─ _initialize_Steam()
  ├─ load_game()                               ┃ 从 LBAL.save 恢复 Persist 节点
  ├─ load_options() / load_stats()
  └─ title()                                   ┃ Main.tscn::1:403
       └─ [ReadyPatch POSTFIX]                 ┃ ReadyPatch.cs:10-13
            └─ _bh_init()                      ┃ 清 _bh_events, 设 _bh_run_id
                                                 ┃ ⚠️ 不初始化 RNG
       └─ [TitlePatch PREFIX]                  ┃ TitlePatch.cs:14-19
            ├─ if _bh_events.size > 0:
            │    _bh_end_run("quit")            ┃ flush 残留 run 到 JSON
            └─ _bh_start_run()                 ┃ 清 events, 设 run_id
                                                 ┃ ⚠️ 不再初始化 RNG（已移除）

       └─ Title.draw()                         ┃ Main.tscn::6:187
            └─ [TitleDrawSeedPatch POSTFIX]    ┃ TitleDrawSeedPatch.cs:14-16
                 └─ _bh_draw_seed_ui()         ┃ 一次性: 创建 Seed 按钮 + Timer
            └─ [HistoryButtonPatch POSTFIX]    ┃ HistoryButtonPatch.cs:14-33
                 └─ 创建 "History" TTButton

       └─ Title._bh_seed_timer (0.3s loop)     ┃ Timer → _bh_on_seed_timer()
            └─ 轮询 seed_config.json
            └─ 更新按钮可见性 / 位置 / 文字 / 颜色
```

## 路径 B: New Game（标准）

```
玩家点 "New Game" → floor 选择
  └─ Title.floor_menu()                        ┃ Main.tscn::6:578
       └─ [MenuPathChangedPatch POSTFIX]       ┃ MenuPathChangedPatch.cs:12-13
            └─ _bh_refresh_seed_visibility()   ┃ 按钮立即显示 (零延迟)
       └─ Title.set_floor(fl)                  ┃ 玩家选楼层
            └─ 设 Title.temp_floor = fl

  └─ Main.new_game()                           ┃ Main.tscn::1:1546
       └─ [TitleSetFloorPatch PREFIX]          ┃ TitleSetFloorPatch.cs:12-21
            ├─ _bh_apply_seed()                ┃ RngInfra:236
            │    └─ Title._bh_get_seed_config()
            │    │    └─ 读 seed_config.json
            │    │       ├─ custom → {type:'custom', input:'ABC123'}
            │    │       └─ random → {type:'random', input:''}
            │    └─ _bh_init_rng(type, input)
            │         ├─ 若 random/空: 生成随机种子串
            │         ├─ 创建 19 个 PCGRng 实例
            │         ├─ 原子赋值到 _bh_rng_*
            │         └─ seed(landlord_seed) ─── 同步 Godot 全局 RNG
            └─ _bh_add_event("run_start", ...) ┃ 记录 run 开始事件

       └─ reset_values()                       ┃ 重置 Reels/Items/Popup 状态
       └─ Title.remove()                       ┃ 移除 Title UI 节点
       └─ Reels.load_base_icons()
       └─ Items.load_items()
       └─ Pop-up 初始事件 (intro email 等)
       └─ change_current_menu_path("slots")    ┃ 进入游戏
```

## 路径 C: Continue Game（精确恢复）

```
游戏冷启动 → title (同路径 A)

玩家点 "Continue"
  └─ Main.continue_game()                      ┃ Main.tscn::1:1670
       ├─ if $"Pop-up".spins > 0:              ┃ 有存档
       │    ├─ load_data(false, true, true)     ┃ 从 LBAL.save 恢复 Persist 节点
       │    │    └─ Pop-up.total_runs 恢复
       │    │    └─ Pop-up.spins 恢复
       │    │    └─ Coins.coins 恢复
       │    │    └─ Reels / Items 状态恢复
       │    └─ load_mods()
       │
       └─ [ContinueGamePatch POSTFIX]           ┃ 在 load_data 之后执行
            └─ if spins > 0:
                 _bh_restore_rng_state()        ┃ RngInfra (新增)
                      ├─ 读 rng_state.json
                      ├─ 指纹校验: total_runs+spins+coins 三联比对
                      │    └─ 不匹配 → return false (拒绝恢复)
                      ├─ 恢复 _bh_rng_seed_type/input/landlord_seed
                      ├─ _bh_make_rng_from() × 19
                      │    └─ PCGRng.new(0) → 直接覆写 .state / .inc
                      │       ⚠️ 绕过 _init, 保证流位置精确
                      └─ seed(landlord_seed)

       └─ Title.remove()
       └─ Reels / Items 恢复
       └─ write_log("--- CONTINUING RUN #... ---")
```

## 路径 D: 游戏中期 — Spin 循环

```
玩家点 Spin
  └─ Main.spin()                                ┃ Main.tscn::4 (Reels 脚本)
       └─ [SpinPatch PREFIX]                    ┃ SpinPatch.cs:14-42
            ├─ 检查 spin 能否执行 (同原生 guard)
            │    └─ effects_playing / emails / coins<=0 / HP adding...
            ├─ if _can_spin:
            │    ├─ _bh_begin_spin_rng()         ┃ 从 _bh_rng_spin 派生本 spin 的
            │    │    │                          ┃ reel/effect/scratch RNG
            │    │    └─ if _bh_rng_spin==null:  ┃ 安全网: 兜底随机初始化
            │    │         _bh_init_rng('random','')
            │    └─ _bh_add_event("spin_start", {
            │         spin_num, coins, floor, rent_paid
            │       })

       └─ 原生 Reel 旋转 / Symbol 选择 ...
            └─ 各 RNG SourceMod 的替换函数
                 ├─ ReelRngRefSourceMod   → 替代 reel shuffle
                 ├─ SlotIconRngSourceMod  → 替代 icon 选择
                 ├─ ItemRngSourceMod      → 替代 item 选择
                 ├─ ChoiceRngSourceMod    → 替代 choice RNG
                 ├─ CosmeticRngSourceMod  → 替代 cosmetic RNG
                 └─ LandlordRngRefSourceMod → 替代 fine print RNG
                 (全部读 _bh_rng_* 实例, 不用 Godot 全局 RNG)

       └─ [BoardValuePatch POSTFIX]             ┃ BoardValuePatch.cs:14-39
            └─ _bh_add_event("board_value", {
                 spin_num, values: [{id, value, badge_*}]
               })

       └─ [WriteLogPatch PREFIX]                ┃ WriteLogPatch.cs:10-43
            ├─ "Coin total is now X" → spin_end 事件
            ├─ "Added item: X"       → item_added 事件
            ├─ "Destroyed item - X"  → item_destroyed 事件
            ├─ "VICTORY"             → _bh_end_run("victory")
            └─ "GAME OVER"           → _bh_end_run("loss")

  └─ Pop-up.update_rent_values()                ┃ Pop-up.tscn::1:2766
       └─ [RentUpdatePatch POSTFIX]             ┃ RentUpdatePatch.cs:13-21
            └─ _bh_add_event("rent_updated", {
                 rent_0, rent_1, times_rent_paid, floor
               })
```

## 路径 E: 游戏存档

```
触发时机: 退出到主菜单 / 过 floor / 游戏自动存档

  └─ Main.save_game()                           ┃ Main.tscn::1:1895
       ├─ 遍历 Persist group 节点
       ├─ 对每个节点调 node.save() → to_json → 写 LBAL.save
       │
       └─ [SaveGamePatch POSTFIX]                ┃ SaveGamePatch.cs:13-16 (新建)
            └─ if not sandbox_mode:
                 _bh_save_rng_state()            ┃ RngInfra (新增)
                      ├─ if _bh_rng_spin == null: return
                      ├─ 写 rng_state.json:
                      │    {
                      │      version: 1,
                      │      seed_type/input/landlord_seed,
                      │      fingerprint: {total_runs, spins, coins},
                      │      streams: {
                      │        spin:      [str(state), str(inc)],
                      │        rarity:    [str(state), str(inc)],
                      │        ... (共 19 条, state/inc 存字符串)
                      │      }
                      │    }
                      └─ 关闭文件
```

## 路径 F: 游戏结束

### F1: 正常结束 (Victory / Loss)

```
write_log("VICTORY") 或 "GAME OVER"
  └─ [WriteLogPatch PREFIX]
       └─ _bh_end_run("victory") 或 _bh_end_run("loss")
            ├─ 检查 _has_spins (过滤幽灵 run)
            ├─ 从 Reels / Items 采集 final state
            ├─ _bh_add_event("run_end", {result, floor, coins,
            │    final_symbols, final_items, run_number,
            │    seed_type, seed_input, landlord_seed})
            └─ _bh_flush()
                 ├─ Phase 1:    构建 spin frames
                 ├─ Phase 1.5:  收集 rent_updated → 实际租金表
                 ├─ Phase 2:    构建 rent_cycles (用实际租金)
                 ├─ Phase 2.5:  抽取 item end_actions
                 ├─ Phase 3:    构建 meta
                 ├─ Phase 4:    构建 summary (含 DPT)
                 └─ Phase 5:    写 JSON → runs/{run_id}.json
```

### F2: 断头台结束 (Guillotine Essence Death)

```
guillotine_essence_anim == 600
  └─ [GuillotineEndPatch PREFIX]                ┃ GuillotineEndPatch.cs:17-22
       └─ if not _bh_run_ended and events.size > 1:
            _bh_end_run("victory")               ┃ flush 在 reset 前完成

  ... 600 frames later ...
  └─ reset_values() → title()
```

### F3: 窗口关闭 / 退出 (Quit)

```
Godot NOTIFICATION_WM_QUIT_REQUEST (1006)
  └─ _notification(what: 1006)                  ┃ RngInfra:249-252
       └─ if events.size > 0 and not _bh_run_ended:
            _bh_end_run("quit")
  └─ Mod.Dispose()                               ┃ Mod.cs:97-104
       └─ UnregisterGameStateReader
       └─ GamePipeServer.Dispose()
            ├─ SeedReader.OnSeedSeq = null
            ├─ SeedReader.OnHistorySeq = null
            ├─ _cts.Cancel()
            ├─ _pushWake.Set()
            ├─ _uiProcess.Kill()                 ┃ 主动杀 WPF
            ├─ _uiProcess.WaitForExit(2000)
            └─ JobObjectHelper.CloseJob(_jobHandle)
                 └─ OS 兜底杀所有绑定的子进程
```

## 路径 G: IPC 通道 (跨进程)

```
GDScript → C# (GameStateBus):
  ┌─ Title._bh_seed_request_seq += 1              ┃ 用户点 Seed 按钮
  └─ SeedSignalReader.Read()                      ┃ 每帧 (游戏主线程)
       └─ if seedSeq changed: OnSeedSeq?.Invoke(seq)
       └─ if histSeq changed: OnHistorySeq?.Invoke(seq)

C# → WPF (Push pipe):
  ┌─ SignalSeedSeq(seq)
  │    └─ Interlocked.Exchange(ref _pendingSeedSeq, seq)
  │    └─ _pushWake.Set()
  │
  └─ PushLoop (单线程)
       └─ pending != acked → TryWrite("seed_request")
       └─ 成功 → _ackedSeedSeq = pending
       └─ 失败 → 不推进, 下次循环自动重试

WPF → C# (Request pipe):
  ┌─ SeedDialog.Confirm_Click
  └─ UiPipeClient.SendSetSeed(input)
       └─ ServerLoop → set_seed handler
            ├─ 原子写 seed_config.json (.tmp → rename)
            └─ 不 push seed_updated (按钮自己读 json)

C# → GDScript (seed_config.json):
  ┌─ GamePipeServer 原子写 seed_config.json
  └─ Title._bh_seed_timer (0.3s)
       └─ _bh_read_seed_config() → 读文件 → 更新按钮文字/颜色
```

## 注入点完整清单

| 序号 | Patch 类 | Hook 目标 | 时机 | 副作用 |
|------|---------|----------|------|--------|
| 1 | `ReadyPatch` | `_ready()` Postfix | 游戏启动 | _bh_init(): 清 events |
| 2 | `TitlePatch` | `title()` **Prefix** | 进入主菜单 | flush 旧 run + _bh_start_run() |
| 3 | `TitleSetFloorPatch` | `new_game()` **Prefix** | 开始新游戏 | _bh_apply_seed() + run_start event |
| 4 | `ContinueGamePatch` | `continue_game()` **Postfix** | 继续游戏 | _bh_restore_rng_state() (sidecar) |
| 5 | `SaveGamePatch` | `save_game()` **Postfix** | 游戏存档 | _bh_save_rng_state() (sidecar) |
| 6 | `SpinPatch` | `spin()` **Prefix** | 每次 spin | _bh_begin_spin_rng() + spin_start event |
| 7 | `WriteLogPatch` | `write_log()` **Prefix** | 日志写入 | spin_end/item/victory/loss event |
| 8 | `BoardValuePatch` | `check_values()` **Postfix** | Board 评估后 | board_value event |
| 9 | `GuillotineEndPatch` | `_process()` **Prefix** | 断头台动画 | _bh_end_run("victory") |
| 10 | `RentUpdatePatch` | `update_rent_values()` **Postfix** | 租金更新 | rent_updated event |
| 11 | `MenuPathChangedPatch` | `change_current_menu_path()` **Postfix** | 菜单切换 | _bh_refresh_seed_visibility() |
| 12 | `TitleDrawSeedPatch` | `Title.draw()` **Postfix** | Title 绘制 | _bh_draw_seed_ui() (bootstrap) |
| 13 | `HistoryButtonPatch` | `Title.draw()` **Postfix** | Title 绘制 | 创建 History TTButton |

| 序号 | ISourceMod | 注入目标 | 作用 |
|------|-----------|---------|------|
| 14 | `MainScriptSourceMod` | Main.tscn::1 | 事件捕获 (_bh_events, _bh_start_run, _bh_end_run, _bh_flush) |
| 15 | `RngInfrastructureSourceMod` | Main.tscn::1 | PCGRng 类 + 19 实例 + _bh_init_rng + sidecar 持久化 |
| 16 | `TitleSeedSourceMod` | Main.tscn::6 | Seed UI 按钮 + Timer + _bh_get_seed_config |
| 17 | `TitleToggleSourceMod` | Main.tscn::6 | History 计数器 _bh_history_request_seq |
| 18 | `ChoiceRngSourceMod` | Pop-up.tscn::1 | Choice RNG 替换 |
| 19 | `ReelRngRefSourceMod` | Reel.tscn::1 | Reel shuffle RNG 替换 |
| 20 | `SlotIconRngSourceMod` | Slot Icon.tscn::1 | Icon 选择 RNG 替换 |
| 21 | `ItemRngSourceMod` | Item.tscn::1 | Item 选择 RNG 替换 |
| 22 | `ReelExtraRngSourceMod` | Reel.tscn::1 | Reel extras RNG 替换 |
| 23 | `LandlordRngRefSourceMod` | Landlord.tscn::9 | Fine print RNG 替换 |
| 24 | `CosmeticRngSourceMod` | (cosmetic nodes) | Cosmetic RNG 替换 |
| 25 | `ClipboardPreserveMod` | TT Button.tscn::1 | 剪贴板保护 |

| 序号 | 运行时组件 | 作用 |
|------|-----------|------|
| 26 | `SeedSignalReader` | GameStateBus: 每帧读 Title._bh_*_request_seq → push 唤醒 |
| 27 | `GamePipeServer.PushLoop` | 单线程 push: pending/acked 收敛, 零并发写 |
| 28 | `GamePipeServer.ServerLoop` | Request pipe: get_run_list/get_run/set_seed (原子写) |
| 29 | `JobObjectHelper` | WPF 子进程 Job Object: 父进程死 → OS 自动杀 |
| 30 | `UiPipeClient.PushListenerLoop` | WPF 侧: 接收 push → HandlePushMessage |

## 关键时序约束

```
冷启动:
  load_game (恢复 Persist) → ReadyPatch (_bh_init)
  → title() → TitlePatch (_bh_start_run, 不碰 RNG) → Title.draw()

New Game:
  TitleSetFloorPatch (_bh_apply_seed) → new_game → reset_values

Continue:
  continue_game → load_data (恢复 Persist)
  → SaveGamePatch (_bh_save_rng_state) ⚠️ 不在 Continue 路径
  → ContinueGamePatch (_bh_restore_rng_state, 读 sidecar)
  ⚠️ sidecar 的指纹必须与 load_data 恢复的 Persist 一致

Mid-game:
  SpinPatch (spin_start + _bh_begin_spin_rng) → BoardValuePatch (board_value)
  → WriteLogPatch (spin_end/item events)

Save:
  save_game (写 LBAL.save) → SaveGamePatch (_bh_save_rng_state → rng_state.json)
  ⚠️ save_game 和 rng_state.json 原子性不一致:
     如果 save_game 成功但 rng_state.json 写一半, Continue 会指纹不匹配 → 拒绝恢复
     如果 save_game 成功但 rng_state.json 不存在, Continue 返回 false → 走兜底

End:
  WriteLogPatch (victory/loss) or GuillotineEndPatch (guillotine)
  → _bh_end_run → _bh_flush → runs/*.json

Exit:
  _notification(1006) → _bh_end_run("quit")
  → Mod.Dispose → GamePipeServer.Dispose → Kill WPF + CloseJob
```
