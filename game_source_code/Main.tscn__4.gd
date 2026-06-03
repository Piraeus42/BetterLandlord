extends Node2D

var displayed_icons = []
var selected_icons = []
var selected_reels = []
var added_icons = []
var conditional_effects = []
var reel_height = 4
var reel_width = 5
var reels = []
var reel_borders = []
var clumps = []
var group_clumps = []
var making_group_clumps = null
var texts = []
var effects_playing = false
var line_colors = ["005499", "CD0074", "FF3333", "00CCCC", "990056", "BF2626"]
var line_color_num = 0
var checking_effects = false
var counting_effects = false
var symbol_queue = []
var symbol_arr = []
var symbol_positions_to_update = []
var symbol_positions_tbd = []

var items
var popup

var sfx_queue = []
var sfx_queue_hashes = []
var p_tbe = []

var fanfare_offset = 35
var instant_fanfare = false
var auto_spin = false
var spinning = false
var counting_symbols = false

var first_one = false
var change_type_checking = false
var type_changed = false
var true_final_value = false
var symbol_removed_during_spin = false
var symbol_destroyed_during_spin = false
var symbol_transformed_during_spin = false
var dove_prevention = false
var destroyed_item_this_spin = false

var counted_symbols = {}
var checked_diff_multis = false
var checking_last_effects = false
var adding_rarity_effects = false
var sfx_timer = 0
var coin_goal_y_offset = 0
var items_being_added_during_spin = 0
var queued_achievements = []
var big_wildcards = []
var added_symbols = []
var destroyed_symbols = []
var bad_arrows = []
var ninja_timer = 0
var grown_strawberries = 0
var grown_apples = 0
var queued_milk = 0
var queued_banana_peels = 0
var queued_honey = 0
var queued_seeds = 0
var stealing_magpie = false

var tmp_effects = []

func _ready():
	do_counted_symbols()
	for i in range(reel_width):
		reels.push_back(get_child(i + 6))
		reel_borders.push_back(get_child(i))
	draw_reels()
	coin_goal_y_offset = $"/root/Main/Options Sprite/Options".resolution_y - 576
	for i in range(reel_height):
		var arr = []
		arr.resize(reel_width)
		conditional_effects.push_back(arr.duplicate())
		displayed_icons.push_back(arr.duplicate())
		added_icons.push_back(arr.duplicate())
	for x in range(reel_width):
		for y in range(reel_height):
			conditional_effects[y][x] = []
	for i in range(reel_width * reel_height):
		var s = Node2D.new()
		s.z_index = 4
		texts.push_back(preload("res://Effect Text.tscn").instance())
		texts[i].rect_size = Vector2(1024, 576)
		texts[i].visible = false
		s.add_child(texts[i])
		add_child(s)
	items = $"/root/Main/Items".items
	popup = $"/root/Main/Pop-up Sprite/Pop-up"

func draw_reels():
	var sc = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	for i in range(reel_width):
		var r = get_child(i + 6)
		var r_border = get_child(i)
		r.mod = int(round(112 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui))
		r.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x / 2 - (reel_width * 120 * sc / 2) + i * 120 * sc + 4 * sc, 8 + ($"/root/Main/Options Sprite/Options".resolution_y - 576) / 2 + (1 - sc) * 120 * reel_height / 2)
		r.reel_num = i
		r.rect_size.x = 112 * sc
		r.rect_size.y = 112 * reel_height * sc
		r_border.position = Vector2(r.rect_position.x - 8 * sc, r.rect_position.y - 8 * sc)
		r_border.get_child(0).rect_size.x = 120 * sc
		r_border.get_child(0).rect_size.y = r.rect_size.y + 16 * sc
		r_border.get_child(1).get_child(0).rect_position.x = 120 * sc
		r_border.get_child(1).get_child(0).rect_size.x = 8 * sc
		r_border.get_child(1).get_child(0).rect_size.y = r.rect_size.y + 16 * sc
		r_border.get_child(1).get_child(1).rect_position.x = 120 * sc
		r_border.get_child(1).get_child(1).rect_size.x = 8 * sc
		r_border.get_child(1).get_child(1).rect_size.y = r.rect_size.y + 16 * sc
		r.max_spin_delay = r.reel_num
		r.spin_speed = 56 * sc
		r.spin_diff = 0
		r.instant_spins = false
		r.spin_delay = r.max_spin_delay
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		$"/root/Main/Landlord/Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"/root/Main/Landlord/Temp".get_font("font").get_string_size($"/root/Main/Landlord/Temp".get_child(0).text).x * $"/root/Main/Landlord/Temp".current_scale / 2.0
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"/root/Main/Landlord/Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"/root/Main/Landlord/Temp".get_child(0).get_font("font").get_string_size($"/root/Main/Landlord/Temp".get_child(0).text).x * $"/root/Main/Landlord/Temp".current_scale / 2.0
	else:
		$"/root/Main/Landlord/Temp".rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - $"/root/Main/Landlord/Temp".get_font("font").get_string_size($"/root/Main/Landlord/Temp".text).x * $"/root/Main/Landlord/Temp".current_scale * 2.0
	$"/root/Main/Landlord/Temp".rect_position.y = $"/root/Main/Reels/Reel Border".position.y
	if $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight:
		$"/root/Main/Reels/Landlord Bar".rect_position = $"/root/Main/Reels/Reel Border".position
		$"/root/Main/Reels/Landlord Bar".rect_size = Vector2($"/root/Main/Reels/Reel Border5".position.x - $"/root/Main/Reels/Reel Border".position.x + $"/root/Main/Reels/Reel Border5".get_child(0).rect_size.x + $"/root/Main/Reels/Reel Border5".get_child(1).get_child(0).rect_size.x, $"/root/Main/Reels/Reel Border".get_child(0).rect_size.y * ((float($"/root/Main/Landlord".hp) + float($"/root/Main/Landlord".queued_damage)) / float($"/root/Main/Landlord".max_hp)))
		for r in $"/root/Main/Reels".reel_borders:
			r.get_child(1).get_child(1).rect_size.y = $"/root/Main/Reels/Reel Border".get_child(0).rect_size.y * ((float($"/root/Main/Landlord".hp) + float($"/root/Main/Landlord".queued_damage)) / float($"/root/Main/Landlord".max_hp))

func update():
	if checking_effects:
		check_effects()
	if sfx_queue.size() > 0:
		var to_be_removed = []
		if $"/root/Main/Options Sprite/Options".counting_speed == 0:
			var s = sfx_queue[0]
			for b in sfx_queue:
				if b.delay > s.delay:
					s = b
			get_node("sfx" + s.name[-1]).stop()
			get_node("sfx" + s.name[-1]).set_stream(load("res://sfx/%s.wav" % str(s.name)))
			get_node("sfx" + s.name[-1]).volume_db = $"/root/Main/Options Sprite/Options".sfx.goal_volume
			if get_node("sfx" + s.name[-1]).volume_db > -80 and not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not $"/root/Main".window_focus):
				get_node("sfx" + s.name[-1]).play()
			sfx_queue.clear()
			sfx_queue_hashes.clear()
		else:
			for s in sfx_queue:
				if s.delay <= 0:
					get_node("sfx" + s.name[-1]).stop()
					get_node("sfx" + s.name[-1]).set_stream(load("res://sfx/%s.wav" % str(s.name)))
					get_node("sfx" + s.name[-1]).volume_db = $"/root/Main/Options Sprite/Options".sfx.goal_volume
					if get_node("sfx" + s.name[-1]).volume_db > -80 and not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not $"/root/Main".window_focus):
						get_node("sfx" + s.name[-1]).play()
					to_be_removed.push_back(s)
				else:
					if $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset == 0.75:
						if $"/root/Main".frame_timer % 3 != 0:
							s.delay -= 1
					elif $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset == 0.5:
						if $"/root/Main".frame_timer % 2 != 0:
							s.delay -= 1
					else:
						s.delay -= ($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset)
			for s in to_be_removed:
				sfx_queue.erase(s)
	else:
		sfx_queue_hashes.clear()
	if sfx_timer > 0:
		sfx_timer -= 1

func load_icons():
	for r in reels:
		r.load_icons()

func do_counted_symbols():
	if $"/root/Main".group_database["symbols"].has("counted"):
		for g in $"/root/Main".group_database["symbols"]["counted"]:
			counted_symbols[g] = 0
	for g in $"/root/Main".counted_symbols.keys():
		counted_symbols[g] = 0

func spin():
	if effects_playing or popup.emails.size() > 0 or $"/root/Main/Coins".coins <= 0 or $"/root/Main/Landlord".anim_time > 0 or $"/root/Main/Sums/HP Sum".adding:
		return
	
	for e in texts:
		if e.effect_timer > 0:
			return
	
	effects_playing = false
	var sc
	var ic
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		sc = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui / 2.0
		ic = $"/root/Main/Options Sprite/Options".ui_scaling.items_ui / 2.0
	else:
		sc = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
		ic = $"/root/Main/Options Sprite/Options".ui_scaling.items_ui
	for e in range(texts.size()):
		texts[e].visible = false
		for l in range(texts[e].lines.size()):
			texts[e].lines[l].line.queue_free()
			texts[e].lines[l].queue_free()
		texts[e].lines.clear()
		texts[e].line_targets.clear()
		texts[e].coin_value = 0
		texts[e].reroll_value = 0
		texts[e].removal_value = 0
		texts[e].essence_value = 0
		texts[e].force_update = true
		if e < reel_width * reel_height:
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				texts[e].text_mod = 1 + -floor((1 - sc) / 0.25)
				texts[e].scale_mod = 1 + -floor((1 - sc) / 0.25) + 1
				if $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui >= 1:
					var extra_mod = int(floor(($"/root/Main/Options Sprite/Options".ui_scaling.reels_ui - 0.5) * 4))
					if extra_mod % 2 == 1:
						extra_mod -= 1
					texts[e].text_mod += extra_mod
			else:
				texts[e].text_mod = -floor((1 - sc) / 0.25)
				texts[e].scale_mod = -floor((1 - sc) / 0.25) + 1
				if $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui == 1.5:
					texts[e].text_mod += 1
					texts[e].scale_mod += 1
				elif $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui >= 3:
					texts[e].scale_mod -= 3
		else:
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				texts[e].text_mod = 1 + -floor((1 - ic) / 0.25)
				texts[e].scale_mod = 1 + -floor((1 - ic) / 0.25) + 1
			else:
				texts[e].text_mod = -floor((1 - ic) / 0.25)
				texts[e].scale_mod = -floor((1 - ic) / 0.25) + 1
				if ic < 1:
					texts[e].scale_mod += 1
		texts[e].change_set_size(texts[e].base_scale)
	$"/root/Main/Sums/Coin Sum".set_start_pos()
	
	for r in reels:
		if r.spinning:
			return
	
	add_tba_symbols()
	
	var ninja_in_inv = false
	
	for r in reels:
		r.spinning = true
		if r.icon_types.has("ninja"):
			ninja_in_inv = true
		for i in r.icons:
			if i.type == "reroll_capsule":
				i.saved_achievement_values[0] += 1
			elif i.type == "removal_capsule":
				i.saved_achievement_values[0] += 1
			elif i.type == "lucky_capsule":
				i.saved_achievement_values[0] += 1
			elif i.type == "chick":
				i.saved_achievement_values[0] += 1
				
	if ninja_in_inv:
		ninja_timer += 1
	
	spinning = true
	
	for i in items:
		i.destroyed = false
		i.c_effects.clear()
		i.item_adding_effects.clear()
	
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.dud_timer != 0:
		if ($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid) < 12 and int(popup.spins) % $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.dud_timer == 0 and popup.spins != 0:
			add_tile(["dud"])
	elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 19:
		if ($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid) < 12 and int(popup.spins) % 15 == 0 and popup.spins != 0:
			add_tile(["dud"])
	elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 14:
		if $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12 and int(popup.spins) % 20 == 0 and popup.spins != 0:
			add_tile(["dud"])
	elif $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 10:
		if $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12 and int(popup.spins) % 25 == 0 and popup.spins != 0:
			add_tile(["dud"])
	
	$"/root/Main/Coins".queued_increase -= 1
	
	$"/root/Main".write_log("--- SPIN #" + str(popup.spins) + " ---")
	$"/root/Main".write_log("Currently have " + str($"/root/Main/Coins".coins) + " coins")
	if $"/root/Main/Landlord".fine_print.size() > 0:
		var fp_str = "Fine print is: ["
		for p in $"/root/Main/Landlord".fine_print:
			fp_str += str(p.num) + ", "
		$"/root/Main".write_log(fp_str.substr(0, fp_str.length() - 2) + "]")
	
	popup.rarity_bonuses = { "symbols": { "uncommon": 1, "rare": 1, "very_rare": 1 }, "items": { "uncommon": 1, "rare": 1, "very_rare": 1 } }
	popup.hex_of_emptiness_trigger = false
	popup.hex_of_hoarding_trigger = false
	popup.symbols_to_choose_from = 3
	popup.symbols_to_choose_from_from_mods = 0
	
	symbol_positions_to_update.clear()
	symbol_positions_tbd.clear()
	
	for t in $"/root/Main/Tooltips".get_children():
		t.queue_free()
	
	popup.prompts_passed.clear()
	popup.saved_symbol_order.clear()

