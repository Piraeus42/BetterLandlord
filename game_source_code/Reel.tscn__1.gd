extends ColorRect

var reel_num
var parent

var y_positions = []
var max_icons = 5
var icons = []
var icon_types = []
var icon_types_to_be_added = []
var saved_icon_data = []
var spinning = false
var spin_delay = 0
var max_spin_delay = 0
var spin_offset = 0
var spin_speed = 56
var spin_diff = 0
var instant_spins = false
var mini_spin = false
var hovering = false
var held = false
var icon_types_tba_bonus_texts = []
var mod = 112
var saved_scale = 1.0

var alignment_tags = {"bottom": false, "right": false, "centered": true, "v_centered": true}
var aligned = true
var saved_resolution = Vector2(1024, 576)

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _input(event):
	if hovering and event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and not $"/root/Main".lmb_down:
		if $"/root/Main/Options Sprite/Options".input_type == 0:
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			else:
				press()
		else:
			held = true
		$"/root/Main".lmb_down = true
	elif held and hovering and event is InputEventMouseButton and not event.is_pressed() and event.button_index == BUTTON_LEFT:
		if $"/root/Main/Options Sprite/Options".input_type == 1 and held:
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			else:
				press()
			held = false
		$"/root/Main".lmb_down = false
	elif event is InputEventMouseButton and not event.is_pressed() and event.button_index == BUTTON_LEFT:
		$"/root/Main".lmb_down = false
		held = false

func _ready():
	parent = get_parent()
	color = $"/root/Main/Options Sprite/Options".colors3["reels"]
	
	mod = int(round(112 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui))
	spin_speed = 56 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	
	saved_scale = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	
	for h in range(parent.reel_height):
		y_positions.push_back(int(h * mod + spin_diff))

func update_scale():
	for i in range(icons.size()):
		icons[i].position.y = (i * mod) % (icons.size() * mod) - mod
	
	spin_speed = 56 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	saved_scale = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	
	y_positions.clear()
	for h in range(parent.reel_height):
		y_positions.push_back(int(h * mod + spin_diff))

