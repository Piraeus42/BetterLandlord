import matplotlib.pyplot as plt
import matplotlib
import numpy as np
from matplotlib import font_manager

font_path = r"C:\Windows\Fonts\simhei.ttf"
font_manager.fontManager.addfont(font_path)
prop = font_manager.FontProperties(fname=font_path)
matplotlib.rcParams['font.family'] = prop.get_name()
matplotlib.rcParams['axes.unicode_minus'] = False

# 原始数据
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

fig = plt.figure(figsize=(16, 12))

# ========== 图1: 核心 - 增长差距滤波图 ==========
ax1 = plt.subplot(3, 2, 1)

# 计算环比增长率
income_growth = np.diff(earned) / earned[:-1] * 100  # 收入增长率
rent_growth = np.diff(rent) / rent[:-1] * 100        # 租金增长率
growth_gap = income_growth - rent_growth              # 增长差距

x = np.arange(len(income_growth))  # 周期间隔

# 绘制原始数据
ax1.bar(x - 0.2, income_growth, 0.4, label='收入环比增长', color='#2E86AB', alpha=0.7)
ax1.bar(x + 0.2, rent_growth, 0.4, label='租金环比增长', color='#E94F37', alpha=0.7)

# 绘制滤波趋势线
ig_smooth = ewm_smooth(income_growth, span=3)
rg_smooth = ewm_smooth(rent_growth, span=3)
gg_smooth = ewm_smooth(growth_gap, span=3)

ax1.plot(x, ig_smooth, 'b-', linewidth=3, alpha=0.9, label='收入增长滤波')
ax1.plot(x, rg_smooth, 'r-', linewidth=3, alpha=0.9, label='租金增长滤波')
ax1.plot(x, gg_smooth, 'k-', linewidth=3.5, alpha=1.0, label='增长差距滤波')

ax1.axhline(y=0, color='gray', linewidth=1.5, linestyle='--', alpha=0.7)
ax1.fill_between(x, 0, gg_smooth, where=(gg_smooth >= 0), interpolate=True, 
                  alpha=0.3, color='green', label='安全区(收入增长>租金增长)')
ax1.fill_between(x, 0, gg_smooth, where=(gg_smooth < 0), interpolate=True, 
                  alpha=0.3, color='red', label='危险区(租金增长>收入增长)')

ax1.set_xlabel('周期间隔', fontsize=12)
ax1.set_ylabel('增长率 (%)', fontsize=12)
ax1.set_title('【核心诊断】收入增长 vs 租金增长 — 滤波后趋势一目了然', fontsize=14, fontweight='bold')
ax1.set_xticks(x + 0.5)
ax1.set_xticklabels([f'{i}->{i+1}' for i in range(1, len(income_growth)+1)])
ax1.legend(loc='upper right', fontsize=9)
ax1.grid(True, alpha=0.3)

# 标注关键压力节点
for i in range(len(growth_gap)):
    if growth_gap[i] < -10:  # 危险节点
        ax1.annotate(f'{growth_gap[i]:+.0f}%', (i, growth_gap[i]), 
                    textcoords="offset points", xytext=(0, -20),
                    ha='center', fontsize=9, color='red', fontweight='bold',
                    arrowprops=dict(arrowstyle='->', color='red', lw=1.5))
    elif growth_gap[i] > 30:  # 安全节点
        ax1.annotate(f'{growth_gap[i]:+.0f}%', (i, growth_gap[i]), 
                    textcoords="offset points", xytext=(0, 15),
                    ha='center', fontsize=9, color='green', fontweight='bold')

# ========== 图2: 增长差距折线图（更清晰）==========
ax2 = plt.subplot(3, 2, 2)
ax2.fill_between(x, 0, gg_smooth, where=(gg_smooth >= 0), interpolate=True, 
                  alpha=0.4, color='green')
ax2.fill_between(x, 0, gg_smooth, where=(gg_smooth < 0), interpolate=True, 
                  alpha=0.4, color='red')
ax2.plot(x, gg_smooth, 'k-', linewidth=4, alpha=0.9)
ax2.axhline(y=0, color='black', linewidth=2, linestyle='--', alpha=0.7)
ax2.set_xlabel('周期间隔', fontsize=12)
ax2.set_ylabel('增长差距 (%)', fontsize=12)
ax2.set_title('【压力指数】收入增长 - 租金增长（滤波后）', fontsize=14, fontweight='bold')
ax2.set_xticks(x + 0.5)
ax2.set_xticklabels([f'{i}->{i+1}' for i in range(1, len(income_growth)+1)])
ax2.grid(True, alpha=0.3)

