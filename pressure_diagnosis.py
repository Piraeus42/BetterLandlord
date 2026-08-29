import matplotlib.pyplot as plt
import matplotlib
import numpy as np
from matplotlib import font_manager

font_path = r"C:\Windows\Fonts\simhei.ttf"
font_manager.fontManager.addfont(font_path)
prop = font_manager.FontProperties(fname=font_path)
matplotlib.rcParams['font.family'] = prop.get_name()
matplotlib.rcParams['axes.unicode_minus'] = False

rent = np.array([25, 50, 100, 150, 225, 300, 375, 450, 600, 650, 700, 777, 1000], dtype=float)
earned = np.array([26, 62, 117, 183, 258, 306, 412, 424, 644, 759, 914, 1209, 1225], dtype=float)
savings = np.array([1, 13, 30, 63, 96, 102, 139, 113, 157, 266, 480, 912, 1137], dtype=float)
periods = np.arange(1, len(rent) + 1)

next_rent = np.roll(rent, -1)
next_rent[-1] = rent[-1]
safety_margin = savings - next_rent
net_cf = earned - rent

def ewm_smooth(data, span):
    arr = np.array(data, dtype=float)
    result = np.zeros_like(arr, dtype=float)
    result[0] = arr[0]
    alpha = 2 / (span + 1)
    for i in range(1, len(arr)):
        result[i] = alpha * arr[i] + (1 - alpha) * result[i-1]
    return result

fig = plt.figure(figsize=(14, 10))

ax1 = plt.subplot(2, 1, 1)
colors_bar = ['#E94F37' if x < 0 else '#27AE60' for x in safety_margin]
ax1.bar(periods, safety_margin, color=colors_bar, alpha=0.7, label='原始安全边际')
sm_smooth = ewm_smooth(safety_margin, span=4)
ax1.plot(periods, sm_smooth, 'k-', linewidth=3, label='安全边际滤波趋势(4期EWM)', zorder=5)
ax1.axhline(y=0, color='black', linewidth=2, linestyle='--', alpha=0.5)

max_pressure_idx = np.argmin(safety_margin)
recovery_idx = None
for i in range(len(safety_margin)):
    if safety_margin[i] >= 0:
        recovery_idx = i
        break

ax1.annotate(f'\u538b\u529b\u9876\u70b9\n\u5468\u671f{max_pressure_idx+1}\n\u7f3a\u53e3{int(safety_margin[max_pressure_idx])}', 
             xy=(max_pressure_idx+1, safety_margin[max_pressure_idx]),
             xytext=(max_pressure_idx+1, safety_margin[max_pressure_idx]-150),
             arrowprops=dict(arrowstyle='->', color='red', lw=2),
             fontsize=11, color='red', ha='center', fontweight='bold')

if recovery_idx is not None:
    ax1.annotate(f'\u9996\u6b21\u5b89\u5168\n\u5468\u671f{recovery_idx+1}', 
                 xy=(recovery_idx+1, safety_margin[recovery_idx]),
                 xytext=(recovery_idx+1, safety_margin[recovery_idx]+100),
                 arrowprops=dict(arrowstyle='->', color='green', lw=2),
                 fontsize=11, color='green', ha='center', fontweight='bold')

ax1.set_xlabel('\u6536\u79df\u5468\u671f', fontsize=12)
ax1.set_ylabel('\u5b89\u5168\u8fb9\u9645 (\u5b58\u6b3e - \u4e0b\u671f\u79df\u91d1)', fontsize=12)
ax1.set_title('\u3010\u538b\u529b\u8bca\u65ad\u56fe\u3011\u5b89\u5168\u8fb9\u9645\u968f\u65f6\u95f4\u53d8\u5316 \u2014\u2014 \u4e00\u773c\u770b\u6e05\u538b\u529b\u8282\u70b9', fontsize=14, fontweight='bold')
ax1.legend(loc='upper left', fontsize=11)
ax1.grid(True, alpha=0.3)
ax1.set_xticks(periods)

for i in range(len(periods)):
    if safety_margin[i] < 0:
        ax1.fill_between([periods[i]], [0], [safety_margin[i]], alpha=0.15, color='#E94F37')
    else:
        ax1.fill_between([periods[i]], [0], [safety_margin[i]], alpha=0.15, color='#27AE60')

ax2 = plt.subplot(2, 1, 2)
ratio_earn_rent = earned / rent
ratio_earn_rent_smooth = ewm_smooth(ratio_earn_rent, span=3)
ratio_save_nextrent = savings / next_rent
ratio_save_nextrent_smooth = ewm_smooth(ratio_save_nextrent, span=3)
ratio_netcf_rent = net_cf / rent
ratio_netcf_rent_smooth = ewm_smooth(ratio_netcf_rent, span=3)

lines = [
    (ratio_earn_rent, ratio_earn_rent_smooth, '#2E86AB', '\u6536\u5165/\u79df\u91d1'),
    (ratio_save_nextrent, ratio_save_nextrent_smooth, '#E94F37', '\u5b58\u6b3e/\u4e0b\u671f\u79df\u91d1'),
    (ratio_netcf_rent, ratio_netcf_rent_smooth, '#F5A623', '\u51c0\u73b0\u91d1\u6d41/\u79df\u91d1'),
]

for data, smooth, color, label in lines:
    ax2.plot(periods, data, 'o-', linewidth=2, markersize=6, color=color, alpha=0.6, label=f'{label} (\u539f\u59cb)')
    ax2.plot(periods, smooth, '-', linewidth=3, color=color, alpha=0.9, label=f'{label} (\u6ee4\u6ce2)')

ax2.axhline(y=1.0, color='black', linewidth=1.5, linestyle='--', alpha=0.7, label='\u57fa\u51c6\u7ebf=1')
ax2.set_xlabel('\u6536\u79df\u5468\u671f', fontsize=12)
ax2.set_ylabel('\u6bd4\u7387', fontsize=12)
ax2.set_title('\u3010\u4e09\u7387\u540c\u5c4f\u3011\u6536\u5165\u8986\u76d6\u7387\u3001\u652f\u4ed8\u80fd\u529b\u3001\u76c8\u4f59\u7387 \u2014\u2014 \u6ee4\u6ce2\u540e\u8d8b\u52bf\u6e05\u6670', fontsize=14, fontweight='bold')
ax2.legend(loc='lower left', fontsize=10)
ax2.grid(True, alpha=0.3)
ax2.set_xticks(periods)
ax2.set_ylim(0, 2.0)

plt.tight_layout()
plt.savefig(r'E:\code\betterLandlord\pressure_diagnosis.png', dpi=150, bbox_inches='tight', facecolor='white', edgecolor='none')
print("Done")

print("\n=== Safety Margin ===")
for i in range(len(periods)):
    s = savings[i]
    nr = next_rent[i]
    sm = safety_margin[i]
    status = "DANGER" if sm < 0 else "SAFE"
    print(f"P{i+1}: savings={s:>4} vs next_rent={nr:>4} = margin={sm:>+4} [{status}]")
print(f"\nMax pressure at period {max_pressure_idx+1}, margin={int(safety_margin[max_pressure_idx])}")
if recovery_idx is not None:
    print(f"First safe at period {recovery_idx+1}")