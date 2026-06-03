extends Control

var essences_unlocked = false
var stats_unlocked = false
var bossfight_unlocked = false
var highest_unlocked_floor = 1
var unlocked_modded_floors = []
var saved_ll_fate
var landlord_fates_seen = []
var landlord_fates_not_seen = []
var total_games_played = []
var total_games_won = []
var current_winstreaks = []
var highest_winstreaks = []
var billionaires_guillotined = []
var time_spent_petting_dog = []
var rabbit_fluff_shed = []
var humans_murdered_by_general_zaroff = []
var alcohol_consumed = []
var times_executed = []
var rabbit_hops = []
var landlord_executions = []
var executions = 0
var just_won = []
var achievements_unlocked = []
var killed = true
var chievos = []
var unlocking = false

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()
		for a in get_children():
			a.queue_free()
			for b in a.get_children():
				b.queue_free()
				for c in b.get_children():
					c.queue_free()
					for d in c.get_children():
						d.queue_free()
						for e in d.get_children():
							e.queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")
	achievements_unlocked.resize(186)
	Steam.connect("current_stats_received", self, "unlock_chievo")

func unlock_achievement(a_num, save_stat):
	if not $"/root/Main".sandbox_mode and (not $"/root/Main/Pop-up Sprite/Pop-up".modded_run or a_num == 17 or a_num == 38 or a_num == 54 or a_num == 65 or a_num == 83 or (a_num >= 150 and a_num <= 185)) and not $"/root/Main".demo:
		if achievements_unlocked[a_num] == null:
			achievements_unlocked[a_num] = true
			if TranslationServer.get_locale() == "zh_TW":
				$"/root/Main".display_error("achievement_unlocked", tr("achievement_" + str(a_num)).replacen(" ", ""))
			else:
				$"/root/Main".display_error("achievement_unlocked", tr("achievement_" + str(a_num)))
			if save_stat:
				$"/root/Main".save_stats()
		if not chievos.has(a_num):
			chievos.push_back(int(a_num))
		Steam.requestCurrentStats()

func unlock_local_chievos():
	var stats = false
	for c in range(achievements_unlocked.size()):
		if achievements_unlocked[c] == true:
			Steam.setAchievement("NEW_ACHIEVEMENT_" + str(2 + floor(c / 32)) + "_" + str(c % 32))
			Steam.storeStats()
			stats = true
	if stats:
		Steam.requestCurrentStats()

func unlock_chievo(game, result, user):
	if not unlocking:
		unlocking = true
		var tbe = []
		for c in chievos:
			Steam.setAchievement("NEW_ACHIEVEMENT_" + str(2 + floor(c / 32)) + "_" + str(c % 32))
			Steam.storeStats()
			tbe.push_back(c)
		for e in tbe:
			chievos.erase(e)
		unlocking = false
		if chievos.size() > 0:
			Steam.requestCurrentStats()

func add_stat(stat, apartment_floor, num, save_stat):
	if self[stat].size() < apartment_floor + 1:
		self[stat].resize(apartment_floor + 1)
		for i in range(self[stat].size() - 1):
			if self[stat][i + 1] == null:
				self[stat][i + 1] = 0
	if not $"/root/Main".sandbox_mode:
		self[stat][apartment_floor] += num
	match stat:
		"humans_murdered_by_general_zaroff":
			if get_converted_stat(stat, "all") >= 1924:
				 $"/root/Main/Reels".add_queued_achievement(59)
		"billionaires_guillotined":
			if get_converted_stat(stat, "all") >= 500:
				 $"/root/Main/Reels".add_queued_achievement(15)
		"rabbit_hops":
			if get_converted_stat(stat, "all") >= 1000:
				 $"/root/Main/Reels".add_queued_achievement(113)
		"time_spent_petting_dog":
			if get_converted_stat(stat, "all") >= 1:
				 $"/root/Main/Reels".add_queued_achievement(47)
		"rabbit_fluff_shed":
			if (get_converted_stat(stat, "all") >= 3 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ko")) or (get_converted_stat(stat, "all") >= 1.73 and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko"):
				 $"/root/Main/Reels".add_queued_achievement(114)
		"alcohol_consumed":
			if (get_converted_stat(stat, "all") >= 50 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ko"or TranslationServer.get_locale() == "de")) or (get_converted_stat(stat, "all") >= 189.3 and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko" and TranslationServer.get_locale() != "de"):
				 $"/root/Main/Reels".add_queued_achievement(147)
	if save_stat:
		$"/root/Main".save_stats()

