# Better Landlord — Mod 项目指南

## 项目概述

Luck be a Landlord 的 SlotWeave 模组。主要功能：确定性 RNG（固定种子）、跳过已拥有物品序列、运行历史数据库。

## 构建与部署

```bash
# 构建
dotnet build Piraeus.BetterLandlord/Piraeus.BetterLandlord.csproj -c Release

# 部署到游戏
cp Piraeus.BetterLandlord/bin/Release/net8.0/Piraeus.BetterLandlord.dll \
   "D:/steam/steamapps/common/Luck be a Landlord/SlotWeave/mods/Piraeus.BetterLandlord/"
cp Piraeus.BetterLandlord/manifest.json \
   "D:/steam/steamapps/common/Luck be a Landlord/SlotWeave/mods/Piraeus.BetterLandlord/"
```

### 验证注入是否成功

SlotWeave 在**游戏启动时**才重新生成 patched 脚本。部署后必须启动游戏，然后检查：

```
D:\steam\steamapps\common\Luck be a Landlord\SlotWeave\scripts_patched\
```

关键文件：
- `Main.tscn__1.gd` — RNG 基础设施、`_bh_begin_item_pick_event` 等函数
- `Pop-up.tscn__1.gd` — ChoiceRng 注入点、`_bh_c_pick_item` 等函数

### 原始游戏源码

项目根目录 `game_source_code/` 包含反编译的游戏 GDScript，用于核对原始缩进和行号。**源码使用真实 tab 字符（`\t`）缩进。** 修改注入锚点时，必须用 `cat -A` 验证目标行的确切 tab 数量。

## 注入点注意事项

`ChoiceRngPatch.cs` 中使用 `source.Replace()` 做字符串匹配。**tab 数量必须与原始源码完全一致**：

```bash
# 用这个命令核对原始源码的 tab 数量：
sed -n '<行号>p' game_source_code/<文件名> | cat -A
# ^I = 1 个 tab，所以 ^I^I = 2 个 tab
```

已有的注入锚点（已确认正确的 tab 数量）：
- `\t\t\t\trandomize()` — Pop-up 行 1346（4 tab）
- `\t\tfor c in range(stcf - cards.size()):` — Pop-up 行 1338（2 tab）

## Release 流程

### 1. 版本号更新

`manifest.json` 中的 `Version` 字段。

### 2. 构建 dist 包

```bash
rm -rf dist/BetterLandlord-vx.x.x
mkdir -p dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord
cp Piraeus.BetterLandlord/bin/Release/net8.0/Piraeus.BetterLandlord.dll \
   dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord/
cp Piraeus.BetterLandlord/manifest.json \
   dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord/
cp Piraeus.BetterLandlord.UI/bin/Release/net8.0-windows/Piraeus.BetterLandlord.UI.dll \
   dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord/
cp Piraeus.BetterLandlord.UI/bin/Release/net8.0-windows/Piraeus.BetterLandlord.UI.exe \
   dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord/
cp Piraeus.BetterLandlord.UI/bin/Release/net8.0-windows/Piraeus.BetterLandlord.UI.runtimeconfig.json \
   dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord/
```

### 3. 打包 zip

Zip **只包含 5 个文件，放在根目录**（不要包含 `SlotWeave/mods/...` 路径前缀）：

```bash
cd dist/BetterLandlord-vx.x.x/SlotWeave/mods/Piraeus.BetterLandlord
powershell -Command "Compress-Archive -Path '*' -DestinationPath '..\..\..\..\BetterLandlord-vx.x.x.zip' -Force"
```

zip 内必须恰好 5 个文件：
- `manifest.json`
- `Piraeus.BetterLandlord.dll`
- `Piraeus.BetterLandlord.UI.dll`
- `Piraeus.BetterLandlord.UI.exe`
- `Piraeus.BetterLandlord.UI.runtimeconfig.json`

确认没有多余的目录层级或重复文件。

### 4. Commit 格式

```
<type>: <description> (v<version>)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

常用 type：`fix`、`feat`、`chore`

### 5. 创建 GitHub Release

```bash
gh release create vx.x.x \
  --title "Better Landlord vx.x.x" \
  --notes "<面向玩家的更新说明，不包含技术细节和代码细节>" \
  --target master

