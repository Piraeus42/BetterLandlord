# Better Landlord

*Luck be a Landlord* 全方位游戏体验增强 Mod。运行于 [SlotWeave](https://github.com/Piraeus42/SlotWeave) 框架。

---

## 功能

### 结构化对局历史
- 每局自动保存完整 JSON 记录：每次 spin 的硬币变化、符号选择、道具获取/摧毁、租金周期
- 时间线回放查看器（WPF UI）——spin-by-spin 复盘
- 历史数据目录：`%AppData%/Godot/app_userdata/Luck be a Landlord/betterHistory/`

### DPT 统计分析
- **Total Value** — 符号整局产生的总硬币
- **DPT (实际)** — 总硬币 / 存在回合数（含未上屏回合）
- **DPT (有效)** — 总硬币 / 实际贡献回合数（仅上屏回合）
- 储物间快照：符号、道具、摧毁/移除记录、Fine Print

### 种子系统
- **Random** — 基于 OS 熵生成不可预测的种子
- **Custom** — 手动输入种子字符串，可复现对局
- 20 条独立 PCG RNG 流，全链路确定性
- 种子对局自动从原生统计和 Steam 成就中排除
- 胜率统计（50/100/200 场滑动窗口 + 总胜率），种子局不计入

### 游戏体验
- Continue 支持（冷启动 Continue + warm Continue）——RNG 状态精确恢复
- 断头台 / 中途退出 / 强退 / Victory 后继续 ——全部正确处理
- 对局可标记为 Quit（非 Defeat）

---

## 安装

1. 确保已安装 **SlotWeave**（`winmm.dll` 在游戏根目录，`SlotWeave/` 目录就位）
2. 将本 Mod 文件夹放入 `SlotWeave/mods/Piraeus.BetterLandlord/`
3. 启动游戏

```
Luck be a Landlord/
├── Luck be a Landlord.exe
├── winmm.dll
└── SlotWeave/
    ├── core/
    └── mods/
        └── Piraeus.BetterLandlord/
            ├── manifest.json
            ├── Piraeus.BetterLandlord.dll
            ├── Piraeus.BetterLandlord.UI.dll
            ├── Piraeus.BetterLandlord.UI.exe
            └── Piraeus.BetterLandlord.UI.runtimeconfig.json
```

---

## 使用

### WPF 时间线查看器
游戏运行时自动启动（隐藏窗口）。点击游戏标题界面的 **History** 按钮即可打开。

- 左侧：对局列表（显示结果、硬币、Top 3 符号图标）
- 右侧：spin-by-spin 时间线 + DPT 排名
- 底栏：胜率统计

### 种子输入
Title 界面的种子输入框支持手动输入 10 位种子码。选中 Custom Seed 锁定图标后生效。

---

## 构建

```bash
dotnet build Piraeus.BetterLandlord.sln -c Release
```

输出到 `SlotWeave/mods/Piraeus.BetterLandlord/`。

调试启动：`run-lbl-debug.bat`（控制台 + dump 脚本 + 无缓存）。

---

## 架构

```
C# Mod DLL (Piraeus.BetterLandlord.dll)
├── ISourceMod × 15    — GDScript 源码注入（RNG 替换、事件采集、种子 UI）
├── [Patch] × 16       — 运行时 Prefix/Postfix（spin、write_log、title、save...）
├── GameStateBus       — 帧级内存直读（种子序列号变更检测）
├── PipeServer         — Named Pipe IPC → WPF UI
└── HistoryStore       — JSON 读写 + manifest 管理

WPF UI (Piraeus.BetterLandlord.UI.exe)
├── UiPipeClient       — Pipe 客户端
├── HistoryViewModel   — 数据绑定 + 胜率计算
└── IconConverter      — 内嵌资源图标加载（854 图标编译进 DLL）
```

### RNG 架构
```
landlord_seed (FNV-1a hash of seed string)
  ├── _bh_derive_seed(seed, 'sym_rarity') → PCGRng → 符号稀有度选择
  ├── _bh_derive_seed(seed, 'sym_common') → PCGRng → 普通符号选择
  ├── _bh_derive_seed(seed, 'sym_uncommon') → PCGRng
  ├── ... (20 streams total)
  └── Per-spin: _bh_derive_seed(seed, 'spin_N') → reel/effect/scratch RNG
```

---

## 常见问题

| 问题 | 答案 |
|------|------|
| 历史数据在哪 | `%AppData%/Godot/app_userdata/Luck be a Landlord/betterHistory/runs/` |
| WPF 窗口不出现 | 点游戏里的 History 按钮；如果还没出现，检查 `SlotWeave.log` |
| 种子对局影响成就吗 | 不影响——种子局已从原生统计和 Steam 成就中排除 |
| 卸载后数据还在吗 | 是的，JSON 文件不会自动删除。可手动删除 `betterHistory/` 目录 |