# 标注数值
for i, v in enumerate(gg_smooth):
    color = 'green' if v >= 0 else 'red'
    ax2.annotate(f'{v:+.0f}', (i, v), textcoords="offset points", 
                xytext=(0, 15 if v >= 0 else -20), ha='center', 
                fontsize=10, color=color, fontweight='bold')

# ========== 图3: 存款消耗深度图 ==========
ax3 = plt.subplot(3, 2, 3)
drawdown = np.maximum(0, rent - earned)
ax3.bar(periods, drawdown, color='#E94F37', alpha=0.6, label='当期存款消耗')
ax3.plot(periods, savings, 'o-', linewidth=2.5, markersize=8, color='#2E86AB', label='剩余存款')
ax3.plot(periods, ewm_smooth(savings, span=3), '--', linewidth=2, color='#2E86AB', alpha=0.6)
ax3.set_xlabel('收租周期', fontsize=12)
ax3.set_ylabel('金额', fontsize=12)
ax3.set_title('【存款轨迹】剩余存款 vs 当期消耗', fontsize=14, fontweight='bold')
ax3.legend(loc='upper left', fontsize=10)
ax3.grid(True, alpha=0.3)
ax3.set_xticks(periods)

# ========== 图4: 玩家分布 + 压力线 ==========
ax4 = plt.subplot(3, 2, 4)

# 玩家数据
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
colors = ['#E94F37', '#F5A623', '#7ED321', '#4AADC8', '#9B59B6',
          '#FF6B6B', '#FFA07A', '#98D8C8', '#B8E6B8', '#D4A5FF']

for idx, player in enumerate(player_data):
    valid = [(i, v) for i, v in enumerate(player) if v is not None]
    if not valid: continue
    px = [x+1 for x, _ in valid]
    py = [y for _, y in valid]
    window = min(3, len(py))
    if window > 1:
        smoothed = [np.mean(py[max(0,i-window//2):min(len(py),i+window//2+1)]) for i in range(len(py))]
    else: smoothed = py[:]
    ax4.plot(px, py, linewidth=1.5, alpha=0.4, color=colors[idx % len(colors)])
    ax4.plot(px, smoothed, linewidth=2.5, alpha=0.9, color=colors[idx % len(colors)], marker='')

# 绘制收入曲线和租金曲线
ax4.plot(periods, earned, 'b-', linewidth=3, alpha=0.8, label='实际收入', zorder=5)
ax4.plot(periods, rent, 'r--', linewidth=2.5, alpha=0.8, label='租金压力', zorder=5)

ax4.set_xlabel('收租周期', fontsize=12)
ax4.set_ylabel('金额', fontsize=12)
ax4.set_title('【全局对比】收入 vs 租金 vs 玩家分布', fontsize=14, fontweight='bold')
ax4.legend(loc='upper left', fontsize=9)
ax4.grid(True, alpha=0.3)
ax4.set_xticks(periods)

# ========== 图5: 盈余热力图 ==========
ax5 = plt.subplot(3, 2, (5, 6))
surplus = earned - rent
period_labels = [f'周期{i+1}' for i in range(len(periods))]
im = ax5.imshow(surplus.reshape(1, -1), cmap='RdYlGn', aspect='auto', vmin=-100, vmax=400)
ax5.set_xticks(range(len(period_labels)))
ax5.set_xticklabels(period_labels, rotation=45, ha='right')
ax5.set_yticks([])
ax5.set_title('【盈余热力图】收入 - 租金 = 盈余(正)/缺口(负)', fontsize=14, fontweight='bold')
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
ax5.legend(loc='upper right', fontsize=10)

plt.tight_layout()
plt.savefig(r'E:\code\betterLandlord\lucky_landlord_chart_v3.png', dpi=150, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
print("图表已保存")

# 打印关键分析
print("\n=== 增长差距分析（收入增长 - 租金增长）===")
print(f"{'间隔':>6} | {'收入增长':>10} | {'租金增长':>10} | {'差距':>8} | {'状态':>6}")
print("-" * 50)
for i in range(len(growth_gap)):
    status = "危险" if growth_gap[i] < 0 else "安全"
    print(f"{i+1}->{i+2:>5} | {income_growth[i]:>+9.1f}% | {rent_growth[i]:>+9.1f}% | {growth_gap[i]:>+7.1f}% | {status:>6}")