func get_converted_stat(stat, apartment_floor):
	if typeof(apartment_floor) == TYPE_STRING and apartment_floor == "all":
		self[stat].resize(highest_unlocked_floor + 1)
		var num = 0
		for i in range(self[stat].size() - 1):
			if self[stat][i + 1] == null:
				self[stat][i + 1] = 0
			num += self[stat][i + 1]
		if stat == "alcohol_consumed" and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko" and TranslationServer.get_locale() != "de":
			return num * 3.786
		elif stat == "rabbit_fluff_shed" and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko":
			return num * 2.204622476037958
		else:
			return num
	else:
		if self[stat].size() < apartment_floor + 1:
			self[stat].resize(apartment_floor + 1)
		if self[stat][apartment_floor] == null:
			self[stat][apartment_floor] = 0
		if stat == "alcohol_consumed" and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko":
			return self[stat][apartment_floor] * 0.2641720372841847
		elif stat == "rabbit_fluff_shed" and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko":
			return self[stat][apartment_floor] * 2.204622476037958
		else:
			return self[stat][apartment_floor]

func add_to_games_played(apartment_floor):
	if total_games_played.size() < apartment_floor + 1 or just_won.size() < apartment_floor + 1 or current_winstreaks.size() < apartment_floor + 1 or highest_winstreaks.size() < apartment_floor + 1:
		total_games_played.resize(apartment_floor + 1)
		just_won.resize(apartment_floor + 1)
		current_winstreaks.resize(apartment_floor + 1)
		highest_winstreaks.resize(apartment_floor + 1)
		for i in range(total_games_played.size() - 1):
			if total_games_played[i + 1] == null:
				total_games_played[i + 1] = 0
			if current_winstreaks[i + 1] == null:
				current_winstreaks[i + 1] = 0
			if highest_winstreaks[i + 1] == null:
				highest_winstreaks[i + 1] = 0
			if just_won[i + 1] == null:
				just_won[i + 1] = false
	if not $"/root/Main".sandbox_mode:
		total_games_played[apartment_floor] += 1
		if just_won[apartment_floor]:
			just_won[apartment_floor] = false
		else:
			add_to_games_lost(apartment_floor)
		
	$"/root/Main".save_stats()

func add_to_games_won(apartment_floor):
	if total_games_won.size() < apartment_floor + 1 or current_winstreaks.size() < apartment_floor + 1 or highest_winstreaks.size() < apartment_floor + 1 or just_won.size() < apartment_floor + 1:
		total_games_won.resize(apartment_floor + 1)
		current_winstreaks.resize(apartment_floor + 1)
		highest_winstreaks.resize(apartment_floor + 1)
		just_won.resize(apartment_floor + 1)
		for i in range(total_games_won.size() - 1):
			if total_games_won[i + 1] == null:
				total_games_won[i + 1] = 0
			if current_winstreaks[i + 1] == null:
				current_winstreaks[i + 1] = 0
			if highest_winstreaks[i + 1] == null:
				highest_winstreaks[i + 1] = 0
			if just_won[i + 1] == null:
				just_won[i + 1] = false
	if not $"/root/Main".sandbox_mode:
		total_games_won[apartment_floor] += 1
		current_winstreaks[apartment_floor] += 1
		if current_winstreaks[apartment_floor] > highest_winstreaks[apartment_floor]:
			highest_winstreaks[apartment_floor] = current_winstreaks[apartment_floor]
		just_won[apartment_floor] = true
		unlock_achievement(apartment_floor + 149, false)
		var tgw = get_converted_stat("total_games_won", "all")
		if tgw >= 5:
			unlock_achievement(170, true)
		if tgw >= 10:
			unlock_achievement(171, true)
		if tgw >= 25:
			unlock_achievement(172, true)
		if tgw >= 50:
			unlock_achievement(173, true)
		if tgw >= 100:
			unlock_achievement(174, true)
		if tgw >= 250:
			unlock_achievement(175, true)
		if tgw >= 500:
			unlock_achievement(176, true)
		if tgw >= 777:
			unlock_achievement(177, true)
	$"/root/Main".save_stats()