func add_tba_symbols():
	for r in reels:
		for t in r.icon_types_to_be_added:
			var icon = generate_icon(t, null)
			r.icons.push_back(icon)
			r.icon_types.push_back(t)
			r.saved_icon_data.push_back({ "coins_earned": 0, "times_coins_given": 0, "times_displayed": 0, "permanent_bonus": 0, "reroll_token_permanent_bonus": 0, "removal_token_permanent_bonus": 0, "essence_token_permanent_bonus": 0, "permanent_multiplier": 1, "reroll_token_permanent_multiplier": 1, "removal_token_permanent_multiplier": 1, "essence_token_permanent_multiplier": 1, "saved_value": 0, "saved_values": {} })
			r.max_icons += 1
			r.add_child(icon)
			if not (r.icons.size() <= reel_height and r.icons.size() > 0):
				icon.visible = false
				icon.set_process_input(false)
			icon.add_init_permanent_bonuses()
		r.icon_types_to_be_added.clear()
		var increment = 0
		for i in r.icons:
			i.stop_animations()
			i.stop_sfx()
			i.hovering = false
			i.active = false
			i.position.y = (increment * r.mod + r.spin_offset) % (r.icons.size() * r.mod) - r.mod
			if increment > 0 or increment < reel_height:
				i.visible = true
				i.set_process_input(true)
				get_child(1).visible = true
				get_child(2).visible = true
				get_child(3).visible = true
			else:
				i.get_child(1).raw_string = ""
				i.get_child(1).visible = false
				i.get_child(2).visible = false
				i.get_child(3).visible = false
			increment += 1
		r.icon_types_tba_bonus_texts.clear()

func can_add_highlander():
	for x in range(reel_width):
		for y in range(reels[x].icons.size()):
			if reels[x].icons[y].type == "highlander":
				return false
	return true

func check_icon_match(icon1, icon2):
	if icon1.type == "empty" or icon2.type == "empty":
		return false
	if icon1.type == icon2.type:
		return true
	if making_group_clumps != null:
		var group_clump = false
		var gc = making_group_clumps.keys()
		if gc.has("groups"):
			var i1 = false
			var i2 = false
			for g in making_group_clumps.groups:
				if icon1.groups.has(g):
					i1 = true
				if icon2.groups.has(g):
					i2 = true
				if i1 and i2:
					group_clump = true
					break
		elif gc.has("types"):
			for g in making_group_clumps.types:
				if making_group_clumps.types.has(icon1.type) and making_group_clumps.types.has(icon2.type):
					group_clump = true
					break
		return group_clump
	else:
		return false
	return false

func shuffle_tiles():
	if (($"/root/Main".sandbox_mode and not $"/root/Main".sandbox_consistent) or not $"/root/Main".sandbox_mode) and ($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor == null or typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) == TYPE_STRING or not $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.consistent_spins):
		var pool = []
		var empty_pool = []
		var total_empties = 0
		var added_empties = 0
		var passes = 0
		for r in reels:
			for i in r.icons:
				pool.push_back(i)
				if i.type == "empty":
					empty_pool.push_back(i)
					total_empties += 1
			r.icons.clear()
			r.max_icons = 0
		var nice_empties = true
		while true:
			if pool.size() <= 25 or total_empties == 0 or not nice_empties:
				break
			else:
				pool.erase(empty_pool[0])
				symbol_arr.erase(empty_pool[0])
				empty_pool[0].queue_free()
				empty_pool.remove(0)
				total_empties -= 1
		randomize()
		pool.shuffle()
		for i in range(pool.size()):
			pool[i].get_parent().remove_child(pool[i])
			if pool[i].type == "empty" and pool.size() - total_empties + added_empties >= 25 and nice_empties:
				passes += 1
			else:
				if pool[i].type == "empty":
					added_empties += 1
				reels[(i - passes) % reel_width].icons.push_back(pool[i])
				reels[(i - passes) % reel_width].add_child(pool[i])
				reels[(i - passes) % reel_width].max_icons += 1
		if nice_empties:
			var offscreen_non_empties = []
			var empties = []
			for r in reels:
				var increment = 0
				for i in r.icons:
					i.position.y = (increment * 112 + (r.reel_num + 1) * 112) % (r.icons.size() * 112) - 112
					i.grid_position = Vector2(i.get_parent().reel_num, int(floor(i.position.y / 112)))
					if (floor(i.position.y / 112) < 0 or floor(i.position.y / 112) >= reel_height) and i.type != "empty":
						offscreen_non_empties.push_back(i)
					elif floor(i.position.y / 112) >= 0 and floor(i.position.y / 112) < reel_height and i.type == "empty":
						empties.push_back(i)
					increment += 1
			empties.shuffle()
			if offscreen_non_empties.size() != 0:
				for e in range(empties.size()):
					if e >= offscreen_non_empties.size():
						break
					else:
						swap_icon_positions(empties[e], offscreen_non_empties[e])
		pool.clear()
		update_icon_types()

func update_icon_types():
	for r in reels:
		r.icon_types.clear()
		r.saved_icon_data.clear()
		r.icon_types.resize(r.icons.size())
		r.saved_icon_data.resize(r.icons.size())
		for i in r.icons:
			r.icon_types[i.grid_position.y] = i.type
			r.saved_icon_data[i.grid_position.y] = { "coins_earned": i.coins_earned, "times_coins_given": i.times_coins_given, "times_displayed": i.times_displayed, "permanent_bonus": i.permanent_bonus, "reroll_token_permanent_bonus": i.reroll_token_permanent_bonus, "removal_token_permanent_bonus": i.removal_token_permanent_bonus, "essence_token_permanent_bonus": i.essence_token_permanent_bonus, "permanent_multiplier": i.permanent_multiplier, "reroll_token_permanent_multiplier": i.reroll_token_permanent_multiplier, "removal_token_permanent_multiplier": i.removal_token_permanent_multiplier, "essence_token_permanent_multiplier": i.essence_token_permanent_multiplier, "saved_value": i.saved_value, "saved_values": i.saved_values.duplicate(true) }

func swap_icon_positions(i1, i2):
	var values_to_keep = ["destroyed", "indestructible", "coins_earned", "times_coins_given", "times_displayed", "value_bonus_arr", "value_multiplier_arr", "permanent_bonus", "displayed_text_value", "final_value", "non_flat_final_value", "non_prev_final_value", "tried_to_give_rand_eff", "permanent_bonus", "reroll_token_permanent_bonus", "removal_token_permanent_bonus", "permanent_multiplier", "reroll_token_permanent_multiplier", "removal_token_permanent_multiplier", "essence_token_permanent_multiplier", "saved_value", "saved_values", "achievement_values", "saved_achievement_values"]
	
	var i1_data = {}
	var i2_data = {}
	
	for v in values_to_keep:
		i1_data[v] = i1[v]
		i2_data[v] = i2[v]
		
	var type1 = i1.type
	var type2 = i2.type
	
	i1.soft_changing = true
	i2.soft_changing = true
	
	i1.change_type(type2, false)
	i2.change_type(type1, false)
	
	for v in values_to_keep:
		i1[v] = i2_data[v]
		i2[v] = i1_data[v]
	
	i1.soft_changing = false
	i2.soft_changing = false
	
	i1.prev_data.clear()
	i2.prev_data.clear()

func write_pre_effects_log():
	$"/root/Main".write_log("Spin layout before effects is:")
	var grid_string = ""
	for y in range(reel_height):
		grid_string += "["
		for x in range(reel_width):
			grid_string += displayed_icons[y][x].type
			if displayed_icons[y][x].displayed_text_value != "":
				grid_string += " (" + displayed_icons[y][x].displayed_text_value + ")"
			if x != reel_width - 1:
				grid_string += ", "
		grid_string += "]"
		$"/root/Main".write_log(grid_string)
		grid_string = ""
	var item_string = "["
	for i in range(items.size()):
		item_string += items[i].type
		if items[i].saved_value != 0:
			item_string += " (" + str(items[i].saved_value) + ")"
		if i != items.size() - 1:
			item_string += ", "
	item_string += "]"
	$"/root/Main".write_log("Items before effects are:")
	$"/root/Main".write_log(item_string)

func write_post_effects_log():
	$"/root/Main".write_log("Spin layout after effects is:")
	var grid_string = ""
	for y in range(reel_height):
		grid_string += "["
		for x in range(reel_width):
			grid_string += displayed_icons[y][x].type
			if displayed_icons[y][x].displayed_text_value != "" or displayed_icons[y][x].displayed_multiplier_value != "" or displayed_icons[y][x].displayed_bonus_value != "" or displayed_icons[y][x].pointing_directions.size() > 0:
				grid_string += "("
				if displayed_icons[y][x].displayed_text_value != "":
					grid_string += displayed_icons[y][x].displayed_text_value + ", "
				if displayed_icons[y][x].displayed_bonus_value != "":
					grid_string += "+" + str(displayed_icons[y][x].permanent_bonus) + ", "
				if displayed_icons[y][x].displayed_multiplier_value != "":
					grid_string += str(displayed_icons[y][x].permanent_multiplier) + "x, "
				if displayed_icons[y][x].pointing_directions.size() > 0:
					for p in displayed_icons[y][x].pointing_directions:
						match p:
							1:
								grid_string += "NE"
							2:
								grid_string += "N"
							3:
								grid_string += "NW"
							4:
								grid_string += "E"
							5:
								grid_string += "SE"
							6:
								grid_string += "S"
							7:
								grid_string += "SW"
							8:
								grid_string += "W"
						if p != displayed_icons[y][x].pointing_directions[displayed_icons[y][x].pointing_directions.size() - 1]:
							grid_string += ", "
					grid_string += ", "
				if grid_string[grid_string.length() - 2] == ",":
					grid_string = grid_string.substr(0, grid_string.length() - 2)
				grid_string += ")"
			if x != reel_width - 1:
				grid_string += ", "
		grid_string += "]"
		$"/root/Main".write_log(grid_string)
		grid_string = ""
	$"/root/Main".write_log("Symbol values after effects are:")
	var value_string = ""
	for y in range(reel_height):
		value_string += "["
		for x in range(reel_width):
			value_string += str(displayed_icons[y][x].get_value("coin"))
			var reroll_value = displayed_icons[y][x].get_value("reroll_token")
			var removal_value = displayed_icons[y][x].get_value("removal_token")
			var essence_value = displayed_icons[y][x].get_value("essence_token")
			if reroll_value != 0:
				value_string += "r" + str(reroll_value)
			if removal_value != 0:
				value_string += "v" + str(removal_value)
			if essence_value != 0:
				value_string += "e" + str(essence_value)
			if x != reel_width - 1:
				value_string += ", "
		value_string += "]"
		$"/root/Main".write_log(value_string)
		value_string = ""
	var item_string = "["
	for i in range(items.size()):
		item_string += items[i].type
		if items[i].disabled:
			item_string += "_d"
		if items[i].saved_value != 0:
			item_string += " (" + str(items[i].saved_value) + ")"
		if i != items.size() - 1:
			item_string += ", "
	item_string += "]"
	$"/root/Main".write_log("There are " + str(items.size()) + " items:")
	$"/root/Main".write_log(item_string)
	var item_value_string = "["
	for i in range(items.size()):
		item_value_string += str(items[i].value)
		if i != items.size() - 1:
			item_value_string += ", "
	item_value_string += "]"
	$"/root/Main".write_log("Item values after effects are:")
	$"/root/Main".write_log(item_value_string)
	$"/root/Main".write_log("There are " + str(popup.destroyed_symbol_types_size) + " destroyed symbols:")
	$"/root/Main".write_log(str(popup.destroyed_symbol_types))
	$"/root/Main".write_log("There are " + str($"/root/Main/Items".destroyed_items.size()) + " destroyed items:")
	$"/root/Main".write_log(str($"/root/Main/Items".destroyed_items))

