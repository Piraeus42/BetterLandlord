extends Node2D

var items = []
var destroyed_items = []

var item_types = []
var item_types_at_end_of_spin = []
var cond_effects_to_add = []
var destroyed_item_types = []
var saved_item_data = []
var saved_destroy_counters = []
var item_count_data = []
var just_added_items = []
var items_destroyed_this_spin = []
var recently_destroyed_items = []
var just_destroyed_items = []
var page = 0
var total_peppers = 0
var loading_items = false
var adding_disabled_item = false
var tooltip_card = false
var visible_items = 0

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

func add_cond_effects():
	$"/root/Main/Reels".symbol_positions_to_update.sort()
	for pos in $"/root/Main/Reels".symbol_positions_to_update:
		for e in cond_effects_to_add:
			$"/root/Main/Reels".displayed_icons[pos.y][pos.x].texture_type = $"/root/Main/Reels".displayed_icons[pos.y][pos.x].type
			$"/root/Main/Reels".displayed_icons[pos.y][pos.x].add_effect(e.duplicate(true))
	cond_effects_to_add.clear()

func has_unmodded_item(p_type):
	p_type = p_type.substr(0, p_type.find("_STEAM_ID_"))
	var a_type = p_type
	if $"/root/Main".existing_items.has(p_type) and $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(p_type) and $"/root/Main".mod_pack_nums.has(p_type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type]) and not $"/root/Main".is_mod_disabled(p_type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type] + "_PACK_" + $"/root/Main".mod_pack_nums[p_type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type]]):
		a_type = p_type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type] + "_PACK_" + $"/root/Main".mod_pack_nums[p_type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type]]
	if (item_types.has(a_type) and items.size() > item_types.find(a_type) and not items[item_types.find(a_type)].modded) or ($"/root/Main".mod_data.items.has(a_type) and (item_types.has(a_type) or item_types_at_end_of_spin.has(a_type)) and $"/root/Main".item_database[a_type].inherit_effects):
		return true
	return false

func has_just_destroyed_unmodded_item(p_type):
	p_type = p_type.substr(0, p_type.find("_STEAM_ID_"))
	var a_type = p_type
	if $"/root/Main".existing_items.has(p_type) and $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(p_type):
		a_type = $"/root/Main".existing_items[p_type] + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type] + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".existing_items[p_type] + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[p_type]]
	if ((items_destroyed_this_spin.has(a_type) and not $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(p_type))) or ($"/root/Main".mod_data.items.has(a_type) and items_destroyed_this_spin.has(a_type) and $"/root/Main".item_database[a_type].inherit_effects):
		return true
	return false

