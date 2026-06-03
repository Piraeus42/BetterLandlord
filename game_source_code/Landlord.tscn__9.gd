extends Node2D

var hp = 750
var max_hp = 750
var queued_damage = 0
var fine_print_counter = 0
var fine_print_threshhold
var queued_fine_print = []
var fine_print = []
var possible_fine_print = []
var total_fine_print = 31
var stolen_symbols = []
var stolen_items = []
var doing_entrance_anim = false
var anim_time = 0

func _ready():
	init_fine_print()
	if not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0:
		$"Temp".scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
		if $"/root/Main/Options Sprite/Options".ui_scaling.text == 0.5:
			$"Temp".scale_mod += 2
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text == 0.75:
			$"Temp".scale_mod += 1
		else:
			$"Temp".text_mod = 0
		if $"/root/Main/Options Sprite/Options".ui_scaling.text == 1.75:
			$"Temp".custom_icon_offset = Vector2(-3, -4)
		else:
			$"Temp".custom_icon_offset = Vector2(0, 0)
		$"/root/Main/Title/Background/Mod Text".rect_position.y = 64 * $"/root/Main/Options Sprite/Options".ui_scaling.text
		$"Temp".texts[8].icon_z_index = 3
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Temp".scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
		if $"/root/Main/Options Sprite/Options".ui_scaling.text > 1:
			$"Temp".scale_mod -= -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
		$"Temp".icon_z_index = 3
		if $"/root/Main/Options Sprite/Options".ui_scaling.text >= 2.25:
			$"Temp".custom_icon_offset.x = -26
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text >= 2:
			$"Temp".custom_icon_offset.x = -22
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text >= 1.5:
			$"Temp".custom_icon_offset.x = -18
		else:
			$"Temp".custom_icon_offset.x = -12
	else:
		$"Temp".scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
		if $"/root/Main/Options Sprite/Options".ui_scaling.text > 1:
			$"Temp".scale_mod -= -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
		$"Temp".icon_z_index = 3
		if $"/root/Main/Options Sprite/Options".ui_scaling.text >= 2.25:
			$"Temp".custom_icon_offset.x = -26
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text >= 2:
			$"Temp".custom_icon_offset.x = -22
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text >= 1.5:
			$"Temp".custom_icon_offset.x = -18
		else:
			$"Temp".custom_icon_offset.x = -12

	$"Temp".change_set_size($"Temp".base_scale)

func init_fine_print():
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		possible_fine_print.clear()
		for p in $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.fine_print:
			var a = p
			if a == "self":
				a = str($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.pack_num)
			if $"/root/Main".mod_packs.has(a):
				for fp in $"/root/Main".mod_packs[a]:
					if fp.mod_type == "fine_print" and not $"/root/Main".is_mod_disabled(fp.type):
						possible_fine_print.push_back(int(fp.type.substr(11, fp.type.find("_STEAM_ID_") - 1)))
			elif a == "base":
				if not possible_fine_print.has(4):
					possible_fine_print.push_back(4)
				for i in range(1, 31):
					if not possible_fine_print.has(i + 1 + 6):
						possible_fine_print.push_back(i + 1 + 6)
	else:
		possible_fine_print.resize(31)
		possible_fine_print[0] = 4
		for i in range(1, 31):
			possible_fine_print[i] = i + 1 + 6

func spawn():
	if $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 13:
		max_hp = 1500
	elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 11:
		max_hp = 1000
	else:
		max_hp = 750
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		max_hp = $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.landlord_max_hp
	if floor(max_hp / 10) != 0:
		fine_print_threshhold = floor(max_hp / 10)
	else:
		fine_print_threshhold = max_hp / 10.0
	$"/root/Main/Stats Sprite/Stats".killed = false
	$"/root/Main".save_stats()
	entrance_anim()

func entrance_anim():
	doing_entrance_anim = true
	$"Temp".visible = true
	$"/root/Main/Reels/Landlord Bar".visible = true
	for r in $"/root/Main/Reels".reel_borders:
		r.get_child(1).get_child(1).visible = true
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		hp = $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.landlord_hp / 150.0
	else:
		hp = max_hp / 150
	init_fine_print()