gh release upload vx.x.x dist/BetterLandlord-vx.x.x.zip --clobber
```

**重要规则：**
- Release 标题：`Better Landlord vx.x.x`（纯版本号，无副标题）
- Release 内容：面向玩家的功能说明，**不包含**技术实现、代码变更、注入细节
- 必须先 push commit，再创建 release
- 创建 release 后必须上传 zip

### 6. 如果 Release 有问题需要重做

```bash
# 删除 GitHub release
gh release delete vx.x.x --yes

# 删除远端 tag
git push origin --delete vx.x.x

# 修复代码后重新 commit（可以用 force push 覆盖）
git push --force origin master

# 重新创建 release + 上传
```

## RNG 架构

### 物品流（Items）
- 4 个稀有度序列 `_bh_item_seq = {common, uncommon, rare, very_rare}`，每个是一段 Fisher-Yates shuffled 数组
- `_bh_item_cursor[rarity]` 逐次推进，skip-owned
- `_bh_item_pick_event` 事件编号（seed 维度：`itemseq_<rarity>_<round>_<event>`）
- `_bh_item_rarity_ctr` 稀有度 roll 计数（seed 维度：`itmrarity_<round>_<counter>`）
- `_bh_begin_item_pick_event()` 入口：递增 event，重建全部 4 个序列，重置 cursor

### 精华流（Essences）
- 1 个序列池 `_bh_essence_seq`（数组，不是 dict），精华只有一个稀有度没有分流
- `_bh_essence_cursor` 逐次推进，skip-owned
- `_bh_essence_pick_event` 事件编号（seed 维度：`essenceseq_<round>_<event>`）
- **没有** rarity counter — 精华稀有度永远来自 `forced_rarity`，不从概率表 roll，不消耗稀有度随机数
- `_bh_begin_essence_pick_event()` 入口：递增 event，重建精华序列，重置 cursor

### 解耦规则
- 物品操作不碰任何 `_bh_essence_*` 变量
- 精华操作不碰任何 `_bh_item_*` 变量，尤其不碰 `_bh_item_rarity_ctr`
- 入口分流依据：`email.extra_values.forced_rarity[0] == "essence"` → 精华流；否则 → 物品流
- 两条流完全独立，都用 skip-owned（Fisher-Yates shuffle + cursor），算法相同、种子域不同

### 调试日志

游戏内置 `write_log(string)` 函数（Main 节点，`game_source_code/Main.tscn__1.gd:1813`）：

- **Main 侧**（RngInfrastructureSourceMod 注入）：直接调用 `write_log('msg')`
- **Pop-up 侧**（ChoiceRngPatch 注入）：调用 `$"/root/Main".write_log('msg')`
- 输出到 `user://run_logs/<run_timestamp>.log`，自动带时间戳

## 关键文件

| 文件 | 用途 |
|------|------|
| `Mod.cs` | 模组入口，注册所有 ISourceMod/Patch |
| `ChoiceRngPatch.cs` | Pop-up.tscn__1 注入：替换 rand_range/shuffle，注入 `_bh_begin_item_pick_event` |
| `RngInfrastructureSourceMod.cs` | Main.tscn__1 注入：PCGRng 类、RNG 状态、skip-owned 序列 |
| `manifest.json` | 版本号和模组元数据 |

## 行为规则

**不要主动改代码。** 用户没有在当前轮次明确提出"修改"、"写代码"、"修一下"、"commit"等指令时，只做分析、调查、解释，不执行任何代码变更。就算发现了明显的 bug，也先汇报，等用户决定是否修。

## 常见陷阱

1. **注入锚点 tab 数量**：原始源码缩进用 tab，`cat -A` 显示为 `^I`。注入锚点中的 `\t` 数量必须逐字匹配。
2. **Patched 文件只读**：SlotWeave 在游戏启动时生成 patched 脚本。部署 DLL 后必须重启游戏才能看到效果。
3. **Zip 文件格式**：必须与 v1.1.2 一致——5 个文件在 zip 根目录，无子目录。
4. **Release 标题**：简单格式 `Better Landlord v1.2.3`，不要加描述性副标题。
5. **Release 内容**：面向玩家，不包含代码/技术细节。