func generate_icon(type, known_data):
	var s = preload("res://Slot Icon.tscn").instance()
	s.type = type
	
	if not $"/root/Main".tile_database.has(s.type):
		s.type = "missing"
	var tile = $"/root/Main".tile_database[s.type]
	
	s.rarity = tile.rarity
	s.value = int(tile.value)
	if typeof(s.value) == TYPE_STRING:
		s.value = 0
	s.final_value = s.value
	s.non_flat_final_value = s.value
	s.non_prev_final_value = s.value
	s.values = [0, 0, 0, 0]
	s.modded = tile.modded
	if tile.has("inherit_effects"):
		s.inherit_effects = tile.inherit_effects
	s.sfx_values = tile.sfx.duplicate(true)
	for v in range(tile.values.size()):
		if v >= 3:
			s.values.push_back(tile.values[v])
		else:
			s.values[v] = tile.values[v]
	s.groups = tile.groups
	s.sfx_values = tile.sfx
	if type == "dud":
		s.can_be_removed = false
	else:
		s.can_be_removed = true
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.dynamic_icon != null and type == fp.dynamic_icon:
				match int(fp.num):
					20, 21, 36:
						s.can_be_removed = false
						break
	
	var pack_num = ""
	for m in $"/root/Main".mod_packs.keys():
		for t in $"/root/Main".mod_packs[m]:
			if t.type.substr(0, t.type.find_last("_")) == s.type and t.mod_type == "art_replacement":
				pack_num = "_" + str(m)
				break
	
	match s.type:
		"d5":
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 6):
				if $"/root/Main".is_mod_disabled("dice" + str(i) + pack_num):
					s.extra_textures.push_back(texture_db["dice" + str(i)])
				else:
					s.extra_textures.push_back(texture_db["dice" + str(i) + pack_num])
		"d3":
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 4):
				if $"/root/Main".is_mod_disabled("d3_" + str(i) + pack_num):
					s.extra_textures.push_back(texture_db["d3_" + str(i)])
				else:
					s.extra_textures.push_back(texture_db["d3_" + str(i) + pack_num])
		"bronze_arrow", "silver_arrow", "golden_arrow":
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 9):
				if $"/root/Main".is_mod_disabled(s.type + str(i) + pack_num):
					s.extra_textures.push_back(texture_db[s.type + str(i)])
				else:
					s.extra_textures.push_back(texture_db[s.type + str(i) + pack_num])
		_:
			if s.modded:
				var texture_db = $"/root/Main".icon_texture_database
				for i in texture_db:
					var digit_pos = s.type.find("_STEAM_ID_")
					if i.substr(0, digit_pos) + i.substr(digit_pos + 1, -1) == s.type.substr(0, s.type.find("_PACK_")):
						var digit = int(i[i.find("_STEAM_ID_") - 1])
						if s.extra_textures.size() < digit:
							s.extra_textures.resize(digit)
						s.extra_textures[digit - 1] = texture_db[i]

	for v in range(s.values.size()):
		s.bonus_values.push_back(0)
		s.bonus_value_multipliers.push_back(1)
	
	if known_data != null:
		for k in known_data.keys():
			s[k] = known_data[k]
	
	symbol_arr.push_back(s)
	
	return s

func get_non_singular_symbols():
	var v = 0
	var symbol_counts = {}
	for s in symbol_arr:
		if s.type != "empty":
			if not symbol_counts.has(s.type):
				symbol_counts[s.type] = 1
			else:
				symbol_counts[s.type] += 1
	for s in symbol_counts.keys():
		if symbol_counts[s] >= 2:
			v += 1
	return v