func update():
	$"Temp".raw_string = "<icon_hp><color_CC0000>" + str(floor(hp + queued_damage)) + "<end>"
	$"Temp".update()
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		$"Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"Temp".get_font("font").get_string_size($"Temp".get_child(0).text).x * $"Temp".current_scale / 2.0
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"Temp".get_child(0).get_font("font").get_string_size($"Temp".get_child(0).text).x * $"Temp".current_scale / 2.0
	else:
		$"Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"Temp".get_font("font").get_string_size($"Temp".text).x * $"Temp".current_scale * 2.0
	$"Temp".rect_position.y = $"/root/Main/Reels/Reel Border".position.y
	if doing_entrance_anim:
		var reached_modded_hp = false
		if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and hp >= $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.landlord_hp:
			reached_modded_hp = true
		if hp < max_hp and not reached_modded_hp and $"/root/Main/Options Sprite/Options".counting_speed != 0:
			if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
				hp += $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.landlord_hp / 150.0 * ($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset)
			else:
				hp += max_hp / 150 * ($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset)
		else:
			if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
				hp = $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.landlord_hp
			else:
				hp = max_hp
			doing_entrance_anim = false
	if doing_entrance_anim or $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight:
		$"Temp".visible = true
		$"/root/Main/Reels/Landlord Bar".visible = true
		for r in $"/root/Main/Reels".reel_borders:
			r.get_child(1).get_child(1).visible = true
		if queued_damage > 0:
			if $"/root/Main/Options Sprite/Options".counting_speed == 0:
				queued_damage = 0
			else:
				queued_damage -= max_hp / 150.0 * ($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset)
			if queued_damage < 0:
				queued_damage = 0
	if anim_time > 0:
		anim_time -= 1
		if (hp == 0 and $"/root/Main".frame_timer % 5 == 0 and anim_time > 30) or hp > 0:
			$"Temp".rect_position.x += 4 * floor(rand_range(-1, 2))
			$"Temp".rect_position.y += 4 * floor(rand_range(-1, 2))
	if anim_time == 0 and hp + queued_damage == 0 and not $"/root/Main/Title".visible and not $"/root/Main/Options Sprite/Options".visible:
		anim_time = -1
		die()
	$"/root/Main/Reels/Landlord Bar".rect_position = $"/root/Main/Reels/Reel Border".position
	$"/root/Main/Reels/Landlord Bar".rect_size = Vector2($"/root/Main/Reels/Reel Border5".position.x - $"/root/Main/Reels/Reel Border".position.x + $"/root/Main/Reels/Reel Border5".get_child(0).rect_size.x + $"/root/Main/Reels/Reel Border5".get_child(1).get_child(0).rect_size.x, $"/root/Main/Reels/Reel Border".get_child(0).rect_size.y * ((float(hp) + float(queued_damage)) / float(max_hp)))
	for r in $"/root/Main/Reels".reel_borders:
		r.get_child(1).get_child(1).rect_size.y = $"/root/Main/Reels/Reel Border".get_child(0).rect_size.y * ((float(hp) + float(queued_damage)) / float(max_hp))

