BetterHistoryMod v0.1 Alpha - 安装说明
=========================================

=== 系统要求 ===
- Windows 10/11 x64
- .NET 8 Runtime (如果没有，会自动提示下载: https://dotnet.microsoft.com/download/dotnet/8.0)
- Luck be a Landlord (Steam 版, Godot 3.4.4)

=== 安装步骤 ===
1. 解压 zip 到游戏根目录 (和 Luck be a Landlord.exe 同级)
   最终结构:
   Luck be a Landlord/
   ├── winmm.dll              (SlotWeave 注入器)
   ├── SlotWeave/
   │   ├── core/               (SlotWeave 运行时)
   │   └── mods/
   │       └── Piraeus.BetterLandlord/
   │           ├── manifest.json
   │           ├── Piraeus.BetterLandlord.dll
   │           ├── Piraeus.BetterLandlord.UI.exe
   │           └── Assets/Icons/
   └── Luck be a Landlord.exe

2. 启动游戏，到标题画面

3. 点击 "History" 按钮 (在标题画面右下角)

4. BetterHistory 独立窗口弹出，显示你的历史记录

=== 操作方法 ===
- 左侧 Run List: 点击查看不同场次的记录
- 中间/右侧: 储物间 (终局物品) + 收租时间轴
- 按住 ← → 键: 切换 DPT 排名模式
- 鼠标悬停: 符号图标显示详细信息和 DPT 数据

=== 已知问题 (Alpha) ===
- 旧版 run.log 的部分记录可能不完整
- 部分符号角标尚未实现
- UI 有大量空白 (非 Bug，等待实现 More 功能)
- 连续多次快速切换 Run 可能导致数据载入延迟

=== 反馈渠道 ===
遇到 Bug 请记录:
1. 你做了什么操作
2. 弹出的错误窗口截图 (如果有)
3. 游戏目录下 SlotWeave/SlotWeave.log 文件

=== 卸载 ===
删除游戏目录下的:
- winmm.dll
- SlotWeave/ 文件夹