func update():
	if spinning:
		if $"/root/Main/Options Sprite/Options".spin_speed == 0:
			if reel_num == 0 and not mini_spin:
				symbol_removal_effects()
				parent.shuffle_tiles()
			if ($"/root/Main".sandbox_mode and $"/root/Main".sandbox_consistent) or ($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.consistent_spins):
				spin_offset = mod * (max_spin_delay - reel_num) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
			else:
				spin_offset = mod * (max_spin_delay + 1) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
		if spin_delay > -1:
			if spin_delay == max_spin_delay and reel_num == parent.reels.size() - 1:
				symbol_removal_effects()
				if not mini_spin and $"/root/Main/Options Sprite/Options".spin_speed != 0:
					parent.shuffle_tiles()
			spin_delay -= 1
			if spin_delay <= -1:
				spin_offset = 0
		if spin_delay <= -1:
			for i in range(icons.size()):
				icons[i].position.y = (i * mod + spin_offset) % (icons.size() * mod) - mod
				icons[i].get_child(1).visible = false
				icons[i].get_child(2).visible = false
				icons[i].get_child(3).visible = false
			if spin_offset >= mod * (max_spin_delay + 1) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui or $"/root/Main/Options Sprite/Options".spin_speed == 0:
				if ($"/root/Main".sandbox_mode and $"/root/Main".sandbox_consistent) or ($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.consistent_spins):
					spin_offset = int(mod * (max_spin_delay - reel_num) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui)
					for i in range(icons.size()):
						icons[i].position.y = (i * mod + spin_offset) % (icons.size() * mod) - mod
				elif spin_offset != mod * (max_spin_delay + 1) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui:
					spin_offset = int(mod * (max_spin_delay + 1) + 1680 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui)
					for i in range(icons.size()):
						icons[i].position.y = (i * mod + spin_offset) % (icons.size() * mod) - mod
				spin_delay = max_spin_delay
				spinning = false
				for i in icons:
					if y_positions.find(int(i.position.y)) != -1:
						parent.displayed_icons[y_positions.find(int(i.position.y))][reel_num] = i
						i.set_process_input(true)
						i.visible = true
					else:
						i.set_process_input(false)
						if max_icons > 20:
							i.visible = false
				for i in icons:
					i.grid_position = Vector2(i.get_parent().reel_num, int(floor(i.position.y / mod)))
				if reel_num == parent.reel_width - 1 or mini_spin:
					if not mini_spin:
						for r in parent.reels:
							var increment = 0
							for i in r.icons:
								i.grid_position = Vector2(i.get_parent().reel_num, int(floor(i.position.y / mod)))
								if i.grid_position.y >= 0 and i.grid_position.y <= parent.reel_height - 1:
									i.get_child(1).visible = true
									i.get_child(2).visible = true
									i.get_child(3).visible = true
									i.update_value_text()
								increment += 1
					else:
						var increment = 0
						for i in icons:
							i.grid_position = Vector2(i.get_parent().reel_num, int(floor(i.position.y / mod)))
							if i.grid_position.y >= 0 and i.grid_position.y <= parent.reel_height - 1:
								i.get_child(1).visible = true
								i.get_child(2).visible = true
								i.get_child(3).visible = true
							increment += 1
					parent.spinning = false
					parent.update_icon_types()
					$"/root/Main/Pop-up Sprite/Pop-up".spin_modifying_effects()
					if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0:
						parent.write_pre_effects_log()
						parent.add_effects()
						parent.checking_effects = true
						for t in $"/root/Main/Tooltips".get_children():
							t.queue_free()
						parent.check_effects()
					for r in parent.reels:
						for i in r.icons:
							i.hovering = false
							if r.y_positions.find(int(i.position.y)) != -1:
								i.active = true
								i.update_value_text()
					mini_spin = false
			else:
				spin_offset += int(spin_speed * ($"/root/Main/Options Sprite/Options".spin_speed + $"/root/Main/Options Sprite/Options".spin_speed_offset))
	if spinning:
		for i in range(icons.size()):
			icons[i].position.y = int(i * mod + spin_offset) % int(icons.size() * mod) - mod
	if hovering and (not OS.is_window_focused() or get_global_mouse_position().x < rect_global_position.x or get_global_mouse_position().x > rect_global_position.x + (rect_size.x + 8) or get_global_mouse_position().y < rect_global_position.y or get_global_mouse_position().y > rect_global_position.y + (rect_size.y + 8)):
		hovering = false
	elif not hovering and OS.is_window_focused() and not (get_global_mouse_position().x < rect_global_position.x or get_global_mouse_position().x > rect_global_position.x + (rect_size.x + 8) or get_global_mouse_position().y < rect_global_position.y or get_global_mouse_position().y > rect_global_position.y + (rect_size.y + 8)):
		hovering = true
	if $"/root/Main".press_timer > 0 and (((not ($"/root/Main".mouse_position.x < rect_global_position.x or $"/root/Main".mouse_position.x > rect_global_position.x + rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < rect_global_position.y or $"/root/Main".mouse_position.y > rect_global_position.y + rect_size.y * rect_scale.y)))):
		press()
	color = $"/root/Main/Options Sprite/Options".colors3["reels"]