func take_damage(dmg_num):
	if dmg_num <= 0:
		return
	elif dmg_num > hp:
		dmg_num = hp
	queued_damage += dmg_num
	hp -= dmg_num
	fine_print_counter += dmg_num
	anim_time = 15
	if hp <= 0:
		hp = 0
		if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
			$"/root/Main/Music Player".fully_fade_out()
		anim_time = 160
		$"/root/Main/Reels/sfx0".set_stream(preload("res://sfx/landlord0.wav"))
		$"/root/Main/Reels/sfx0".volume_db = $"/root/Main/Options Sprite/Options".sfx.goal_volume
		if $"/root/Main/Reels/sfx0".volume_db > -80 and not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not $"/root/Main".window_focus):
			$"/root/Main/Reels/sfx0".play()
	else:
		if rand_range(0, 1) < 0.33:
			$"/root/Main/Reels/sfx0".set_stream(preload("res://sfx/hit0.wav"))
		elif rand_range(0, 1) < 0.66:
			$"/root/Main/Reels/sfx0".set_stream(preload("res://sfx/hit1.wav"))
		else:
			$"/root/Main/Reels/sfx0".set_stream(preload("res://sfx/hit2.wav"))
		$"/root/Main/Reels/sfx0".volume_db = $"/root/Main/Options Sprite/Options".sfx.goal_volume
		if $"/root/Main/Reels/sfx0".volume_db > -80 and not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not $"/root/Main".window_focus):
			$"/root/Main/Reels/sfx0".play()
		var total_fp = 1
		if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
			total_fp = $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.fine_print_multiplier
		elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 20:
			total_fp = 3
		elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 17:
			total_fp = 2
		while fine_print_counter >= fine_print_threshhold:
			for i in range(total_fp):
				var p_fine_print = possible_fine_print.duplicate(true)
				for p in fine_print:
					p_fine_print.erase(int(p.num))
				for p in queued_fine_print:
					p_fine_print.erase(int(p.num))
				if p_fine_print.size() > 0:
					var fp = get_fine_print(p_fine_print)
					queued_fine_print.push_back(fp)
					queued_fine_print[queued_fine_print.size() - 1]["num"] = int(fp.fine_print_num)
			fine_print_counter -= fine_print_threshhold

