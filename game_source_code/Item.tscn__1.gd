extends Sprite

var type
var rarity
var values
var saved_value = 0
var saved_values = {}
var destroy_counters = 0
var item_count = 1
var bonus_values = []
var bonus_value_multipliers = []
var c_effects = []
var groups = []
var hovering
var active = false
var value = 0
var reroll_value = 0
var removal_value = 0
var essence_value = 0
var symbols_removed_this_spin = 0
var changed_value
var destroyed = false
var destroyable = false
var symbol_trigger = false
var affected_symbols = []
var erased_effects = []
var item_adding_effects = []
var tile_adding_effects = []
var given_effect_hashes = []
var grid_position = null
var given_effects = []
var prev_data = []
var t_prev_data = []
var disabled = false
var modded = false
var inherit_effects = false
var inherit_art = false
var description = ""
var localized_descriptions = []
var localized_names = []
var inherited_effects = []
var manually_destroyable = false
var can_be_destroyed_before_rent = false
var skip_rent_on_destroy = false
var is_icon = false
var no_item_multi_diffs = ["lucky_seven", "reroll", "compost_heap", "flush", "piggy_bank", "rusty_gear"]

var tooltips
var reels

var extra_symbol_choices = null
var extra_item_choices = null
var forced_add = null
var forced_skip = null
var multiple_of = null
var hotfix_num = null
var symbols_in_inventory = null
var symbols_to_choose_from = null
var items_to_choose_from = null
var permanent_bonuses = null
var fighting_boss = null
var symbols_removed_pre_spin = []

var prev_data_obj = null

var rect_global_position
var rect_size
var selectable = false
var off_screen = false
var cant_go_dirs = []
var selector_alignment = "left"
var gained_saved_achievement_value = false

var need_to_update = true

var spins_left = 0
var coins = 0
var reroll_tokens = 0
var removal_tokens = 0
var essence_tokens = 0
var rent_due = 0

var addding_post_spin_effects = false
var tmp_fp_num = -1

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

func _input(event):
	if $"/root/Main/Landlord".anim_time > 0 or $"/root/Main/Sums/HP Sum".adding or not need_to_update:
		return
	if not reels.effects_playing and not reels.spinning and $"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0 and hovering and not event.is_echo():
		if event is InputEventMouseButton and ((event.is_pressed() and $"/root/Main/Options Sprite/Options".input_type == 1) or ($"/root/Main/Options Sprite/Options".input_type == 0 and (event.is_pressed() or Steam.isSteamRunningOnSteamDeck()))) and event.button_index == BUTTON_LEFT and destroyable and not disabled:
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			else:
				destroy()
		elif event is InputEventKey and event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["enable_disable_item"][0] and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			toggle_disabled()
		elif event is InputEventMouseButton and event.button_index == $"/root/Main/Options Sprite/Options".hotkeys["enable_disable_item"][0] and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			toggle_disabled()
	if is_instance_valid($"/root/Main") and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and event is InputEventKey and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		if event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["inspect"][0]:
			if not $"/root/Main/Selector Sprite/Selector".visible:
				$"/root/Main/Selector Sprite/Selector".visible = true
			else:
				hover()

func _ready():
	tooltips = $"/root/Main/Tooltips"
	reels = $"/root/Main/Reels"
	scale = Vector2(round($"/root/Main/Options Sprite/Options".ui_scaling.items_ui / 0.25), round($"/root/Main/Options Sprite/Options".ui_scaling.items_ui / 0.25))
	get_child(0).text_mod = -3
	get_child(1).text_mod = -3
	get_child(2).text_mod = -3
	get_child(0).dont_scale = true
	get_child(1).dont_scale = true
	get_child(2).dont_scale = true
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		get_child(0).change_set_size(0.125)
		get_child(1).change_set_size(0.125)
		get_child(2).change_set_size(0.125)
	else:
		get_child(0).change_set_size(0.25)
		get_child(1).change_set_size(0.25)
		get_child(2).change_set_size(0.25)
	if type != null:
		var ty = type.substr(0, type.find("_STEAM_ID_"))
		if ty == "popsicle" or ty == "popsicle_essence" or ty == "frozen_pizza_essence":
			toggle_disabled()