func add_item(p_type):
	var can_add = true
	
	var type
	
	if $"/root/Main".mod_data.items.has(p_type) and $"/root/Main".item_database.has($"/root/Main".append_steam_id(p_type, $"/root/Main".mod_data.items[p_type].author_id)):
		type = $"/root/Main".append_steam_id(p_type, $"/root/Main".mod_data.items[p_type].author_id)
	elif $"/root/Main".item_database.has(p_type):
		type = p_type
	else:
		type = "item_missing"
		if item_types.has(p_type):
			item_types[item_types.find(p_type)] = type
	
	var dis = false
	
	var z_num = item_types.find(type)
	if z_num == -1:
		z_num = item_types.find(type + "_d")
		if z_num != -1:
			type += "_d"
			dis = true
	
	if z_num != -1 and item_types.find(type) != -1 and items.size() >= z_num and items.size() == item_types.size() and (items[item_types.find(type)].type == type or (dis and items[item_types.find(type)].type + "_d" == type)):
		can_add = false
		var z = items[item_types.find(type)]
		z.item_count += 1
		if $"/root/Main/Reels".items_being_added_during_spin > 0:
			$"/root/Main/Reels".items_being_added_during_spin -= 1
		if $"/root/Main/Reels".items_being_added_during_spin == 0:
			z.get_child(0).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_count_text"] + ">" + z.get_child(0).parse_num_str(str(z.item_count)) + "<end>"
			z.get_child(0).force_update = true
			z.get_child(0).update()
			z.update_value_text()
			if $"/root/Main/Reels".checking_effects:
				z.add_conditional_effects()
	if dis:
		type = type.substr(0, type.length() - 2)
	
	if $"/root/Main".item_database[type].groups.has("pepper"):
		total_peppers += 2.0
	
	if can_add:
		var item = preload("res://Item.tscn").instance()
		add_child(item)
		
		if not $"/root/Main/Reels".checking_effects:
			for e in $"/root/Main".mod_on_item_add_effects:
				var item_num = item_types.find($"/root/Main".existing_items[e.type])
				if item_num == -1:
					continue
				var i = items[item_num]
				i.addding_post_spin_effects = true
				i.add_conditional_effects()
				i.addding_post_spin_effects = false
				i.check_conditional_effects()
				i.c_effects.clear()
		
		var i = $"/root/Main".item_database[type]
		
		item.modded = i.modded
		if item.modded:
			item.inherit_effects = i.inherit_effects
			item.inherit_art = i.inherit_art
			item.symbols_removed_pre_spin = i.symbols_removed_pre_spin
			item.inherited_effects = i.inherited_effects
		item.groups = i.groups
		
		if not loading_items:
			just_added_items.push_back(type)
		
		item.set_type(type)
		if not item_types.has(type) and not item_types.has(type + "_d"):
			item_types.push_back(type)
		saved_item_data.push_back(0)
		saved_destroy_counters.push_back(0)
		item_count_data.push_back(1)
		
		item.rarity = i.rarity
		item.values = i.values
		item.disabled = adding_disabled_item
		
		item.get_child(3).visible = item.disabled
		
		if item.modded:
			item.description = $"/root/Main".item_database[type].description
			item.localized_descriptions = $"/root/Main".item_database[type].localized_descriptions
			item.localized_names = $"/root/Main".item_database[type].localized_names
		
		if not loading_items:
			if i.groups.has("essence") and item.destroy_counters == 0 and item.type != "popsicle_essence":
				if has_unmodded_item("popsicle"):
					item.destroy_counters = items[item_types.find("popsicle")].values[0] + items[item_types.find("popsicle")].item_count - 1
					item.update_value_text()
				elif has_unmodded_item("popsicle_essence"):
					if item.destroy_counters < items[item_types.find("popsicle_essence")].values[0]:
						item.destroy_counters = items[item_types.find("popsicle_essence")].values[0]
						item.update_value_text()
			elif item.type == "popsicle":
				var popsicle_essence = false
				if has_unmodded_item("popsicle_essence"):
					popsicle_essence = true
					var b = items[item_types.find("popsicle_essence")]
					if b.destroy_counters == 0:
						b.destroy_counters = item.values[0] + item.item_count - 1
						b.update_value_text()
				if not popsicle_essence:
					for z in items:
						if $"/root/Main".item_database[z.type].groups.has("essence") and z.destroy_counters == 0:
							z.destroy_counters = item.values[0] + item.item_count - 1
							z.update_value_text()
			elif item.type == "popsicle_essence":
				if has_unmodded_item("popsicle"):
					item.destroy_counters = items[item_types.find("popsicle")].values[0] + items[item_types.find("popsicle")].item_count - 1
				for z in items:
					if $"/root/Main".item_database[z.type].groups.has("essence") and z.destroy_counters >= 0:
						if z.destroy_counters < $"/root/Main".item_database["popsicle_essence"].values[0]:
							z.destroy_counters = item.values[0]
							z.update_value_text()
		if not item.disabled and item.type == "guillotine_essence" and $"/root/Main/Coins".coins >= i.values[0]:
			$"/root/Main".guillotine_essence_anim = 600
		
		if not item.modded or (item.modded and item.inherit_effects):
			var ty = item.type.substr(0, item.type.find("_STEAM_ID_"))
			match ty:
				"symbol_bomb_small", "symbol_bomb_big", "symbol_bomb_very_big", "booster_pack", "piggy_bank", "swear_jar", "barrel_o_dwarves", "lunchbox", "treasure_map", "adoption_papers", "goldilocks", "symbol_bomb_quantum", "blue_suits", "red_suits":
					item.destroyable = true
				_:
					item.destroyable = false
		if item.modded and i.manually_destroyable:
			item.destroyable = true
		
		for v in range(item.values.size()):
			item.bonus_values.push_back(0)
			item.bonus_value_multipliers.push_back(1)
		
		item.position = Vector2(1 + 13 * (items.size() % 4) + 76 * floor((items.size() % 4) / 2), 1 + 13 * floor(items.size() / 4))
		
		if type == "void_portal":
			item.saved_value = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types_size
		
		item.update_value_text()
		
		var texts = $"/root/Main/Reels".texts
		
		items.push_back(item)
		var s = Node2D.new()
		s.z_index = 4
		texts.push_back(preload("res://Effect Text.tscn").instance())
		texts[texts.size() - 1].rect_size = Vector2(128, 72)
		texts[texts.size() - 1].visible = false
		s.add_child(texts[texts.size() - 1])
		add_child(s)
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			var ic = $"/root/Main/Options Sprite/Options".ui_scaling.items_ui / 2.0
			texts[texts.size() - 1].text_mod = 1 + -floor((1 - ic) / 0.25)
			texts[texts.size() - 1].scale_mod = 1 + -floor((1 - ic) / 0.25) + 1
		else:
			var ic = $"/root/Main/Options Sprite/Options".ui_scaling.items_ui
			texts[texts.size() - 1].text_mod = -floor((1 - ic) / 0.25)
			texts[texts.size() - 1].scale_mod = -floor((1 - ic) / 0.25) + 1
			if ic < 1:
				texts[texts.size() - 1].scale_mod += 1
		update_positions()
		var reels = $"/root/Main/Reels"
		if reels.checking_effects:
			item.get_child(0).force_update = true
			item.get_child(0).update()
			item.update_value_text()
			for z in items:
				z.add_conditional_effects()
				z.symbol_check()
				z.check_conditional_effects()
		if reels.symbol_arr.size() > 0:
			for x in range(reels.reel_width):
				for y in range(reels.reel_height):
					if reels.checking_effects:
						reels.add_symbol_position_to_update(Vector2(x, y))
					reels.displayed_icons[y][x].update_value_text()
		if reels.checking_effects:
			for x in range(reels.reel_width):
				for y in range(reels.reel_height):
					reels.displayed_icons[y][x].add_conditional_effects()
			$"/root/Main/Items".add_cond_effects()
		$"/root/Main".write_log("Added item: " + type)

