import matplotlib.pyplot as plt
import matplotlib
import numpy as np
from matplotlib import font_manager

# 强制使用 SimHei 字体
font_path = r"C:\Windows\Fonts\simhei.ttf"
font_manager.fontManager.addfont(font_path)
prop = font_manager.FontProperties(fname=font_path)
matplotlib.rcParams['font.family'] = prop.get_name()
matplotlib.rcParams['axes.unicode_minus'] = False

# 原始数据
player_data = [
    [4, 10, 15, 28, 52, 57, 58, 40, 63, 79, 86, 138, 155],
    [4, 13, 19, 30, 37, 53, 46, 44, 61, 86, 79, 86, 174],
    [5, 12, 15, 19, 32, 34, 58, 49, 62, 82, 76, 146, 99],
    [6, 13, 20, 43, 26, 49, 44, 55, 59, 81, 111, 143, 111],
    [7, 14, 17, 44, 49, 38, 54, 54, 104, 88, 131, 117, 188],
    [None, None, 31, 19, 30, 42, 50, 56, 69, 102, 94, 104, 85],
    [None, None, None, None, 32, 33, 54, 69, 79, 81, 86, 123, 124],
    [None, None, None, None, None, None, 48, 57, 82, 88, 96, 139, 108],
    [None, None, None, None, None, None, None, None, 65, 72, 88, 93, 92],
    [None, None, None, None, None, None, None, None, None, None, 67, 120, 89],
]

rent = np.array([25, 50, 100, 150, 225, 300, 375, 450, 600, 650, 700, 777, 1000], dtype=float)
earned = np.array([26, 62, 117, 183, 258, 306, 412, 424, 644, 759, 914, 1209, 1225], dtype=float)
savings = np.array([1, 13, 30, 63, 96, 102, 139, 113, 157, 266, 480, 912, 1137], dtype=float)
periods = np.arange(1, len(rent) + 1)

def ewm_smooth(data, span):
    arr = np.array(data, dtype=float)
    result = np.zeros_like(arr, dtype=float)
    result[0] = arr[0]
    alpha = 2 / (span + 1)
    for i in range(1, len(arr)):
        result[i] = alpha * arr[i] + (1 - alpha) * result[i-1]
    return result

fig = plt.figure(figsize=(16, 14))
colors = ['#E94F37', '#F5A623', '#7ED321', '#4AADC8', '#9B59B6',
          '#FF6B6B', '#FFA07A', '#98D8C8', '#B8E6B8', '#D4A5FF']

# ========== 图1: 增长率比率 ==========
ax1 = plt.subplot(3, 2, 1)
ratio = earned / rent
ax1.plot(periods, ratio, marker='o', markersize=8, linewidth=2.5, color='#2E86AB', label='收入/租金比率')
ax1.axhline(y=1.0, color='#E94F37', linestyle='--', linewidth=2, label='比率=1 (收支平衡线)')
ax1.fill_between(periods, 0, ratio, alpha=0.15, color='#2E86AB')
ax1.set_xlabel('收租周期', fontsize=11)
ax1.set_ylabel('收入 / 租金 比率', fontsize=11)
ax1.set_title('【核心指标】每期收入能否覆盖租金', fontsize=13, fontweight='bold')
ax1.grid(True, alpha=0.3)
ax1.set_xticks(periods)
for i, (p, r) in enumerate(zip(periods, ratio)):
    color = '#27AE60' if r >= 1.0 else '#E94F37'
    ax1.annotate(f'{r:.2f}', (p, r), textcoords="offset points", xytext=(0, 12),
                 ha='center', fontsize=8, color=color, fontweight='bold')
ax1.legend(loc='upper left')
ax1.set_ylim(0, 1.8)