func get_fine_print(fp_arr):
	var symbol_types = []
	var symbol_groups = []
	for r in $"/root/Main/Reels".reels:
		for i in r.icons:
			symbol_types.push_back(i.type)
			symbol_groups.push_back(i.groups)
	var fp_tbe = []
	var added_fp
	for p_f_num in fp_arr:
		var f_num = str(p_f_num)
		added_fp = false
		if $"/root/Main".fine_print_database[f_num].reliant_types != null:
			for type in $"/root/Main".fine_print_database[f_num].reliant_types:
				if not symbol_types.has(type):
					fp_tbe.push_back(f_num)
					added_fp = true
					break
		if added_fp:
			continue
		if $"/root/Main".fine_print_database[f_num].reliant_groups != null:
			for group in $"/root/Main".fine_print_database[f_num].reliant_groups:
				if not symbol_groups.has(group):
					fp_tbe.push_back(f_num)
					break
	if $"/root/Main/Pop-up Sprite/Pop-up".current_floor < 15 or ($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.difficulty < 1):
		for f in fp_arr:
			if $"/root/Main".fine_print_database[str(f)].difficulty == 1:
				fp_tbe.push_back(str(f))
	for f in fp_tbe:
		fp_arr.erase(f)
	fp_tbe.clear()
	var fp
	var highest_count = 0
	var first_fp
	while highest_count == 0 and fp_arr.size() > 0:
		var counts = {}
		var fp_num = floor(rand_range(0, fp_arr.size()))
		fp = $"/root/Main".fine_print_database[str(fp_arr[fp_num])]
		if fp.reliant_types != null:
			var t = fp.reliant_types
			if t.substr(0, 5) == "item_" and $"/root/Main/Items".items.size() > 0:
				if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(t.substr(5, -1)):
					t += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[t.substr(5, -1)] + "_PACK_" + $"/root/Main".mod_pack_nums[t.substr(5, -1) + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[t.substr(5, -1)]]
				if $"/root/Main".existing_items.has(t.substr(5, -1)):
					counts[t.substr(5, -1)] = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items[t.substr(5, -1)])].item_count
				else:
					counts[t.substr(5, -1)] = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(t.substr(5, -1))].item_count
			else:
				if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
					t += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t] + "_PACK_" + $"/root/Main".mod_pack_nums[t + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]]
				if $"/root/Main".existing_symbols.has(t):
					counts[t] = symbol_types.count($"/root/Main".existing_symbols[t])
				else:
					counts[t] = symbol_types.count(t)
			for c in counts.keys():
				if highest_count < counts[c]:
					highest_count = counts[c]

		if fp.reliant_groups != null:
			var g = fp.reliant_groups
			if g.substr(0, 5) == "item_":
				for i in $"/root/Main/Items".items:
					if i.groups.has(g.substr(5, -1)):
						counts[i.type] = i.item_count
			elif $"/root/Main".group_database.symbols.has(g):
				for t in $"/root/Main".group_database.symbols[g]:
					counts[t] = symbol_types.count(t)
			for c in counts.keys():
				if highest_count < counts[c]:
					highest_count = counts[c]
		match int(fp.fine_print_num):
			1:
				for i in $"/root/Main/Items".items:
					if i.rarity == "common":
						counts[i.type] = i.item_count
			2:
				for i in $"/root/Main/Items".items:
					if i.rarity == "uncommon":
						counts[i.type] = i.item_count
			3:
				for i in $"/root/Main/Items".items:
					if i.rarity == "rare":
						counts[i.type] = i.item_count
			5:
				for r in $"/root/Main/Reels".reels:
					for i in r.icons:
						if i.rarity == "common":
							counts[i.type] = symbol_types.count(i.type)
			6:
				for r in $"/root/Main/Reels".reels:
					for i in r.icons:
						if i.rarity == "uncommon":
							counts[i.type] = symbol_types.count(i.type)
			7:
				for r in $"/root/Main/Reels".reels:
					for i in r.icons:
						if i.rarity == "rare":
							counts[i.type] = symbol_types.count(i.type)
		match int(fp.fine_print_num):
			1, 2, 3, 5, 6, 7:
				for c in counts.keys():
					if highest_count < counts[c]:
						highest_count = counts[c]
		
		var possible_icons = []
		
		for c in counts.keys():
			if highest_count == counts[c]:
				possible_icons.push_back(c)
		
		var fp_text = tr("fine_print_" + fp.fine_print_num)
		
		if fp.has("localized_text") and fp.localized_text.has(TranslationServer.get_locale()):
			fp_text = fp.localized_text[TranslationServer.get_locale()]
		elif fp.has("text"):
			fp_text = fp.text
		
		if possible_icons.size() > 0 and fp_text.find("<dynamic_") != -1:
			fp["dynamic_icon"] = possible_icons[floor(rand_range(0, possible_icons.size()))]
		elif fp_text.find("<dynamic_") == -1 and not [1, 2, 3, 5, 6, 7].has(fp_num):
			fp["dynamic_icon"] = null
			highest_count = 1
		else:
			fp["dynamic_icon"] = null
		
		if highest_count == 0:
			if fp.reliant_types != null:
				if fp.reliant_types.substr(0, 5) == "item_" and $"/root/Main".existing_items.has(fp.reliant_types.substr(5, -1)):
					var t = fp.reliant_types
					if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(t.substr(5, -1)):
						t += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[t.substr(5, -1)] + "_PACK_" + $"/root/Main".mod_pack_nums[t + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[t.substr(5, -1)]]
					if $"/root/Main".existing_items.has(t.substr(5, -1)):
						fp["dynamic_icon"] = $"/root/Main".existing_items[fp.reliant_types.substr(5, -1)]
					else:
						fp["dynamic_icon"] = t
				elif $"/root/Main".existing_symbols.has(fp.reliant_types):
					var t = fp.reliant_types
					if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
						t += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t] + "_PACK_" + $"/root/Main".mod_pack_nums[t + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]]
					if $"/root/Main".existing_symbols.has(t):
						fp["dynamic_icon"] = $"/root/Main".existing_symbols[fp.reliant_types]
					else:
						fp["dynamic_icon"] = t
			elif fp.reliant_groups != null:
				if fp.reliant_groups.substr(0, 5) == "item_" and $"/root/Main".group_database.items.has(fp.reliant_groups.substr(5, -1)):
					fp["dynamic_icon"] = $"/root/Main".group_database.items[fp.reliant_groups.substr(5, -1)][floor(rand_range(0, $"/root/Main".group_database.items[fp.reliant_groups.substr(5, -1)].size()))]
				elif $"/root/Main".group_database.symbols.has(fp.reliant_groups):
					fp["dynamic_icon"] = $"/root/Main".group_database.symbols[fp.reliant_groups][floor(rand_range(0, $"/root/Main".group_database.symbols[fp.reliant_groups].size()))]

		possible_icons.clear()
		symbol_types.clear()
		symbol_groups.clear()
		
		if first_fp == null:
			first_fp = fp
		
		if highest_count == 0:
			fp_arr.remove(fp_num)
	if fp_arr.size() == 0:
		fp = first_fp
	return fp