func add_tile(t):
	
	added_symbols += t
	
	var visible_possibles = []
	var possibles = []
	var num = 0
	for type in t:
		randomize()
		
		visible_possibles.clear()
		possibles.clear()
		
		for r in range(reels.size()):
			for i in reels[r].icons:
				if i.type == "empty" and not t.has("empty"):
					possibles.push_back(r)
					if i.grid_position.y >= 0 and i.grid_position.y <= reel_height - 1:
						visible_possibles.push_back(r)
						break
		num += 1
		if visible_possibles.size() > 0:
			reels[visible_possibles[floor(rand_range(0, visible_possibles.size()))]].add_tile([type])
		elif possibles.size() > 0:
			reels[possibles[floor(rand_range(0, possibles.size()))]].add_tile([type])
		else:
			for r in range(reels.size()):
				if possibles.size() > 0 and reels[r].max_icons > possibles[0].total_icons:
					possibles.clear()
					possibles.push_back({"pos": r, "total_icons": reels[r].max_icons})
				elif reels[r].max_icons > 0:
					possibles.push_back({"pos": r, "total_icons": reels[r].max_icons})
			reels[possibles[floor(rand_range(0, possibles.size()))].pos].add_tile([type])
			break
	if num < t.size():
		reels[possibles[floor(rand_range(0, possibles.size()))].pos].add_tile(t.slice(num, t.size(), true))
	popup.saved_symbol_order.clear()
	popup.saved_symbol_data.clear()
	popup.saved_symbol_counts.clear()
	
	var item_types = $"/root/Main/Items".item_types
	
	if not checking_effects:
		for e in $"/root/Main".mod_on_symbol_add_effects:
			var item_num = item_types.find($"/root/Main".existing_items[e.type])
			if item_num == -1:
				continue
			var i = items[item_num]
			i.addding_post_spin_effects = true
			i.add_conditional_effects()
			i.addding_post_spin_effects = false
			i.check_conditional_effects()
			i.c_effects.clear()
	if $"/root/Main/Items".has_unmodded_item("brown_pepper"):
		var i = items[item_types.find($"/root/Main".existing_items["brown_pepper"])]
		if checking_effects:
			popup.symbols_added_this_spin += float(t.size())
		else:
			$"/root/Main/Sums/Coin Sum".add_value(i.values[0] * i.item_count)
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(i.values[0] * i.item_count)
			$"/root/Main/Sums/HP Sum".adding = true
	if $"/root/Main/Items".has_unmodded_item("brown_pepper_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["brown_pepper_essence"])]
		if not checking_effects:
			$"/root/Main/Sums/Coin Sum".add_value(i.values[0] * t.size())
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(i.values[0] * t.size())
			$"/root/Main/Sums/HP Sum".adding = true
		else:
			i.value += i.values[0] * t.size()
		i.temp_destroy()
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("frozen_pizza_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["frozen_pizza_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("shattered_mirror_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["shattered_mirror_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
			$"/root/Main/Sums/Coin Sum".add_value(i.values[2])
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(i.values[2])
			$"/root/Main/Sums/HP Sum".adding = true
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("symbol_bomb_small_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["symbol_bomb_small_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
			$"/root/Main/Sums/Extra Sum".add_value(0, i.values[1], 0)
			$"/root/Main/Sums/Extra Sum".adding = true
			popup.removal_tokens += i.values[1]
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("symbol_bomb_big_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["symbol_bomb_big_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
			$"/root/Main/Sums/Extra Sum".add_value(0, i.values[1], 0)
			$"/root/Main/Sums/Extra Sum".adding = true
			popup.removal_tokens += i.values[1]
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("symbol_bomb_very_big_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["symbol_bomb_very_big_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
			$"/root/Main/Sums/Extra Sum".add_value(0, i.values[1], 0)
			$"/root/Main/Sums/Extra Sum".adding = true
			popup.removal_tokens += i.values[1]
	if not checking_effects and $"/root/Main/Items".has_unmodded_item("symbol_bomb_quantum_essence") and not spinning:
		var i = items[item_types.find($"/root/Main".existing_items["symbol_bomb_quantum_essence"])]
		i.saved_value += 1
		i.update_value_text()
		if i.saved_value >= i.values[0]:
			i.temp_destroy()
			$"/root/Main/Items".add_item("symbol_bomb_quantum")
	for type in t:
		if $"/root/Main/Items".has_unmodded_item("lunchbox_essence") and $"/root/Main".group_database.symbols["food"].has(type) and not spinning:
			var i = items[item_types.find($"/root/Main".existing_items["lunchbox_essence"])]
			i.saved_value += 1
			i.update_value_text()
			if i.saved_value >= i.values[0]:
				if not checking_effects:
					i.temp_destroy()
					$"/root/Main/Sums/Coin Sum".add_value(i.values[1])
					$"/root/Main/Sums/Coin Sum".adding = true
					$"/root/Main/Sums/HP Sum".add_value(i.values[1])
					$"/root/Main/Sums/HP Sum".adding = true
				else:
					i.destroyed = true
		if $"/root/Main/Items".has_unmodded_item("adoption_papers_essence") and $"/root/Main".group_database.symbols["animal"].has(type) and not spinning:
			var i = items[item_types.find($"/root/Main".existing_items["adoption_papers_essence"])]
			i.saved_value += 1
			i.update_value_text()
			if i.saved_value >= i.values[0]:
				if not checking_effects:
					i.temp_destroy()
					$"/root/Main/Sums/Coin Sum".add_value(i.values[1])
					$"/root/Main/Sums/Coin Sum".adding = true
					$"/root/Main/Sums/HP Sum".add_value(i.values[1])
					$"/root/Main/Sums/HP Sum".adding = true
				else:
					i.destroyed = true

func add_symbol_position_to_update(grid_pos):
	if not symbol_positions_to_update.has(grid_pos) or (symbol_positions_to_update.count(grid_pos) == p_tbe.count(grid_pos) and symbol_positions_to_update.has(grid_pos)):
		symbol_positions_to_update.push_back(grid_pos)

func add_symbol_position_tbd(grid_pos):
	if not symbol_positions_tbd.has(grid_pos) or (symbol_positions_tbd.count(grid_pos) == p_tbe.count(grid_pos) and symbol_positions_tbd.has(grid_pos)):
		symbol_positions_tbd.push_back(grid_pos)

func count_symbols(c_b):
	var can_break = c_b
	var all_zeroes = true
	var to_update = []
	var not_ready = false
	if can_break and all_zeroes:
		$"/root/Main/Reels".counting_symbols = true
		for i in items:
			if not i.destroyed:
				i.symbol_check()
			i.check_conditional_effects()
			if i.changed_value:
				can_break = false
		$"/root/Main/Reels".counting_symbols = false
		var temp_counts = {}
		var first_bools = {}
		for c in counted_symbols.keys():
			temp_counts[c] = 0
			if $"/root/Main".group_database["symbols"]["eachother"].has(c):
				first_bools[c] = false
			else:
				first_bools[c] = true
		for x in range(reel_width):
			for y in range(reel_height):
				if displayed_icons[y][x] == null:
					not_ready = true
					break
				for c in counted_symbols.keys():
					if displayed_icons[y][x].type == c:
						if first_bools[c]:
							temp_counts[c] += 1
						else:
							first_bools[c] = true
						to_update.push_back(Vector2(x, y))
						break
				for c in counted_symbols.keys():
					for p in displayed_icons[y][x].prev_data:
						if p.type == c and displayed_icons[y][x].type != c:
							if first_bools[c]:
								temp_counts[c] += 1
							else:
								first_bools[c] = true
							to_update.push_back(Vector2(x, y))
			if not_ready:
				break
		if not not_ready:
			var counts_different = false
			for c in counted_symbols.keys():
				if counted_symbols[c] != temp_counts[c]:
					counts_different = true
					break
			if counts_different:
				for t in to_update:
					add_symbol_position_to_update(t)
				for c in counted_symbols.keys():
					counted_symbols[c] = temp_counts[c]
				can_break = false
	if counted_symbols.has("spirit") and counted_symbols["spirit"] >= 10:
		add_queued_achievement(130)
	if counted_symbols.has("spades") and counted_symbols["spades"] >= 5:
		add_queued_achievement(129)
	if counted_symbols.has("hearts") and counted_symbols["hearts"] >= 5:
		add_queued_achievement(66)
	if counted_symbols.has("clubs") and counted_symbols["clubs"] >= 5:
		add_queued_achievement(30)
	if counted_symbols.has("diamonds") and counted_symbols["diamonds"] >= 5:
		add_queued_achievement(45)
	if counted_symbols.has("diamond") and counted_symbols["diamond"] + 1 >= 5:
		add_queued_achievement(44)
	if counted_symbols.has("cultist") and counted_symbols["cultist"] + 1 >= 6:
		add_queued_achievement(40)
	if counted_symbols.has("candy") and counted_symbols["candy"] >= 8:
		add_queued_achievement(21)
	if counted_symbols.has("watermelon") and counted_symbols["watermelon"] + 1 >= 5:
		add_queued_achievement(145)
	return can_break

func add_effects():
	make_clumps()
	for x in range(reel_width):
		for y in range(reel_height):
			symbol_positions_to_update.push_back(Vector2(x, y))
	for i in items:
		i.add_conditional_effects()
		if i.type == "telescope" or i.type == "protractor" or i.type == "telescope_essence" or i.type == "protractor_essence":
			i.check_conditional_effects()
	adding_rarity_effects = true
	for x in range(reel_width):
		for y in range(reel_height):
			if displayed_icons[y][x].groups.has("raritymod") or displayed_icons[y][x].type == "dove":
				displayed_icons[y][x].add_conditional_effects()
				var can_break
				while true:
					can_break = true
					displayed_icons[y][x].check_conditional_effects(conditional_effects[y][x])
					if displayed_icons[y][x].changed_value:
						can_break = false
					if can_break:
						break
			displayed_icons[y][x].times_displayed += 1
	adding_rarity_effects = false
	for x in range(reel_width):
		for y in range(reel_height):
			displayed_icons[y][x].add_conditional_effects()
	$"/root/Main/Items".add_cond_effects()
	first_one = true

func check_effects():
	effects_playing = true
	checking_last_effects = false
	
	var can_break
	
	while true:
		can_break = true
		var no_anims = true
		
		if first_one:
			for i in items:
				if not i.destroyed:
					i.symbol_check()
				i.check_conditional_effects()
				if i.changed_value:
					can_break = false
			first_one = false
			no_anims = false
		else:
			for x in range(reel_width):
				for y in range(reel_height):
					if displayed_icons[y][x].queued_anims.size() > 0:
						no_anims = false
						break
				if not no_anims:
					break
		if no_anims or $"/root/Main/Options Sprite/Options".animation_speed == 0:
			if symbol_positions_tbd.size() == 0 and (symbol_destroyed_during_spin or symbol_queue.size() > 0 or type_changed):
				if symbol_queue.size() > 0:
					add_tile(symbol_queue)
				if symbol_queue.size() > 0 or type_changed or symbol_destroyed_during_spin:
					can_break = false
					if symbol_positions_to_update.size() > 0:
						for i in items:
							i.add_conditional_effects()
							i.symbol_check()
							i.check_conditional_effects()
						symbol_positions_to_update.sort()
						$"/root/Main/Items".add_cond_effects()
					symbol_queue.clear()
					$"/root/Main".save_log()
					type_changed = false
					symbol_destroyed_during_spin = false
					return
				elif symbol_positions_to_update.size() > 0 and type_changed:
					type_changed = false
					for i in items:
						i.symbol_check()
						i.check_conditional_effects()
				symbol_destroyed_during_spin = false
			symbol_positions_to_update.sort()
			for pos in symbol_positions_to_update:
				if can_break:
					var prev_changed_value = displayed_icons[pos.y][pos.x].changed_value
					displayed_icons[pos.y][pos.x].check_conditional_effects(conditional_effects[pos.y][pos.x])
					if displayed_icons[pos.y][pos.x].changed_value or prev_changed_value:
						can_break = false
						displayed_icons[pos.y][pos.x].update_value_text()
						if $"/root/Main/Options Sprite/Options".animation_speed == 0:
							while displayed_icons[pos.y][pos.x].queued_anims.size() > 0:
								displayed_icons[pos.y][pos.x].animate()
					else:
						p_tbe.push_back(pos)
				else:
					break
			if p_tbe.size() > 0:
				can_break = false
				for p in p_tbe:
					symbol_positions_to_update.erase(p)
				p_tbe.clear()
			if (symbol_positions_to_update.size() == 0 and symbol_positions_tbd.size() > 0) or symbol_removed_during_spin or symbol_transformed_during_spin or dove_prevention:
				var midas_bombs = []
				for s in symbol_positions_tbd:
					displayed_icons[s.y][s.x].destroy()
					if displayed_icons[s.y][s.x].prev_data[displayed_icons[s.y][s.x].prev_data.size() - 1].type == "midas_bomb":
						midas_bombs.push_back(s)
				for s in symbol_positions_tbd:
					displayed_icons[s.y][s.x].add_c_effs(true)
					displayed_icons[s.y][s.x].check_conditional_effects(conditional_effects[s.y][s.x])
					displayed_icons[s.y][s.x].update_value_text()
				symbol_positions_tbd.clear()
				for m in midas_bombs:
					displayed_icons[m.y][m.x].add_conditional_effects()
					for a in displayed_icons[m.y][m.x].get_adjacent_icons():
						a.check_conditional_effects(conditional_effects[a.grid_position.y][a.grid_position.x])
						a.update_value_text()
				for x in range(reel_width):
					for y in range(reel_height):
						displayed_icons[y][x].add_conditional_effects()
						add_symbol_position_to_update(Vector2(x, y))
				for i in items:
					i.symbol_check()
					i.check_conditional_effects()
				if not dove_prevention:
					symbol_destroyed_during_spin = true
				symbol_removed_during_spin = false
				symbol_transformed_during_spin = false
				dove_prevention = false
				can_break = false
			if can_break and destroyed_item_this_spin:
				destroyed_item_this_spin = false
				for x in range(reel_width):
					for y in range(reel_height):
						if checking_effects:
							add_symbol_position_to_update(Vector2(x, y))
						displayed_icons[y][x].update_value_text()
				for x in range(reel_width):
					for y in range(reel_height):
						displayed_icons[y][x].add_conditional_effects()
			can_break = count_symbols(can_break)
			if can_break and not checked_diff_multis and not $"/root/Main".demo:
				for x in range(reel_width):
					for y in range(reel_height):
						var data_arr = [displayed_icons[y][x]]
						data_arr += displayed_icons[y][x].prev_data
						var inc = 0
						for p in data_arr:
							if $"/root/Main".group_database.symbols["anvillikes"].has(p.type):
								var pdo
								if inc != 0:
									pdo = p
								data_arr[0].update_dynamic_diffs(true, "dwarf", pdo)
							elif $"/root/Main".group_database.symbols["monkeylikes"].has(p.type):
								var pdo
								if inc != 0:
									pdo = p
								data_arr[0].update_dynamic_diffs(true, "monkey", pdo)
							inc += 1
			if can_break and not checking_last_effects and not $"/root/Main".demo:
				checking_last_effects = true
				for i in items:
					i.add_conditional_effects()
					i.symbol_check()
					i.check_conditional_effects()
				for x in range(reel_width):
					for y in range(reel_height):
						displayed_icons[y][x].check_last_effects(conditional_effects[y][x])
		else:
			can_break = false
			break
		
		if can_break:
			break
			
	if not can_break:
		return
		
	checking_effects = false
	
	if $"/root/Main/Items".has_unmodded_item("ancient_lizard_blade"):
		var i = items[$"/root/Main/Items".item_types.find("ancient_lizard_blade")]
		var non_uniques = 0
		var symbol_counts = {}
		for s in symbol_arr:
			if s.type != "empty":
				if not symbol_counts.has(s.type):
					symbol_counts[s.type] = 1
				else:
					symbol_counts[s.type] += 1
		for s in symbol_counts.keys():
			if symbol_counts[s] >= i.values[2]:
				non_uniques += 1
		i.value = (i.values[0] - non_uniques * i.values[1]) * i.item_count
		if i.value < i.values[3]:
			i.value = i.values[3]
	if $"/root/Main/Items".has_unmodded_item("ancient_lizard_blade_essence"):
		var i = items[$"/root/Main/Items".item_types.find("ancient_lizard_blade_essence")]
		var non_uniques = 0
		var symbol_counts = {}
		for s in symbol_arr:
			if s.type != "empty":
				if not symbol_counts.has(s.type):
					symbol_counts[s.type] = 1
				else:
					symbol_counts[s.type] += 1
		for s in symbol_counts.keys():
			if symbol_counts[s] >= i.values[2]:
				non_uniques += 1
		i.value = (i.values[0] - non_uniques * i.values[1]) * i.item_count
		if i.value < i.values[3]:
			i.value = i.values[3]
	
	for x in range(reel_width):
		for y in range(reel_height):
			displayed_icons[y][x].flat_value_bonus = 0
			
	for x in range(reel_width):
		for y in range(reel_height):
			if displayed_icons[y][x].wildcarded:
				var updated = false
				
				for adj_icon in displayed_icons[y][x].get_adjacent_icons():
					if adj_icon.get_value("coin") > displayed_icons[y][x].flat_value_bonus and not adj_icon.wildcarded:
						displayed_icons[y][x].flat_value_bonus = adj_icon.get_value("coin")
						updated = true
	check_values()
	
func check_values():
	for t in texts:
		if not t.to_be_added:
			t.visible = false
	
	for i in range(added_icons.size()):
		added_icons[i].resize(0)
		added_icons[i].resize(reel_width)
		for n in conditional_effects[i].size():
			conditional_effects[i][n].clear()
			displayed_icons[i][n].current_effect_hashes.clear()
	var total_value = 0
	var coin_values = []
	counting_effects = true
	true_final_value = true
	var sc = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	for x in range(reel_width):
		for y in range(reel_height):
			var e = x + y * reel_width
			var coin_value = displayed_icons[y][x].get_value("coin")
			var reroll_value = displayed_icons[y][x].get_value("reroll_token")
			var removal_value = displayed_icons[y][x].get_value("removal_token")
			var essence_value = displayed_icons[y][x].get_value("essence_token")
			
			var non_zeros = 0
			var currencies = []
			var sum_pos = $"/root/Main/Sums/Coin Sum".start_pos
			
			if coin_value != 0:
				non_zeros += 1
			if reroll_value != 0:
				non_zeros += 1
			if removal_value != 0:
				non_zeros += 1
			if essence_value != 0:
				non_zeros += 1
			
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui <= 1.5:
					texts[e].custom_icon_offset = Vector2(0, -2 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui)
				else:
					texts[e].custom_icon_offset = Vector2(-2 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui, -4 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui)
			
			if non_zeros > 0:
				total_value += coin_value
				var font = texts[e].get_font("font")
				if int($"/root/Main/Options Sprite/Options".display_font) > 0:
					font = texts[e].get_child(0).get_font("font")
				displayed_icons[y][x].coins_earned += coin_value
				if coin_value != 0:
					if coin_value > 0:
						displayed_icons[y][x].times_coins_given += 1
					texts[e].coin_value = coin_value
					if $"/root/Main/Items".has_unmodded_item("lucky_dice_essence") and (displayed_icons[y][x].type == "d3" or displayed_icons[y][x].type == "d5"):
						var i = items[$"/root/Main/Items".item_types.find("lucky_dice_essence")]
						i.saved_value += 1
						i.update_value_text()
						if i.saved_value >= i.values[0]:
							i.temp_destroy()
					if $"/root/Main/Items".has_unmodded_item("checkered_flag_essence") and coin_value > 0 and displayed_icons[y][x].groups.has("slow"):
						var i = items[$"/root/Main/Items".item_types.find("checkered_flag_essence")]
						i.saved_value += 1
						i.update_value_text()
						if i.saved_value >= i.values[0]:
							i.temp_destroy()
				if reroll_value != 0:
					texts[e].reroll_value = reroll_value
				if removal_value != 0:
					texts[e].removal_value = removal_value
				if essence_value != 0:
					texts[e].essence_value = essence_value
				if (texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value != 0 or texts[e].reroll_value != 0 or texts[e].removal_value != 0 or texts[e].essence_value != 0) and not coin_values.has(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value):
					coin_values.push_back(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value)
				var text_str
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					text_str = "\u2003\u2002" + texts[e].parse_num_str(str(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value))
					texts[e].rect_position.x = 48 * sc + reels[0].rect_position.x + x * 120 * sc - (font.get_string_size(text_str).x * texts[e].current_scale) / 2
					texts[e].rect_position.y = 40 * sc + reels[0].rect_position.y - (font.get_height() * texts[e].current_scale) * (text_str.count("\n") + 1) / 8 + y * 112 * sc
				else:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						text_str = "\u2003" + texts[e].get_child(0).cjk_space + texts[e].parse_num_str(str(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value))
						if TranslationServer.get_locale() != "th":
							texts[e].rect_position.x = 48 * sc + reels[0].rect_position.x + x * 120 * sc - (font.get_string_size(text_str).x * texts[e].current_scale) / 2
							texts[e].rect_position.y = 40 * sc + reels[0].rect_position.y - (font.get_height() * texts[e].current_scale) * (text_str.count("\n") + 1) / 8 + y * 112 * sc
						else:
							texts[e].rect_position.x = 24 * sc + reels[0].rect_position.x + x * 120 * sc - (font.get_string_size(text_str).x * texts[e].current_scale) / 2
							texts[e].rect_position.y = 48 * sc + reels[0].rect_position.y - (font.get_height() * texts[e].current_scale) * (text_str.count("\n") + 1) / 8 + y * 112 * sc
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						text_str = " " + texts[e].get_child(0).cjk_space + texts[e].parse_num_str(str(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value))
						texts[e].rect_position.x = 56 * sc + reels[0].rect_position.x + x * 120 * sc - (font.get_string_size(text_str).x * texts[e].current_scale) / 2
						texts[e].rect_position.y = 40 * sc + reels[0].rect_position.y - (font.get_height() * texts[e].current_scale) * (text_str.count("\n") + 1) / 8 + y * 112 * sc
					else:
						text_str = "\u2009 " + texts[e].parse_num_str(str(texts[e].coin_value + texts[e].reroll_value + texts[e].removal_value + texts[e].essence_value))
						texts[e].rect_position.x = 56 * sc + reels[0].rect_position.x + x * 120 * sc - (font.get_string_size(text_str).x * texts[e].current_scale * 4.0) / 2
						texts[e].rect_position.y = 40 * sc + reels[0].rect_position.y - (font.get_height() * texts[e].current_scale) * (text_str.count("\n") + 1) / 2 + y * 112 * sc
				
				if coin_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_FBF236>" + texts[e].parse_num_str(str(texts[e].coin_value)) + "<end><icon_coin>")
					else:
						currencies.push_back("<color_FBF236><icon_coin>" + texts[e].parse_num_str(str(texts[e].coin_value)) + "<end>")
				
				if reroll_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_49AA10>" + texts[e].parse_num_str(str(texts[e].reroll_value)) + "<end><icon_reroll_token>")
					else:
						currencies.push_back("<color_49AA10><icon_reroll_token>" + texts[e].parse_num_str(str(texts[e].reroll_value)) + "<end>")
				
				if removal_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_6B6B6B>" + texts[e].parse_num_str(str(texts[e].removal_value)) + "<end><icon_removal_token>")
					else:
						currencies.push_back("<color_6B6B6B><icon_removal_token>" + texts[e].parse_num_str(str(texts[e].removal_value)) + "<end>")
						
				if essence_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_FF005D>" + texts[e].parse_num_str(str(texts[e].essence_value)) + "<end><icon_essence_token>")
					else:
						currencies.push_back("<color_FF005D><icon_essence_token>" + texts[e].parse_num_str(str(texts[e].essence_value)) + "<end>")
				
				match currencies.size():
					1:
						texts[e].raw_string = currencies[0]
						if coin_value == 0:
							texts[e].set_goal_pos(2)
						else:
							texts[e].set_goal_pos(0)
					2:
						texts[e].raw_string = currencies[0] + "\n" + currencies[1]
						if coin_value == 0:
							texts[e].set_goal_pos(2)
						else:
							texts[e].set_goal_pos(1)
						texts[e].rect_position.y -= 24
					3:
						texts[e].raw_string = currencies[0] + "\n" + currencies[1] + " " + currencies[2]
						texts[e].set_goal_pos(0)
						texts[e].rect_position.x -= 24
						texts[e].rect_position.y -= 24
					4:
						texts[e].raw_string = currencies[0] + " " + currencies[1] + "\n" + currencies[2] + " " + currencies[3]
						texts[e].set_goal_pos(0)
						texts[e].rect_position.x -= 24
						texts[e].rect_position.y -= 24
				texts[e].update()
			currencies.clear()
	for e in texts:
		e.start_pos = e.rect_position
	for r in reels:
		for i in r.icons:
			i.update_value_text()
	var black_cat
	var black_cat_text_num
	var swear_jar
	var swear_jar_num
	var white_pepper
	var white_pepper_num
	var white_pepper_essence
	var white_pepper_essence_num
	var devils_deal_essence
	var devils_deal_essence_num
	var swear_jar_essence
	var swear_jar_essence_num
	var mod_data = []
	var mod_types = []
	for i in range(reel_width * reel_height, texts.size()):
		if i - reel_width * reel_height >= $"/root/Main/Items".page * $"/root/Main/Items".visible_items and i - reel_width * reel_height < $"/root/Main/Items".page * $"/root/Main/Items".visible_items + $"/root/Main/Items".visible_items:
			texts[i].hidden = false
		else:
			texts[i].hidden = true
		if $"/root/Main/Options Sprite/Options".ui_scaling.items_ui < 1:
			texts[i].text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.items_ui) / 0.25)
		else:
			texts[i].text_mod = floor(($"/root/Main/Options Sprite/Options".ui_scaling.items_ui - 1) / 0.25)

		texts[i].change_set_size(texts[i].base_scale)
		var item = items[i - reel_width * reel_height]
		var coin_value = item.value
		var reroll_value = item.reroll_value
		var removal_value = item.removal_value
		var essence_value = item.essence_value
		var ty = item.type.substr(0, item.type.find("_STEAM_ID_"))
		
		var non_zeros = 0
		var currencies = []
		
		if coin_value != 0:
			non_zeros += 1
		if reroll_value != 0:
			non_zeros += 1
		if removal_value != 0:
			non_zeros += 1
		if essence_value != 0:
			non_zeros += 1
		
		if item.disabled:
			pass
		elif ty == "black_cat":
			black_cat = item
			black_cat_text_num = i
		elif ty == "swear_jar":
			swear_jar = item
			swear_jar_num = i
		elif ty == "white_pepper":
			white_pepper = item
			white_pepper_num = i
		elif ty == "white_pepper_essence":
			white_pepper_essence = item
			white_pepper_essence_num = i
		elif ty == "devils_deal_essence":
			devils_deal_essence = item
			devils_deal_essence_num = i
		elif ty == "swear_jar_essence":
			swear_jar_essence = item
			swear_jar_essence_num = i
		else:
			var a_mod = false
			for m in $"/root/Main".mod_multiple_effects:
				if m.type == item.type:
					mod_data.push_back({"item": item, "num": i, "eff": m.eff})
					mod_types.push_back(item.type)
					a_mod = true
			if not a_mod:
				total_value += coin_value
		if non_zeros > 0:
			var font = texts[i].get_font("font")
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				font = texts[i].get_child(0).get_font("font")
			var font_offset = Vector2(font.extra_spacing_char, font.extra_spacing_top)
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				font_offset.y += 15
			if coin_value != 0:
				texts[i].coin_value = coin_value
			if reroll_value != 0:
				texts[i].reroll_value = reroll_value
			if removal_value != 0:
				texts[i].removal_value = removal_value
			if essence_value != 0:
				texts[i].essence_value = essence_value
			var mod_names = []
			for m in mod_data:
				mod_names.push_back(item.type)
			if not coin_values.has(texts[i].coin_value + texts[i].reroll_value + texts[i].removal_value + texts[i].essence_value) and ty != "black_cat" and ty != "swear_jar" and ty != "swear_jar_essence" and ty != "white_pepper" and ty != "white_pepper_essence" and ty != "devils_deal_essence" and not mod_names.has(item.type) and (texts[i].coin_value != 0 or texts[i].reroll_value != 0 or texts[i].removal_value != 0 or texts[i].essence_value != 0):
				coin_values.push_back(texts[i].coin_value + texts[i].reroll_value + texts[i].removal_value + texts[i].essence_value)
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - ((font.get_string_size(texts[i].parse_num_str(str(texts[i].coin_value))).x) * texts[i].current_scale * 2 + 18 * texts[i].get_child(0).icon_scale_override) / 2
			elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
				if texts[i].current_scale > 0.125:
					texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - ((font.get_string_size(texts[i].parse_num_str(str(texts[i].coin_value))).x) * texts[i].current_scale + 12 * texts[i].get_child(0).icon_scale_override) / 2
				else:
					texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - ((font.get_string_size(texts[i].parse_num_str(str(texts[i].coin_value))).x) * (0.5 + (texts[i].current_scale - 0.5) * 2.5) + 12 * texts[i].get_child(0).icon_scale_override) / 2
			elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
				if texts[i].current_scale > 0.25:
					texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - ((font.get_string_size(texts[i].parse_num_str(str(texts[i].coin_value))).x) * texts[i].current_scale + 12 * texts[i].get_child(0).icon_scale_override) / 2
				else:
					texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - ((font.get_string_size(texts[i].parse_num_str(str(texts[i].coin_value))).x) * texts[i].current_scale + 6 * texts[i].get_child(0).icon_scale_override) / 2
			else:
				texts[i].rect_position.x = item.position.x + 22 * item.scale.x / 2 - (font.get_string_size("\u2009 " + texts[i].parse_num_str(str(texts[i].coin_value))).x * texts[i].current_scale) * 2
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				texts[i].rect_position.y = item.position.y + 11 * item.scale.x / 2
			else:
				texts[i].rect_position.y = item.position.y + 13 * item.scale.x / 2
			
			if coin_value != 0:
				if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
					currencies.push_back("<color_FBF236>" + texts[i].parse_num_str(str(texts[i].coin_value)) + "<end><icon_coin>")
				else:
					currencies.push_back("<color_FBF236><icon_coin>" + texts[i].parse_num_str(str(texts[i].coin_value)) + "<end>")
				
			if reroll_value != 0:
				if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
					currencies.push_back("<color_49AA10>" + texts[i].parse_num_str(str(texts[i].reroll_value)) + "<end><icon_reroll_token>")
				else:
					currencies.push_back("<color_49AA10><icon_reroll_token>" + texts[i].parse_num_str(str(texts[i].reroll_value)) + "<end>")
				
			if removal_value != 0:
				if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
					currencies.push_back("<color_6B6B6B>" + texts[i].parse_num_str(str(texts[i].removal_value)) + "<end><icon_removal_token>")
				else:
					currencies.push_back("<color_6B6B6B><icon_removal_token>" + texts[i].parse_num_str(str(texts[i].removal_value)) + "<end>")
			
			if essence_value != 0:
				if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
					currencies.push_back("<color_FF005D>" + texts[i].parse_num_str(str(texts[i].essence_value)) + "<end><icon_essence_token>")
				else:
					currencies.push_back("<color_FF005D><icon_essence_token>" + texts[i].parse_num_str(str(texts[i].essence_value)) + "<end>")
			
			match currencies.size():
				1:
					texts[i].raw_string = currencies[0]
					if coin_value == 0:
						texts[i].set_goal_pos(2)
					else:
						texts[i].set_goal_pos(0)
				2:
					texts[i].raw_string = currencies[0] + "\n" + currencies[1]
					if coin_value == 0:
						texts[i].set_goal_pos(2)
					else:
						texts[i].set_goal_pos(1)
					texts[i].rect_position.y -= 16
				3:
					texts[i].raw_string = currencies[0] + "\n" + currencies[1] + " " + currencies[2]
					texts[i].set_goal_pos(0)
					texts[i].rect_position.y -= 16
				4:
					texts[i].raw_string = currencies[0] + " " + currencies[1] + "\n" + currencies[2] + " " + currencies[3]
					texts[i].set_goal_pos(0)
					texts[i].rect_position.y -= 16
			texts[i].start_pos = texts[i].rect_position
			texts[i].update()
			currencies.clear()
	if black_cat != null:
		if int(total_value) % int(black_cat.values[1]) != 0:
			black_cat.value = 0
			texts[black_cat_text_num].coin_value = 0
			texts[black_cat_text_num].raw_string = ""
			texts[black_cat_text_num].update()
		elif not coin_values.has(black_cat.value):
			coin_values.push_back(black_cat.value)
	if swear_jar != null:
		if total_value > swear_jar.values[2] - 1:
			swear_jar.value = 0
			texts[swear_jar_num].coin_value = 0
			texts[swear_jar_num].raw_string = ""
			texts[swear_jar_num].update()
		else:
			swear_jar.saved_value += swear_jar.values[0]
			$"/root/Main/Items".saved_item_data[items.find(swear_jar)] = swear_jar.saved_value
			if swear_jar.saved_value != 0:
				swear_jar.get_child(1).raw_string = "<color_FBF236>" + swear_jar.get_child(1).parse_num_str(str(swear_jar.saved_value)) + "<end>"
			if not coin_values.has(swear_jar.value):
				coin_values.push_back(swear_jar.value)
	if white_pepper != null:
		if int(total_value) % int(white_pepper.values[1]) != 0:
			white_pepper.value = 0
			texts[white_pepper_num].coin_value = 0
			texts[white_pepper_num].raw_string = ""
			texts[white_pepper_num].update()
		elif not coin_values.has(white_pepper.value):
			coin_values.push_back(white_pepper.value)
	if white_pepper_essence != null:
		if int(total_value) % int(white_pepper_essence.values[1]) != 0:
			white_pepper_essence.value = 0
			texts[white_pepper_essence_num].coin_value = 0
			texts[white_pepper_essence_num].raw_string = ""
			texts[white_pepper_essence_num].update()
		else:
			white_pepper_essence.temp_destroy()
			if not coin_values.has(white_pepper_essence.value):
				coin_values.push_back(white_pepper_essence.value)
	if devils_deal_essence != null:
		var dde_num = 0
		var destroy_counters_to_remove = -1
		while devils_deal_essence.destroy_counters - destroy_counters_to_remove > 1 or (devils_deal_essence.destroy_counters == 0 and destroy_counters_to_remove < 0):
			if $"/root/Main/Coins".coins + total_value + dde_num >= popup.rent_values[0] or popup.rent_values[1] > 1:
				devils_deal_essence.value = 0
				texts[devils_deal_essence_num].coin_value = 0
				texts[devils_deal_essence_num].raw_string = ""
				texts[devils_deal_essence_num].update()
				break
			else:
				dde_num += devils_deal_essence.values[0]
				destroy_counters_to_remove += 1
		if dde_num != 0:
			for i in range(destroy_counters_to_remove):
				$"/root/Main/Items".destroyed_item_types.push_back("devils_deal_essence")
			devils_deal_essence.destroy_counters -= destroy_counters_to_remove
			devils_deal_essence.temp_destroy()
			devils_deal_essence.value = dde_num
			texts[devils_deal_essence_num].coin_value = dde_num
			if not coin_values.has(dde_num):
				coin_values.push_back(dde_num)
			if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
				texts[devils_deal_essence_num].raw_string = "<color_FBF236>" + str(dde_num) + "<end><icon_coin>"
			else:
				texts[devils_deal_essence_num].raw_string = "<icon_coin><color_FBF236>" + str(dde_num) + "<end>"
			texts[devils_deal_essence_num].update()
	if swear_jar_essence != null:
		if total_value > swear_jar_essence.values[0]:
			swear_jar_essence.value = 0
			texts[swear_jar_essence_num].coin_value = 0
			texts[swear_jar_essence_num].raw_string = ""
			texts[swear_jar_essence_num].update()
		else:
			swear_jar_essence.temp_destroy()
			if not coin_values.has(swear_jar_essence.value):
				coin_values.push_back(swear_jar_essence.value)
	var done_mod_types = []
	for m in mod_data:
		var multiple = 0
		for comp in m.eff.comparisons:
			if comp.a == "multiple_of":
				multiple = comp.b
				break
		if int(total_value) % int(multiple) != 0:
			texts[m.num].coin_value = m.item.value
			texts[m.num].reroll_value = m.item.reroll_value
			texts[m.num].removal_value = m.item.removal_value
			texts[m.num].essence_value = m.item.essence_value
			if not coin_values.has(m.item.value + m.item.reroll_value + m.item.removal_value + m.item.essence_value):
				coin_values.push_back(m.item.value + m.item.reroll_value + m.item.removal_value + m.item.essence_value)
		else:
			var currency_values = $"/root/Main/Pop-up Sprite/Pop-up".check_value_to_change(m.eff, m.item)
			texts[m.num]["coin_value"] += currency_values["coins"]
			texts[m.num]["reroll_value"] += currency_values["reroll"]
			texts[m.num]["removal_value"] += currency_values["removal"]
			texts[m.num]["essence_value"] += currency_values["essence"]
			if not coin_values.has(m.item.value + m.item.reroll_value + m.item.removal_value + m.item.essence_value):
				var i = m.num
				var currencies = []
				var coin_value = texts[m.num]["coin_value"]
				var reroll_value = texts[m.num]["reroll_value"]
				var removal_value = texts[m.num]["removal_value"]
				var essence_value = texts[m.num]["essence_value"]
				if coin_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_FBF236>" + texts[i].parse_num_str(str(texts[i].coin_value)) + "<end><icon_coin>")
					else:
						currencies.push_back("<color_FBF236><icon_coin>" + texts[i].parse_num_str(str(texts[i].coin_value)) + "<end>")
					
				if reroll_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_49AA10>" + texts[i].parse_num_str(str(texts[i].reroll_value)) + "<end><icon_reroll_token>")
					else:
						currencies.push_back("<color_49AA10><icon_reroll_token>" + texts[i].parse_num_str(str(texts[i].reroll_value)) + "<end>")
					
				if removal_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_6B6B6B>" + texts[i].parse_num_str(str(texts[i].removal_value)) + "<end><icon_removal_token>")
					else:
						currencies.push_back("<color_6B6B6B><icon_removal_token>" + texts[i].parse_num_str(str(texts[i].removal_value)) + "<end>")
				
				if essence_value != 0:
					if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
						currencies.push_back("<color_FF005D>" + texts[i].parse_num_str(str(texts[i].essence_value)) + "<end><icon_essence_token>")
					else:
						currencies.push_back("<color_FF005D><icon_essence_token>" + texts[i].parse_num_str(str(texts[i].essence_value)) + "<end>")
				
				match currencies.size():
					1:
						texts[i].raw_string = currencies[0]
						if coin_value == 0:
							texts[i].goal_pos = Vector2(1.0, 53.0 + coin_goal_y_offset)
						else:
							texts[i].goal_pos = Vector2(1.0, 59.0 + coin_goal_y_offset)
					2:
						texts[i].raw_string = currencies[0] + "\n" + currencies[1]
						if coin_value == 0:
							texts[i].goal_pos = Vector2(1.0, 53.0 + coin_goal_y_offset)
						else:
							texts[i].goal_pos = Vector2(1.0, 56.0 + coin_goal_y_offset)
						texts[i].rect_position.y -= 16
					3:
						texts[i].raw_string = currencies[0] + "\n" + currencies[1] + " " + currencies[2]
						texts[i].goal_pos = Vector2(1.0, 59.0 + coin_goal_y_offset)
						texts[i].rect_position.y -= 16
					4:
						texts[i].raw_string = currencies[0] + " " + currencies[1] + "\n" + currencies[2] + " " + currencies[3]
						texts[i].goal_pos = Vector2(1.0, 59.0 + coin_goal_y_offset)
						texts[i].rect_position.y -= 16
				done_mod_types.push_back(m.item.type)
				if done_mod_types.count(m.item.type) == mod_types.count(m.item.type):
					coin_values.push_back(texts[m.num]["coin_value"] + texts[m.num]["reroll_value"] + texts[m.num]["removal_value"] + texts[m.num]["essence_value"])
					texts[i].force_update = true
					texts[i].update()
	coin_values.sort()
	
	for e in texts:
		if e.coin_value != 0 or e.reroll_value != 0 or e.removal_value != 0 or e.essence_value != 0:
			e.effect_timer = 160 + 24 * coin_values.find(e.coin_value + e.reroll_value + e.removal_value + e.essence_value)
			e.animating = true
			e.to_be_added = true
			var sfx_num = coin_values.find(e.coin_value + e.reroll_value + e.removal_value + e.essence_value)
			if sfx_num > 7:
				sfx_num = 7
			if not sfx_queue_hashes.has({"name": "text" + str(sfx_num), "delay": 24 * coin_values.find(e.coin_value + e.reroll_value + e.removal_value + e.essence_value)}.hash()):
				sfx_queue.push_back({"name": "text" + str(sfx_num), "delay": 24 * coin_values.find(e.coin_value + e.reroll_value + e.removal_value + e.essence_value)})
				sfx_queue_hashes.push_back({"name": "text" + str(sfx_num), "delay": 24 * coin_values.find(e.coin_value + e.reroll_value + e.removal_value + e.essence_value)}.hash())
	finalize_clumps()

func make_clumps():
	clumps.clear()
	group_clumps.clear()
	for i in range(added_icons.size()):
		added_icons[i].resize(0)
		added_icons[i].resize(reel_width)
	
	var checker_x
	var checker_y
	
	var icons_to_check_num = 9
	
	var telescope
	var protractor
	
	if ($"/root/Main/Items".has_unmodded_item("telescope") and items[$"/root/Main/Items".item_types.find("telescope")].saved_value >= items[$"/root/Main/Items".item_types.find("telescope")].values[0]) or $"/root/Main/Items".has_unmodded_item("telescope_essence"):
		telescope = true
		icons_to_check_num = reel_width * reel_height
	if ($"/root/Main/Items".has_unmodded_item("protractor") and items[$"/root/Main/Items".item_types.find("protractor")].saved_value >= items[$"/root/Main/Items".item_types.find("protractor")].values[0]) or $"/root/Main/Items".has_unmodded_item("protractor_essence"):
		protractor = true
		icons_to_check_num = 13
	
	for x in range(reel_width):
		for y in range(reel_height):
			for n in range(icons_to_check_num):
				if telescope != null:
					checker_x = (n % reel_width) - x
					checker_y = -y + floor(n / reel_width)
				elif protractor != null and n >= 9:
					match n:
						9:
							checker_x = -x
							checker_y = -y
						10:
							checker_x = reel_width - x - 1
							checker_y = -y
						11:
							checker_x = -x
							checker_y = reel_height - y - 1
						12:
							checker_x = reel_width - x - 1
							checker_y = reel_height - y - 1
				else:
					checker_x = (n % 3) - 1
					checker_y = -1 + floor(n / 3)
				if x + checker_x >= 0 and x + checker_x < displayed_icons[y].size() and y + checker_y >= 0 and y + checker_y < displayed_icons.size() and not (checker_x == 0 and checker_y == 0):
					if check_icon_match(displayed_icons[y][x], displayed_icons[y + checker_y][x + checker_x]):
						if added_icons[y][x] == null:
							add_to_clump(y, x, telescope, protractor)
						if added_icons[y + checker_y][x + checker_x] == null:
							add_to_clump(y + checker_y, x + checker_x, telescope, protractor)
	combine_clumps()

func protractor_adjacent(y, x):
	return ((y == 0 and x == 0) or (y == 0 and x == reel_width - 1) or (y == reel_height - 1 and x == 0) or (y == reel_height - 1 and x == reel_width - 1))

func add_queued_achievement(num):
	if queued_achievements.find(num) == -1:
		queued_achievements.push_back(num)

func add_to_clump(y, x, telescope, protractor):
	var arr = clumps
	if making_group_clumps != null:
		arr = group_clumps
	for n in range(arr.size()):
		for b in range(arr[n].size()):
			if (abs(y - arr[n][b].y) <= 1 and abs(x - arr[n][b].x) <= 1) or telescope != null or (protractor != null and (protractor_adjacent(y, x) or protractor_adjacent(arr[n][b].y, arr[n][b].x))):
				if check_icon_match(displayed_icons[y][x], arr[n][b]):
					arr[n].push_back({"type": displayed_icons[y][x].type, "groups": displayed_icons[y][x].groups, "y": y, "x": x})
					added_icons[y][x] = n
					return
	arr.push_back([{"type": displayed_icons[y][x].type, "groups": displayed_icons[y][x].groups, "y": y, "x": x, "grid_position": displayed_icons[y][x].grid_position}])
	added_icons[y][x] = arr.size() - 1

func combine_clumps():
	var checker_x
	var checker_y
	var x = 0
	var y = 0
	
	var arr = clumps
	if making_group_clumps != null:
		arr = group_clumps
	
	while y < added_icons.size():
		if arr.size() == 1:
			break
		while x < added_icons[y].size():
			for n in range(9):
				checker_x = (n % 3) - 1
				checker_y = -1 + floor(n / 3)
				if x + checker_x >= 0 and x + checker_x < displayed_icons[y].size() and y + checker_y >= 0 and y + checker_y < displayed_icons.size() and not (checker_x == 0 and checker_y == 0):
					if added_icons[y][x] != added_icons[y + checker_y][x + checker_x] and added_icons[y][x] != null and added_icons[y + checker_y][x + checker_x] != null:
						var icon_num
						var adj_icon_num
						for c in range(arr[added_icons[y][x]].size()):
							if arr[added_icons[y][x]][c].x == x and arr[added_icons[y][x]][c].y == y:
								icon_num = c
								break
						for c in range(arr[added_icons[y + checker_y][x + checker_x]].size()):
							if arr[added_icons[y + checker_y][x + checker_x]][c].x == x + checker_x and arr[added_icons[y + checker_y][x + checker_x]][c].y == y + checker_y:
								adj_icon_num = c
								break
						if icon_num != null and adj_icon_num != null and check_icon_match(arr[added_icons[y][x]][icon_num], arr[added_icons[y + checker_y][x + checker_x]][adj_icon_num]):
							for c in arr[added_icons[y + checker_y][x + checker_x]]:
								arr[added_icons[y][x]].push_back(c)
							arr.remove(added_icons[y + checker_y][x + checker_x])
							
							var removed_num = added_icons[y + checker_y][x + checker_x]
							if added_icons[y + checker_y][x + checker_x] > added_icons[y][x]:
								removed_num = added_icons[y][x]
							
							for y2 in range(added_icons.size()):
								for x2 in range(added_icons[y2].size()):
									if added_icons[y2][x2] != null and added_icons[y2][x2] > removed_num:
										added_icons[y2][x2] -= 1
							y = -1
							x = -1
							break
			if y == -1 and x == -1:
				break
			else:
				x += 1
		y += 1
		x = 0
	for c in clumps:
		if c.size() >= 3 and c[0].type == "cherry":
			add_queued_achievement(27)
			break

func execute_clumps():
	effects_playing = true
	var arr = clumps
	if making_group_clumps != null:
		arr = group_clumps
	for i in range(arr.size()):
		var first_column = 0
		var first_match = false
		for b in range(texts.size()):
			var e = (b * reel_width) % texts.size() + int(floor(b / reel_height))
			if texts[e].clump == arr[i]:
				if not first_match:
					first_match = true
					first_column = e % reel_width
				for t in range(5):
					var num = e - reel_width - 1 + reel_width * (t % 3) + floor(t / 3) + floor(t / 4) * reel_width
					if num < 0 or num > texts.size() - 1 or (t < 3 and (e % reel_width == 0)):
						continue
					elif texts[e].clump == texts[num].clump:
						texts[e].line_targets.push_back(texts[num])
						texts[e].line_color = Color("06799F")
						texts[e].line_color.a = 0.8
				if not instant_fanfare:
					texts[e].effect_timer = 160 + (e % reel_width) * 7 + (i * (87 - fanfare_offset)) - first_column * 7
				else:
					texts[e].effect_timer = 160
				texts[e].animating = true
		line_color_num += 1

func finalize_clumps():
	for e in texts:
		if e.effect_timer > 0:
			return
	write_post_effects_log()
	counting_effects = false
	for r in reels:
		for i in r.icons:
			if i.type == "removal_capsule" and i.saved_achievement_values[0] >= 3:
				add_queued_achievement(117)
			elif i.type == "reroll_capsule" and i.saved_achievement_values[0] >= 3:
				add_queued_achievement(118)
			elif i.type == "lucky_capsule" and i.saved_achievement_values[0] >= 3:
				add_queued_achievement(86)
			elif i.type == "chick" and i.saved_achievement_values[0] >= 12:
				add_queued_achievement(28)
			elif i.type == "void_fruit" and i.achievement_values[0] > 0:
				add_queued_achievement(143)
			elif not $"/root/Main".demo and $"/root/Main".group_database.symbols["triggerhex"].has(i.type):
				if i.grid_position.y < 0 or i.grid_position.y >= reel_height or not i.gained_saved_achievement_value:
					i.saved_achievement_values[0] = 0
	if destroyed_symbols.has("tedium_capsule") and destroyed_symbols.has("rarity_capsule"):
		add_queued_achievement(134)
	if destroyed_symbols.count("urn") >= 2:
		add_queued_achievement(141)
	if destroyed_symbols.count("big_urn") >= 2:
		add_queued_achievement(14)
	for x in range(reel_width):
		for y in range(reel_height):
			if displayed_icons[y][x].type == "magpie" and displayed_icons[y][x].final_value < 0:
				stealing_magpie = true
			displayed_icons[y][x].value_multiplier_arr.clear()
			displayed_icons[y][x].value_bonus_arr.clear()
			displayed_icons[y][x].erased_effects.clear()
			displayed_icons[y][x].erased_effect_hashes.clear()
			displayed_icons[y][x].current_effect_hashes.clear()
			displayed_icons[y][x].one_times.clear()
			displayed_icons[y][x].final_value = (displayed_icons[y][x].value + displayed_icons[y][x].permanent_bonus) * displayed_icons[y][x].permanent_multiplier
			displayed_icons[y][x].non_flat_final_value = (displayed_icons[y][x].value + displayed_icons[y][x].permanent_bonus) * displayed_icons[y][x].permanent_multiplier
			displayed_icons[y][x].non_prev_final_value = (displayed_icons[y][x].value + displayed_icons[y][x].permanent_bonus) * displayed_icons[y][x].permanent_multiplier
			displayed_icons[y][x].flat_value_bonus = 0
			displayed_icons[y][x].given_effects.clear()
			displayed_icons[y][x].given_effect_hashes.clear()
			displayed_icons[y][x].pdi = 0
			displayed_icons[y][x].destroyed = false
			displayed_icons[y][x].dove_destroyed = false
			displayed_icons[y][x].being_destroyed = false
			displayed_icons[y][x].destroyed_giver_on_destroy = false
			displayed_icons[y][x].removed = false
			displayed_icons[y][x].tbd = false
			displayed_icons[y][x].indestructible = false
			displayed_icons[y][x].tried_to_give_rand_eff = false
			displayed_icons[y][x].getting_extra = false
			displayed_icons[y][x].drained = false
			displayed_icons[y][x].wildcarded = false
			displayed_icons[y][x].did_destroyed_anim = false
			displayed_icons[y][x].gained_saved_achievement_value = false
			displayed_icons[y][x].done_spinning = false
			displayed_icons[y][x].current_effect = null
			displayed_icons[y][x].texture_effect = null
			displayed_icons[y][x].prev_data_obj = null
			displayed_icons[y][x].same_rand_adjacent_symbol = null
			displayed_icons[y][x].affected_symbols.clear()
			displayed_icons[y][x].tile_adding_effects.clear()
			displayed_icons[y][x].item_adding_effects.clear()
			displayed_icons[y][x].prev_data.clear()
			displayed_icons[y][x].t_prev_data.clear()
			displayed_icons[y][x].destroyed_or_removed_by.clear()
			displayed_icons[y][x].symbols_destroyed.clear()
			displayed_icons[y][x].achievement_values = [0, 0, 0]
			displayed_icons[y][x].added_by = ""
			displayed_icons[y][x].pointing_directions.clear()
			displayed_icons[y][x].void_arr.clear()
			displayed_icons[y][x].hex_effects.clear()
			displayed_icons[y][x].dynamic_diff_targets.clear()
			displayed_icons[y][x].grid_position = Vector2(displayed_icons[y][x].get_parent().reel_num, int(floor(displayed_icons[y][x].position.y / reels[0].mod)))
			
			displayed_icons[y][x].reroll_token_value = 0
			displayed_icons[y][x].reroll_token_value_multiplier_arr.clear()
			displayed_icons[y][x].reroll_token_value_bonus_arr.clear()
			displayed_icons[y][x].reroll_token_final_value = 0
			displayed_icons[y][x].reroll_token_non_flat_final_value = 0
			displayed_icons[y][x].reroll_token_flat_value_bonus = 0

			displayed_icons[y][x].removal_token_value = 0
			displayed_icons[y][x].removal_token_value_multiplier_arr.clear()
			displayed_icons[y][x].removal_token_value_bonus_arr.clear()
			displayed_icons[y][x].removal_token_final_value = 0
			displayed_icons[y][x].removal_token_non_flat_final_value = 0
			displayed_icons[y][x].removal_token_flat_value_bonus = 0
			
			displayed_icons[y][x].essence_token_value = 0
			displayed_icons[y][x].essence_token_value_multiplier_arr.clear()
			displayed_icons[y][x].essence_token_value_bonus_arr.clear()
			displayed_icons[y][x].essence_token_final_value = 0
			displayed_icons[y][x].essence_token_non_flat_final_value = 0
			displayed_icons[y][x].essence_token_flat_value_bonus = 0
			
			if displayed_icons[y][x].type == "empty":
				displayed_icons[y][x].value = 0
			for v in range(displayed_icons[y][x].bonus_values.size()):
				displayed_icons[y][x].bonus_values[v] = 0
			for v in range(displayed_icons[y][x].bonus_value_multipliers.size()):
				displayed_icons[y][x].bonus_value_multipliers[v] = 1
	var to_be_destroyed = []
	var compost_heap = false
	for i in items:
		i.value = 0
		i.reroll_value = 0
		i.removal_value = 0
		i.essence_value = 0
		i.symbols_removed_this_spin = 0
		i.symbol_trigger = false
		i.c_effects.clear()
		i.affected_symbols.clear()
		i.erased_effects.clear()
		i.tile_adding_effects.clear()
		i.item_adding_effects.clear()
		if i.item_count <= 0:
			i.destroyed = true
		if i.destroyed and (not popup.coffee_essence or i.type == "coffee_essence"):
			to_be_destroyed.push_back(i)
		$"/root/Main/Items".saved_item_data[$"/root/Main/Items".item_types.find(i.type)] = i.saved_value
		$"/root/Main/Items".saved_destroy_counters[$"/root/Main/Items".item_types.find(i.type)] = i.destroy_counters
		$"/root/Main/Items".item_count_data[$"/root/Main/Items".item_types.find(i.type)] = i.item_count
	if $"/root/Main/Items".has_unmodded_item("compost_heap"):
		compost_heap = true
	if $"/root/Main/Items".has_unmodded_item("telescope"):
		var i = items[$"/root/Main/Items".item_types.find("telescope")]
		if i.saved_value >= i.values[0]:
			i.saved_value -= i.values[0]
			i.check_conditional_effects()
	if $"/root/Main/Items".has_unmodded_item("protractor"):
		var i = items[$"/root/Main/Items".item_types.find("protractor")]
		if i.saved_value >= i.values[0]:
			i.saved_value -= i.values[0]
			i.check_conditional_effects()
	if $"/root/Main/Items".has_unmodded_item("void_party"):
		var i = items[$"/root/Main/Items".item_types.find("void_party")]
		if i.saved_value > 0:
			i.saved_value = 0
	if $"/root/Main/Items".has_unmodded_item("mobius_strip"):
		var i = items[$"/root/Main/Items".item_types.find("mobius_strip")]
		if i.saved_value > 0:
			i.saved_value = 0
	for i in to_be_destroyed:
		$"/root/Main/Items".saved_destroy_counters[$"/root/Main/Items".item_types.find(i.type)] = i.destroy_counters
		i.destroy()

		i.destroyed = false
	$"/root/Main/Items".item_types_at_end_of_spin = $"/root/Main/Items".item_types.duplicate(true)
	if not compost_heap:
		popup.compost_heap_symbols_destroyed = 0

	$"/root/Main/Items".update_positions()
	$"/root/Main/Items".just_added_items.clear()
	$"/root/Main/Items".just_destroyed_items.clear()
	$"/root/Main/Items".cond_effects_to_add.clear()
	update_icon_types()
	
	popup.symbols_added_this_spin = 0
	popup.symbols_destroyed_this_spin = 0
	popup.items_destroyed_this_spin = 0
	popup.coffee_essence = false
	for c in counted_symbols.keys():
		counted_symbols[c] = 0
	checked_diff_multis = false
	
	$"/root/Main".write_log("Gained " + str($"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value) + " coins this spin")
	if $"/root/Main/Sums/Extra Sum".reroll_value != 0:
		$"/root/Main".write_log("Gained " + str($"/root/Main/Sums/Extra Sum".reroll_value) + " reroll tokens this spin")
	if $"/root/Main/Sums/Extra Sum".removal_value != 0:
		$"/root/Main".write_log("Gained " + str($"/root/Main/Sums/Extra Sum".removal_value) + " removal tokens this spin")
	if $"/root/Main/Sums/Extra Sum".essence_value != 0:
		$"/root/Main".write_log("Gained " + str($"/root/Main/Sums/Extra Sum".essence_value) + " essence tokens this spin")
	$"/root/Main".write_log("Coin total is now " + str($"/root/Main/Coins".coins + $"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value) + " after spinning")
	$"/root/Main".save_log()
	
	$"/root/Main/Sums/Coin Sum".adding = true
	$"/root/Main/Sums/Extra Sum".adding = true
	$"/root/Main/Sums/HP Sum".adding = true
	
	$"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens += $"/root/Main/Sums/Extra Sum".reroll_value
	$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens += $"/root/Main/Sums/Extra Sum".removal_value
	$"/root/Main/Pop-up Sprite/Pop-up".essence_tokens += $"/root/Main/Sums/Extra Sum".essence_value
	
	selected_icons.clear()
	selected_reels.clear()
	symbol_positions_to_update.clear()
	symbol_positions_tbd.clear()
	
	true_final_value = false
	destroyed_item_this_spin = false
	checking_last_effects = false
	symbol_destroyed_during_spin = false
	symbol_removed_during_spin = false
	symbol_transformed_during_spin = false
	dove_prevention = false
	
	popup.spins += 1
	popup.rent_values[1] -= 1
	
	if popup.spins == 1:
		$"/root/Main/Stats Sprite/Stats".add_to_games_played(popup.current_floor)
	
	popup.sme_this_spin.clear()
	popup.respun_reel = -1
	popup.respun_essence_reel = -1
	
	for p in popup.permanent_bonuses:
		if p.has("rarity"):
			if p.rarity.has("symbols"):
				for k in p.rarity.symbols.keys():
					popup.rarity_bonuses["symbols"][k] *= p.rarity.symbols[k]
			if p.rarity.has("items"):
				for k in p.rarity.items.keys():
					popup.rarity_bonuses["items"][k] *= p.rarity.items[k]
	for i in $"/root/Main/Items".destroyed_items:
		if i == "lucky_cat_essence":
			popup.rarity_bonuses["symbols"]["uncommon"] *= $"/root/Main".item_database["lucky_cat_essence"].values[1]
			popup.rarity_bonuses["symbols"]["rare"] *= $"/root/Main".item_database["lucky_cat_essence"].values[1]
			popup.rarity_bonuses["symbols"]["very_rare"] *= $"/root/Main".item_database["lucky_cat_essence"].values[1]
	for fp in $"/root/Main/Landlord".fine_print:
		if fp.num == 23:
			popup.rarity_bonuses["symbols"]["uncommon"] /= fp.values[0]
			popup.rarity_bonuses["symbols"]["rare"] /= fp.values[0]
			popup.rarity_bonuses["symbols"]["very_rare"] /= fp.values[0]
			break
	if $"/root/Main/Items".destroyed_items.has("lucky_seven_essence"):
		var rarity_db = $"/root/Main".rarity_database
		if rarity_db["symbols"]["uncommon"].has("chemical_seven"):
			rarity_db["symbols"]["uncommon"].erase("chemical_seven")
			rarity_db["symbols"]["common"].push_back("chemical_seven")
			$"/root/Main".tile_database["chemical_seven"].rarity = "common"
	
	effects_playing = false
	if popup.rent_values[1] > 0:
		if $"/root/Main/Coins".coins + $"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value > 0:
			if popup.doing_boss_fight and $"/root/Main/Landlord".hp - $"/root/Main/Sums/HP Sum".hp_value <= 0:
				pass
			else:
				if popup.hex_of_emptiness_trigger:
					popup.add_event("hex_of_emptiness_trigger", null)
				elif popup.forced_rarities.size() > 0:
					popup.add_event("add_tile", popup.get_forced_rarities(popup.symbols_to_choose_from))
				else:
					popup.add_event("add_tile", {"forced_rarity": []})
				if $"/root/Main/Items".has_unmodded_item("frozen_pizza_essence"):
					popup.add_event("add_tile", popup.get_forced_rarities(popup.symbols_to_choose_from))
		else:
			if destroyed_symbols.has("essence_capsule"):
				add_queued_achievement(53)
			if destroyed_symbols.has("hustler"):
				add_queued_achievement(77)
			popup.add_event("out_of_money", null)
			$"/root/Main/Music Player".fully_fade_out()
	else:
		if popup.doing_boss_fight and $"/root/Main/Landlord".hp - $"/root/Main/Sums/HP Sum".hp_value <= 0:
			pass
		elif $"/root/Main/Pop-up Sprite/Pop-up".rent_values[0] == 0:
			$"/root/Main/Pop-up Sprite/Pop-up".endless_rent_email()
		elif popup.can_try_to_pay_rent():
			popup.add_event("rent_due", null)
		else:
			if destroyed_symbols.has("essence_capsule"):
				add_queued_achievement(53)
			if destroyed_symbols.has("hustler"):
				add_queued_achievement(77)
			if $"/root/Main/Coins".coins + $"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value == popup.rent_values[0] - 1 and stealing_magpie:
				add_queued_achievement(88)
			popup.add_event("game_over", null)
			$"/root/Main/Music Player".fully_fade_out()
	if big_wildcards.size() >= 3:
		add_queued_achievement(146)
	if popup.destroyed_symbol_types.count("lockbox") >= 5 and popup.times_rent_paid < 12:
		add_queued_achievement(85)
	if popup.destroyed_symbol_types.count("safe") >= 4 and popup.times_rent_paid < 12:
		add_queued_achievement(121)
	if popup.destroyed_symbol_types.count("treasure_chest") >= 3 and popup.times_rent_paid < 12:
		add_queued_achievement(139)
	if popup.destroyed_symbol_types.count("mega_chest") >= 2 and popup.times_rent_paid < 12:
		add_queued_achievement(91)
	if added_symbols.count("emerald") >= 2:
		add_queued_achievement(52)
	if added_symbols.count("ruby") >= 2:
		add_queued_achievement(120)
	if $"/root/Main/Items".item_types.find("mining_pick") != -1 and items[$"/root/Main/Items".item_types.find("mining_pick")].item_count >= 2 and popup.times_rent_paid < 12:
		add_queued_achievement(94)
	if ninja_timer >= 3:
		add_queued_achievement(100)
	if popup.transformed_coals >= 2 and popup.times_rent_paid < 4:
		add_queued_achievement(31)
	if grown_strawberries >= 2:
		add_queued_achievement(131)
	if grown_apples >= 2:
		add_queued_achievement(2)
	if destroyed_symbols.count("bubble") >= 3:
		add_queued_achievement(19)
	if destroyed_symbols.count("chemical_seven") >= 3:
		add_queued_achievement(26)
	if $"/root/Main/Items".item_types.find("pool_ball_essence") != -1 and items[$"/root/Main/Items".item_types.find("pool_ball_essence")].item_count >= 2:
		add_queued_achievement(17)
	if bad_arrows.count("bronze_arrow") >= 3:
		add_queued_achievement(18)
	if bad_arrows.count("silver_arrow") >= 3:
		add_queued_achievement(126)
	if bad_arrows.count("golden_arrow") >= 3:
		add_queued_achievement(60)
		
	for q in queued_achievements:
		$"/root/Main/Stats Sprite/Stats".unlock_achievement(q, false)
	queued_achievements.clear()
	big_wildcards.clear()
	added_symbols.clear()
	destroyed_symbols.clear()
	bad_arrows.clear()
	queued_milk = 0
	queued_banana_peels = 0
	queued_honey = 0
	queued_seeds = 0
	grown_strawberries = 0
	grown_apples = 0
	stealing_magpie = false
	$"/root/Main".save_game()
	$"/root/Main".save_stats()