func update():
	if not need_to_update:
		return
	if is_instance_valid($"/root/Main") and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and not reels.effects_playing and not reels.spinning and $"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0:
		tts()
		if $"/root/Main".down_keys["confirm_select"] == 1 and destroyable and not disabled:
			$"/root/Main".down_keys["confirm_select"] += 1
			destroy()
			return
		elif $"/root/Main".down_keys["enable_disable_item"] == 1:
			$"/root/Main".down_keys["confirm_select"] += 1
			toggle_disabled()
			return
		elif $"/root/Main".down_keys["inspect"] == 1:
			$"/root/Main".down_keys["inspect"] += 1
			if tooltips.get_children().size() < 10:
				hover()
				if tooltips.get_children().size() > 0:
					$"/root/Main".selected_node = tooltips.get_child(tooltips.get_children().size() - 1)
				return
	rect_global_position = global_position
	rect_size = Vector2((texture.get_size().x + 2) * scale.x, (texture.get_size().y + 2) * scale.y)
	selectable = not destroyed and destroy_counters >= 0 and $"/root/Main/Pop-up Sprite/Pop-up".offset_y >= 128 and not reels.spinning and ($"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0 or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].prompt)
	active = selectable
	if selectable:
		if hovering and (not OS.is_window_focused() or ($"/root/Main".mouse_position.x < global_position.x or $"/root/Main".mouse_position.x > global_position.x + texture.get_size().x * scale.x or $"/root/Main".mouse_position.y < global_position.y or $"/root/Main".mouse_position.y > global_position.y + texture.get_size().y * scale.y)):
			unhover()
			hovering = false
		elif not hovering and OS.is_window_focused() and not ($"/root/Main".mouse_position.x < global_position.x or $"/root/Main".mouse_position.x > global_position.x + texture.get_size().x * scale.x or $"/root/Main".mouse_position.y < global_position.y or $"/root/Main".mouse_position.y > global_position.y + texture.get_size().y * scale.y):
			hover()
		if $"/root/Main".press_timer > 0 and destroyable and (((not ($"/root/Main".mouse_position.x < global_position.x or $"/root/Main".mouse_position.x > global_position.x + texture.get_size().x * scale.x or $"/root/Main".mouse_position.y < global_position.y or $"/root/Main".mouse_position.y > global_position.y + texture.get_size().y * scale.y)))):
			destroy()

func toggle_disabled():
	for fp in $"/root/Main/Landlord".fine_print:
		if fp.num == 31:
			return
	var ty = type.substr(0, type.find("_STEAM_ID_"))
	if ty == "popsicle" or ty == "popsicle_essence" or ty == "frozen_pizza_essence" or (modded and $"/root/Main".mod_data.items[type.substr(0, type.find("_STEAM_ID_"))].cannot_be_disabled):
		disabled = false
		return
	else:
		disabled = !disabled
	get_child(3).visible = disabled
	if disabled:
		c_effects.clear()
		get_parent().item_types[get_parent().item_types.find(type)] = type + "_d"
		var rarity_db = $"/root/Main".rarity_database
		if modded:
			for eff in $"/root/Main".item_database[type].effects.duplicate(true):
				if eff.has("value_to_change") and eff.value_to_change == "rarity":
					for comp in eff.comparisons:
						if typeof(comp.a) == TYPE_STRING and comp.a == "type":
							$"/root/Main".tile_database[$"/root/Main".existing_symbols[comp.b]].rarity = $"/root/Main".get_rarity($"/root/Main".base_rarities.symbols, $"/root/Main".existing_symbols[comp.b])
							$"/root/Main".rarity_database.symbols[$"/root/Main".existing_symbols[comp.b]] = $"/root/Main".get_rarity($"/root/Main".base_rarities.symbols, $"/root/Main".existing_symbols[comp.b])
						elif comp.a == "groups":
							for t in $"/root/Main".group_database.symbols[comp.b]:
								$"/root/Main".tile_database[t].rarity = $"/root/Main".get_rarity($"/root/Main".base_rarities.symbols, t)
								$"/root/Main".rarity_database.symbols[t] = $"/root/Main".get_rarity($"/root/Main".base_rarities.symbols, t)
			match type.substr(0, type.find("_STEAM_ID_")):
				"rain_cloud":
					if rarity_db["symbols"]["common"].has("rain"):
						rarity_db["symbols"]["common"].erase("rain")
						rarity_db["symbols"]["uncommon"].push_back("rain")
						$"/root/Main".tile_database["rain"].rarity = "uncommon"
				"dark_humor":
					if rarity_db["symbols"]["uncommon"].has("comedian"):
						rarity_db["symbols"]["uncommon"].erase("comedian")
						rarity_db["symbols"]["rare"].push_back("comedian")
						$"/root/Main".tile_database["comedian"].rarity = "rare"
				"void_party":
					if rarity_db["symbols"]["common"].has("void_creature"):
						rarity_db["symbols"]["common"].erase("void_creature")
						rarity_db["symbols"]["uncommon"].push_back("void_creature")
						$"/root/Main".tile_database["void_creature"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("void_stone"):
						rarity_db["symbols"]["common"].erase("void_stone")
						rarity_db["symbols"]["uncommon"].push_back("void_stone")
						$"/root/Main".tile_database["void_stone"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("void_fruit"):
						rarity_db["symbols"]["common"].erase("void_fruit")
						rarity_db["symbols"]["uncommon"].push_back("void_fruit")
						$"/root/Main".tile_database["void_fruit"].rarity = "uncommon"
				"flush":
					if rarity_db["symbols"]["common"].has("clubs"):
						rarity_db["symbols"]["common"].erase("clubs")
						rarity_db["symbols"]["uncommon"].push_back("clubs")
						$"/root/Main".tile_database["clubs"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("diamonds"):
						rarity_db["symbols"]["common"].erase("diamonds")
						rarity_db["symbols"]["uncommon"].push_back("diamonds")
						$"/root/Main".tile_database["diamonds"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("hearts"):
						rarity_db["symbols"]["common"].erase("hearts")
						rarity_db["symbols"]["uncommon"].push_back("hearts")
						$"/root/Main".tile_database["hearts"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("spades"):
						rarity_db["symbols"]["common"].erase("spades")
						rarity_db["symbols"]["uncommon"].push_back("spades")
						$"/root/Main".tile_database["spades"].rarity = "uncommon"
		else:
			$"/root/Main".rarity_database = $"/root/Main".base_rarities.duplicate(true)
			match type:
				"rain_cloud":
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["rain"]].rarity = "uncommon"
				"dark_humor":
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["comedian"]].rarity = "rare"
				"void_party":
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["void_creature"]].rarity = "uncommon"
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["void_stone"]].rarity = "uncommon"
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["void_fruit"]].rarity = "uncommon"
				"flush":
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["clubs"]].rarity = "uncommon"
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["diamonds"]].rarity = "uncommon"
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["hearts"]].rarity = "uncommon"
					$"/root/Main".tile_database[$"/root/Main".existing_symbols["spades"]].rarity = "uncommon"
	else:
		get_parent().item_types[get_parent().item_types.find(type + "_d")] = type
		if type == "void_portal":
			saved_value = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types_size
			update_value_text()
		var rarity_db = $"/root/Main".rarity_database
		if modded:
			for eff in $"/root/Main".item_database[type].effects:
				if eff.has("value_to_change") and eff.value_to_change == "rarity":
					$"/root/Main".rarity_database = $"/root/Main".base_rarities.duplicate(true)
					for comp in eff.comparisons:
						if comp.a == "type":
							$"/root/Main".tile_database[$"/root/Main".existing_symbols[comp.b]].rarity = eff.diff
							$"/root/Main".rarity_database.symbols[$"/root/Main".existing_symbols[comp.b]] = eff.diff
						elif comp.a == "groups":
							for t in $"/root/Main".group_database.symbols[comp.b]:
								$"/root/Main".tile_database[t].rarity = eff.diff
								$"/root/Main".rarity_database.symbols[t] = eff.diff
			match type.substr(0, type.find("_STEAM_ID_")):
				"rain_cloud":
					if rarity_db["symbols"]["uncommon"].has("rain"):
						rarity_db["symbols"]["uncommon"].erase("rain")
						rarity_db["symbols"]["common"].push_back("rain")
						$"/root/Main".tile_database["rain"].rarity = "common"
				"dark_humor":
					if rarity_db["symbols"]["rare"].has("comedian"):
						rarity_db["symbols"]["rare"].erase("comedian")
						rarity_db["symbols"]["uncommon"].push_back("comedian")
						$"/root/Main".tile_database["comedian"].rarity = "uncommon"
				"void_party":
					if rarity_db["symbols"]["uncommon"].has("void_creature"):
						rarity_db["symbols"]["uncommon"].erase("void_creature")
						rarity_db["symbols"]["common"].push_back("void_creature")
						$"/root/Main".tile_database["void_creature"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("void_stone"):
						rarity_db["symbols"]["uncommon"].erase("void_stone")
						rarity_db["symbols"]["common"].push_back("void_stone")
						$"/root/Main".tile_database["void_stone"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("void_fruit"):
						rarity_db["symbols"]["uncommon"].erase("void_fruit")
						rarity_db["symbols"]["common"].push_back("void_fruit")
						$"/root/Main".tile_database["void_fruit"].rarity = "common"
				"flush":
					if rarity_db["symbols"]["uncommon"].has("clubs"):
						rarity_db["symbols"]["uncommon"].erase("clubs")
						rarity_db["symbols"]["common"].push_back("clubs")
						$"/root/Main".tile_database["clubs"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("diamonds"):
						rarity_db["symbols"]["uncommon"].erase("diamonds")
						rarity_db["symbols"]["common"].push_back("diamonds")
						$"/root/Main".tile_database["diamonds"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("hearts"):
						rarity_db["symbols"]["uncommon"].erase("hearts")
						rarity_db["symbols"]["common"].push_back("hearts")
						$"/root/Main".tile_database["hearts"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("spades"):
						rarity_db["symbols"]["uncommon"].erase("spades")
						rarity_db["symbols"]["common"].push_back("spades")
						$"/root/Main".tile_database["spades"].rarity = "common"
		else:
			match type:
				"rain_cloud":
					if rarity_db["symbols"]["uncommon"].has("rain"):
						rarity_db["symbols"]["uncommon"].erase("rain")
						rarity_db["symbols"]["common"].push_back("rain")
						$"/root/Main".tile_database["rain"].rarity = "common"
				"dark_humor":
					if rarity_db["symbols"]["rare"].has("comedian"):
						rarity_db["symbols"]["rare"].erase("comedian")
						rarity_db["symbols"]["uncommon"].push_back("comedian")
						$"/root/Main".tile_database["comedian"].rarity = "uncommon"
				"void_party":
					if rarity_db["symbols"]["common"].has("void_creature"):
						rarity_db["symbols"]["common"].erase("void_creature")
						rarity_db["symbols"]["uncommon"].push_back("void_creature")
						$"/root/Main".tile_database["void_creature"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("void_stone"):
						rarity_db["symbols"]["common"].erase("void_stone")
						rarity_db["symbols"]["uncommon"].push_back("void_stone")
						$"/root/Main".tile_database["void_stone"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("void_fruit"):
						rarity_db["symbols"]["common"].erase("void_fruit")
						rarity_db["symbols"]["uncommon"].push_back("void_fruit")
						$"/root/Main".tile_database["void_fruit"].rarity = "uncommon"
				"flush":
					if rarity_db["symbols"]["common"].has("clubs"):
						rarity_db["symbols"]["common"].erase("clubs")
						rarity_db["symbols"]["uncommon"].push_back("clubs")
						$"/root/Main".tile_database["clubs"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("diamonds"):
						rarity_db["symbols"]["common"].erase("diamonds")
						rarity_db["symbols"]["uncommon"].push_back("diamonds")
						$"/root/Main".tile_database["diamonds"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("hearts"):
						rarity_db["symbols"]["common"].erase("hearts")
						rarity_db["symbols"]["uncommon"].push_back("hearts")
						$"/root/Main".tile_database["hearts"].rarity = "uncommon"
					if rarity_db["symbols"]["common"].has("spades"):
						rarity_db["symbols"]["common"].erase("spades")
						rarity_db["symbols"]["uncommon"].push_back("spades")
						$"/root/Main".tile_database["spades"].rarity = "uncommon"
	$"/root/Main".save_game()

func set_type(_type):
	type = _type
	if $"/root/Main".icon_texture_database.has(type):
		texture = $"/root/Main".icon_texture_database[type]
	else:
		texture = $"/root/Main".icon_texture_database["item_missing"]

func get_author_id(c, p_id, comp, target, v_num):
	var id
	if p_id != null and p_id != "0":
		id = p_id
	elif c != null and c.has("giver"):
		id = $"/root/Main".mod_data.items[c.giver.type].author_id
	else:
		id = $"/root/Main".mod_data.items[target.type].author_id
	if not target.saved_values.has(id):
		target.saved_values[id] = []
	if comp == null:
		if v_num != null:
			if v_num >= target.saved_values[id].size() - 1:
				for i in range(v_num + 1 - target.saved_values[id].size()):
					target.saved_values[id].push_back(0)
		elif c.value_num >= target.saved_values[id].size() - 1:
			for i in range(c.value_num + 1 - target.saved_values[id].size()):
				target.saved_values[id].push_back(0)
	else:
		if comp.value_num >= target.saved_values[id].size() - 1:
			for i in range(comp.value_num + 1 - target.saved_values[id].size()):
				target.saved_values[id].push_back(0)
	return id

func can_add_tooltip():
	if tooltips.get_children().size() == 0 and type != "item_missing":
		return true
	else:
		return false

func hover():
	var container = $"/root/Main/Pop-up Sprite/Pop-up/Container"
	if can_add_tooltip() and visible and not Rect2(global_position.x, global_position.y, texture.get_size().x * scale.x, texture.get_size().y * scale.y).intersects(Rect2(container.rect_global_position.x, container.rect_global_position.y, container.rect_size.x, container.rect_size.y)):
		hovering = true
		var tooltip = load("res://Tooltip.tscn").instance()
		tooltip.get_child(0).data = $"/root/Main/".item_database[type]
		tooltip.get_child(0).data.erase("value")
		tooltip.source = self
		if destroyable:
			tooltip.extra_desc_text = "\n\n<color_797979>" + tr("destroy_reminder") + "<end>"
			if str(Input.get_joy_name(0)) != "":
				tooltip.extra_desc_text += " " + $"/root/Main/Options Sprite/Options".hotkeys["confirm_select"][3]
		if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and $"/root/Main/Selector Sprite/Selector".visible:
			tooltip.controller_tooltip = true
		tooltips.add_child(tooltip)
		tts()

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	var t_label = preload("res://Outline Label.tscn").instance()
	t_label.visible = false
	add_child(t_label)
	t_label.raw_string = tr(type) + "\n"
	if rarity != "none":
		t_label.raw_string += tr(rarity) + "\n"
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		t_label.get_child(0).custom_max_width = 10000000
	else:
		t_label.custom_max_width = 10000000
	t_label.tts = true
	t_label.update()
	var start
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		start = t_label.get_child(0).text
	else:
		start = t_label.text
	remove_child(t_label)
	t_label.queue_free()
	if tr(type + "_desc") == type + "_desc":
		if destroyable:
			$"/root/Main".tts(start + tr(type) + "\n" + tr("destroy_reminder"), [], self)
		else:
			$"/root/Main".tts(start + tr(type), [], self)
	else:
		if destroyable:
			$"/root/Main".tts(start + tr(type + "_desc") + "\n" + tr("destroy_reminder"), values, self)
		else:
			$"/root/Main".tts(start + tr(type + "_desc"), values, self)

func unhover():
	for t in tooltips.get_children():
		if t.locked_pos == null:
			t.queue_free()

func temp_destroy():
	if destroy_counters <= 1:
		modulate.a = 0.3
	var ty = type.substr(0, type.find("_STEAM_ID_"))
	if (reels.checking_effects and ty != "brown_pepper_essence") or ty == "symbol_bomb_small_essence" or ty == "symbol_bomb_big_essence" or ty == "symbol_bomb_very_big_essence" or ty == "frozen_pizza_essence" or ty == "shattered_mirror_essence" or ty == "lunchbox_essence" or (ty == "brown_pepper_essence" and not reels.checking_effects) or ty == "gray_pepper_essence" or ty == "lime_pepper_essence" or ty == "pink_pepper_essence" or ty == "adoption_papers_essence" or ty == "quigley_the_wolf_essence" or ty == "comfy_pillow_essence" or ty == "symbol_bomb_quantum_essence":
		destroy()
	else:
		destroyed = true
		update_value_text()
		get_parent().items_destroyed_this_spin.push_back(type)

func parse_conditional(v1, v2, cond):
	match cond:
		"greater_than_eq":
			if v1 >= v2:
				return true
		"greater_than":
			if v1 > v2:
				return true
		"less_than_eq":
			if v1 <= v2:
				return true
		"less_than":
			if v1 < v2:
				return true
		_:
			if v1 == v2:
				return true
	return false

func parse_var_math(data, giver, eff):
	var num = 0
	if data.has("starting_value"):
		var a = data.starting_value
		match a:
			"coins":
				num = $"/root/Main/Coins".coins
			"reroll_tokens":
				num = $"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens
			"removal_tokens":
				num = $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens
			"essence_tokens":
				num = $"/root/Main/Pop-up Sprite/Pop-up".essence_tokens
			"rent_due":
				num = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[0]
			"spins_left":
				num = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1]
			"hotfix_num":
				num = $"/root/Main".hotfix_num
			"symbols_destroyed_this_spin":
				num = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
			"items_destroyed_this_spin":
				num = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
			"extra_symbol_choices":
				num = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
			"extra_item_choices":
				num = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices
			"symbols_to_choose_from":
				num = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
			"items_to_choose_from":
				num = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
			"non_singular_symbols":
				num = $"/root/Main/Reels".get_non_singular_symbols()
			"var_math", "starting_value":
				num = parse_var_math(a, giver, eff)
			_:
				if typeof(a) == TYPE_STRING:
					if data.has("target_self") and data.target_self:
						num = giver[a]
					else:
						num = self[a]
				elif typeof(a) == TYPE_DICTIONARY:
					if a.has("var_math") or a.has("starting_value"):
						num = parse_var_math(a, giver, eff)
					elif a.has("rand_num"):
						var minimum = 0
						var maximum = 100
						if a.rand_num.has("min"):
							minimum = a.rand_num.min
						if a.rand_num.has("max"):
							maximum = a.rand_num.max
						randomize()
						num = rand_range(minimum, maximum)
						if a.rand_num.has("floor"):
							num = floor(num)
						elif a.rand_num.has("ceil"):
							num = ceil(num)
						elif a.rand_num.has("round"):
							num = round(num)
					elif a.has("counted_adjacent_symbols"):
						num = 0
						if a.counted_adjacent_symbols.has("type"):
							var t = a.counted_adjacent_symbols.type
							var with_id = t
							if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
								with_id = $"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t])]
								if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
									with_id = t
							reels.making_group_clumps = {"types": [with_id]}
							reels.make_clumps()
							for c in reels.group_clumps:
								if c.size() >= num and with_id == c[0].type:
									num = c.size()
									for s in c:
										affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
							reels.making_group_clumps = null
						elif a.counted_adjacent_symbols.has("groups"):
							reels.making_group_clumps = {"groups": [a.counted_adjacent_symbols.groups]}
							reels.make_clumps()
							for c in reels.group_clumps:
								if c.size() >= num and $"/root/Main".group_database["symbols"][a.counted_adjacent_symbols.groups].has(c[0].type):
									num = c.size()
									for s in c:
										affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
							reels.making_group_clumps = null
					elif a.has("counted_items"):
						num = 0
						var with_id = a.counted_items
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(a.counted_items):
							with_id = $"/root/Main".append_steam_id(a.counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(a.counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_items])]
							if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = a.counted_items
						if get_parent().item_types.has(with_id):
							num = get_parent().items[get_parent().item_types.find(with_id)].item_count
					elif a.has("counted_destroyed_items"):
						num = 0
						var with_id = a.counted_destroyed_items
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(a.counted_destroyed_items):
							with_id = $"/root/Main".append_steam_id(a.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(a.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_destroyed_items])]
							if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = a.counted_destroyed_items
						num = get_parent().destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
					elif a.has("counted_symbols"):
						num = 0
						reels.count_symbols(true)
						var with_id = a.counted_symbols
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(a.counted_symbols):
							with_id = $"/root/Main".append_steam_id(a.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[a.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(a.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[a.counted_symbols])]
							if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = a.counted_symbols
						if reels.counted_symbols.has(with_id):
							num = reels.counted_symbols[with_id]
					elif a.has("saved_values"):
						var p_id = type.substr(type.find("_STEAM_ID_") + 10, -1)
						p_id = p_id.substr(0, p_id.find("_PACK_"))
						var id = get_author_id(null, p_id, null, self, a.saved_values.value_num)
						num = saved_values[id][a.saved_values.value_num]
						eff["v_num"] = [id, a.saved_values.value_num].hash()
					elif a.has("destroyed_symbol_type_count"):
						if $"/root/Main".existing_symbols.has(a.destroyed_symbol_type_count):
							num = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count($"/root/Main".existing_symbols[a.destroyed_symbol_type_count])
						else:
							num = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(a.destroyed_symbol_type_count)
					elif a.has("removed_symbol_type_count"):
						if $"/root/Main".existing_symbols.has(a.removed_symbol_type_count):
							num = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count($"/root/Main".existing_symbols[a.removed_symbol_type_count])
						else:
							num = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(a.removed_symbol_type_count)
					elif a.has("destroyed_symbol_group_count"):
						num = 0
						for g in $"/root/Main".group_database.symbols[a.destroyed_symbol_group_count]:
							num += $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(g)
					elif a.has("removed_symbol_group_count"):
						num = 0
						for g in $"/root/Main".group_database.symbols[a.removed_symbol_group_count]:
							num += $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(g)
					elif a.has("symbols_in_inventory"):
						num = 0
						if a.symbols_in_inventory.has("type"):
							if $"/root/Main".existing_symbols.has(a.symbols_in_inventory.type):
								a.symbols_in_inventory.type = $"/root/Main".existing_symbols[a.symbols_in_inventory.type]
							for r in $"/root/Main/Reels".reels:
								for t in r.icon_types:
									if t == a.symbols_in_inventory.type:
										num += 1
						elif a.symbols_in_inventory.has("groups"):
							for r in $"/root/Main/Reels".reels:
								for t in r.icon_types:
									if $"/root/Main".group_database.symbols[a.symbols_in_inventory.groups].has(t):
										num += 1
				else:
					num = a
		if typeof(a) == TYPE_DICTIONARY and a.has("abs") and a.abs:
			num = abs(num)
	if data.has("var_math"):
		for a in data.var_math:
			var v = a[a.keys()[0]]
			if typeof(v) == TYPE_STRING or typeof(v) == TYPE_DICTIONARY:
				match v:
					"coins":
						v = $"/root/Main/Coins".coins
					"reroll_tokens":
						v = $"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens
					"removal_tokens":
						v = $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens
					"essence_tokens":
						v = $"/root/Main/Pop-up Sprite/Pop-up".essence_tokens
					"rent_due":
						v = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[0]
					"spins_left":
						v = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1]
					"hotfix_num":
						v = $"/root/Main".hotfix_num
					"symbols_destroyed_this_spin":
						v = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
					"items_destroyed_this_spin":
						v = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
					"extra_symbol_choices":
						v = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
					"extra_item_choices":
						v = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices
					"symbols_to_choose_from":
						v = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
					"items_to_choose_from":
						v = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
					"non_singular_symbols":
						v = $"/root/Main/Reels".get_non_singular_symbols()
					"var_math", "starting_value":
						v = parse_var_math(v, giver, eff)
					_:
						if typeof(v) == TYPE_STRING:
							if a.has("target_self") and a.target_self:
								v = giver[v]
							else:
								v = self[v]
						elif typeof(v) == TYPE_DICTIONARY:
							if v.has("var_math") or v.has("starting_value"):
								v = parse_var_math(v, giver, eff)
							elif v.has("rand_num"):
								var minimum = 0
								var maximum = 100
								if v.rand_num.has("min"):
									minimum = v.rand_num.min
								if v.rand_num.has("max"):
									maximum = v.rand_num.max
								randomize()
								var rnd = rand_range(minimum, maximum)
								if v.rand_num.has("floor"):
									v = floor(rnd)
								elif v.rand_num.has("ceil"):
									v = ceil(rnd)
								elif v.rand_num.has("round"):
									v = round(rnd)
								else:
									v = rnd
									num = 0
							elif v.has("counted_adjacent_symbols"):
								if v.counted_adjacent_symbols.has("type"):
									var t = v.counted_adjacent_symbols.type
									var with_id = t
									if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
										with_id = $"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t])]
										if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
											with_id = t
									reels.making_group_clumps = {"types": [with_id]}
									reels.make_clumps()
									for c in reels.group_clumps:
										if c.size() >= num and with_id == c[0].type:
											num = c.size()
										for s in c:
											affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
									reels.making_group_clumps = null
								elif v.counted_adjacent_symbols.has("groups"):
									var n = 0
									reels.making_group_clumps = {"groups": [v.counted_adjacent_symbols.groups]}
									reels.make_clumps()
									for c in reels.group_clumps:
										if c.size() >= num and $"/root/Main".group_database["symbols"][v.counted_adjacent_symbols.groups].has(c[0].type):
											n = c.size()
											for s in c:
												affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
									reels.making_group_clumps = null
									v = n
							elif v.has("counted_items"):
								var with_id = v.counted_items
								if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(v.counted_items):
									with_id = $"/root/Main".append_steam_id(v.counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(v.counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_items])]
									if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
										with_id = v.counted_items
								if get_parent().item_types.has(with_id):
									v = get_parent().items[get_parent().item_types.find(with_id)].item_count
								else:
									v = 0
							elif v.has("counted_destroyed_items"):
								var with_id = v.counted_destroyed_items
								if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(v.counted_destroyed_items):
									with_id = $"/root/Main".append_steam_id(v.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(v.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_destroyed_items])]
									if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
										with_id = v.counted_destroyed_items
								v = get_parent().destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
							elif v.has("counted_symbols"):
								reels.count_symbols(true)
								var with_id = v.counted_symbols
								if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(v.counted_symbols):
									with_id = $"/root/Main".append_steam_id(v.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[v.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(v.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[v.counted_symbols])]
									if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
										with_id = v.counted_symbols
								if reels.counted_symbols.has(with_id):
									v = reels.counted_symbols[with_id]
								else:
									v = 0
							elif v.has("saved_values"):
								var p_id = type.substr(type.find("_STEAM_ID_") + 10, -1)
								p_id = p_id.substr(0, p_id.find("_PACK_"))
								var id = get_author_id(null, p_id, null, self, v.saved_values.value_num)
								eff["v_num"] = [id, v.saved_values.value_num].hash()
								v = saved_values[id][v.saved_values.value_num]
							elif v.has("destroyed_symbol_type_count"):
								if $"/root/Main".existing_symbols.has(v.destroyed_symbol_type_count):
									v = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count($"/root/Main".existing_symbols[v.destroyed_symbol_type_count])
								else:
									v = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(v.destroyed_symbol_type_count)
							elif v.has("removed_symbol_type_count"):
								if $"/root/Main".existing_symbols.has(v.removed_symbol_type_count):
									v = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count($"/root/Main".existing_symbols[v.removed_symbol_type_count])
								else:
									v = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(v.removed_symbol_type_count)
							elif v.has("destroyed_symbol_group_count"):
								var n = 0
								for g in $"/root/Main".group_database.symbols[v.destroyed_symbol_group_count]:
									n += $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(g)
								v = n
							elif v.has("removed_symbol_group_count"):
								var n = 0
								for g in $"/root/Main".group_database.symbols[v.removed_symbol_group_count]:
									n += $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(g)
								v = n
							elif v.has("symbols_in_inventory"):
								var n = 0
								if v.symbols_in_inventory.has("type"):
									if $"/root/Main".existing_symbols.has(v.symbols_in_inventory.type):
										v.symbols_in_inventory.type = $"/root/Main".existing_symbols[v.symbols_in_inventory.type]
									for r in $"/root/Main/Reels".reels:
										for t in r.icon_types:
											if t == v.symbols_in_inventory.type:
												n += 1
								elif v.symbols_in_inventory.has("groups"):
									for r in $"/root/Main/Reels".reels:
										for t in r.icon_types:
											if $"/root/Main".group_database.symbols[v.symbols_in_inventory.groups].has(t):
												n += 1
								v = n
			if a.has("*"):
				num *= v
			elif a.has("/"):
				num /= v
			elif a.has("+"):
				num += v
			elif a.has("-"):
				num -= v
			if a.has("abs"):
				num = abs(num)
	if data.has("floor"):
		num = floor(num)
	elif data.has("ceil"):
		num = ceil(num)
	elif data.has("round"):
		num = round(num)
	return num

func destroy():
	var popup = $"/root/Main/Pop-up Sprite/Pop-up"
	var can_be_destroyed = true
	if Steam.isSteamRunningOnSteamDeck():
		$"/root/Main".press_timer = 0
	var ty = type.substr(0, type.find("_STEAM_ID_"))
	match ty:
		"devils_deal":
			var arr = []
			for i in range(values[0]):
				arr.push_back("dud")
			reels.add_tile(arr)
		"symbol_bomb_small":
			popup.add_event("add_tile", {"after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back(null)
		"symbol_bomb_big":
			popup.add_event("add_tile", {"after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back(null)
		"symbol_bomb_very_big":
			popup.add_event("add_tile", {"after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back(null)
		"booster_pack":
			popup.add_event("add_tile", {"forced_rarity": ["common", "common", "common"], "all_symbols_same": true, "after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back({"forced_rarity": ["common", "common", "common"], "all_symbols_same": true, "after_spin": false})
			for i in range(values[1]):
				popup.queued_symbols.push_back({"forced_rarity": ["uncommon", "uncommon", "uncommon"], "all_symbols_same": true, "after_spin": false})
			for i in range(values[2]):
				popup.queued_symbols.push_back({"forced_rarity": ["rare", "rare", "rare"], "all_symbols_same": true, "after_spin": false})
		"piggy_bank":
			$"/root/Main/Sums/Coin Sum".add_value(round(saved_value * values[1]))
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(round(saved_value * values[1]))
			$"/root/Main/Sums/HP Sum".adding = true
		"swear_jar":
			$"/root/Main/Sums/Coin Sum".add_value(saved_value * values[1])
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(saved_value * values[1])
			$"/root/Main/Sums/HP Sum".adding = true
		"coffee":
			popup.rent_values[1] += 1
		"barrel_o_dwarves":
			var arr = []
			for i in range(values[0]):
				arr.push_back("dwarf")
			reels.add_tile(arr)
		"goldilocks":
			var arr = []
			for i in range(values[0]):
				arr.push_back("bear")
			reels.add_tile(arr)
		"lunchbox":
			popup.add_event("add_tile", {"forced_group": "food", "after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back({"forced_group": "food", "after_spin": false})
		"treasure_map":
			if saved_value >= values[0]:
				reels.add_tile(["key"])
				reels.add_tile(["treasure_chest"])
			else:
				can_be_destroyed = false
		"blue_suits":
			if saved_value >= values[0]:
				reels.add_tile(["clubs"])
				reels.add_tile(["spades"])
			else:
				can_be_destroyed = false
		"red_suits":
			if saved_value >= values[0]:
				reels.add_tile(["diamonds"])
				reels.add_tile(["hearts"])
			else:
				can_be_destroyed = false
		"treasure_map_essence":
			reels.add_tile(["key"])
			reels.add_tile(["mega_chest"])
		"adoption_papers":
			popup.add_event("add_tile", {"forced_group": "animal", "after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back({"forced_group": "animal", "after_spin": false})
		"booster_pack_essence":
			for i in range(values[0]):
				popup.add_event("add_tile", {"forced_rarity": ["uncommon", "uncommon", "uncommon"], "all_symbols_same": true})
			for i in range(values[2]):
				popup.add_event("add_tile", {"forced_rarity": ["very_rare", "very_rare", "very_rare"], "all_symbols_same": true})
		"coffee_essence":
			popup.rent_values[1] += values[0] + 1
		"bag_of_holding_essence":
			for i in range(values[0]):
				popup.add_event("add_item", {"push_front": true})
			popup.delay_timer = 0
		"symbol_bomb_quantum":
			popup.add_event("add_tile", {"forced_group": "passed", "after_spin": false})
			popup.delay_timer = 0
			for i in range(values[0] - 1):
				popup.queued_symbols.push_back({"forced_group": "passed", "after_spin": false})
	for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.items:
		if type == m.type:
			var currency_values = {"coins": 0, "reroll": 0, "removal": 0, "essence": 0}
			for e in m.effects:
				var eff = e.duplicate(true)
				if eff.has("comparisons"):
					var correct_comp = false
					for comp in eff.comparisons:
						if comp.hash() == {"a": "destroyed", "b": true}.hash():
							correct_comp = true
							break
					if correct_comp and not reels.effects_playing and not reels.checking_effects and not reels.counting_effects:
						if eff.has("value_to_change"):
							if typeof(eff.diff) == TYPE_DICTIONARY:
								eff.diff = parse_var_math(eff.diff, self, eff)
							if eff.value_to_change == "value":
								currency_values.coins += eff.diff * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(m.type)].item_count
							elif eff.value_to_change == "reroll_value":
								currency_values.reroll += eff.diff * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(m.type)].item_count
							elif eff.value_to_change == "removal_value":
								currency_values.removal += eff.diff * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(m.type)].item_count
							elif eff.value_to_change == "essence_value":
								currency_values.essence += eff.diff * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(m.type)].item_count
							elif eff.value_to_change == "extra_symbol_choices":
								$"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices += eff.diff
							elif eff.value_to_change == "extra_item_choices":
								$"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices += eff.diff
							elif eff.value_to_change == "spins_left":
								$"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] += eff.diff
						if eff.has("tiles_to_add"):
							var destroyed_symbols = []
							var symbol_arr = []
							if eff.tiles_to_add.has("prev_destroyed_symbol"):
								destroyed_symbols = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.duplicate(true)
								var d_tbe = []
								for d in destroyed_symbols:
									if d == "time_capsule" or $"/root/Main".group_database["symbols"]["time_capsule_effects"].has(d) or $"/root/Main".rarity_database["symbols"]["none"].has(d) or (not reels.can_add_highlander() and d == "highlander"):
										d_tbe.push_back(d)
								for d in d_tbe:
									destroyed_symbols.erase(d)
							for t in eff.tiles_to_add:
								if typeof(t) == TYPE_STRING and t == "prev_destroyed_symbol":
									if destroyed_symbols.size() > 0:
										symbol_arr.push_back(destroyed_symbols[floor(rand_range(0, destroyed_symbols.size()))])
								elif t.has("group"):
									randomize()
									var rand_num = rand_range(0, 1)
									var r_chances = $"/root/Main/".rarity_chances["symbols"].duplicate(true)
									r_chances["uncommon"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["uncommon"]
									r_chances["rare"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["rare"]
									r_chances["very_rare"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["very_rare"]
									
									var group_db = $"/root/Main".group_database["symbols"][t.group].duplicate(true)
									
									var possible_symbol_counts = { "common": 0, "uncommon": 0, "rare": 0, "very_rare": 0 }
									
									for z in group_db:
										if $"/root/Main".rarity_database["symbols"]["common"].has(z):
											possible_symbol_counts["common"] += 1
										elif $"/root/Main".rarity_database["symbols"]["uncommon"].has(z):
											possible_symbol_counts["uncommon"] += 1
										elif $"/root/Main".rarity_database["symbols"]["rare"].has(z):
											possible_symbol_counts["rare"] += 1
										elif $"/root/Main".rarity_database["symbols"]["very_rare"].has(z):
											possible_symbol_counts["very_rare"] += 1
											
									var rar = "common"
									if t.has("min_rarity"):
										rar = t.min_rarity
									if rand_num < r_chances.very_rare and possible_symbol_counts["very_rare"] > 0:
										rar = "very_rare"
									elif rand_num < r_chances.very_rare + r_chances.rare and rar != "very_rare" and possible_symbol_counts["rare"] > 0:
										rar = "rare"
									elif rand_num < r_chances.very_rare + r_chances.rare + r_chances.uncommon and rar != "rare" and rar != "very_rare" and possible_symbol_counts["uncommon"] > 0:
										rar = "uncommon"
										
									var possible_symbols = []
									var rarities = ["common", "uncommon", "rare", "very_rare"]
									
									rarities.erase(rar)
									
									if t.has("min_rarity"):
										rarities.clear()
									
									while possible_symbols.size() == 0 and rar != null:
										for z in group_db:
											if $"/root/Main".rarity_database["symbols"][rar].has(z):
												possible_symbols.push_back(z)
										if possible_symbols.size() > 0:
											reels.add_tile([possible_symbols[floor(rand_range(0, possible_symbols.size()))]])
											break
										if rarities.size() > 0:
											rar = rarities[0]
											rarities.remove(0)
										else:
											rar = null
								else:
									if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t.type):
										var with_id = $"/root/Main".append_steam_id(t.type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]) + "_PACK_" + $"/root/Main".mod_pack_nums[t.type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]]
										if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t.type) and not $"/root/Main".mod_data.symbols[with_id].art_replacement and not $"/root/Main".is_mod_disabled(with_id):
											reels.add_tile([with_id])
										else:
											reels.add_tile([$"/root/Main".existing_symbols[t.type]])
									else:
										reels.add_tile([$"/root/Main".existing_symbols[t.type]])
							for s in symbol_arr:
								reels.symbol_queue.push_back(s)
							for x in range(reels.reel_width):
								for y in range(reels.reel_height):
									reels.add_symbol_position_to_update(Vector2(x, y))
							
							for s in symbol_arr:
								if $"/root/Main/Reels".checking_effects:
									$"/root/Main/Reels".symbol_queue.push_back(s)
								else:
									$"/root/Main/Reels".add_tile([s])
						if eff.has("items_to_add"):
							for i in eff.items_to_add:
								if i.has("rarity"):
									var item_pool = $"/root/Main/".rarity_database["items"][i.rarity].duplicate(true)
									for z in $"/root/Main/Items".items:
										item_pool.erase(z.type)
									randomize()
									if item_pool.size() > 0:
										$"/root/Main/Items".add_item(item_pool[floor(rand_range(0, item_pool.size()))])
									else:
										$"/root/Main/Items".add_item("pool_ball")
								else:
									$"/root/Main/Items".add_item(i.type)
			if currency_values["coins"] != 0:
				$"/root/Main/Sums/Coin Sum".add_value(currency_values["coins"])
				$"/root/Main/Sums/Coin Sum".adding = true
				$"/root/Main/Sums/HP Sum".add_value(currency_values["coins"])
				$"/root/Main/Sums/HP Sum".adding = true
			if currency_values["reroll"] != 0 or currency_values["removal"] != 0 or currency_values["essence"] != 0:
				$"/root/Main/Sums/Extra Sum".add_value(currency_values["reroll"], currency_values["removal"], currency_values["essence"])
				$"/root/Main/Sums/Extra Sum".adding = true
				$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens += currency_values["removal"]
				$"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens += currency_values["reroll"]
				$"/root/Main/Pop-up Sprite/Pop-up".essence_tokens += currency_values["essence"]
	var pos = get_parent().item_types.find(type)
	if can_be_destroyed:
		$"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin += 1
	if can_be_destroyed and item_count > 1:
		item_count -= 1
		get_parent().destroyed_item_types.push_back(type)
		$"/root/Main".write_log("Destroyed item - " + type + ", " + str(item_count) + " left")
		get_parent().item_count_data[pos] = item_count
		if $"/root/Main".item_database[type].groups.has("essence"):
			saved_value = 0
			saved_values.clear()
		update_value_text()
		$"/root/Main".save_game()
	elif can_be_destroyed and destroy_counters <= 1:
		destroy_counters = -1
		get_parent().destroyed_items.push_back(type)
		if type != "lucky_seven" and destroy_counters <= 1:
			get_parent().destroyed_item_types.push_back(type)
			if $"/root/Main".is_mod_disabled($"/root/Main".existing_items[type]):
				get_parent().recently_destroyed_items.push_back({"type": $"/root/Main".existing_items[type].substr(0, $"/root/Main".existing_items[type].find("_STEAM_ID_")), "rarity": $"/root/Main".item_database[$"/root/Main".existing_items[type].substr(0, $"/root/Main".existing_items[type].find("_STEAM_ID_"))].rarity, "payments": 3})
			else:
				get_parent().recently_destroyed_items.push_back({"type": $"/root/Main".existing_items[type], "rarity": $"/root/Main".item_database[$"/root/Main".existing_items[type]].rarity, "payments": 3})
		reels.texts.remove(reels.texts.size() - 1)
		get_parent().item_types.remove(pos)
		get_parent().saved_item_data.remove(pos)
		get_parent().item_count_data.remove(pos)
		get_parent().saved_destroy_counters.remove(pos)
		$"/root/Main".write_log("Destroyed item - " + type)
		$"/root/Main".save_game()
		
		destroyed = true
		get_parent().items_destroyed_this_spin.push_back(type)

		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
		get_parent().items.erase(self)
		
		if $"/root/Main".item_database[type].groups.has("essence"):
			if get_parent().has_unmodded_item("popsicle_essence") and not get_parent().items[get_parent().item_types.find($"/root/Main".existing_items["popsicle_essence"])].destroyed:
				for i in get_parent().items:
					if i.type == $"/root/Main".existing_items["popsicle_essence"]:
						i.destroy()
						break
		
		while get_parent().page * get_parent().visible_items >= get_parent().items.size() and get_parent().items.size() != 0:
			get_parent().page -= 1
		get_parent().update_page_buttons()
		get_parent().update_positions()
		get_parent().remove_child(self)
	elif can_be_destroyed and destroy_counters > 1:
		destroy_counters -= 1
		get_parent().destroyed_item_types.push_back(type)
		$"/root/Main".write_log("Destroy counters - " + type + " now has " + str(destroy_counters))
		get_parent().saved_destroy_counters[pos] = destroy_counters
		destroyed = true
		if $"/root/Main".item_database[type].groups.has("essence"):
			saved_value = 0
			saved_values.clear()
		update_value_text()

func symbol_check():
	var prev_symbol_trigger = symbol_trigger
	var prev_affected_symbols_positions = []
	var affected_symbol_positions = []
	var value_reset = false
	for s in affected_symbols:
		prev_affected_symbols_positions.push_back(Vector2(s.grid_position.x, s.grid_position.y))
	if not disabled and not prev_symbol_trigger:
		match type:
			"red_pepper", "red_pepper_essence":
				var symbol_types = []
				symbol_trigger = true
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if symbol_types.has(reels.displayed_icons[y][x].type):
							symbol_trigger = false
							break
						elif reels.displayed_icons[y][x].type != "empty":
							symbol_types.push_back(reels.displayed_icons[y][x].type)
			"green_pepper", "green_pepper_essence":
				symbol_trigger = false
				var symbol_counts = {}
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if not symbol_counts.has(reels.displayed_icons[y][x].type) and reels.displayed_icons[y][x].type != "empty":
							symbol_counts[reels.displayed_icons[y][x].type] = 1
						elif reels.displayed_icons[y][x].type != "empty":
							symbol_counts[reels.displayed_icons[y][x].type] += 1
							if symbol_counts[reels.displayed_icons[y][x].type] >= values[1]:
								symbol_trigger = true
								break
			"blue_pepper", "blue_pepper_essence":
				symbol_trigger = false
				var empty_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == "empty":
							empty_count += 1
							if empty_count >= values[1]:
								symbol_trigger = true
								break
			"yellow_pepper", "yellow_pepper_essence":
				symbol_trigger = true
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == "empty":
								symbol_trigger = false
								break
			"purple_pepper", "purple_pepper_essence":
				reels.make_clumps()
				symbol_trigger = false
				for c in reels.clumps:
					var symbols = {}
					if c.size() >= values[1]:
						for i in c:
							if symbols.has(i.type):
								symbols[i.type].push_back(i)
							else:
								symbols[i.type] = [i]
					for s in symbols.keys():
						if symbols[s].size() >= values[1]:
							symbol_trigger = true
							break
					if symbol_trigger:
						break
			"rusty_gear":
				reels.make_clumps()
				symbol_trigger = false
				affected_symbols.clear()
				var symbols = {}
				for c in reels.clumps:
					if c.size() >= values[0]:
						for i in c:
							if symbols.has(i.type):
								symbols[i.type].push_back(i)
							else:
								symbols[i.type] = [i]
				for s in symbols.keys():
					if symbols[s].size() >= values[0]:
						symbol_trigger = true
						for a in range(symbols[s].size()):
							affected_symbols.push_back(reels.displayed_icons[symbols[s][a].y][symbols[s][a].x])
							affected_symbol_positions.push_back(Vector2(affected_symbols[affected_symbols.size() - 1].grid_position.x, affected_symbols[affected_symbols.size() - 1].grid_position.y))
				if prev_symbol_trigger != symbol_trigger or prev_affected_symbols_positions != affected_symbol_positions:
					for x in range(reels.reel_width):
						for y in range(reels.reel_height):
							for i in range(item_count):
								for v in range(reels.displayed_icons[y][x].value_multiplier_arr.size()):
									if reels.displayed_icons[y][x].value_multiplier_arr[v].source == self:
										reels.displayed_icons[y][x].value_multiplier_arr.remove(v)
										break
								for a in reels.displayed_icons[y][x].prev_data:
									for p in range(a.value_multiplier_arr.size()):
										if a.value_multiplier_arr[p].source == self:
											a.value_multiplier_arr.remove(p)
											break
			"cyan_pepper", "cyan_pepper_essence":
				symbol_trigger = true
				var symbol_counts = {}
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if not symbol_counts.has(reels.displayed_icons[y][x].type) and reels.displayed_icons[y][x].type != "empty":
							symbol_counts[reels.displayed_icons[y][x].type] = 1
						elif reels.displayed_icons[y][x].type != "empty":
							symbol_counts[reels.displayed_icons[y][x].type] += 1
							if symbol_counts[reels.displayed_icons[y][x].type] > values[1] - 1:
								symbol_trigger = false
								break
			"lemon_essence":
				symbol_trigger = false
				var empty_count = 0
				var empty = $"/root/Main".get_appended_steam_id("empty", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == empty:
							empty_count += 1
							if empty_count >= values[0]:
								symbol_trigger = true
								break
			"cleaning_rag_essence":
				symbol_trigger = false
				var gem_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["gem"].has(reels.displayed_icons[y][x].type):
							gem_count += 1
							if gem_count >= values[0]:
								symbol_trigger = true
								break
			"fruit_basket_essence":
				symbol_trigger = false
				var fruit_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["fruit"].has(reels.displayed_icons[y][x].type):
							fruit_count += 1
							if fruit_count >= values[0]:
								symbol_trigger = true
								break
			"goldilocks_essence":
				symbol_trigger = false
				var bear_count = 0
				var bear = $"/root/Main".get_appended_steam_id("bear", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == bear:
							bear_count += 1
							if bear_count >= values[0]:
								symbol_trigger = true
								break
			"copycat_essence":
				reels.make_clumps()
				symbol_trigger = false
				var cat = $"/root/Main".get_appended_steam_id("cat", "symbol")
				for c in reels.clumps:
					if c.size() >= values[0] and c[0].type == cat:
						symbol_trigger = true
						break
			"undertaker_essence":
				symbol_trigger = false
				var spirit_count = 0
				var spirit = $"/root/Main".get_appended_steam_id("spirit", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == spirit:
							spirit_count += 1
							if spirit_count >= values[0]:
								symbol_trigger = true
								break
			"triple_coins_essence":
				symbol_trigger = false
				var coin_count = 0
				var coin = $"/root/Main".get_appended_steam_id("coin", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == coin:
							coin_count += 1
							if coin_count >= values[0]:
								symbol_trigger = true
								break
			"nori_the_rabbit_essence":
				symbol_trigger = false
				var nori_count = 0
				var rabbit = $"/root/Main".get_appended_steam_id("rabbit", "symbol")
				var rabbit_fluff = $"/root/Main".get_appended_steam_id("rabbit_fluff", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == rabbit or reels.displayed_icons[y][x].type == rabbit_fluff:
							nori_count += 1
							if nori_count >= values[0]:
								symbol_trigger = true
								break
			"lucky_cat_essence", "black_cat_essence":
				symbol_trigger = false
				var cat_count = 0
				var cat = $"/root/Main".get_appended_steam_id("cat", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == cat:
							cat_count += 1
							if cat_count >= values[0]:
								symbol_trigger = true
								break
			"rusty_gear_essence":
				if not destroyed:
					reels.make_clumps()
					symbol_trigger = false
					affected_symbols.clear()
					var symbols = {}
					for c in reels.clumps:
						if c.size() >= values[0]:
							for i in c:
								if symbols.has(i.type):
									symbols[i.type].push_back(i)
								else:
									symbols[i.type] = [i]
					for s in symbols.keys():
						if symbols[s].size() >= values[0]:
							for i in symbols[s]:
								reels.displayed_icons[i.y][i.x].permanent_multiplier *= values[1]
								reels.displayed_icons[i.y][i.x].update_value_text()
							symbol_trigger = true
			"ritual_candle_essence":
				symbol_trigger = false
				var hex_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["fossillikes"].has(reels.displayed_icons[y][x].type):
							hex_count += 1
				if hex_count >= values[0]:
					symbol_trigger = true
			"holy_water_essence":
				symbol_trigger = false
				var hex_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["hex"].has(reels.displayed_icons[y][x].type):
							hex_count += 1
				if hex_count >= values[0]:
					symbol_trigger = true
			"blue_suits_essence":
				symbol_trigger = false
				var count = 0
				var clubs = $"/root/Main".get_appended_steam_id("clubs", "symbol")
				var spades = $"/root/Main".get_appended_steam_id("spades", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == clubs or reels.displayed_icons[y][x].type == spades:
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"red_suits_essence":
				symbol_trigger = false
				var count = 0
				var hearts = $"/root/Main".get_appended_steam_id("hearts", "symbol")
				var diamonds = $"/root/Main".get_appended_steam_id("diamonds", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == diamonds or reels.displayed_icons[y][x].type == hearts:
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"birdhouse_essence":
				reels.making_group_clumps = {"groups": ["bird"]}
				reels.make_clumps()
				symbol_trigger = false
				for c in reels.group_clumps:
					if c.size() >= values[0] and $"/root/Main".group_database["symbols"]["bird"].has(c[0].type):
						symbol_trigger = true
						break
				reels.making_group_clumps = null
			"anthropology_degree_essence":
				symbol_trigger = false
				var count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["human"].has(reels.displayed_icons[y][x].type):
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"cursed_katana_essence":
				symbol_trigger = false
				var count = 0
				var ninja = $"/root/Main".get_appended_steam_id("ninja", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == ninja:
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"fifth_ace_essence":
				symbol_trigger = false
				var suit_count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["suit"].has(reels.displayed_icons[y][x].type):
							suit_count += 1
				if suit_count >= values[0]:
					symbol_trigger = true
			"ricky_the_banana_essence":
				symbol_trigger = false
				var count = 0
				var banana = $"/root/Main".get_appended_steam_id("banana", "symbol")
				var banana_peel = $"/root/Main".get_appended_steam_id("banana_peel", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == banana or reels.displayed_icons[y][x].type == banana_peel:
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"kyle_the_kernite_essence":
				symbol_trigger = false
				var count = 0
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if $"/root/Main".group_database["symbols"]["kyle"].has(reels.displayed_icons[y][x].type):
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"lefty_the_rabbit_essence":
				symbol_trigger = false
				var count = 0
				var rabbit = $"/root/Main".get_appended_steam_id("rabbit", "symbol")
				var rabbit_fluff = $"/root/Main".get_appended_steam_id("rabbit_fluff", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == rabbit or reels.displayed_icons[y][x].type == rabbit_fluff:
							count += 1
							if count >= values[0]:
								symbol_trigger = true
								break
			"quigley_the_wolf_essence":
				reels.making_group_clumps = {"types": ["dog", "wolf"]}
				reels.make_clumps()
				symbol_trigger = false
				for c in reels.group_clumps:
					if c.size() >= values[0] and (c[0].type == "dog" or c[0].type == "wolf"):
						symbol_trigger = true
						break
				reels.making_group_clumps = null
			"swapping_device_essence":
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						for i in range(item_count):
							for v in range(reels.displayed_icons[y][x].value_multiplier_arr.size()):
								if reels.displayed_icons[y][x].value_multiplier_arr[v].source == self:
									symbol_trigger = false
									break
							for a in reels.displayed_icons[y][x].prev_data:
								for p in range(a.value_multiplier_arr.size()):
									if a.value_multiplier_arr[p].source == self:
										symbol_trigger = false
										break
			"turtle_and_rabbit":
				symbol_trigger = false
				var turtle_trigger = false
				var rabbit_trigger = false
				var turtle = $"/root/Main".get_appended_steam_id("turtle", "symbol")
				var rabbit = $"/root/Main".get_appended_steam_id("rabbit", "symbol")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == turtle and x == reels.reel_width - 1:
							turtle_trigger = true
						elif reels.displayed_icons[y][x].type == rabbit and x == 0:
							rabbit_trigger = true
						if turtle_trigger and rabbit_trigger:
							symbol_trigger = true
							break
			_:
				if not modded:
					value_reset = true
		var mod_found = false
		for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.items:
			if type == m.type and typeof(m.symbol_triggers) == TYPE_ARRAY:
				var a_symbols = []
				var total_triggers = 0
				mod_found = true
				for t in m.symbol_triggers:
					var vars = {}
					symbol_trigger = false
					match t.type:
						"displayed":
							if t.has("types"):
								for tp in t.types:
									vars[tp] = []
								for x in range(reels.reel_width):
									for y in range(reels.reel_height):
										for v in vars.keys():
											if reels.displayed_icons[y][x].type == v:
												vars[v].push_back(reels.displayed_icons[y][x])
							elif t.has("groups"):
								for gp in t.groups:
									vars[gp] = []
								for x in range(reels.reel_width):
									for y in range(reels.reel_height):
										for v in vars.keys():
											if reels.displayed_icons[y][x].groups.has(v):
												vars[v].push_back(reels.displayed_icons[y][x])
							elif t.has("any_types") and t.any_types:
								for x in range(reels.reel_width):
									for y in range(reels.reel_height):
										if vars.has(reels.displayed_icons[y][x].type):
											vars[reels.displayed_icons[y][x].type] += reels.displayed_icons[y][x]
										elif not t.has("ignored_types") or (t.has("ignored_types") and not t.ignored_types.has(reels.displayed_icons[y][x].type)):
											vars[reels.displayed_icons[y][x].type] = [reels.displayed_icons[y][x]]
						"adjacent":
							if t.has("types"):
								vars["types"] = []
								reels.making_group_clumps = {"types": t.types}
								reels.make_clumps()
								for c in reels.group_clumps:
									if t.types.has(c[0].type):
										vars["types"].push_back(c)
							elif t.has("groups"):
								vars["groups"] = []
								reels.making_group_clumps = {"groups": t.groups}
								reels.make_clumps()
								for c in reels.group_clumps:
									for g in t.groups:
										if $"/root/Main".group_database["symbols"][g].has(c[0].type):
											vars["groups"].push_back(c)
											break
							elif t.has("any_types") and t.any_types:
								reels.make_clumps()
								for c in reels.clumps:
									if vars.has(c[0].type):
										vars[c[0].type].push_back(c)
									else:
										vars[c[0].type] = [c]
									if symbol_trigger:
										break
							reels.making_group_clumps = null
					if t.has("sum_of_symbols") and t.sum_of_symbols and t.type == "displayed":
						var sum = 0
						for v in vars.keys():
							sum += vars[v].size()
							a_symbols += vars[v]
						if not t.has("conditional"):
							if parse_conditional(sum, t.value, null):
								total_triggers += 1
						else:
							if parse_conditional(sum, t.value, t.conditional):
								total_triggers += 1
					else:
						for v in vars.keys():
							var triggered = false
							if typeof(vars[v][0]) == TYPE_ARRAY:
								for clump in vars[v]:
									if not t.has("conditional"):
										if parse_conditional(clump.size(), t.value, null):
											if not triggered:
												total_triggers += 1
												triggered = true
											for c in clump:
												a_symbols += c
									else:
										if parse_conditional(clump.size(), t.value, t.conditional):
											if not triggered:
												total_triggers += 1
												triggered = true
											for c in clump:
												a_symbols += c
							else:
								if not t.has("conditional"):
									if parse_conditional(vars[v].size(), t.value, null):
										if not triggered:
											total_triggers += 1
											triggered = true
										a_symbols += vars[v]
								else:
									if parse_conditional(vars[v].size(), t.value, t.conditional):
										if not triggered:
											total_triggers += 1
											triggered = true
										a_symbols += vars[v]
				if (total_triggers == m.symbol_triggers.size() and (m.symbol_triggers.has("and") or not m.symbol_triggers.has("or"))) or (total_triggers > 0 and m.symbol_triggers.has("or")):
					symbol_trigger = true
				var affected_symbols_effects = []
				for c in c_effects:
					var correct_comp = false
					for comp in c.comparisons:
						if typeof(comp.a) == TYPE_STRING and comp.a == "symbol_trigger" and comp.b:
							correct_comp = true
							break
					if c.has("affected_symbols") and c.has("comparisons") and correct_comp and symbol_trigger:
						affected_symbols_effects.push_back(c)
				if symbol_trigger:
					affected_symbols.clear()
					for a in range(a_symbols.size()):
						affected_symbols.push_back(reels.displayed_icons[a_symbols[a].grid_position.y][a_symbols[a].grid_position.x])
						affected_symbol_positions.push_back(Vector2(affected_symbols[affected_symbols.size() - 1].grid_position.x, affected_symbols[affected_symbols.size() - 1].grid_position.y))
					if prev_symbol_trigger != symbol_trigger or prev_affected_symbols_positions != affected_symbol_positions:
						for x in range(reels.reel_width):
							for y in range(reels.reel_height):
								for i in range(item_count):
									for k in affected_symbols_effects:
										if k.has("value_to_change"):
											match k.value_to_change:
												"value_multiplier":
													for v in range(reels.displayed_icons[y][x].value_multiplier_arr.size()):
														if reels.displayed_icons[y][x].value_multiplier_arr[v].source == self:
															reels.displayed_icons[y][x].value_multiplier_arr.remove(v)
															break
													for a in reels.displayed_icons[y][x].prev_data:
														for p in range(a.value_multiplier_arr.size()):
															if a.value_multiplier_arr[p].source == self:
																a.value_multiplier_arr.remove(p)
																break
												"value_bonus":
													for v in range(reels.displayed_icons[y][x].value_bonus_arr.size()):
														if reels.displayed_icons[y][x].value_bonus_arr[v].source == self:
															reels.displayed_icons[y][x].value_bonus_arr.remove(v)
															break
													for a in reels.displayed_icons[y][x].prev_data:
														for p in range(a.value_bonus_arr.size()):
															if a.value_bonus_arr[p].source == self:
																a.value_bonus_arr.remove(p)
																break
		if not mod_found:
			value_reset = true
		if prev_symbol_trigger != symbol_trigger or prev_affected_symbols_positions != affected_symbol_positions:
			if value_reset:
				value = 0
				reroll_value = 0
				removal_value = 0
			for effect in erased_effects:
				for comp in effect.comparisons:
					if typeof(comp.a) == TYPE_STRING and comp.a == "symbol_trigger":
						erased_effects.erase(effect)
			add_conditional_effects()
		
func add_to_cond_effects(effect):
	if not destroyed or destroy_counters > 0 or type == "frying_pan_essence" or type == "tax_evasion_essence" or type == "lefty_the_rabbit_essence" or type == "quigley_the_wolf_essence" or type == "oil_can_essence":
		if not effect.has("from_item"):
			effect["from_item"] = type
			
		if not effect.has("source"):
			effect["source"] = self
		
		if effect.has("target_self") and effect.target_self:
			effect.erase("target_self")
			effect["target"] = self
		
		if effect.has("diff") and (typeof(effect.diff) == TYPE_INT or typeof(effect.diff) == TYPE_REAL) and item_count > 1 and no_item_multi_diffs.find(type) == -1 and effect.diff > 0 and effect.value_to_change != "bonus_value_multipliers" and effect.value_to_change != "bonus_values":
			if effect.value_to_change != "value_multiplier" and effect.value_to_change != "saved_value":
				effect.diff *= item_count
			else:
				effect.diff = pow(effect.diff, item_count)
			
		if effect.comparisons.size() == 0:
			effect.comparisons.push_back({"a": "dummy", "b": true})
		
		if effect.has("push_front") or (effect.has("value_to_change") and effect.value_to_change == "indestructible"):
			get_parent().cond_effects_to_add.push_front(effect)
		else:
			get_parent().cond_effects_to_add.push_back(effect)

func add_effect_to_symbol(y, x, effect):
	if not effect.has("from_item"):
		effect["from_item"] = type
	reels.displayed_icons[y][x].add_effect(effect)

func get_cleaned_effect(effect):
	var c = effect.duplicate(true)
	
	var c_tbe = []
	var comp_num = 0
	for comparison in c.comparisons:
		if comparison.has("rand") or comparison.has("dynamic_a_target") or comparison.has("dynamic_b_target"):
			c_tbe.push_back(comparison)
		for k in comparison.keys():
			if typeof(comparison[k]) == TYPE_DICTIONARY and (comparison[k].has("var_math") or comparison[k].has("starting_value")):
				if str(comparison[k]).find("rand_num:") != -1:
					c_tbe.push_back(comparison)
				if c.has("giver"):
					c.comparisons[comp_num][k] = c.giver.parse_var_math(comparison[k], c.giver, c)
				elif c.has("from_item"):
					c.comparisons[comp_num][k] = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(comparison[k], get_parent().items[get_parent().item_types.find(c.from_item)], c)
				else:
					c.comparisons[comp_num][k] = parse_var_math(comparison[k], self, c)
		comp_num += 1
	for comparison in c_tbe:
		c.comparisons.erase(comparison)
	if c.has("dynamic_diff_target"):
		c.erase("dynamic_diff_target") 
		c.erase("dynamic_diff_key")
	if c.has("rarity_mod") or c.has("forced_rarities"):
		c.erase("target")
	if c.has("emails_to_add"):
		c.erase("emails_to_add")
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY and (c.diff.has("var_math") or c.diff.has("starting_value")):
		if c.has("giver"):
			c.diff = c.giver.parse_var_math(c.diff, c.giver, c)
		elif c.has("from_item"):
			c.diff = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(c.diff, get_parent().items[get_parent().item_types.find(c.from_item)], c)
		else:
			c.diff = parse_var_math(c.diff, self, c)
		if str(effect.diff).find("rand_num:") != -1:
			c.erase("diff")
	return c

func add_effect(c):
	var can_add = true
	
	if not c.has("comparisons"):
		c["comparisons"] = []
	
	var erase_rand_eff = false
	
	if c.has("required_items"):
		for i in c.required_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not get_parent().item_types.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if not get_parent().item_types.has(with_id):
					can_add = false
					break
			elif not get_parent().item_types.has(i):
				can_add = false
			if not can_add:
				break
	if c.has("required_disabled_items"):
		for i in c.required_disabled_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not get_parent().item_types.has(m_i + "_d"):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if not get_parent().item_types.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]] + "_d"):
					can_add = false
					break
			elif not get_parent().item_types.has(i + "_d"):
				can_add = false
				break
			if not can_add:
				break
	if c.has("required_destroyed_items"):
		for i in c.required_destroyed_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not get_parent().destroyed_item_types.has(m_i) and not get_parent().items_destroyed_this_spin.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if not get_parent().destroyed_item_types.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]) and not get_parent().items_destroyed_this_spin.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]):
					can_add = false
					break
			elif not get_parent().destroyed_item_types.has(i) and not get_parent().items_destroyed_this_spin.has(i):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_items"):
		for i in c.forbidden_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if get_parent().item_types.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if get_parent().item_types.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]):
					can_add = false
					break
			elif get_parent().item_types.has(i):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_disabled_items"):
		for i in c.forbidden_disabled_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if get_parent().item_types.has(m_i + "_d"):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if get_parent().item_types.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]] + "_d"):
					can_add = false
					break
			elif get_parent().item_types.has(i + "_d"):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_destroyed_items"):
		for i in c.forbidden_destroyed_items:
			var with_id
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if get_parent().destroyed_item_types.has(m_i) or get_parent().items_destroyed_this_spin.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i) and not $"/root/Main".is_mod_disabled(with_id):
				if get_parent().destroyed_item_types.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]) or get_parent().items_destroyed_this_spin.has(i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]):
					can_add = false
					break
			elif get_parent().destroyed_item_types.has(i) or get_parent().items_destroyed_this_spin.has(i):
				can_add = false
				break
			if not can_add:
				break
	
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY:
		if (c.diff.has("var_math") or c.diff.has("starting_value")):
			if str(c.diff).find("rand_num:") != -1:
				erase_rand_eff = true
			if c.has("giver"):
				c.diff = c.giver.parse_var_math(c.diff, c.giver, c)
			elif c.has("from_item"):
				c.diff = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(c.diff, get_parent().items[get_parent().item_types.find(c.from_item)], c)
			else:
				c.diff = parse_var_math(c.diff, null, c)
		elif c.diff.has("counted_symbols"):
			var with_id = c.diff.counted_symbols
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(c.diff.counted_symbols):
				if not $"/root/Main".mod_data.symbols[$"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols])]].art_replacement:
					with_id = $"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols])]
				else:
					with_id = c.diff.counted_symbols
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = c.diff.counted_symbols
			reels.count_symbols(true)
			c.diff = reels.counted_symbols[with_id]
		elif c.diff.has("values"):
			c.diff = values[c.diff.values]
	if c.has("diff") and (typeof(c.diff) == TYPE_INT or typeof(c.diff) == TYPE_REAL) and item_count > 1 and no_item_multi_diffs.find(type) == -1 and c.diff > 0 and c.value_to_change != "bonus_value_multipliers" and c.value_to_change != "bonus_values":
		if c.value_to_change != "value_multiplier" and c.value_to_change != "saved_value" and (not c.has("target") or (c.has("target") and c.target != $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"] and c.target != $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["items"])):
			c.diff *= item_count
		else:
			c.diff = pow(c.diff, item_count)
	if c.has("items_to_add"):
		var temp_diff = c.items_to_add.duplicate(true)
		for i in range(item_count - 1):
			c.items_to_add += temp_diff
	if c.has("tiles_to_add"):
		var temp_diff = c.tiles_to_add.duplicate(true)
		for i in range(item_count - 1):
			c.tiles_to_add += temp_diff
	var comp_num = 0
	for comp in c.comparisons:
		if comp.has("a") and comp.has("b") and typeof(comp.a) == TYPE_STRING and comp.a == "type" and typeof(comp.b) == TYPE_STRING and comp.b == "dynamic_item":
			for fp in $"/root/Main/Landlord".fine_print:
				if tmp_fp_num == fp.num:
					comp.b = fp.dynamic_icon
					break
		if str(c.comparisons[comp_num]).find("rand_num:") != -1:
			erase_rand_eff = true
		for k in comp.keys():
			if typeof(comp[k]) == TYPE_DICTIONARY:
				if comp[k].has("values"):
					c.comparisons[comp_num][k] = values[comp[k].values]
				elif comp[k].has("counted_symbols"):
					var with_id = comp[k].counted_symbols
					if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comp[k].counted_symbols):
						if not $"/root/Main".mod_data.symbols[$"/root/Main".append_steam_id(comp[k].counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comp[k].counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comp[k].counted_symbols])]].art_replacement:
							with_id = $"/root/Main".append_steam_id(comp[k].counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comp[k].counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comp[k].counted_symbols])]
						else:
							with_id = comp[k].counted_symbols
						if $"/root/Main".is_mod_disabled(with_id):
							with_id = comp[k].counted_symbols
					reels.count_symbols(true)
					c.comparisons[comp_num][k] = reels.counted_symbols[with_id]
				elif comp[k].has("counted_items"):
					var with_id = comp[k].counted_items
					if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(comp[k].counted_items):
						with_id = $"/root/Main".append_steam_id(comp[k].counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_items])]
						if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
							with_id = comp[k].counted_items
					if get_parent().item_types.has(with_id):
						c.comparisons[comp_num][k] = get_parent().items[get_parent().item_types.find(with_id)].item_count
				elif comp[k].has("counted_destroyed_items"):
					var with_id = comp[k].counted_destroyed_items
					if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(comp[k].counted_destroyed_items):
						with_id = $"/root/Main".append_steam_id(comp[k].counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_destroyed_items])]
						if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
							with_id = comp[k].counted_destroyed_items
					c.comparisons[comp_num][k] = get_parent().destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
				if str(c.comparisons[comp_num]).find("rand_num:") != -1:
					erase_rand_eff = true
				if c.has("giver"):
					c.comparisons[comp_num][k] = c.giver.parse_var_math(comp[k], c.giver, c)
				elif c.has("from_item"):
					c.comparisons[comp_num][k] = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(comp[k], get_parent().items[get_parent().item_types.find(c.from_item)], c)
				elif comp[k].has("destroyed_symbol_type_count"):
					if $"/root/Main".existing_symbols.has(c.comparisons[comp_num]["a"].destroyed_symbol_type_count):
						c.comparisons[comp_num]["a"].destroyed_symbol_type_count = $"/root/Main".existing_symbols[c.comparisons[comp_num]["a"].destroyed_symbol_type_count]
				elif comp[k].has("removed_symbol_type_count"):
					if $"/root/Main".existing_symbols.has(c.comparisons[comp_num]["a"].removed_symbol_type_count):
						c.comparisons[comp_num]["a"].removed_symbol_type_count = $"/root/Main".existing_symbols[c.comparisons[comp_num]["a"].removed_symbol_type_count]
				elif comp[k].has("destroyed_symbol_group_count"):
					var n = 0
					for g in $"/root/Main".group_database.symbols[comp[k].destroyed_symbol_group_count]:
						n += $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(g)
					c.comparisons[comp_num]["a"] = n
				elif comp[k].has("removed_symbol_group_count"):
					var n = 0
					for g in $"/root/Main".group_database.symbols[comp[k].removed_symbol_group_count]:
						n += $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(g)
					c.comparisons[comp_num]["a"] = n
				elif comp[k].has("symbols_in_inventory"):
					var num = 0
					if comp[k].symbols_in_inventory.has("type"):
						if $"/root/Main".existing_symbols.has(comp[k].symbols_in_inventory.type):
							comp[k].symbols_in_inventory.type = $"/root/Main".existing_symbols[comp[k].symbols_in_inventory.type]
						for r in $"/root/Main/Reels".reels:
							for t in r.icon_types:
								if t == comp[k].symbols_in_inventory.type:
									num += 1
					elif comp[k].symbols_in_inventory.has("groups"):
						for r in $"/root/Main/Reels".reels:
							for t in r.icon_types:
								if $"/root/Main".group_database.symbols[comp[k].symbols_in_inventory.groups].has(t):
									num += 1
					c.comparisons[comp_num]["a"] = num
				elif comp[k].has("counted_adjacent_symbols"):
					var num = 0
					if comp[k].counted_adjacent_symbols.has("type"):
						var t = comp[k].counted_adjacent_symbols.type
						var with_id = t
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
							with_id = $"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t])]
							if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = t
						reels.making_group_clumps = {"types": [with_id]}
						reels.make_clumps()
						for c in reels.group_clumps:
							if c.size() >= num and with_id == c[0].type:
								num = c.size()
								for s in c:
									affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
						reels.making_group_clumps = null
					elif comp[k].counted_adjacent_symbols.has("groups"):
						reels.making_group_clumps = {"groups": [comp[k].counted_adjacent_symbols.groups]}
						reels.make_clumps()
						for c in reels.group_clumps:
							if c.size() >= num and $"/root/Main".group_database["symbols"][comp[k].counted_adjacent_symbols.groups].has(c[0].type):
								num = c.size()
								for s in c:
									affected_symbols.push_back(reels.displayed_icons[s.y][s.x])
						reels.making_group_clumps = null
					c.comparisons[comp_num]["a"] = num
				else:
					c.comparisons[comp_num][k] = parse_var_math(comp[k], null, c)
			elif typeof(comp[k]) == TYPE_STRING and k == "a":
				match comp[k]:
					"fighting_boss":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight
					"coins":
						c.comparisons[comp_num]["a"] = $"/root/Main/Coins".coins
					"reroll_tokens":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens
					"removal_tokens":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens
					"essence_tokens":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".essence_tokens
					"rent_due":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[0]
					"spins_left":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1]
					"hotfix_num":
						c.comparisons[comp_num]["a"] = $"/root/Main".hotfix_num
					"symbols_destroyed_this_spin":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
					"items_destroyed_this_spin":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
					"symbols_to_choose_from":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
					"items_to_choose_from":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
					"non_singular_symbols":
						c.comparisons[comp_num]["a"] = $"/root/Main/Reels".get_non_singular_symbols()
					"extra_symbol_choices":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
					"extra_item_choices":
						c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices

		if typeof(comp.a) == TYPE_STRING and comp.a == "type" and $"/root/Main".mod_data.items.has(comp.b) and not $"/root/Main".mod_data.items[comp.b].art_replacement:
			c.comparisons[comp_num].b = $"/root/Main".append_steam_id(comp.b, $"/root/Main".mod_data.items[comp.b].author_id)
		comp_num += 1
	
	var check_it = false
	
	var cleaned_c = get_cleaned_effect(c)
	
	var effect_arr = erased_effects.duplicate(true)
	for eff in c_effects:
		effect_arr.push_back(get_cleaned_effect(eff))
	
	if not cleaned_c.has("while"):
		for e in effect_arr:
			if cleaned_c.hash() == get_cleaned_effect(e).hash():
				can_add = false
				break
	
	if c.has("rarity_mod") or c.has("forced_rarities"):
		for e in c_effects:
			if e.hash() == cleaned_c.hash():
				can_add = false
				break
		for e in erased_effects:
			if e.hash() == cleaned_c.hash():
				can_add = false
				break

	if erase_rand_eff and not erased_effects.has(cleaned_c):
		erased_effects.push_back(cleaned_c)
	
	if c.has("last") and c.last and not reels.checking_last_effects:
		can_add = false
	
	if can_add:
		if c.has("effect_type") and c.effect_type == "counted_adjacent_symbols":
			for s in affected_symbols:
				add_effect_to_symbol(s.grid_position.y, s.grid_position.x, c)
		elif c.has("push_front"):
			c_effects.push_front(c)
		else:
			c_effects.push_back(c)