func die():
	hp = 0
	queued_fine_print.clear()
	fine_print.clear()
	$"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight = false
	$"Temp".visible = false
	$"/root/Main/Reels/Landlord Bar".visible = false
	for r in $"/root/Main/Reels".reel_borders:
		r.get_child(1).get_child(1).visible = false
	if not $"/root/Main/Stats Sprite/Stats".killed:
		$"/root/Main/Stats Sprite/Stats".add_stat("landlord_executions", $"/root/Main/Pop-up Sprite/Pop-up".current_floor, 1, false)
		$"/root/Main/Stats Sprite/Stats".add_to_games_won($"/root/Main/Pop-up Sprite/Pop-up".current_floor)
		if $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor < $"/root/Main/Pop-up Sprite/Pop-up".max_floor and $"/root/Main/Pop-up Sprite/Pop-up".current_floor == $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor:
			$"/root/Main/Pop-up Sprite/Pop-up".floor_unlocked_this_game = true
			$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor += 1
		$"/root/Main/Stats Sprite/Stats".killed = true
		$"/root/Main".write_log("VICTORY")
		$"/root/Main".save_log()
		for i in stolen_items:
			$"/root/Main/Items".add_item(i)
		for s in stolen_symbols:
			$"/root/Main/Reels".add_tile([s])
		$"/root/Main".save_stats()
	$"/root/Main/Pop-up Sprite/Pop-up".removal_cost = 1
	$"/root/Main/Pop-up Sprite/Pop-up".reroll_cost = 1
	stolen_items.clear()
	stolen_symbols.clear()
	if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0:
		$"/root/Main/Pop-up Sprite/Pop-up".offset_y = $"/root/Main/Pop-up Sprite/Pop-up".offset_top
		if $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "removal_token_prompt":
			$"/root/Main/Pop-up Sprite/Pop-up".resolve_event("<icon_deny>")
		else:
			$"/root/Main/Pop-up Sprite/Pop-up".resolve_event("dont")
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		for e in $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.ending_emails:
			var e_type = e.type
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.emails.has(e_type):
				e_type += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.emails[e_type]
			if $"/root/Main".mod_pack_nums.has(e_type):
				e_type += "_PACK_" + str($"/root/Main".mod_pack_nums[e_type])
			if e.keys().size() > 1:
				var extra_values = e.duplicate(true)
				extra_values.erase("type")
				extra_values["push_front"] = true
				$"/root/Main/Pop-up Sprite/Pop-up".add_event(e_type, extra_values)
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".add_event(e_type, null)
	else:
		$"/root/Main/Pop-up Sprite/Pop-up".add_event("ending", {"push_front": true})
	if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
		$"/root/Main/Music Player".fully_fade_out()
		$"/root/Main/Music Player".play_rand_music()
		$"/root/Main/Music Player".fade_in()
	$"/root/Main/Stats Sprite/Stats".unlock_achievement(83, true)

func save():
	var save_dict = {
		"path": get_path(),
		"hp": hp,
		"max_hp": max_hp,
		"queued_damage": queued_damage,
		"fine_print_counter": fine_print_counter,
		"fine_print_threshhold": fine_print_threshhold,
		"queued_fine_print": queued_fine_print,
		"fine_print": fine_print,
		"stolen_symbols": stolen_symbols,
		"stolen_items": stolen_items,
		"doing_entrance_anim": doing_entrance_anim,
		"anim_time": anim_time
	}
	return save_dict