func symbol_removal_effects():
	var removed_symbols = []
	var relevant_items = {}
	
	var symbol_types = {"egg": ["egg"], "coin": ["coin"], "rabbit_fluff": ["rabbit_fluff"], "goldfish": ["goldfish"], "dwarf": ["dwarf"], "clubs": ["clubs"], "diamonds": ["diamonds"], "hearts": ["hearts"], "spades": ["spades"]}
	
	var fp_20 = false
	var fp_21 = false

	for fp in $"/root/Main/Landlord".fine_print:
		if fp.num == 20:
			fp_20 = true
		elif fp.num == 21:
			fp_21 = true
	
	for s in $"/root/Main".modded_existing.symbols:
		if symbol_types.keys().has(s.substr(0, s.find("_STEAM_ID_"))):
			symbol_types[s.substr(0, s.find("_STEAM_ID_"))].push_back(s)
	
	for i in $"/root/Main/Items".item_types:
		var with_id = i
		i = i.substr(0, i.find("_STEAM_ID_"))
		for s in $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)].symbols_removed_pre_spin:
			if s.has("type"):
				for r in parent.reels:
					for icon in r.icons:
						if $"/root/Main".modded_existing_base_types.symbols.has(s.type):
							for t in $"/root/Main".modded_existing_base_types.symbols[s.type]:
								if icon.type == t:
									$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
									removed_symbols.push_back(icon.type)
									icon.change_type("empty", false)
									icon.prev_data.clear()
									$"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)].symbols_removed_this_spin += 1
						else:
							if icon.type == s.type:
								$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
								removed_symbols.push_back(icon.type)
								icon.change_type("empty", false)
								icon.prev_data.clear()
								$"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)].symbols_removed_this_spin += 1
			elif s.has("groups"):
				for r in parent.reels:
					for icon in r.icons:
						if $"/root/Main".modded_existing_base_types.symbols.has(s.type):
							for t in $"/root/Main".modded_existing_base_types.symbols[s.type]:
								if icon.groups.has(s.groups):
									$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
									removed_symbols.push_back(icon.type)
									icon.change_type("empty", false)
									icon.prev_data.clear()
									$"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)].symbols_removed_this_spin += 1
						else:
							if icon.groups.has(s.groups):
								$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
								removed_symbols.push_back(icon.type)
								icon.change_type("empty", false)
								icon.prev_data.clear()
								$"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)].symbols_removed_this_spin += 1
		if (i == "egg_carton" or i == "egg_carton_essence") and not fp_21:
			for r in parent.reels:
				for icon in r.icons:
					for t in symbol_types["egg"]:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
							icon.prev_data.clear()
		elif (i == "coin_on_a_string" or i == "coin_on_a_string_essence") and not fp_20:
			for r in parent.reels:
				for icon in r.icons:
					for t in symbol_types["coin"]:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
						icon.prev_data.clear()
		elif i == "flush" or i == "flush_essence":
			var tmp_arr = symbol_types["clubs"].duplicate(true) + symbol_types["diamonds"].duplicate(true) + symbol_types["hearts"].duplicate(true) + symbol_types["spades"].duplicate(true)
			for r in parent.reels:
				for icon in r.icons:
					for t in tmp_arr:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
							icon.prev_data.clear()
		elif i == "lint_roller" or i == "lint_roller_essence":
			for r in parent.reels:
				for icon in r.icons:
					for t in symbol_types["rabbit_fluff"]:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
							icon.prev_data.clear()
		elif i == "fish_bowl" or i == "fish_bowl_essence":
			for r in parent.reels:
				for icon in r.icons:
					for t in symbol_types["goldfish"]:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
							icon.prev_data.clear()
		elif i == "barrel_o_dwarves_essence":
			for r in parent.reels:
				for icon in r.icons:
					for t in symbol_types["dwarf"]:
						if icon.type == t:
							$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(icon.type)
							removed_symbols.push_back(icon.type)
							icon.change_type("empty", false)
							icon.prev_data.clear()
		else:
			continue
		relevant_items[i] = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(with_id)]
	for s in removed_symbols:
		if symbol_types["egg"].has(s):
			if relevant_items.has("egg_carton"):
				if relevant_items["egg_carton"].saved_value < relevant_items["egg_carton"].values[1]:
					relevant_items["egg_carton"].saved_value += relevant_items["egg_carton"].values[0]
			if relevant_items.has("egg_carton_essence"):
				relevant_items["egg_carton_essence"].value += relevant_items["egg_carton_essence"].values[1] * relevant_items["egg_carton_essence"].item_count
				relevant_items["egg_carton_essence"].saved_value += 1
		elif symbol_types["coin"].has(s):
			if relevant_items.has("coin_on_a_string"):
				relevant_items["coin_on_a_string"].value += relevant_items["coin_on_a_string"].values[1] * relevant_items["coin_on_a_string"].item_count
			if relevant_items.has("coin_on_a_string_essence"):
				relevant_items["coin_on_a_string_essence"].value += relevant_items["coin_on_a_string_essence"].values[1] * relevant_items["coin_on_a_string_essence"].item_count
				relevant_items["coin_on_a_string_essence"].saved_value += 1
		elif symbol_types["rabbit_fluff"].has(s):
			if relevant_items.has("lint_roller"):
				relevant_items["lint_roller"].value += relevant_items["lint_roller"].values[0] * relevant_items["lint_roller"].item_count
			if relevant_items.has("lint_roller_essence"):
				relevant_items["lint_roller_essence"].value += relevant_items["lint_roller_essence"].values[1]
				relevant_items["lint_roller_essence"].saved_value += 1
		elif symbol_types["clubs"].has(s) or symbol_types["diamonds"].has(s) or symbol_types["hearts"].has(s) or symbol_types["spades"].has(s):
			if relevant_items.has("flush"):
				relevant_items["flush"].value += relevant_items["flush"].values[0] * relevant_items["flush"].item_count
			if relevant_items.has("flush_essence"):
				relevant_items["flush_essence"].value += relevant_items["flush_essence"].values[1]
				relevant_items["flush_essence"].saved_value += 1
		elif symbol_types["goldfish"].has(s):
			if relevant_items.has("fish_bowl"):
				relevant_items["fish_bowl"].saved_value += relevant_items["fish_bowl"].values[0]
			if relevant_items.has("fish_bowl_essence"):
				relevant_items["fish_bowl_essence"].value += relevant_items["fish_bowl_essence"].values[1] * relevant_items["fish_bowl_essence"].item_count
				relevant_items["fish_bowl_essence"].saved_value += 1
		elif symbol_types["dwarf"].has(s):
			if relevant_items.has("barrel_o_dwarves_essence"):
				relevant_items["barrel_o_dwarves_essence"].value += relevant_items["barrel_o_dwarves_essence"].values[1] * relevant_items["barrel_o_dwarves_essence"].item_count
				relevant_items["barrel_o_dwarves_essence"].saved_value += 1