func update_value_text():
	var color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_reminder_up_text"] + ">"
	var str_value = saved_value
	if not modded or (modded and inherit_effects):
		var t = type.substr(0, type.find("_STEAM_ID_"))
		match t:
			"void_portal":
				color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_reminder_down_text"] + ">"
			"compost_heap", "frozen_pizza", "telescope", "protractor", "lefty_the_rabbit", "treasure_map", "blue_suits", "red_suits", "flush_essence", "coin_on_a_string_essence", "egg_carton_essence", "lucky_dice_essence", "symbol_bomb_small_essence", "symbol_bomb_big_essence", "symbol_bomb_very_big_essence", "mining_pick_essence", "lockpick_essence", "shrine_essence", "conveyor_belt_essence", "time_machine_essence", "pool_ball_essence", "horseshoe_essence", "bowling_ball_essence", "four_leaf_clover_essence", "lucky_seven_essence", "frozen_pizza_essence", "barrel_o_dwarves_essence", "happy_hour_essence", "telescope_essence", "protractor_essence", "checkered_flag_essence", "shattered_mirror_essence", "lunchbox_essence", "dishwasher_essence", "cardboard_box_essence", "treasure_map_essence", "lint_roller_essence", "fish_bowl_essence", "adoption_papers_essence", "oil_can_essence", "swapping_device_essence", "credit_card", "symbol_bomb_quantum_essence", "void_party_essence", "mobius_strip_essence", "oil_can":
				color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_reminder_down_text"] + ">"
				str_value = values[0] - saved_value
			"shattered_mirror", "cardboard_box", "dishwasher", "piggy_bank_essence", "lucky_carrot_essence", "golden_carrot_essence", "booster_pack_essence":
				color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_reminder_down_text"] + ">"
				str_value = values[1] - saved_value
			"reroll_essence":
				color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_reminder_down_text"] + ">"
				str_value = values[2] - saved_value
			"void_party", "mobius_strip":
				str_value = 0
	for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.items:
		if type == m.type:
			if typeof(m.value_text) == TYPE_DICTIONARY and m.value_text.has("color"):
				if $"/root/Main/Options Sprite/Options".colors3.has(m.value_text.color):
					color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3[m.value_text.color] + ">"
				else:
					color_string = "<color_" + m.value_text.color + ">"
				if m.value_text.has("value") and typeof(m.value_text.value) == TYPE_DICTIONARY and (m.value_text.value.has("var_math") or m.value_text.value.has("starting_value")):
					str_value = parse_var_math(m.value_text.value, self, null)
				else:
					str_value = m.value_text.value
	if str_value > 0:
		get_child(1).raw_string = color_string + get_child(1).parse_num_str(str(str_value)) + "<end>"
	else:
		get_child(1).raw_string = ""
	if item_count > 1:
		get_child(0).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_count_text"] + ">" + get_child(0).parse_num_str(str(item_count)) + "<end>"
	else:
		get_child(0).raw_string = ""
	if destroy_counters > 1:
		get_child(2).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_destroy_text"] + ">" + get_child(2).parse_num_str(str(destroy_counters)) + "<end>"
	else:
		get_child(2).raw_string = ""
	
	get_child(0).update()
	get_child(1).update()
	get_child(2).update()
	
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		get_child(0).rect_position.x = round(22 - get_child(0).get_font("font").get_string_size(get_child(0).get_child(0).text).x * 0.125)
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		get_child(0).rect_position.x = round(26 - get_child(0).get_child(0).get_font("font").get_string_size(get_child(0).get_child(0).text).x * 0.125)
		get_child(0).rect_position.y = 18
		get_child(1).rect_position.x = 4
		get_child(1).rect_position.y = 2
		get_child(2).rect_position.x = round(26 - get_child(2).get_child(0).get_font("font").get_string_size(get_child(2).get_child(0).text).x * 0.125)
		get_child(2).rect_position.y = 2
	else:
		get_child(0).rect_position.x = round(22 - get_child(0).get_font("font").get_string_size(get_child(0).text).x)