# ========== 图2: 玩家存活曲线（折线滤波）==========
ax2 = plt.subplot(3, 2, 2)
for idx, player in enumerate(player_data):
    valid = [(i, v) for i, v in enumerate(player) if v is not None]
    if not valid:
        continue
    px = [x+1 for x, _ in valid]
    py = [y for _, y in valid]
    window = min(3, len(py))
    if window > 1:
        smoothed = []
        for i in range(len(py)):
            start = max(0, i - window//2)
            end = min(len(py), i + window//2 + 1)
            smoothed.append(np.mean(py[start:end]))
    else:
        smoothed = py[:]
    ax2.plot(px, py, marker='o', markersize=4, linewidth=1.2, alpha=0.5, color=colors[idx % len(colors)])
    ax2.plot(px, smoothed, marker='', linewidth=2, alpha=0.9, color=colors[idx % len(colors)])

ax2.plot(periods, savings, 'k-', linewidth=3, alpha=0.8, label='累积存款趋势（均值滤波）')
ax2.plot(periods, rent, 'r--', linewidth=2, alpha=0.7, label='每期租金压力')
ax2.set_xlabel('收租周期', fontsize=11)
ax2.set_ylabel('存款金额', fontsize=11)
ax2.set_title('【玩家存活曲线】各玩家存款 vs 租金压力', fontsize=13, fontweight='bold')
ax2.legend(loc='upper left', fontsize=9)
ax2.grid(True, alpha=0.3)
ax2.set_xticks(periods)

# ========== 图3: 滤波折线图 ==========
ax3 = plt.subplot(3, 2, 3)
player_savings_filtered = []
for player in player_data:
    valid = [v for v in player if v is not None]
    if len(valid) >= 3:
        filtered = ewm_smooth(valid, span=3)
        player_savings_filtered.append(filtered)
    else:
        player_savings_filtered.append(valid)

for idx, filtered in enumerate(player_savings_filtered):
    start_i = sum(1 for p in player_data[:idx] if p[0] is None)
    px = list(range(start_i + 1, start_i + 1 + len(filtered)))
    py = list(filtered)
    ax3.plot(px, py, linewidth=1.5, alpha=0.4, color=colors[idx % len(colors)])

ax3.plot(periods, savings, 'b-', linewidth=3, marker='o', markersize=8, label='实际存款趋势', alpha=0.9)
ax3.plot(periods, rent, 'r--', linewidth=2.5, label='租金需求', alpha=0.9)

for i in range(len(periods)-1):
    if savings[i] >= rent[i]:
        ax3.fill_between([periods[i], periods[i+1]], [0, 0], [rent[i], rent[i+1]], 
                          alpha=0.1, color='green')
    else:
        ax3.fill_between([periods[i], periods[i+1]], [0, 0], [rent[i], rent[i+1]], 
                          alpha=0.15, color='red')

ax3.set_xlabel('收租周期', fontsize=11)
ax3.set_ylabel('金额', fontsize=11)
ax3.set_title('【滤波生存图】存款 vs 租金压力 (含玩家分布滤波)', fontsize=13, fontweight='bold')
ax3.legend(loc='upper left', fontsize=9)
ax3.grid(True, alpha=0.3)
ax3.set_xticks(periods)

# ========== 图4: 增长率条形图 + 滤波趋势 ==========
ax4 = plt.subplot(3, 2, 4)
income_growth = np.diff(earned) / earned[:-1] * 100
rent_growth = np.diff(rent) / rent[:-1] * 100
x = np.arange(len(income_growth))
width = 0.35
bars1 = ax4.bar(x - width/2, income_growth, width, label='收入增长率', color='#2E86AB', alpha=0.8)
bars2 = ax4.bar(x + width/2, rent_growth, width, label='租金增长率', color='#E94F37', alpha=0.8)
income_growth_smooth = ewm_smooth(income_growth, span=3)
rent_growth_smooth = ewm_smooth(rent_growth, span=3)
ax4.plot(x, income_growth_smooth, 'b-', linewidth=2.5, alpha=0.9, label='收入增长滤波趋势')
ax4.plot(x, rent_growth_smooth, 'r-', linewidth=2.5, alpha=0.9, label='租金增长滤波趋势')
ax4.axhline(y=0, color='black', linewidth=0.5)
ax4.set_xlabel('周期间隔', fontsize=11)
ax4.set_ylabel('增长率 (%)', fontsize=11)
ax4.set_title('【增长率对比】收入增长 vs 租金增长 (含滤波趋势线)', fontsize=13, fontweight='bold')
ax4.set_xticks(x + 0.5)
ax4.set_xticklabels([f'{i}->{i+1}' for i in range(1, len(income_growth)+1)])
ax4.legend(loc='upper right', fontsize=9)
ax4.grid(True, alpha=0.3)

# ========== 图5: 盈余/缺口热力图 ==========
ax5 = plt.subplot(3, 2, (5, 6))
surplus = earned - rent
period_labels = [f'周期{i+1}' for i in range(len(periods))]
im = ax5.imshow(surplus.reshape(1, -1), cmap='RdYlGn', aspect='auto', vmin=-200, vmax=400)
ax5.set_xticks(range(len(period_labels)))
ax5.set_xticklabels(period_labels, rotation=45, ha='right')
ax5.set_yticks([])
ax5.set_title('【盈余热力图】每期收入 - 租金 = 盈余/缺口', fontsize=13, fontweight='bold')
for i in range(len(surplus)):
    val = surplus[i]
    color = 'white' if abs(val) > 150 else 'black'
    ax5.text(i, 0, f'{val:+.0f}', ha='center', va='center', fontsize=14, 
             fontweight='bold', color=color)
surplus_smooth = ewm_smooth(surplus, span=3)
ax5.plot(range(len(surplus)), surplus_smooth, 'k-', linewidth=3, alpha=0.9, label='盈余滤波趋势')
ax5.axhline(y=0, color='gray', linewidth=1.5, linestyle='--', alpha=0.7)
cbar = plt.colorbar(im, ax=ax5, fraction=0.046, pad=0.04)
cbar.set_label('盈余金额', fontsize=10)
ax5.legend(loc='upper right', fontsize=9)

plt.tight_layout()
plt.savefig(r'E:\code\betterLandlord\lucky_landlord_chart.png', dpi=150, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
print("图表已保存至 E:\\code\\betterLandlord\\lucky_landlord_chart.png")

print("\n=== 关键数据分析 ===")
print(f"{'周期':>4} | {'租金':>6} | {'收入':>6} | {'盈余':>6} | {'比率':>5} | {'存货':>6}")
print("-" * 55)
for i in range(len(periods)):
    r = rent[i]
    e = earned[i]
    s = surplus[i]
    ratio = e / r
    sav = savings[i]
    status = "OK" if s >= 0 else "FAIL"
    print(f"{i+1:>4} | {r:>6} | {e:>6} | {s:>+6} | {ratio:>5.2f} | {sav:>6} {status}")
