# BetterHistoryMod — 待办

## ✅ P0：场景进出逻辑

- [x] 删除死文件
- [x] TitleHistoryMenuSourceMod — `history_menu()` 仿照 `stats_menu()` 模式
- [x] HistoryButtonPatch — 主菜单入口
- [x] InitSelectablePatch — 手柄焦点
- [x] Mod.cs 注册

## ✅ P1：事件捕获修复

- [x] flush 路径 `events/` → `runs/`
- [x] `_bh_run_ended` 幂等守卫
- [x] TitlePatch 条件检查

## ✅ P2：UI 配置系统

- [x] `ui_config.json` 读取
- [x] 所有控件参数可配置
- [x] 优先从 mod 目录读取

## ✅ P3：时间线基本显示

- [x] 事件→round 分组 (_bh_build_timeline)
- [x] 租金计算 + coin 图标标签
- [x] 排除符号 (dud)
- [x] rent_pad 数字对齐
- [x] 左右翻页

## ⬜ P4：图标尺寸/间距问题（当前）

- [ ] 确认纹理尺寸假设（对比异常图标的 PNG 文件）
- [ ] 探讨统一缩放的方案
  - 方案 A: 遍历 HoverIcon 子节点，统一设置 rect_scale
  - 方案 B: 回到旧查看器的独立 Label 方案（每个图标独自控制 scale）
  - 方案 C: 修改 HoverIcon 创建逻辑，注入统一的 rect_scale

## ⬜ P5：数据完整性

- [ ] `_bh_end_run()` 构建完整 meta 结构（与 C# RunRecord 对齐）
- [ ] ResolveEventPatch 捕获 `rent_increase`→`rent_paid` 事件
- [ ] 原生捕获兼容 migrated log 的 JSON 结构