func check_conditional_effects():
	changed_value = false
	var item_queue = []
	var c_tbe = []
	for c in c_effects:
		var target = self
		var change_value = true
		if ((c.has("last") and c.last and not reels.checking_last_effects) or (reels.checking_last_effects and not c.has("last"))):
			continue
		if c.has("target"):
			target = c["target"]
		if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY:
			if c.diff.has("var_math") or c.diff.has("starting_value"):
				if c.has("giver"):
					c.diff = c.giver.parse_var_math(c.diff, c.giver, c)
				elif c.has("from_item"):
					c.diff = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(c.diff, get_parent().items[get_parent().item_types.find(c.from_item)], c)
				else:
					c.diff = parse_var_math(c.diff, self, c)
		while true:
			var comp_num = 0
			for comparison in c.comparisons:
				var comparison_target = self
				
				if comparison.has("target_self") and c.has("giver"):
					comparison_target = c.giver
				
				for k in comparison.keys():
					if typeof(comparison[k]) == TYPE_DICTIONARY:
						if comparison[k].has("var_math") or comparison[k].has("starting_value"):
							if c.has("giver"):
								c.comparisons[comp_num][k] = c.giver.parse_var_math(comparison[k], c.giver, c)
							elif c.has("from_item"):
								c.comparisons[comp_num][k] = get_parent().items[get_parent().item_types.find(c.from_item)].parse_var_math(comparison[k], get_parent().items[get_parent().item_types.find(c.from_item)], c)
							else:
								c.comparisons[comp_num][k] = parse_var_math(comparison[k], self, c)
				comp_num += 1
				
				if comparison.has("dynamic_a_target"):
					comparison.a = comparison.dynamic_a_key
					comparison_target = comparison.dynamic_a_target
				if comparison.has("dynamic_b_target"):
					comparison.b = comparison.dynamic_b_target[comparison.dynamic_b_key]
					if comparison.has("dynamic_b_multiplier"):
						comparison.b = floor(comparison.dynamic_b_target[comparison.dynamic_b_key] * comparison.dynamic_b_multiplier)
					if comparison.has("dynamic_b_divider"):
						comparison.b = floor(comparison.dynamic_b_target[comparison.dynamic_b_key] / comparison.dynamic_b_divider)
				if typeof(comparison.a) == TYPE_STRING and comparison.a == "values":
					if comparison.has("rand"):
						var the_bool = (comparison_target.values[comparison.value_num] + comparison_target.bonus_values[comparison.value_num]) * comparison_target.bonus_value_multipliers[comparison.value_num] < comparison.b
						if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
							change_value = false
							comparison_target.erased_effects.push_back(get_cleaned_effect(c))
							c_tbe.push_back(c)
							break
					elif comparison.has("greater_than_eq"):
						var the_bool = (comparison_target.values[comparison.value_num] + comparison_target.bonus_values[comparison.value_num]) * comparison_target.bonus_value_multipliers[comparison.value_num] < comparison.b
						if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
							change_value = false
							break
					else:
						var the_bool = (comparison_target.values[comparison.value_num] + comparison_target.bonus_values[comparison.value_num]) * comparison_target.bonus_value_multipliers[comparison.value_num] != comparison.b
						if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
							change_value = false
							break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "multiple_of":
					change_value = false
					break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "type":
					var the_bool = comparison_target.type != comparison.b
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("destroyed_symbol_type_count"):
					var count = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(comparison.a.destroyed_symbol_type_count)
					var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("removed_symbol_type_count"):
					var count = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(comparison.a.removed_symbol_type_count)
					var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("destroyed_symbol_group_count"):
					var count = 0
					var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					for g in $"/root/Main".group_database.symbols[comparison.a.destroyed_symbol_group_count]:
						count += $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(g)
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("removed_symbol_group_count"):
					var count = 0
					var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					for g in $"/root/Main".group_database.symbols[comparison.a.removed_symbol_group_count]:
						count += $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(g)
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "destroyed_symbol_count":
					var the_bool = comparison_target.type != comparison.b
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "non_singular_symbols":
					var stcf = $"/root/Main/Reels".get_non_singular_symbols()
					var the_bool = (stcf <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (stcf < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (stcf >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (stcf > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = stcf != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "symbols_destroyed_this_spin":
					var sdts = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
					var the_bool = (sdts <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (sdts < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (sdts >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (sdts > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = sdts != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "items_destroyed_this_spin":
					var sdts = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
					var the_bool = (sdts <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (sdts < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (sdts >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (sdts > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = sdts != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and comparison.a == "saved_values":
					var id = get_author_id(c, null, comparison, target, null)
					var the_bool = (target.saved_values[id][c.value_num] <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (target.saved_values[id][c.value_num] < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (target.saved_values[id][c.value_num] >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (target.saved_values[id][c.value_num] > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
					var the_bool2 = target.saved_values[id][c.value_num] != comparison.b
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif comparison.has("rand"):
					var the_bool = false
					if typeof(comparison.a) == TYPE_STRING:
						the_bool = comparison_target[comparison.a] < comparison.b
					if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
						change_value = false
						break
				elif comparison.has("less_than"):
					var the_bool = false
					if typeof(comparison.a) == TYPE_STRING:
						the_bool = int(comparison_target[comparison.a]) >= int(comparison.b)
					var the_bool2 = false
					if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
						the_bool2 = int(comparison.a) >= int(comparison.b)
					if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
						change_value = false
						break
					elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
						change_value = false
						break
				elif comparison.has("less_than_eq"):
					var the_bool = false
					if typeof(comparison.a) == TYPE_STRING:
						the_bool = int(comparison_target[comparison.a]) > int(comparison.b)
					var the_bool2 = false
					if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
						the_bool2 = int(comparison.a) > int(comparison.b)
					if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
						change_value = false
						break
					elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
						change_value = false
						break
				elif comparison.has("greater_than"):
					var the_bool = false
					if typeof(comparison.a) == TYPE_STRING:
						the_bool = int(comparison_target[comparison.a]) <= int(comparison.b)
					var the_bool2 = false
					if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
						the_bool2 = int(comparison.a) <= int(comparison.b)
					if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
						change_value = false
						break
					elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
						change_value = false
						break
				elif comparison.has("greater_than_eq"):
					var the_bool = false
					if typeof(comparison.a) == TYPE_STRING:
						the_bool = int(comparison_target[comparison.a]) < int(comparison.b)
					var the_bool2 = false
					if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
						the_bool2 = int(comparison.a) < int(comparison.b)
					if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
						change_value = false
						break
					elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and typeof(comparison_target[comparison.a]) == TYPE_ARRAY:
					var the_bool = not comparison_target[comparison.a].has(comparison.b)
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						change_value = false
						break
				elif typeof(comparison.a) == TYPE_STRING and (comparison_target[comparison.a] != comparison.b or (not comparison_target[comparison.a] != comparison.b and comparison.has("not") and comparison["not"])):
					change_value = false
					break
				elif (typeof(comparison.a) == TYPE_REAL or typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_BOOL) and (comparison.a != comparison.b or (not comparison.a != comparison.b and comparison.has("not") and comparison["not"])):
					change_value = false
					break
			if change_value:
				changed_value = true
				
				if c.has("tiles_to_add"):
					var destroyed_symbols = []
					var symbol_arr = []
					if c.tiles_to_add.has("prev_destroyed_symbol"):
						destroyed_symbols = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.duplicate(true)
						var d_tbe = []
						for d in destroyed_symbols:
							if d == "time_capsule" or $"/root/Main".group_database["symbols"]["time_capsule_effects"].has(d) or $"/root/Main".group_database["symbols"]["time_capsule_effects"].has(d) or (not reels.can_add_highlander() and d == "highlander"):
								d_tbe.push_back(d)
						for d in d_tbe:
							destroyed_symbols.erase(d)
					for t in c.tiles_to_add:
						if typeof(t) == TYPE_STRING and t == "prev_destroyed_symbol":
							if destroyed_symbols.size() > 0:
								symbol_arr.push_back(destroyed_symbols[floor(rand_range(0, destroyed_symbols.size()))])
						elif t.has("group"):
							randomize()
							var group_db = $"/root/Main".group_database["symbols"][t.group]
							reels.symbol_queue.push_back(group_db[floor(rand_range(0, group_db.size()))])
						else:
							var did_it = false
							if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t.type):
								var with_id = $"/root/Main".append_steam_id(t.type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]) + "_PACK_" + $"/root/Main".mod_pack_nums[t.type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]]
								if not $"/root/Main".mod_data.symbols[with_id].art_replacement and not $"/root/Main".is_mod_disabled(with_id):
									reels.symbol_queue.push_back(with_id)
									did_it = true
							if not did_it:
								reels.symbol_queue.push_back($"/root/Main".existing_symbols[t.type])
					for s in symbol_arr:
						reels.symbol_queue.push_back($"/root/Main".existing_symbols[s])
				if c.has("items_to_add") and not item_adding_effects.has(get_cleaned_effect(c).hash()):
					item_adding_effects.push_back(get_cleaned_effect(c).hash())
					for i in c.items_to_add:
						if i.has("rarity"):
							var item_pool = $"/root/Main/".rarity_database["items"][i.rarity].duplicate(true)
							for z in $"/root/Main/Items".items:
								item_pool.erase(z.type)
							randomize()
							if item_pool.size() > 0:
								item_queue.push_back(item_pool[floor(rand_range(0, item_pool.size()))])
							else:
								item_queue.push_back("pool_ball")
						else:
							item_queue.push_back(i.type)
				if c.has("rarity_mod"):
					if c.rarity_mod.has("symbols"):
						for r in c.rarity_mod.symbols:
							$"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"][r.keys()[0]] *= r[r.keys()[0]]
					if c.rarity_mod.has("items"):
						for r in c.rarity_mod.items:
							$"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["items"][r.keys()[0]] *= r[r.keys()[0]]
				if c.has("forced_rarities"):
					if c.forced_rarities.has("symbols"):
						$"/root/Main/Pop-up Sprite/Pop-up".forced_rarities.push_back({"forced_rarity": c.forced_rarities.symbols, "or_better": c.forced_rarities.or_better})
					if c.forced_rarities.has("items"):
						$"/root/Main/Pop-up Sprite/Pop-up".forced_item_rarities.push_back({"forced_rarity": c.forced_rarities.items, "or_better": c.forced_rarities.or_better})
				if c.has("emails_to_add"):
					for e in c.emails_to_add:
						if typeof(e) == TYPE_DICTIONARY:
							var pack_num = ""
							var steam_id = ""
							for m in $"/root/Main".mod_packs.keys():
								for t in $"/root/Main".mod_packs[m]:
									if t.type.substr(0, t.type.find("_STEAM_ID_")) == e.type and t.mod_type == "email":
										pack_num = "_" + str(m)
										steam_id = str(t.author_id)
										break
								if pack_num != "":
									break
							e["type"] = e.type + "_STEAM_ID_" + steam_id + "_PACK" + pack_num
							if e.has("extra_values"):
								$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], e.extra_values)
							elif e.type == "add_item" and not e.has("extra_values"):
								$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], $"/root/Main/Pop-up Sprite/Pop-up".get_forced_item_rarities($"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from))
							elif e.type == "add_tile" and not e.has("extra_values"):
								$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], $"/root/Main/Pop-up Sprite/Pop-up".get_forced_rarities($"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from))
							else:
								$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], {})
				if c.has("dynamic_diff_target"):
					c.diff = c.dynamic_diff_target[c.dynamic_diff_key]
					if c.has("dynamic_diff_multiplier"):
						c.diff *= c.dynamic_diff_multiplier
					if c.has("dynamic_diff_divider"):
						c.diff = floor(c.diff / c.dynamic_diff_divider)
					if c.has("dynamic_diff_modifier"):
						c.diff += c.dynamic_diff_modifier
					if no_item_multi_diffs.find(type) == -1:
						c.diff *= item_count
						
				if not c.has("value_to_change"):
					pass
				elif c.has("affected_symbols"):
					var uc = false
					if type == "swapping_device_essence" or c.has("unconditional"):
						uc = true
					for n in range(target.affected_symbols.size()):
						var s = reels.displayed_icons[target.affected_symbols[n].grid_position.y][target.affected_symbols[n].grid_position.x]
						var source_num = target.item_count
						if c.value_to_change == "value_multiplier" or c.value_to_change == "value_bonus":
							var vtc = c.value_to_change + "_arr"
							for v in s[vtc]:
								if v.source == target:
									source_num -= 1
							var can_add
							for i in range(source_num):
								can_add = true
								for t in s.prev_data:
									if t.type == s.type:
										for z in t[vtc]:
											if z.source == target:
												can_add = false
												break
									if can_add:
										break
								if can_add:
									s[vtc].push_back({ "source": target, "value": c.diff, "unconditional": uc, "source_eff": c.duplicate(true), "giver": self })
									s.final_value = s.get_value("coin")
									s.non_flat_final_value = s.get_non_flat_value("coin")
									s.update_value_text()
									s.changed_value = true
						elif c.value_to_change == "permanent_multiplier":
							reels.displayed_icons[s.grid_position.y][s.grid_position.x].permanent_multiplier *= c.diff
							reels.displayed_icons[s.grid_position.y][s.grid_position.x].update_value_text()
						elif c.value_to_change == "permanent_bonus":
							reels.displayed_icons[s.grid_position.y][s.grid_position.x].permanent_bonus += c.diff
							reels.displayed_icons[s.grid_position.y][s.grid_position.x].update_value_text()
						else:
							var eff = {"comparisons": [], "value_to_change": c.value_to_change, "from_symbol_trigger": true}
							if c.has("anim"):
								eff["anim"] = c.anim
							if c.has("diff"):
								eff["diff"] = c.diff
							if c.has("sfx_override"):
								eff["sfx_override"] = c.sfx_override
							reels.displayed_icons[s.grid_position.y][s.grid_position.x].add_effect(eff)
				elif c.value_to_change == "rarity_bonuses":
					for k in c.diff.keys():
						target[k] *= c.diff[k]
				elif c.value_to_change == "bonus_values":
					target[c.value_to_change][c.bonus_value_num] += c.diff
				elif c.value_to_change == "value_multiplier" or c.value_to_change == "bonus_value_multipliers" or c.has("multiply"):
					target[c.value_to_change] *= c.diff
				elif c.value_to_change == "forced_add":
					if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1 and not $"/root/Main/Pop-up Sprite/Pop-up".hex_of_emptiness_trigger:
						$"/root/Main/Pop-up Sprite/Pop-up".hex_of_hoarding_trigger = true
				elif c.value_to_change == "forced_skip":
					if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1 and not $"/root/Main/Pop-up Sprite/Pop-up".hex_of_hoarding_trigger:
						$"/root/Main/Pop-up Sprite/Pop-up".hex_of_emptiness_trigger = true
				elif c.value_to_change == "extra_symbol_choices":
					$"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices += c.diff
				elif c.value_to_change == "extra_item_choices":
					$"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices += c.diff
				elif c.value_to_change == "spins_left":
					$"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] += c.diff
				elif c.value_to_change == "saved_values":
					var id = get_author_id(c, null, null, target, null)
					if c.has("overwrite") and c.overwrite:
						target.saved_values[id][c.value_num] = c.diff
					else:
						target.saved_values[id][c.value_num] += c.diff
				elif c.value_to_change == "type":
					if c.has("group"):
						randomize()
						var group_db = $"/root/Main".group_database["symbols"][c.group]
						target.change_type(group_db[floor(rand_range(0, group_db.size()))], true)
					else:
						target.change_type(c.diff, true)
				elif c.value_to_change == "symbols_to_choose_from":
					$"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from_from_mods += c.diff
				elif c.value_to_change == "items_to_choose_from":
					$"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from_from_mods += c.diff
				elif c.value_to_change == "item_count":
					target[c.value_to_change] += c.diff
					if target[c.value_to_change] <= 1:
						target.get_child(0).raw_string = ""
					if c.diff < 0:
						for d in range(-c.diff):
							get_parent().destroyed_item_types.push_back(target.type)
						$"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin -= c.diff
				elif c.value_to_change == "alpha":
					target.modulate.a = c.diff
				elif typeof(c.diff) == TYPE_BOOL or c.has("overwrite"):
					target[c.value_to_change] = c.diff
					if c.value_to_change == "destroyed" and reels.checking_effects and type != "lefty_the_rabbit_essence":
						reels.destroyed_item_this_spin = true
						get_parent().just_destroyed_items.push_back(type)
				elif c.has("add_to_array"):
					if c.value_to_change == "permanent_bonuses":
						for it in range(item_count):
							$"/root/Main/Pop-up Sprite/Pop-up".permanent_bonuses.push_back(c.diff)
							for r in reels.reels:
								for i in r.icons:
									var eff
									var a
									var b
									var value_to_change
									var diff
									if c.diff.has("groups"):
										a = "groups"
										b = c.diff.groups
									elif c.diff.has("type"):
										a = "type"
										if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(c.diff.type):
											b = c.diff.type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.type]
											if $"/root/Main".mod_pack_nums.has(b):
												b += "_PACK_" + $"/root/Main".mod_pack_nums[b]
											if $"/root/Main".is_mod_disabled(b) and $"/root/Main".tile_database.has(b.substr(0, b.find("_STEAM_ID_"))):
												b = b.substr(0, b.find("_STEAM_ID_"))
										else:
											b = $"/root/Main".existing_symbols[c.diff.type]
									var tmp_diff = {}
									tmp_diff[a] = b
									if c.diff.has("multiplier"):
										value_to_change = "value_multiplier"
										diff = c.diff.multiplier
										tmp_diff["multiplier"] = diff
									elif c.diff.has("bonus"):
										value_to_change = "value_bonus"
										diff = c.diff.bonus
										tmp_diff["bonus"] = diff
									eff = {"comparisons": [{"a": a, "b": b}], "value_to_change": value_to_change, "diff": diff}
									i.add_permanent_bonus(tmp_diff, eff, true)
					else:
						target[c.value_to_change].push_back(c.diff)
				else:
					target[c.value_to_change] += c.diff
					if c.value_to_change == "saved_value" or c.value_to_change == "saved_values":
						target.update_value_text()
				if not c.has("while"):
					var eff = c.duplicate(true)
					if eff.has("source"):
						eff.source = eff.source.type
					if eff.has("target") and eff.target is Node and not eff.target is Control:
						eff.target = eff.target.type
					if eff.has("giver"):
						eff.giver = eff.giver.type
					if eff.has("carry_over"):
						eff.erase("carry_over")
					if eff.has("source"):
						eff.erase("source")
					if eff.has("anim"):
						eff.erase("anim")
					if eff.has("anim_targets"):
						eff.erase("anim_targets")
					if eff.has("anim_targets"):
						eff.erase("anim_targets")
					if eff.has("sfx_type"):
						eff.erase("sfx_type")
					$"/root/Main".write_log("Effect - " + type + ": " + str(eff))
					erased_effects.push_back(c)
					c_tbe.push_back(c)
					break
			else:
				break
	for c in c_tbe:
		c_effects.erase(c)
	update_value_text()
	for i in item_queue:
		$"/root/Main/Items".add_item(i)
	if not $"/root/Main/Reels".effects_playing and not $"/root/Main/Reels".counting_symbols:
		if value != 0:
			$"/root/Main/Sums/Coin Sum".add_value(value)
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(value)
			$"/root/Main/Sums/HP Sum".adding = true
		if reroll_value != 0 or removal_value != 0 or essence_value != 0:
			$"/root/Main/Sums/Extra Sum".add_value(reroll_value, removal_value, essence_value)
			$"/root/Main/Sums/Extra Sum".adding = true
			$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens += removal_value
			$"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens += reroll_value
			$"/root/Main/Pop-up Sprite/Pop-up".essence_tokens += essence_value

func add_conditional_effects():
	if not disabled:
		var t = type.substr(0, type.find("_STEAM_ID_"))
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.dynamic_icon != null and type == fp.dynamic_icon:
				match int(fp.num):
					17:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}], "value_to_change": "value", "last": true, "diff": -fp.values[0] * item_count})
			elif t == "guillotine":
				match int(fp.num):
					18:
						return
		if not modded or (modded and inherit_effects):
			match t:
				"coin_on_a_string":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[0]})
				"lucky_carrot":
					var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "uncommon", "diff": values[0]})
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "rare", "diff": values[0]})
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "very_rare", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}], "value_to_change": "value_multiplier", "diff": values[1]})
				"golden_carrot":
					var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "uncommon", "diff": values[0]})
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "rare", "diff": values[0]})
					add_effect({"comparisons": [], "target": symbol_rarity, "multiply": true, "value_to_change": "very_rare", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}], "value_to_change": "value_multiplier", "diff": values[1]})
				"lemon":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "empty"}], "value_to_change": "value_bonus", "diff": values[0]})
				"fertilizer":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "bonus_values", "bonus_value_num": 0, "diff": values[0], "push_front": true})
				"watering_can":
					var fertilizer
					var compost_heap
					var fertilizer_essence
					if get_parent().has_unmodded_item("fertilizer"):
						fertilizer = get_parent().items[get_parent().item_types.find("fertilizer")]
					if get_parent().has_unmodded_item("compost_heap"):
						compost_heap = get_parent().items[get_parent().item_types.find("compost_heap")]
					if get_parent().has_unmodded_item("fertilizer_essence"):
						fertilizer_essence = get_parent().items[get_parent().item_types.find("fertilizer_essence")]
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "value_bonus", "diff": values[1]})
					var fp_34 = false
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 34:
							fp_34 = true
							break
					if not fp_34:
						if fertilizer_essence != null:
							add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}], "item_to_destroy": "fertilizer_essence", "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "very_rare"})
						elif fertilizer != null:
							add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}], "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "rare"})
						elif compost_heap != null:
							add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}], "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "uncommon"})
						else:
							add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}], "anim": "shake", "value_to_change": "type", "group": "plant"})
				"cleaning_rag":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "gem"}], "value_to_change": "value_bonus", "diff": values[0]})
				"fruit_basket":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "fruit"}], "value_to_change": "value_bonus", "diff": values[0]})
				"reroll":
					var reroll_essence = false
					if get_parent().has_unmodded_item("reroll_essence"):
						reroll_essence = true
					if not reroll_essence:
						randomize()
						add_to_cond_effects({"comparisons": [{"a": "type", "b": $"/root/Main".get_appended_steam_id("d3", "symbol")}, {"a": "value_bonus", "b": values[0], "less_than": true}, {"a": "value_bonus", "b": 1, "greater_than_eq": true}], "anim": "bounce", "value_to_change": "tried_to_give_rand_eff", "diff": true})
						add_to_cond_effects({"comparisons": [{"a": "type", "b": $"/root/Main".get_appended_steam_id("d3", "symbol")}, {"a": "tried_to_give_rand_eff", "b": true}], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": floor(rand_range($"/root/Main".tile_database[$"/root/Main".get_appended_steam_id("d3", "symbol")].values[0], $"/root/Main".tile_database[$"/root/Main".get_appended_steam_id("d3", "symbol")].values[1] + 1)), "overwrite": true})
						randomize()
						add_to_cond_effects({"comparisons": [{"a": "type", "b": $"/root/Main".get_appended_steam_id("d5", "symbol")}, {"a": "value_bonus", "b": values[1], "less_than": true}, {"a": "value_bonus", "b": 1, "greater_than_eq": true}], "anim": "bounce", "value_to_change": "tried_to_give_rand_eff", "diff": true})
						add_to_cond_effects({"comparisons": [{"a": "type", "b": $"/root/Main".get_appended_steam_id("d5", "symbol")}, {"a": "tried_to_give_rand_eff", "b": true}], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": floor(rand_range($"/root/Main".tile_database[$"/root/Main".get_appended_steam_id("d5", "symbol")].values[0], $"/root/Main".tile_database[$"/root/Main".get_appended_steam_id("d5", "symbol")].values[1] + 1)), "overwrite": true})
				"wanted_poster":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "thief"}, {"a": "destroyed", "b": true}, {"a": "value_bonus", "b": 1, "less_than": true}], "value_to_change": "flat_value_bonus", "diff": 1, "overwrite": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "thief"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"flush":
					var rarity_db = $"/root/Main".rarity_database
					if rarity_db["symbols"]["uncommon"].has("clubs"):
						rarity_db["symbols"]["uncommon"].erase("clubs")
						rarity_db["symbols"]["common"].push_back("clubs")
						$"/root/Main".tile_database["clubs"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("diamonds"):
						rarity_db["symbols"]["uncommon"].erase("diamonds")
						rarity_db["symbols"]["common"].push_back("diamonds")
						$"/root/Main".tile_database["diamonds"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("hearts"):
						rarity_db["symbols"]["uncommon"].erase("hearts")
						rarity_db["symbols"]["common"].push_back("hearts")
						$"/root/Main".tile_database["hearts"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("spades"):
						rarity_db["symbols"]["uncommon"].erase("spades")
						rarity_db["symbols"]["common"].push_back("spades")
						$"/root/Main".tile_database["spades"].rarity = "common"
				"piggy_bank":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": -values[0]})
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": values[0]})
				"swear_jar":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": -values[0]})
				"lockpick":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "chest"}, {"a": "values", "b": "rand_num", "value_num": 0, "rand": true, "dynamic_a_target": self, "dynamic_a_key": "values"}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"maxwell_the_bear":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "bear"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"rain_cloud":
					var rarity_db = $"/root/Main".rarity_database
					if rarity_db["symbols"]["uncommon"].has("rain"):
						rarity_db["symbols"]["uncommon"].erase("rain")
						rarity_db["symbols"]["common"].push_back("rain")
						$"/root/Main".tile_database["rain"].rarity = "common"
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rain"}], "value_to_change": "value_bonus", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rain"}], "overwrite": true, "value_to_change": "rarity", "diff": "common"})
				"looting_glove":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "box"}, {"a": "destroyed", "b": true}], "value_to_change": "value_multiplier", "diff": values[0]})
				"red_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"green_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"blue_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"compost_heap":
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "saved_value", "dynamic_b_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_b_key": "compost_heap_symbols_destroyed", "less_than": true}], "value_to_change": "saved_value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "compost_heap_symbols_destroyed", "overwrite": true, "while": true})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}, {"a": null, "b": values[0], "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "compost_heap_symbols_destroyed", "greater_than_eq": true}], "tiles_to_add": [{"type": "seed"}], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "compost_heap_symbols_destroyed", "diff": -values[0], "while": true})
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "compost_heap_symbols_destroyed", "dynamic_b_target": self, "dynamic_b_key": "saved_value", "less_than": true}], "value_to_change": "saved_value", "diff": -values[0], "while": true})
				"shrine":
					var spirit_arr = []
					for i in item_count:
						spirit_arr.push_back({"type": "spirit"})
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "organism"}, {"a": "destroyed", "b": true}], "tiles_to_add": spirit_arr})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "golem", "not_prev": true}, {"a": "tbd", "b": true}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"undertaker":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "spirit"}], "value_to_change": "indestructible", "diff": true, "push_front": true})
				"grave_robber":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "spiritbox"}, {"a": "values", "b": "rand_num", "value_num": 0, "rand": true, "dynamic_a_target": self, "dynamic_a_key": "values"}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"conveyor_belt":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "spawner0"}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 0, "diff": values[0], "push_front": true})
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "spawner1"}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 1, "diff": values[0], "push_front": true})
				"jackolantern":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "halloween"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"triple_coins":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "coin"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"shedding_season":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}], "value_to_change": "bonus_values", "bonus_value_num": 0, "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}, {"a": "values", "b": "rand_num", "value_num": 0, "rand": true}], "anim": "bounce", "stat_to_change": "rabbit_fluff_shed", "stat_diff": 0.01, "stat_to_change_2": "rabbit_hops", "stat_diff_2": 3,  "tiles_to_add": [{"type": "rabbit_fluff"}]})
				"chicken_coop":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "chickenstuff"}], "value_to_change": "value_bonus", "diff": values[2]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "chicken"}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 0, "diff": values[0], "push_front": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "chicken"}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 1, "diff": values[0], "push_front": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "egg"}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 0, "diff": values[1], "push_front": true})
				"yellow_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"nori_the_rabbit":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}], "value_to_change": "value_bonus", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit_fluff"}], "value_to_change": "value_bonus", "diff": values[0]})
				"lucky_seven":
					add_effect({"comparisons": [{"a": "item_count", "b": values[0], "greater_than_eq": true}], "value_to_change": "value", "diff": values[1], "overwrite": true})
					add_effect({"comparisons": [{"a": "item_count", "b": values[0], "greater_than_eq": true}], "value_to_change": "item_count", "diff": -values[0]})
				"egg_carton", "fish_bowl":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": saved_value * values[0]})
				"rusty_gear":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value_multiplier", "diff": values[1], "affected_symbols": true})
				"frozen_pizza", "protractor", "telescope":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
				"oil_can":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_to_cond_effects({"comparisons": [{"a": "grid_position_x", "b": $"/root/Main/Pop-up Sprite/Pop-up".respun_reel}], "value_to_change": "value_multiplier", "diff": values[1], "unconditional": true})
				"purple_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"black_cat":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "value_multiplier", "diff": values[2]})
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[0]})
				"pool_ball", "horseshoe", "bowling_ball", "four_leaf_clover":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"ritual_candle":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "fossillikes"}], "value_to_change": "value_bonus", "diff": values[0]})
				"holy_water":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "hex"}], "value_to_change": "value_bonus", "diff": values[0]})
				"happy_hour":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "booze"}], "value_to_change": "value_bonus", "diff": values[0]})
				"dwarven_anvil":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "dwarf"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"birdhouse":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "bird"}], "value_to_change": "value_bonus", "diff": values[0]})
				"oswald_the_monkey":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "monkey"}], "value_to_change": "value_multiplier", "diff": values[0]})
				"mining_pick":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "minerlikes"}, {"a": "destroyed", "b": true}, {"a": "tbd", "b": false}], "target": self, "value_to_change": "value", "diff": values[0]})
				"anthropology_degree":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "human"}], "value_to_change": "value_bonus", "diff": values[0]})
				"black_pepper":
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "value", "dynamic_b_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_b_key": "symbols_destroyed_this_spin", "less_than": true, "dynamic_b_multiplier": values[0] * item_count}], "value_to_change": "value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "symbols_destroyed_this_spin", "overwrite": true, "while": true})
				"shattered_mirror":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "value", "diff": values[0]})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "saved_value", "diff": 0, "overwrite": true})
				"tax_evasion":
					add_to_cond_effects({"comparisons": [{"a": "non_prev_final_value", "b": 0, "less_than": true}], "value_to_change": "value_bonus", "diff": values[0], "push_front": true})
				"void_portal":
					add_to_cond_effects({"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}], "target": self, "value_to_change": "saved_value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "destroyed_symbol_types_size", "overwrite": true})
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "value", "dynamic_b_target": self, "dynamic_b_key": "saved_value", "dynamic_b_divider": values[1], "less_than": true}], "value_to_change": "value", "dynamic_diff_target": self, "dynamic_diff_key": "saved_value", "dynamic_diff_divider": values[1], "overwrite": true, "while": true})
				"white_pepper", "white_pepper_essence":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[0]})
				"quigley_the_wolf":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "wolf"}], "value_to_change": "value_bonus", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "dog", "not_prev": true}], "anim": "shake", "value_to_change": "type", "diff": "wolf"})
				"pizza_the_cat":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "cat"}], "value_to_change": "value_bonus", "diff": values[0]})
				"recycling":
					add_effect({"comparisons": [], "value_to_change": "reroll_value", "diff": values[0]})
				"lefty_the_rabbit":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "tiles_to_add": [{"type": "rabbit_fluff"}], "stat_to_change": "rabbit_fluff_shed", "stat_diff": 0.01, "value_to_change": "saved_value", "diff": -values[0], "while": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}, {"a": "grid_position_x", "b": 0}], "value_to_change": "value_multiplier", "diff": values[1]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit_fluff"}, {"a": "grid_position_x", "b": 0}], "value_to_change": "value_multiplier", "diff": values[1]})
				"ricky_the_banana":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "banana"}], "value_to_change": "value_bonus", "diff": values[0]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "banana_peel"}], "value_to_change": "value_bonus", "diff": values[0]})
				"chili_powder":
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "value", "dynamic_b_target": $"/root/Main/Items", "dynamic_b_key": "total_peppers", "less_than": true}], "value_to_change": "value", "dynamic_diff_target": $"/root/Main/Items", "dynamic_diff_key": "total_peppers", "overwrite": true, "while": true})
				"treasure_map", "blue_suits", "red_suits":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
				"cyan_pepper":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"guillotine":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "billionaire"}], "anim": "shake", "sfx_type": 1, "value_to_change": "destroyed", "stat_to_change": "billionaires_guillotined", "stat_diff": 1, "diff": true})
				"cardboard_box":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "removal_value", "diff": values[0]})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "saved_value", "diff": 0, "overwrite": true})
				"sunglasses":
					add_effect({"comparisons": [{"a": null, "b": values[1], "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "removal_tokens", "greater_than_eq": true}], "value_to_change": "removal_value", "diff": values[0]})
				"kyle_the_kernite":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "kyle"}], "value_to_change": "value_bonus", "diff": values[0]})
				"frying_pan":
					var symbol_arr = []
					for i in range(item_count):
						symbol_arr.push_back({"type": "omelette"})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "egg"}, {"a": "destroyed", "b": true}], "target": self, "tiles_to_add": symbol_arr})
				"brown_pepper":
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "value", "dynamic_b_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_b_key": "symbols_added_this_spin", "less_than": true}], "value_to_change": "value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "symbols_added_this_spin", "overwrite": true, "while": true})
				"dishwasher":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "essence_value", "diff": values[0]})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "saved_value", "diff": 0, "overwrite": true})
				"coin_on_a_string_essence", "lint_roller_essence", "fish_bowl_essence", "barrel_o_dwarves_essence":
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"lucky_carrot_essence", "golden_carrot_essence":
					var rarity_arr = []
					for i in range(values[0]):
						rarity_arr.push_back("very_rare")
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "forced_rarities", "diff": {"forced_rarity": rarity_arr, "or_better": true}, "add_to_array": true})
				"egg_carton_essence":
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"devils_deal_essence":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"lemon_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "empty"}], "value_to_change": "value_bonus", "diff": values[1]})
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
				"lucky_dice_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d3"}], "value_to_change": "value_bonus", "diff": values[1]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d5"}], "value_to_change": "value_bonus", "diff": values[1]})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"reroll_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d3"}, {"a": "value_bonus", "b": values[0], "less_than": true}, {"a": "value_bonus", "b": 1, "greater_than_eq": true}], "anim": "bounce", "value_to_change": "tried_to_give_rand_eff", "diff": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d3"}, {"a": "tried_to_give_rand_eff", "b": true}], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": $"/root/Main".tile_database.d3.values[1], "overwrite": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d5"}, {"a": "value_bonus", "b": values[1], "less_than": true}, {"a": "value_bonus", "b": 1, "greater_than_eq": true}], "anim": "bounce", "value_to_change": "tried_to_give_rand_eff", "diff": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "d5"}, {"a": "tried_to_give_rand_eff", "b": true}], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": $"/root/Main".tile_database.d5.values[1], "overwrite": true})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[2], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"watering_can_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "value_bonus", "diff": values[0]})
				"booster_pack_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"cleaning_rag_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "gem", "multiplier": values[1]}, "add_to_array": true})
				"fruit_basket_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "fruit", "multiplier": values[1]}, "add_to_array": true})
				"mining_pick_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "minerlikes"}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[1], "overwrite": true})
				"flush_essence":
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"piggy_bank_essence":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": -values[0]})
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[2]})
				"swear_jar_essence":
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[1], "overwrite": true})
				"wanted_poster_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "bounty_hunter", "multiplier": values[0]}, "add_to_array": true})
				"goldilocks_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "bear", "bonus": values[1]}, "add_to_array": true})
				"lockpick_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "chest"}, {"a": "values", "b": "rand_num", "value_num": 1, "rand": true, "dynamic_a_target": self, "dynamic_a_key": "values"}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "chest"}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"maxwell_the_bear_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "bear", "multiplier": values[0]}, "add_to_array": true})
				"rain_cloud_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "flower", "bonus": values[0]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "rain", "bonus": values[0]}, "add_to_array": true})
				"ninja_and_mouse_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "ninja", "bonus": values[0]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "mouse", "bonus": values[0]}, "add_to_array": true})
				"copycat_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "cat", "multiplier": values[1]}, "add_to_array": true})
				"clear_sky_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "sun", "multiplier": values[0]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "moon", "multiplier": values[0]}, "add_to_array": true})
				"looting_glove_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "box"}, {"a": "destroyed", "b": true}], "item_to_destroy": "looting_glove_essence", "value_to_change": "value_multiplier", "diff": values[0]})
				"red_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"green_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"blue_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"yellow_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"purple_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"cyan_pepper_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true, "overwrite": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"compost_heap_essence":
					var watermelon_arr = []
					for w in range(values[0]):
						watermelon_arr.push_back({"type": "watermelon"})
					add_effect({"comparisons": [{"a": null, "b": values[1], "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "symbols_destroyed_this_spin", "greater_than_eq": true}], "tiles_to_add": watermelon_arr, "value_to_change": "destroyed", "diff": true})
				"shrine_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "spirit"}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"undertaker_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "spirit", "bonus": values[1]}, "add_to_array": true})
				"conveyor_belt_essence":
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"time_machine_essence":
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"jackolantern_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "halloween", "multiplier": values[0]}, "add_to_array": true})
				"zaroffs_contract_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"triple_coins_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "coin", "bonus": values[1]}, "add_to_array": true})
				"frying_pan_essence":
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "egg"}, {"a": "destroyed", "b": true}], "target": self, "tiles_to_add": [{"type": "omelette"}]})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "omelette", "multiplier": values[0]}, "add_to_array": true})
				"chicken_coop_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "chickenstuff", "bonus": values[0]}, "add_to_array": true})
				"nori_the_rabbit_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "rabbit", "multiplier": values[1]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "rabbit_fluff", "multiplier": values[1]}, "add_to_array": true})
				"recycling_essence":
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "reroll_value", "diff": values[1]})
				"pool_ball_essence", "horseshoe_essence", "bowling_ball_essence", "four_leaf_clover_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [], "value_to_change": "value", "diff": values[1], "overwrite": true})
				"lucky_cat_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
				"lucky_seven_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"rusty_gear_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
				"black_cat_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "cat", "multiplier": values[1]}, "add_to_array": true})
				"ritual_candle_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "fossillikes", "multiplier": values[1]}, "add_to_array": true})
				"holy_water_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "hex", "multiplier": values[1]}, "add_to_array": true})
				"happy_hour_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "booze", "not_prev": true}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "booze", "multiplier": values[1]}, "add_to_array": true})
				"telescope_essence", "protractor_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"blue_suits_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "clubs", "bonus": values[1]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "spades", "bonus": values[1]}, "add_to_array": true})
				"red_suits_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "hearts", "bonus": values[1]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "diamonds", "bonus": values[1]}, "add_to_array": true})
				"checkered_flag_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "slow"}], "value_to_change": "times_displayed", "diff": 100000})
				"dwarven_anvil_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "dwarf", "multiplier": values[0]}, "add_to_array": true})
				"birdhouse_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "bird", "bonus": values[1]}, "add_to_array": true})
				"anthropology_degree_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "human", "multiplier": values[1]}, "add_to_array": true})
				"oswald_the_monkey_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "monkey", "multiplier": values[0]}, "add_to_array": true})
				"black_pepper_essence":
					add_effect({"comparisons": [{"a": null, "b": null, "dynamic_a_target": self, "dynamic_a_key": "value", "dynamic_b_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_b_key": "symbols_destroyed_this_spin", "dynamic_b_multiplier": values[0] * item_count, "less_than": true}], "value_to_change": "value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "symbols_destroyed_this_spin", "dynamic_diff_multiplier": values[0], "overwrite": true, "while": true})
					add_effect({"comparisons": [{"a": "value", "b": 1, "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"ancient_lizard_blade_essence":
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true})
				"tax_evasion_essence":
					add_to_cond_effects({"comparisons": [{"a": "non_prev_final_value", "b": 0, "less_than": true}], "value_to_change": "value_bonus", "diff": values[0], "item_to_destroy": "tax_evasion_essence", "push_front": true})
				"lunchbox_essence", "adoption_papers_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[1], "overwrite": true})
				"void_portal_essence":
					add_effect({"comparisons": [{"a": null, "b": true, "dynamic_a_target": $"/root/Main/Reels", "dynamic_a_key": "symbol_destroyed_during_spin"}], "value_to_change": "value", "dynamic_diff_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_diff_key": "destroyed_symbol_types_size", "overwrite": true})
					add_effect({"comparisons": [{"a": "value", "b": 1, "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"cursed_katana_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "ninja", "bonus": values[1]}, "add_to_array": true})	
				"dishwasher_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "essence_value", "diff": values[1]})
				"cardboard_box_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "removal_value", "diff": values[1]})
				"sunglasses_essence":
					add_effect({"comparisons": [{"a": null, "b": values[1], "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "removal_tokens", "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "removal_value", "diff": values[0]})
				"treasure_map_essence":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
				"fifth_ace_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "suit", "bonus": values[1]}, "add_to_array": true})
				"ricky_the_banana_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "banana", "bonus": values[1]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "banana_peel", "bonus": values[1]}, "add_to_array": true})
				"pizza_the_cat_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "cat", "multiplier": values[0]}, "add_to_array": true})
				"kyle_the_kernite_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "kyle", "bonus": values[1]}, "add_to_array": true})
				"lefty_the_rabbit_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit"}, {"a": "grid_position_x", "b": 0}], "value_to_change": "value_multiplier", "diff": values[1]})
					add_to_cond_effects({"comparisons": [{"a": "type", "b": "rabbit_fluff"}, {"a": "grid_position_x", "b": 0}], "value_to_change": "value_multiplier", "diff": values[1]})
				"oil_can_essence":
					add_to_cond_effects({"comparisons": [{"a": "grid_position_x", "b": $"/root/Main/Pop-up Sprite/Pop-up".respun_essence_reel}], "from_item": "oil_can_essence", "value_to_change": "value_multiplier", "diff": values[1], "unconditional": true})
				"quigley_the_wolf_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "wolf", "bonus": values[1]}, "add_to_array": true})
				"swapping_device_essence":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "value_multiplier", "diff": values[2], "from_item": "swapping_device_essence", "affected_symbols": true})
				"dark_humor":
					var rarity_db = $"/root/Main".rarity_database
					if rarity_db["symbols"]["rare"].has("comedian"):
						rarity_db["symbols"]["rare"].erase("comedian")
						rarity_db["symbols"]["uncommon"].push_back("comedian")
						$"/root/Main".tile_database["comedian"].rarity = "uncommon"
				"dark_humor_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "funny", "bonus": values[0]}, "add_to_array": true})
				"credit_card":
					add_effect({"comparisons": [], "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "saved_value", "diff": 0, "overwrite": true})
				"credit_card_essence":
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true})
				"void_party":
					var rarity_db = $"/root/Main".rarity_database
					if rarity_db["symbols"]["uncommon"].has("void_creature"):
						rarity_db["symbols"]["uncommon"].erase("void_creature")
						rarity_db["symbols"]["common"].push_back("void_creature")
						$"/root/Main".tile_database["void_creature"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("void_stone"):
						rarity_db["symbols"]["uncommon"].erase("void_stone")
						rarity_db["symbols"]["common"].push_back("void_stone")
						$"/root/Main".tile_database["void_stone"].rarity = "common"
					if rarity_db["symbols"]["uncommon"].has("void_fruit"):
						rarity_db["symbols"]["uncommon"].erase("void_fruit")
						rarity_db["symbols"]["common"].push_back("void_fruit")
						$"/root/Main".tile_database["void_fruit"].rarity = "common"
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "void"}], "overwrite": true, "value_to_change": "rarity", "diff": "common"})
					randomize()
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "void"}, {"a": "destroyed", "b": true, "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "rand": true, "value_num": 0, "value_target_override": self}, {"a": null, "b": values[1], "dynamic_a_target": self, "dynamic_a_key": "saved_value", "less_than": true}], "item_to_add_saved_value": "void_party", "can_add_after_destroy": true, "tiles_to_add": ["current_type"]})
				"mobius_strip":
					randomize()
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "box"}, {"a": "destroyed", "b": true, "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "rand": true, "value_num": 0, "value_target_override": self}, {"a": null, "b": values[1], "dynamic_a_target": self, "dynamic_a_key": "saved_value", "less_than": true}], "item_to_add_saved_value": "mobius_strip", "can_add_after_destroy": true, "tiles_to_add": ["current_type"]})
				"void_party_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "void"}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "void", "multiplier": values[1]}, "add_to_array": true})
				"mobius_strip_essence":
					add_to_cond_effects({"comparisons": [{"a": "groups", "b": "box"}, {"a": "tbd", "b": true}], "target": self, "value_to_change": "saved_value", "diff": 1})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[0], "greater_than_eq": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"groups": "box", "multiplier": values[1]}, "add_to_array": true})
				"turtle_and_rabbit":
					add_effect({"comparisons": [{"a": "symbol_trigger", "b": true}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "value", "diff": values[0], "overwrite": true})
				"turtle_and_rabbit_essence":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "rabbit", "bonus": values[0]}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "permanent_bonuses", "diff": {"type": "turtle", "bonus": values[0]}, "add_to_array": true})
		var fp_effects = []
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num > 37:
				for r in fp.effects:
					if fp.for_items:
						var fp_types = fp.reliant_types
						var fp_groups = fp.reliant_groups
						if fp.reliant_types != "" and $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(fp.reliant_types):
							fp_types = fp.reliant_types + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[fp.reliant_types] + "_PACK_" + $"/root/Main".mod_pack_nums[fp.reliant_types + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[fp.reliant_types]]
						if (fp_types != "" and fp_types == type) or (fp_groups != "" and $"/root/Main".group_database.items.has(fp_groups.substr(5, -1)) and $"/root/Main".group_database.items[fp_groups.substr(5, -1)].has(type)) or (fp_types == "" and fp_groups == ""):
							var eff = r.duplicate(true)
							eff["fp_num"] = fp.num
							fp_effects.push_back(eff)
		for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.items:
			if type == m.type:
				for eff in m.effects:
					add_modded_effect(eff)
		for f in fp_effects:
			tmp_fp_num = f.fp_num
			add_modded_effect(f)
		for k in $"/root/Main".inherited_effects_database.keys():
			for i in inherited_effects:
				if "inherited_effects_" + i + "_STEAM_ID_" + str(k.substr(k.find("_STEAM_ID_") + 10, -1)) == k:
					for eff in $"/root/Main".inherited_effects_database[k]:
						add_modded_effect(eff)
					break
		add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "destroy_counters", "b": 2, "less_than": true}, {"a": "item_count", "b": 2, "less_than": true}], "value_to_change": "alpha", "diff": 0.3})
		if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
			for f in $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.item_effects:
				add_modded_effect(f)

func add_modded_effect(eff):
	if not eff.has("effect_type"):
		add_effect(eff.duplicate(true))
	else:
		match eff["effect_type"]:
			"symbols":
				add_to_cond_effects(eff.duplicate(true))
			"symbol_added", "item_added", "rent_paid":
				if addding_post_spin_effects:
					add_effect(eff.duplicate(true))
			_:
				add_effect(eff.duplicate(true))