func add_to_games_lost(apartment_floor):
	if current_winstreaks.size() < apartment_floor + 1 or highest_winstreaks.size() < apartment_floor + 1 or just_won.size() < apartment_floor + 1:
		current_winstreaks.resize(apartment_floor + 1)
		highest_winstreaks.resize(apartment_floor + 1)
		just_won.resize(apartment_floor + 1)
	for i in range(current_winstreaks.size() - 1):
		if current_winstreaks[i + 1] == null:
			current_winstreaks[i + 1] = 0
		if highest_winstreaks[i + 1] == null:
			highest_winstreaks[i + 1] = 0
	if not $"/root/Main".sandbox_mode:
		current_winstreaks[apartment_floor] = 0
	$"/root/Main".save_stats()

func check_if_bossfight_unlocked():
	if not bossfight_unlocked and not $"/root/Main".demo:
		var games_won = 0
		for i in range(total_games_won.size() - 1):
			games_won += total_games_won[i + 1]
		if games_won >= 9 or highest_unlocked_floor >= 9:
			bossfight_unlocked = true
		$"/root/Main".save_stats()

func check_if_essences_unlocked():
	if not essences_unlocked and not $"/root/Main".demo:
		var games_won = 0
		for i in range(total_games_won.size() - 1):
			games_won += total_games_won[i + 1]
		if games_won >= 7 or highest_unlocked_floor >= 7:
			essences_unlocked = true
		$"/root/Main".save_stats()
	if essences_unlocked:
		unlock_achievement(54, true)

func check_if_stats_unlocked():
	if not stats_unlocked and not $"/root/Main".demo:
		var games_won = 0
		for i in range(total_games_won.size() - 1):
			if total_games_won[i + 1] > 0:
				stats_unlocked = true
		$"/root/Main".save_stats()

func save():
	var save_dict = {
		"path" : get_path(),
		"essences_unlocked": essences_unlocked,
		"stats_unlocked": stats_unlocked,
		"bossfight_unlocked": bossfight_unlocked,
		"highest_unlocked_floor": highest_unlocked_floor,
		"unlocked_modded_floors": unlocked_modded_floors,
		"saved_ll_fate": saved_ll_fate,
		"landlord_fates_seen": landlord_fates_seen,
		"landlord_fates_not_seen": landlord_fates_not_seen,
		"total_games_played": total_games_played,
		"total_games_won": total_games_won,
		"current_winstreaks": current_winstreaks,
		"highest_winstreaks": highest_winstreaks,
		"billionaires_guillotined": billionaires_guillotined,
		"time_spent_petting_dog": time_spent_petting_dog,
		"rabbit_fluff_shed": rabbit_fluff_shed,
		"humans_murdered_by_general_zaroff": humans_murdered_by_general_zaroff,
		"alcohol_consumed": alcohol_consumed,
		"rabbit_hops": rabbit_hops,
		"landlord_executions": landlord_executions,
		"times_executed": times_executed,
		"just_won": just_won,
		"executions": executions,
		"achievements_unlocked": achievements_unlocked,
		"killed": killed
	}
	return save_dict
