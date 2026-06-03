# Force-Close 路径控制流追踪 — Run #110

## 场景

玩家打开游戏 → 新开一局 → 玩到一半（4 spins）→ 直接杀进程关闭 → 重新打开游戏 → 看到该局在历史中，标记为 "Defeat"（实际 JSON 为 "quit"）

## 步骤对照表

| # | 操作 | 游戏原生控制流 | Mod 注入点 | 结果 | 期望？ |
|---|------|--------------|-----------|------|--------|
| 1 | 冷启动 | `_ready()` → `load_game()` → `title()` | `ReadyPatch` → `_bh_init()` 清 events，设 `_bh_run_id` | events 空，准备就绪 | ✅ |
| 2 | 点 New Game，选 floor | `new_game()` ×2 | `TitleSetFloorPatch`：floor_selected=true → `_bh_start_run()` → `_bh_apply_seed()` → `_bh_add_event("run_start")` | run_id="1780498368"，seed 应用，events=[run_start] | ✅ |
| 3 | 玩 4 spins | spin→reel→board 循环 | `SpinPatch`、`WriteLogPatch`、`BoardValuePatch` 记录 events；`SaveGamePatch` 周期性写 sidecar + events dump | events 累积，sidecar 随 save 同步 | ✅ |
| 4 | 强杀进程 | 进程终止 | `NOTIFICATION_WM_QUIT_REQUEST (1006)` → `_notification(1006)` → `_bh_end_run("quit")` → `_bh_flush()` → 写 `runs/1780498368.json`，ended_by="quit" | JSON 落盘 ✅ | ✅ |
| 5 | 冷启动 | `_ready()` → `load_game()` → `title()` | `ReadyPatch` → `_bh_init()` 清 events，改 `_bh_run_id` | events 空，旧 run_id 丢失 | ⚠️ 见注1 |
| 6 | WPF History 加载 | pipe → `get_run_list` → parse | `HistoryViewModel` 读 run list | 显示 run #110=Defeat, run #109=Defeat... | ⚠️ 见注2 |
| 7 | 看到 Continue 按钮 | `Pop-up.spins > 0`（LBAL.save 恢复） | — | Continue 可用 | ✅ |
| 8 | 点 Continue | `continue_game()` → `load_data()` | `ContinueGamePatch` → `_bh_restore_rng_state()` → 指纹匹配 → 恢复 19 条流 + `_bh_load_events_for_continue(save_spins)` → truncate 到 save 点 → 回填 events | RNG 精确恢复，events 回填，run_id 恢复为 sidecar 中的 "1780498368" | ✅ |
| 9 | 继续玩 → 结束 | victory/loss | `WriteLogPatch` → `_bh_end_run` → `_bh_flush` 覆盖 JSON | 最终 JSON 覆盖步骤4的 quit 版本 | ✅ |

### 注1: `_bh_init` 覆盖 run_id

步骤5 `_bh_init()` 将 `_bh_run_id` 改为新的时间戳。但步骤8 `_bh_restore_rng_state` 会从 sidecar 恢复为 "1780498368"，所以最终 JSON 路径正确。

**但如果用户不点 Continue，直接点 New Game**：`TitleSetFloorPatch` 会 `_bh_start_run()` 设新 run_id，旧 run 的 events temp 文件成为孤儿（`events_1780498368.json` 不会被清理——`_bh_flush` 只清理当前 `_bh_run_id` 的文件）。需要后续清理逻辑。

### 注2: "quit" 显示为 "Defeat"

UI 层 `FormatEndedBy`：`ended_by == "victory" ? "Victory" : "Defeat"`。  
`"quit" → "Defeat"`, `"loss" → "Defeat"`。

产品层面的判断：force-close 应该显示什么？当前统一归为 "Defeat"，可以接受。如果需要区分 "Quit" 和 "Defeat"，只需改 UI 映射。

## 关键确认

| 检查项 | 状态 |
|--------|------|
| JSON 是否在 force-close 时写入 | ✅ 是（_notification 1006 触发） |
| RNG 在 Continue 后是否一致 | ✅ 是（sidecar 同步 + 指纹校验） |
| events 是否在 Continue 后接续 | ✅ 是（_bh_load_events_for_continue 回填 + truncate） |
| 重复 JSON 问题 | ✅ 已消除（TitlePatch 不再 flush） |
| 重复 events 问题 | ✅ 已消除（truncate 到 save_spins 边界） |
| 幽灵 run 守卫 | ✅ 正确（_has_spins 检查，纯启动不 flush） |