func press():
	if $"/root/Main/Pop-up Sprite/Pop-up".reels_to_select > 0 and $"/root/Main/Pop-up Sprite/Pop-up".offset_y == $"/root/Main/Pop-up Sprite/Pop-up".offset_top:
		if Steam.isSteamRunningOnSteamDeck():
			$"/root/Main".press_timer = 0
		$"/root/Main/Pop-up Sprite/Pop-up".reels_to_select -= 1
		parent.selected_reels.push_back(self)
		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
		if $"/root/Main/Pop-up Sprite/Pop-up".reels_to_select == 0:
			$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(null)

func load_base_icons():
	if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		var symbol_arr = []
		var tmp_symbol_arr = []
		if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.starting_symbols.has("base"):
			tmp_symbol_arr = ["coin", "cherry", "pearl", "flower", "cat"]
		for s in $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.starting_symbols:
			if s == "base":
				continue
			else:
				tmp_symbol_arr.push_back(s)
		for s in tmp_symbol_arr:
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(s):
				var t = s + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[s]
				if $"/root/Main".mod_pack_nums.has(t) and not $"/root/Main".is_mod_disabled(t + "_PACK_" + $"/root/Main".mod_pack_nums[t]):
					symbol_arr.push_back(t + "_PACK_" + $"/root/Main".mod_pack_nums[t])
				else:
					symbol_arr.push_back(s)
			else:
				symbol_arr.push_back(s)
		match symbol_arr.size():
			1:
				if reel_num == 2:
					icon_types = [null, symbol_arr[0]]
			2:
				match reel_num:
					1:
						icon_types = [null, null, symbol_arr[0]]
					3:
						icon_types = [null, null, symbol_arr[1]]
			3:
				match reel_num:
					1:
						icon_types = [null, null, symbol_arr[0]]
					2:
						icon_types = [null, symbol_arr[1]]
					3:
						icon_types = [null, null, symbol_arr[2]]
			4:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0]]
					1:
						icon_types = [null, null, symbol_arr[1]]
					3:
						icon_types = [null, null, symbol_arr[2]]
					4:
						icon_types = [null, symbol_arr[3]]
			5:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0]]
					1:
						icon_types = [null, null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2]]
					3:
						icon_types = [null, null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4]]
			6:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0]]
					1:
						icon_types = [null, null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2], null, symbol_arr[5]]
					3:
						icon_types = [null, null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4]]
			7:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4]]
			8:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2], null, symbol_arr[7]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4]]
			9:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2], null]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			10:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1]]
					2:
						icon_types = [null, symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			11:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1]]
					2:
						icon_types = [symbol_arr[10], symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			12:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [null, symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			13:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			14:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], null, symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], symbol_arr[13], symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [null, symbol_arr[4], null, symbol_arr[8]]
			15:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [null, symbol_arr[4], symbol_arr[14], symbol_arr[8]]
			16:
				match reel_num:
					0:
						icon_types = [null, symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], symbol_arr[15], symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [null, symbol_arr[4], symbol_arr[14], symbol_arr[8]]
			17:
				match reel_num:
					0:
						icon_types = [symbol_arr[15], symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [symbol_arr[16], symbol_arr[4], symbol_arr[14], symbol_arr[8]]
			18:
				match reel_num:
					0:
						icon_types = [symbol_arr[15], symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], null, symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], symbol_arr[17], symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], null, symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [symbol_arr[16], symbol_arr[4], symbol_arr[14], symbol_arr[8]]
			19:
				match reel_num:
					0:
						icon_types = [symbol_arr[15], symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], symbol_arr[17], symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], null, symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], symbol_arr[18], symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [symbol_arr[16], symbol_arr[4], symbol_arr[14], symbol_arr[8]]
			20:
				match reel_num:
					0:
						icon_types = [symbol_arr[15], symbol_arr[0], symbol_arr[13], symbol_arr[7]]
					1:
						icon_types = [symbol_arr[5], symbol_arr[17], symbol_arr[1], symbol_arr[10]]
					2:
						icon_types = [symbol_arr[12], symbol_arr[2], symbol_arr[19], symbol_arr[9]]
					3:
						icon_types = [symbol_arr[6], symbol_arr[18], symbol_arr[3], symbol_arr[11]]
					4:
						icon_types = [symbol_arr[16], symbol_arr[4], symbol_arr[14], symbol_arr[8]]
	elif not $"/root/Main".sandbox_mode:
		match reel_num:
			0:
				icon_types = [null, "coin"]
			1:
				if $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 7:
					icon_types = ["dud", null, "cherry"]
				else:
					icon_types = [null, null, "cherry"]
			2:
				if ($"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 5 and $"/root/Main/Pop-up Sprite/Pop-up".current_floor < 7) or $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 12:
					icon_types = [null, "pearl", null, "dud"]
				else:
					icon_types = [null, "pearl"]
			3:
				if $"/root/Main/Pop-up Sprite/Pop-up".current_floor >= 7:
					icon_types = ["dud", null, "flower"]
				else:
					icon_types = [null, null, "flower"]
			4:
				icon_types = [null, "cat"]
	for i in range(icon_types.size()):
		var t
		if $"/root/Main".modded_existing_base_types.symbols.has(icon_types[i]):
			var arr = $"/root/Main".modded_existing_base_types.symbols[icon_types[i]].duplicate(true)
			var tbe = []
			for a in arr:
				if $"/root/Main".is_mod_disabled(a):
					tbe.push_back(a)
			for a in tbe:
				arr.erase(a)
			if arr.size() > 0:
				randomize()
				t = arr[floor(rand_range(0, arr.size()))]
		if icon_types[i] == null:
			continue
		elif t != null:
			icon_types[i] = t
	load_icons()

func load_icons():
	if $"/root/Main".sandbox_icons.size() > 0 and $"/root/Main".sandbox_mode and $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor == null:
		icon_types = $"/root/Main".sandbox_icons[reel_num].duplicate(true)
	icons.resize(max_icons)
	icon_types.resize(max_icons)
	saved_icon_data.resize(max_icons)
	for i in range(max_icons):
		if icon_types[fposmod(i - 1, max_icons)] == null:
			icon_types[fposmod(i - 1, max_icons)] = "empty"
		elif $"/root/Main".is_mod_disabled(icon_types[fposmod(i - 1, max_icons)]):
			icon_types[fposmod(i - 1, max_icons)] = "missing"
		icons[i] = parent.generate_icon(str(icon_types[fposmod(i - 1, max_icons)]), saved_icon_data[fposmod(i - 1, max_icons)])
		icons[i].position.y = (i * mod + spin_offset) % (icons.size() * mod) - mod
		add_child(icons[i])
		icons[i].overwrite_values = false
		icons[i].change_type(str(icon_types[fposmod(i - 1, max_icons)]), false)
		icons[i].overwrite_values = true
		if $"/root/Main".sandbox_mode:
			icons[i].saved_value = 0
		if i <= parent.reel_height and i > 0:
			icons[i].active = true
			icons[i].visible = true
			icons[i].set_process_input(true)
			icons[i].update_value_text()
			icons[i].rotate(0)
			parent.displayed_icons[i - 1][reel_num] = icons[i]
		else:
			if max_icons > 20:
				icons[i].visible = false
			icons[i].active = false
			icons[i].set_process_input(false)

func add_tile(t):
	randomize()
	var empty_positions = []
	var visible_empties = []
	
	var num = 0
	var s = preload("res://Slot Icon.tscn").instance()
	s.in_reels = false
	add_child(s)

	var tmp = load("res://Outline Label.tscn").instance()
	add_child(tmp)

	for type in t:
		if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(type) and not $"/root/Main".is_mod_disabled($"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])):
			t[num] = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])
		num += 1
		for i in range(icons.size()):
			if icons[i].type == "empty":
				empty_positions.push_back(i)
				if icons[i].grid_position.y >= 0 and icons[i].grid_position.y <= parent.reel_height - 1:
					visible_empties.push_back(i)
		if visible_empties.size() > 0 and type != "empty":
			var empty_pos = floor(rand_range(0, visible_empties.size()))
			icons[visible_empties[empty_pos]].change_type(type, parent.checking_effects)
			icons[visible_empties[empty_pos]].active = true
			icon_types[visible_empties[empty_pos]] = type
			saved_icon_data[visible_empties[empty_pos]] = { "coins_earned": 0, "times_coins_given": 0, "times_displayed": 0, "permanent_bonus": 0, "reroll_token_permanent_bonus": 0, "removal_token_permanent_bonus": 0, "saved_value": 0, "saved_values": {} }
			icons[visible_empties[empty_pos]].update_value_text()
			if parent.queued_milk > 0 and type == "milk":
				parent.queued_milk -= 1
				icons[visible_empties[empty_pos]].added_by = "cow"
			elif parent.queued_banana_peels > 0 and type == "banana_peel":
				parent.queued_banana_peels -= 1
				icons[visible_empties[empty_pos]].added_by = "banana"
			elif parent.queued_honey > 0 and type == "honey":
				parent.queued_honey -= 1
				icons[visible_empties[empty_pos]].added_by = "beehive"
			elif parent.queued_seeds > 0 and type == "seed":
				parent.queued_seeds -= 1
				icons[visible_empties[empty_pos]].added_by = "peach"
		elif empty_positions.size() > 0 and type != "empty":
			var empty_pos = floor(rand_range(0, empty_positions.size()))
			icon_types[empty_positions[empty_pos]] = type
			icons[empty_positions[empty_pos]].change_type(type, false)
			saved_icon_data[empty_positions[empty_pos]] = { "coins_earned": 0, "times_coins_given": 0, "times_displayed": 0, "permanent_bonus": 0, "reroll_token_permanent_bonus": 0, "removal_token_permanent_bonus": 0, "saved_value": 0, "saved_values": {} }
		elif type != null:
			s.soft_changing = true
			s.type = type
			s.permanent_bonus = 0
			s.permanent_multiplier = 1
			s.change_type(type, false)
			icon_types_tba_bonus_texts.push_back([])
			if s.permanent_bonus > 0:
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + tmp.parse_num_str(str(s.permanent_bonus)) + "<end>")
			elif type == "eldritch_beast" and s.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * s.values[0] > 0:
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + tmp.parse_num_str(str(s.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * s.values[0])) + "<end>")
			else:
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("")
			if s.permanent_multiplier > 1:
				if s.permanent_multiplier >= 10:
					icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(round(s.permanent_multiplier))) + "x<end>")
				else:
					icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(stepify(s.permanent_multiplier, 0.1))) + "x<end>")
			else:
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back("")
			s.update_value_text()
			var color_break_num = str(s.get_child(1).raw_string).find(">")
			if color_break_num == -1:
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back(tmp.parse_num_str(str(s.get_child(1).raw_string)))
			else:
				var num_str = str(s.get_child(1).raw_string)
				icon_types_tba_bonus_texts[icon_types_tba_bonus_texts.size() - 1].push_back(num_str.substr(0, color_break_num + 1) + tmp.parse_num_str(num_str.substr(color_break_num + 1, num_str.length() - color_break_num - 6)) + "<end>")
			icon_types_to_be_added.push_back(type)
	remove_child(s)
	remove_child(tmp)
	s.queue_free()
	tmp.queue_free()
	$"/root/Main".write_log("Added symbols: " + str(t))
	empty_positions.clear()
	visible_empties.clear()

func save():
	var save_dict = {
		"path" : get_path(),
		"spinning": spinning,
		"max_icons": max_icons,
		"icon_types": icon_types,
		"icon_types_to_be_added": icon_types_to_be_added,
		"icon_types_tba_bonus_texts": icon_types_tba_bonus_texts,
		"saved_icon_data": saved_icon_data
	}
	return save_dict