func update_positions():
	if items.size() > 0:
		visible_items = 0
		var item_size = int(26 * items[0].scale.x)
		var item_range = int($"/root/Main/Options Sprite/Options".resolution_x - ($"/root/Main/Reels".reel_borders[4].position.x + $"/root/Main/Reels".reel_borders[4].get_child(0).rect_size.x - $"/root/Main/Reels".reel_borders[0].position.x))
		var reels_rect = Rect2($"/root/Main/Reels".reel_borders[0].position.x, $"/root/Main/Reels".reel_borders[0].position.y, $"/root/Main/Reels".reel_borders[4].get_child(0).rect_size.x * 5, $"/root/Main/Reels".reel_borders[4].get_child(0).rect_size.y)
		var grid = []
		var full_rows = []
		var first_after_breaks = []
		var y_num = floor($"/root/Main/Menus".buttons_menu.spin_button.rect_position.y / item_size)
		if floor($"/root/Main/Menus".buttons_menu.options_button.rect_position.y / item_size) < y_num:
			y_num = floor($"/root/Main/Menus".buttons_menu.options_button.rect_position.y / item_size)
		var x_num = round(float($"/root/Main/Options Sprite/Options".resolution_x) / item_size)
		for y in y_num:
			grid.push_back([])
			full_rows.push_back(true)
			first_after_breaks.push_back(-1)
			for x in x_num:
				var b = Rect2(x * item_size, y * item_size, item_size, item_size)
				if reels_rect.intersects(b):
					grid[y].push_back(1)
					full_rows[y] = false
				else:
					grid[y].push_back(0)
					visible_items += 1
					if not full_rows[y] and first_after_breaks[y] == -1:
						first_after_breaks[y] = x
			if first_after_breaks[y] != -1:
				for x in range(first_after_breaks[y] - 1, x_num):
					var b = Rect2($"/root/Main/Options Sprite/Options".resolution_x - 22 * items[0].scale.x - (item_range % item_size) / 2 - item_size * (x_num - x - 1), y * item_size, item_size, item_size)
					if not reels_rect.intersects(b):
						if grid[y][x] != 0:
							grid[y][x] = 0
							visible_items += 1
					elif grid[y][x] != 1:
						grid[y][x] = 1
						visible_items -= 1
			if full_rows[y] and $"/root/Main/Options Sprite/Options".resolution_x - (item_size * grid[y].size()) / 2 + item_size * x_num >= $"/root/Main/Options Sprite/Options".resolution_x:
				grid[y].pop_back()
				visible_items -= 1
		for i in range(items.size()):
			var in_grid = false
			if i >= visible_items * page:
				for y in y_num:
					var g = grid[y].find(0)
					if g != -1:
						if full_rows[y]:
							items[i].position = Vector2(($"/root/Main/Options Sprite/Options".resolution_x - (item_size * grid[y].size())) / 2 + item_size * g, 2 * items[i].scale.x + item_size * y)
						elif g < x_num / 2.0:
							items[i].position = Vector2((item_range % item_size) / 2 + item_size * g, 2 * items[i].scale.x + item_size * y)
						else:
							items[i].position = Vector2($"/root/Main/Options Sprite/Options".resolution_x - 22 * items[0].scale.x - (item_range % item_size) / 2 - item_size * abs(g - x_num + 1), 2 * items[i].scale.x + item_size * y)
						grid[y][g] = 1
						in_grid = true
						break
			if in_grid:
				items[i].visible = true
				items[i].need_to_update = true
				items[i].set_process_input(true)
			else:
				items[i].visible = false
				items[i].need_to_update = false
				items[i].set_process_input(false)
	update_page_buttons()

func scroll_items_left():
	if not $"/root/Main/Reels".spinning and not $"/root/Main/Reels".effects_playing and not $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0:
		$"/root/Main/Menus".buttons_menu.left_button.down = false
		$"/root/Main/Menus".buttons_menu.left_button.visual_reset()
		page -= 1
		update_positions()

func scroll_items_right():
	if not $"/root/Main/Reels".spinning and not $"/root/Main/Reels".effects_playing and not $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0:
		$"/root/Main/Menus".buttons_menu.right_button.down = false
		$"/root/Main/Menus".buttons_menu.right_button.visual_reset()
		page += 1
		update_positions()

func update_page_buttons():
	var left_button = $"/root/Main/Menus".buttons_menu.left_button
	var right_button = $"/root/Main/Menus".buttons_menu.right_button
	
	if page == 0:
		left_button.visible = false
		if $"/root/Main".selected_node == left_button:
			$"/root/Main".selected_node = $"/root/Main/Menus".buttons_menu.spin_button
	elif items.size() != 0:
		left_button.visible = true
	if visible_items != 0 and page < floor((items.size() - 1) / visible_items) and items.size() != 0:
		right_button.visible = true
	else:
		right_button.visible = false
		if $"/root/Main".selected_node == right_button:
			$"/root/Main".selected_node = $"/root/Main/Menus".buttons_menu.spin_button

func load_items():
	loading_items = true
	var dupe_nums = []
	var num = 0
	for d in item_types:
		var t = d
		if t.substr(t.length() - 2, 2) == "_d":
			t = t.substr(0, t.length() - 2)
			adding_disabled_item = true
		add_item(t)
		if item_types.count(d) > 1 and item_types.find(d) != num:
			dupe_nums.push_back(num)
		adding_disabled_item = false
		if not $"/root/Main".sandbox_mode:
			items[items.size() - 1].saved_value = saved_item_data[items.size() - 1]
			items[items.size() - 1].destroy_counters = saved_destroy_counters[items.size() - 1]
			items[items.size() - 1].item_count = item_count_data[items.size() - 1]
			items[items.size() - 1].update_value_text()
		num += 1
	num = 0
	for d in dupe_nums:
		item_types.remove(d - num)
		num += 1
	dupe_nums.clear()
	for t in destroyed_item_types:
		destroyed_items.push_back(t)
	loading_items = false

func save():
	var save_dict = {
		"path" : get_path(),
		"item_types": item_types,
		"item_types_at_end_of_spin": item_types_at_end_of_spin,
		"items_destroyed_this_spin": items_destroyed_this_spin,
		"destroyed_item_types": destroyed_item_types,
		"saved_item_data": saved_item_data,
		"saved_destroy_counters": saved_destroy_counters,
		"item_count_data": item_count_data,
		"just_added_items": just_added_items,
		"recently_destroyed_items": recently_destroyed_items
	}
	return save_dict
