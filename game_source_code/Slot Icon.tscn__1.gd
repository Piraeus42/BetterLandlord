extends "res://Outline Icon.tscn::1"

var title
var text
var rarity
var groups

var value
var value_multiplier_arr = []
var value_bonus_arr = []
var final_value = 0
var non_flat_final_value = 0
var non_prev_final_value = 0
var flat_value_bonus = 0
var permanent_bonus = 0
var permanent_multiplier = 1

var reroll_token_value = 0
var reroll_token_value_multiplier_arr = []
var reroll_token_value_bonus_arr = []
var reroll_token_final_value = 0
var reroll_token_non_flat_final_value = 0
var reroll_token_flat_value_bonus = 0
var reroll_token_permanent_bonus = 0
var reroll_token_permanent_multiplier = 1

var removal_token_value = 0
var removal_token_value_multiplier_arr = []
var removal_token_value_bonus_arr = []
var removal_token_final_value = 0
var removal_token_non_flat_final_value = 0
var removal_token_flat_value_bonus = 0
var removal_token_permanent_bonus = 0
var removal_token_permanent_multiplier = 1

var essence_token_value = 0
var essence_token_value_multiplier_arr = []
var essence_token_value_bonus_arr = []
var essence_token_final_value = 0
var essence_token_non_flat_final_value = 0
var essence_token_flat_value_bonus = 0
var essence_token_permanent_bonus = 0
var essence_token_permanent_multiplier = 1

var prev_data = []
var t_prev_data = []
var prev_data_obj
var values
var sfx_values
var bonus_values = []
var bonus_value_multipliers = []
var destroyed = false
var removed = false
var dove_destroyed = false
var changed_value
var tbd = false
var anim_offset = Vector2(0, 0)
var base_offset
var offset_num = 0
var coins_earned = 0
var times_coins_given = 0
var times_displayed = 0
var saved_value = 0
var saved_values = {}
var reels
var hovering = false
var active = false
var selectable = true
var off_screen = false
var cant_go_dirs = []
var selector_alignment = "centered"
var rect_global_position
var rect_size
var indestructible = false
var dove_checker = false
var tried_to_give_rand_eff = false
var item_adding_effects = []
var tile_adding_effects = []
var getting_extra = false
var drained = false
var can_be_removed = true
var extra_textures = []
var current_effect
var texture_effect
var permanent_bonuses = null
var affected_symbols = []
var erased_effects = []
var erased_effect_hashes = []
var current_effect_hashes = []
var one_times = []
var pointing_directions = []
var void_arr = []
var destroyed_or_removed_by = []
var symbols_destroyed = []
var added_by = ""
var done_spinning = false
var wildcarded = false
var soft_changing = false
var being_destroyed = false
var gained_saved_achievement_value = false

var anim_targets = []
var queued_anims = []
var given_effects = []
var given_effect_hashes = []
var hex_effects = []
var dynamic_diff_targets = []
var queued_wc_increase = 0
var effect_hashes = []
var achievement_values = [0, 0, 0]
var saved_achievement_values = [0, 0, 0]

var tooltips
var items
var item_types
var items_destroyed_this_spin

var sfx_player
var displayed_text_value = ""
var displayed_multiplier_value = ""
var displayed_bonus_value = ""

var grid_position
var dummy = true
var modded = false
var inherit_effects = false
var inherit_art = false
var description = ""
var localized_descriptions = []
var localized_names = []
var inherited_effects = []
var manually_destroyed = false
var value_text = {}
var pdi = 0
var texture_type
var did_destroyed_anim = false
var flagged_for_empty_texture = false
var init_adj_icons = false
var destroyed_giver_on_destroy = false

var held = false
var delayed_sfx = []
var in_reels = true

var void_check = null
var fighting_boss = null
var hotfix_num = null
var symbols_in_inventory = null
var value_bonus = null
var value_multiplier = null
var extra_symbol_choices = null
var extra_item_choices = null
var symbols_to_choose_from = null
var items_to_choose_from = null
var forced_add = null
var forced_skip = null
var grid_position_x = null
var grid_position_y = null
var spins_left = 0
var coins = 0
var reroll_tokens = 0
var removal_tokens = 0
var essence_tokens = 0
var rent_due = 0
var sprite_after_anim = 0
var t_index = 0
var is_icon = true

var alignment_tags = {"bottom": false, "right": false, "centered": false, "v_centered": false}
var aligned = false
var saved_resolution = Vector2(1024, 576)

var overwrite_values = true
var tmp_fp_num = -1
var same_rand_adjacent_symbol

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
	if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type != "oil_can_prompt":
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
	if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		if (event is InputEventKey and event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["inspect"][0]) or (event is InputEventJoypadButton and event.button_index == $"/root/Main/Options Sprite/Options".hotkeys["inspect"][1]):
			if not $"/root/Main/Selector Sprite/Selector".visible:
				$"/root/Main/Selector Sprite/Selector".visible = true
			else:
				hover()
				if tooltips.get_children().size() > 0:
					$"/root/Main".down_keys["inspect"] = 1
					$"/root/Main".selected_node = tooltips.get_child(tooltips.get_children().size() - 1)
		elif (event is InputEventKey and event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["confirm_select"][0]) or (event is InputEventJoypadButton and event.button_index == $"/root/Main/Options Sprite/Options".hotkeys["confirm_select"][1]):
			if not $"/root/Main/Selector Sprite/Selector".visible:
				$"/root/Main/Selector Sprite/Selector".visible = true
			else:
				press()

func _ready():
	get_child(5).offset = Vector2(7, 7)
	get_child(1).dont_scale = true
	get_child(2).dont_scale = true
	get_child(3).dont_scale = true
	get_child(1).rtl = false
	get_child(2).rtl = false
	get_child(3).rtl = false
	update_scale()
	base_offset = get_child(5).offset
	tooltips = $"/root/Main/Tooltips"
	items = $"/root/Main/Items".items
	item_types = $"/root/Main/Items".item_types
	items_destroyed_this_spin = $"/root/Main/Items".items_destroyed_this_spin
	reels = $"/root/Main/Reels"
	if get_children().size() >= 3:
		get_child(1).overwrite_scale = true
		get_child(2).overwrite_scale = true
		get_child(3).overwrite_scale = true
		get_child(1).can_display_decimals = false
		get_child(3).can_display_decimals = false
		get_child(1).alignment_tags.dont = true
		get_child(2).alignment_tags.dont = true
		get_child(3).alignment_tags.dont = true
		get_child(1).remove_from_group("Pause Update 2")
		get_child(2).remove_from_group("Pause Update 2")
		get_child(3).remove_from_group("Pause Update 2")
		sfx_player = get_child(0)
	if get_parent().get_parent() == $"/root/Main/Reels":
		grid_position = Vector2(get_parent().reel_num, floor(position.y / (112 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui)))

func update_scale():
	var sc = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	get_child(5).scale = Vector2(8 * sc, 8 * sc)
	if get_children().size() >= 3:
		var mod = floor($"/root/Main/Options Sprite/Options".ui_scaling.reels_ui / 0.25) - 5
		for i in range(1, 4):
			get_child(i).overwrite_scale = true
			get_child(i).text_mod = mod
			get_child(i).change_set_size(get_child(1).base_scale)
		rotate(0)

func press():
	if $"/root/Main/Pop-up Sprite/Pop-up".offset_y == $"/root/Main/Pop-up Sprite/Pop-up".offset_top:
		if Steam.isSteamRunningOnSteamDeck():
			$"/root/Main".press_timer = 0
		if $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_select > 0 and reels.selected_icons.has(self):
			$"/root/Main/Pop-up Sprite/Pop-up".symbols_to_select += 1
			reels.selected_icons.erase(self)
			stop_animations()
		elif $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_select > 0:
			$"/root/Main/Pop-up Sprite/Pop-up".symbols_to_select -= 1
			reels.selected_icons.push_back(self)
			queued_anims.push_back({"anim_type": "circle", "anim_timer": 100000, "anim_texture": type, "anim_comps": [], "anim_vtc": null, "giver_texture": null, "giver": null, "unconditional": false, "ignore_speed": true})
			for t in $"/root/Main/Tooltips".get_children():
				t.queue_free()
			if $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_select == 0:
				$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(null)
		elif $"/root/Main/Pop-up Sprite/Pop-up".reels_to_select > 0:
			get_parent().press()

func rotate(degrees):
	var font_mod
	var r_text
	var c_scale = $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui
	if $"/root/Main/Options Sprite/Options".CJK_lang or get_child(2).forced_font != null or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		font_mod = 1.0
		r_text = get_child(2).get_child(0).text
	else:
		font_mod = 4.0
		r_text = get_child(2).text
	match degrees:
		90:
			get_child(5).offset = Vector2(7, -7)
			get_child(1).rect_position = Vector2(0, -6 * c_scale)
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				get_child(2).rect_position = Vector2(0, -round(112 * c_scale - get_child(2).get_child(0).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod))
			else:
				get_child(2).rect_position = Vector2(0, -round(108 * c_scale - get_child(2).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod))
			get_child(3).rect_position = Vector2(80 * c_scale, -6 * c_scale)
		180:
			get_child(5).offset = Vector2(-7, -7)
			get_child(1).rect_position = Vector2(-6 * c_scale, 0)
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				get_child(2).rect_position = Vector2(-round(112 * c_scale - get_child(2).get_child(0).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod), 0)
			else:
				get_child(2).rect_position = Vector2(-round(108 * c_scale - get_child(2).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod), 0)
			get_child(3).rect_position = Vector2(-6 * c_scale, -80 * c_scale)
		270:
			get_child(5).offset = Vector2(-7, 7)
			get_child(1).rect_position = Vector2(0, 6 * c_scale)
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				get_child(2).rect_position = Vector2(0, round(112 * c_scale - get_child(2).get_child(0).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod))
			else:
				get_child(2).rect_position = Vector2(0, round(108 * c_scale - get_child(2).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod))
			get_child(3).rect_position = Vector2(-80 * c_scale, 6 * c_scale)
		_:
			get_child(5).offset = Vector2(7, 7)
			get_child(1).rect_position = Vector2(6 * c_scale, 0)
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				get_child(2).rect_position = Vector2(round(112 * c_scale - get_child(2).get_child(0).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod), 0)
			else:
				get_child(2).rect_position = Vector2(round(108 * c_scale - get_child(2).get_font("font").get_string_size(r_text).x * get_child(2).current_scale * font_mod), 0)
			get_child(3).rect_position = Vector2(6 * c_scale, 80 * c_scale)
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		get_child(1).rect_position.y += 2
		get_child(2).rect_position.y += 2
		get_child(3).rect_position.y += 2
	rotation_degrees = degrees
	base_offset = get_child(5).offset
	get_child(1).rect_rotation = -degrees
	get_child(2).rect_rotation = -degrees
	get_child(3).rect_rotation = -degrees

func change_type(p_type, need_cond_effects):
	if not is_inside_tree() and in_reels:
		return
	var symbol
	if not $"/root/Main".tile_database.has(p_type):
		p_type = "missing"
	symbol = $"/root/Main".tile_database[p_type]
	if in_reels:
		get_parent().icon_types[grid_position.y] = p_type
	
	var prev_destroyed_state = destroyed
	var prev_removed_state = removed
	
	if not soft_changing:
		if p_type != "empty" or prev_removed_state:
			if not prev_removed_state:
				did_destroyed_anim = false
			if reels.symbol_queue.size() == 0:
				reels.type_changed = true
			destroyed = false
			dove_destroyed = false
			tile_adding_effects.clear()
			item_adding_effects.clear()
		elif current_effect != null and current_effect.has("value_to_change") and current_effect.value_to_change == "removed":
			reels.type_changed = true
		removed = false
		tbd = false
		
		if need_cond_effects:
			var c_effects = reels.conditional_effects[grid_position.y][grid_position.x]
			if current_effect != null:
				var cleaned_c = get_cleaned_effect(current_effect)
				erased_effects.push_back(cleaned_c)
				erased_effect_hashes.push_back(cleaned_c.hash())
				current_effect_hashes.erase(cleaned_c.hash())
				if given_effect_hashes.find(get_cleaned_effect(current_effect).hash()) != -1:
					given_effects.remove(given_effect_hashes.find(get_cleaned_effect(current_effect).hash()))
				given_effect_hashes.erase(cleaned_c.hash())
				if current_effect.has("giver"):
					hex_effects.erase(current_effect)
				for c in c_effects:
					if c.hash() == current_effect.hash():
						c_effects.erase(c)
						break
			reels.change_type_checking = true
			check_conditional_effects(c_effects)
			reels.change_type_checking = false
			changed_value = true
		
		var p_pdi = -1
		
		for p in prev_data:
			if p.type == p_type and (current_effect == null or p.effect_hashes.has(get_prev_cleaned_effect(current_effect).hash())):
				p_pdi += 1
		
		var p_obj = {"type": type, "destroyed": prev_destroyed_state, "final_value": get_value("coin"), "non_flat_final_value": get_non_flat_value("coin"), "value": value, "value_multiplier_arr": value_multiplier_arr.duplicate(true), "value_bonus_arr": value_bonus_arr.duplicate(true), "flat_value_bonus": flat_value_bonus, "permanent_bonus": permanent_bonus, "permanent_multiplier": permanent_multiplier, "non_prev_final_value": get_non_prev_value("coin"), "wildcarded": wildcarded, "effect_hashes": [], "reroll_token_value": reroll_token_value, "reroll_token_value_multiplier_arr": reroll_token_value_multiplier_arr.duplicate(true), "reroll_token_value_bonus_arr": reroll_token_value_bonus_arr.duplicate(true), "reroll_token_final_value": get_value("reroll_token"), "reroll_token_non_flat_final_value": get_non_flat_value("reroll_token"), "reroll_token_flat_value_bonus": reroll_token_flat_value_bonus, "reroll_token_permanent_multiplier": reroll_token_permanent_multiplier, "reroll_token_permanent_bonus": reroll_token_permanent_bonus, "removal_token_value": removal_token_value, "removal_token_value_multiplier_arr": removal_token_value_multiplier_arr.duplicate(true), "removal_token_value_bonus_arr": removal_token_value_bonus_arr.duplicate(true), "removal_token_final_value": get_value("removal_token"), "removal_token_non_flat_final_value": get_non_flat_value("removal_token"), "removal_token_flat_value_bonus": removal_token_flat_value_bonus, "removal_token_permanent_bonus": removal_token_permanent_bonus, "removal_token_permanent_multiplier": removal_token_permanent_multiplier, "essence_token_value": essence_token_value, "essence_token_value_multiplier_arr": essence_token_value_multiplier_arr.duplicate(true), "essence_token_value_bonus_arr": essence_token_value_bonus_arr.duplicate(true), "essence_token_final_value": get_value("essence_token"), "essence_token_non_flat_final_value": get_non_flat_value("essence_token"), "essence_token_flat_value_bonus": essence_token_flat_value_bonus, "essence_token_permanent_bonus": essence_token_permanent_bonus, "essence_token_permanent_multiplier": essence_token_permanent_multiplier, "removed": prev_removed_state, "can_be_removed": can_be_removed, "indestructible": indestructible, "sprite_after_anim": sprite_after_anim, "grid_position": grid_position, "void_arr": void_arr, "times_displayed": times_displayed, "times_coins_given": times_coins_given, "getting_extra": getting_extra, "tbd": tbd, "saved_value": saved_value, "saved_values": saved_values, "sfx_values": sfx_values, "pdi": p_pdi, "modded": modded, "inherit_effects": inherit_effects, "inherited_effects": inherited_effects, "rarity": rarity, "destroyed_or_removed_by": destroyed_or_removed_by.duplicate(true), "achievement_values": achievement_values, "saved_achievement_values": saved_achievement_values, "symbols_destroyed": symbols_destroyed, "added_by": added_by, "pointing_directions": pointing_directions, "affected_symbols": affected_symbols}
		
		if need_cond_effects or being_destroyed:
			for e in erased_effects:
				p_obj.effect_hashes.push_back(get_prev_cleaned_effect(e).hash())
			if current_effect != null:
				p_obj.effect_hashes.push_back(get_prev_cleaned_effect(current_effect).hash())
			prev_data.push_back(p_obj)
			
		if overwrite_values:
			coins_earned = 0
			times_coins_given = 0
			if reels.checking_effects and (symbol.rarity != "none" or symbol.modded):
				times_displayed = 1
			else:
				times_displayed = 0
			saved_value = 0
			saved_values = {}
			permanent_bonus = 0
			reroll_token_permanent_bonus = 0
			removal_token_permanent_bonus = 0
			essence_token_permanent_bonus = 0
			permanent_multiplier = 1
			reroll_token_permanent_multiplier = 1
			removal_token_permanent_multiplier = 1
			essence_token_permanent_multiplier = 1
		indestructible = false
		dove_checker = false
		tried_to_give_rand_eff = false
		sprite_after_anim = 0
		gained_saved_achievement_value = false
		destroyed_giver_on_destroy = false
		same_rand_adjacent_symbol = null
		affected_symbols.clear()
		
		var unconditionals = [[], []]
		
		for v in value_multiplier_arr:
			if v.unconditional:
				unconditionals[0].push_back(v)
				if not v.source_eff.has("from_item") and (p_type == "amethyst" or p_type == "pear"):
					if v.giver.type == "buffing_powder":
						var multi = $"/root/Main".tile_database[p_type].values[0]
						var cm_num = item_types.find("capsule_machine")
						var cme_num = item_types.find("capsule_machine_essence")
						if cm_num != -1:
							multi *= items[cm_num].values[0]
						if cme_num != -1:
							multi *= items[cme_num].values[0]
						permanent_bonus += multi
						v.giver.achievement_values[0] += 1
						if v.giver.achievement_values[0] >= 2:
							reels.add_queued_achievement(20)
					else:
						permanent_bonus += $"/root/Main".tile_database[p_type].values[0]
					if p_type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
						reels.add_queued_achievement(0)
					elif p_type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
						reels.add_queued_achievement(107)
		for v in value_bonus_arr:
			if v.unconditional:
				unconditionals[1].push_back(v)
				if not v.source_eff.has("from_item") and (p_type == "amethyst" or p_type == "pear"):
					if v.giver.type == "buffing_powder":
						var multi = $"/root/Main".tile_database[p_type].values[0]
						var cm_num = item_types.find("capsule_machine")
						var cme_num = item_types.find("capsule_machine_essence")
						if cm_num != -1:
							multi *= items[cm_num].values[0]
						if cme_num != -1:
							multi *= items[cme_num].values[0]
						permanent_bonus += multi
						v.giver.achievement_values[0] += 1
						if v.giver.achievement_values[0] >= 2:
							reels.add_queued_achievement(20)
					else:
						permanent_bonus += $"/root/Main".tile_database[p_type].values[0]
					if p_type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
						reels.add_queued_achievement(0)
					elif p_type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
						reels.add_queued_achievement(107)
		value_multiplier_arr = unconditionals[0]
		value_bonus_arr = unconditionals[1]
		symbols_destroyed.clear()
		if type != "tomb" and type != "oyster" and type != "pearl" and type != "anchor":
			destroyed_or_removed_by.clear()
			achievement_values = [0, 0, 0]
		saved_achievement_values = [0, 0, 0]
		added_by = ""
		get_child(1).visible = true
		get_child(2).visible = true
		get_child(3).visible = true
	
	if p_type == "dud":
		can_be_removed = false
	else:
		can_be_removed = true
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.dynamic_icon != null and p_type == fp.dynamic_icon:
				match int(fp.num):
					10:
						indestructible = true
						break
					36:
						indestructible = true
						can_be_removed = false
						break
			else:
				match int(fp.num):
					20:
						if p_type == "coin":
							can_be_removed = false
							break
					21:
						if p_type == "egg":
							can_be_removed = false
							break
	
	modded = symbol.modded
	
	if modded:
		inherit_effects = symbol.inherit_effects
		description = symbol.description
		localized_descriptions = symbol.localized_descriptions
		localized_names = symbol.localized_names
		value_text = symbol.value_text
		inherited_effects = symbol.inherited_effects
	else:
		inherit_effects = false
	
	type = symbol.type
	
	rarity = symbol.rarity
	
	value = int(symbol.value)
	final_value = (value + permanent_bonus) * permanent_multiplier
	non_flat_final_value = (value + permanent_bonus) * permanent_multiplier
	non_prev_final_value = (value + permanent_bonus) * permanent_multiplier
	
	reroll_token_value = 0
	reroll_token_final_value = (reroll_token_value + reroll_token_permanent_bonus) * reroll_token_permanent_multiplier
	reroll_token_non_flat_final_value = (reroll_token_value + reroll_token_permanent_bonus) * reroll_token_permanent_multiplier
	reroll_token_value_multiplier_arr.clear()
	reroll_token_value_bonus_arr.clear()
	
	removal_token_value = 0
	removal_token_final_value = (removal_token_value + removal_token_permanent_bonus) * removal_token_permanent_multiplier
	removal_token_non_flat_final_value = (removal_token_value + removal_token_permanent_bonus) * removal_token_permanent_multiplier
	removal_token_value_multiplier_arr.clear()
	removal_token_value_bonus_arr.clear()
	
	essence_token_value = 0
	essence_token_final_value = (essence_token_value + essence_token_permanent_bonus) * essence_token_permanent_multiplier
	essence_token_non_flat_final_value = (essence_token_value + essence_token_permanent_bonus) * essence_token_permanent_multiplier
	essence_token_value_multiplier_arr.clear()
	essence_token_value_bonus_arr.clear()
	
	pointing_directions.clear()
	
	wildcarded = false
	values = [0, 0, 0, 0]
	sfx_values = symbol.sfx.duplicate(true)
	for v in range(symbol.values.size()):
		if v >= 4:
			values.push_back(symbol.values[v])
		else:
			values[v] = symbol.values[v]
	groups = symbol.groups
	
	bonus_values.clear()
	bonus_value_multipliers.clear()
	
	for v in range(values.size()):
		bonus_values.push_back(0)
		bonus_value_multipliers.push_back(1)
	
	t_prev_data.clear()
	
	if overwrite_values:
		add_init_permanent_bonuses()
	
	extra_textures.clear()
	
	var pack_num = ""
	var steam_id = ""
	for m in $"/root/Main".mod_packs.keys():
		for t in $"/root/Main".mod_packs[m]:
			if t.type.substr(0, t.type.find_last("_")) == type and t.mod_type == "art_replacement":
				pack_num = "_" + str(m)
				steam_id = str(t.author_id)
				break
		if pack_num != "":
			break
	
	var d5 = $"/root/Main".get_appended_steam_id("d5", "symbol")
	var d3 = $"/root/Main".get_appended_steam_id("d3", "symbol")
	var bronze_arrow = $"/root/Main".get_appended_steam_id("bronze_arrow", "symbol")
	var silver_arrow = $"/root/Main".get_appended_steam_id("silver_arrow", "symbol")
	var golden_arrow = $"/root/Main".get_appended_steam_id("golden_arrow", "symbol")
	
	match type:
		d5:
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 6):
				if $"/root/Main".is_mod_disabled("dice" + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num) or pack_num == "" or steam_id == "":
					extra_textures.push_back(texture_db["dice" + str(i)])
				else:
					extra_textures.push_back(texture_db["dice" + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num])
		d3:
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 4):
				if $"/root/Main".is_mod_disabled("d3_" + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num) or pack_num == "" or steam_id == "":
					extra_textures.push_back(texture_db["d3_" + str(i)])
				else:
					extra_textures.push_back(texture_db["d3_" + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num])
		bronze_arrow, silver_arrow, golden_arrow:
			var texture_db = $"/root/Main".icon_texture_database
			for i in range(1, 9):
				if $"/root/Main".is_mod_disabled(type + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num) or pack_num == "" or steam_id == "":
					extra_textures.push_back(texture_db[type + str(i)])
				else:
					extra_textures.push_back(texture_db[type.substr(0, type.find("_STEAM_ID_")) + str(i) + "_STEAM_ID_" + steam_id + "_PACK" + pack_num])
		_:
			if modded:
				var texture_db = $"/root/Main".icon_texture_database
				for i in texture_db:
					var digit_pos = type.find("_STEAM_ID_")
					if i.substr(0, digit_pos) + i.substr(digit_pos + 1, -1) == type.substr(0, type.find("_PACK_")):
						var digit = int(i[i.find("_STEAM_ID_") - 1])
						if extra_textures.size() < digit:
							extra_textures.resize(digit)
						extra_textures[digit - 1] = texture_db[i]
						
	if in_reels and (need_cond_effects or being_destroyed):
		reels.conditional_effects[grid_position.y][grid_position.x].clear()
	given_effects.clear()
	given_effect_hashes.clear()
	erased_effects.clear()
	erased_effect_hashes.clear()
	current_effect_hashes.clear()
	one_times.clear()
	
	add_c_effs(need_cond_effects)
	
	if ((not need_cond_effects or prev_destroyed_state or prev_removed_state) and texture_effect == null and (type != "empty" or prev_removed_state)) or soft_changing or reels.symbol_queue.size() > 0 or reels.reels[reels.reels.size() - 1].spin_delay == reels.reels[reels.reels.size() - 1].max_spin_delay:
		get_child(5).texture = $"/root/Main".get_replacement_texture(type)
		texture_effect = null
		if prev_data.size() and prev_data[prev_data.size() - 1].type != "empty" and need_cond_effects and not prev_removed_state:
			get_child(5).texture = $"/root/Main".get_replacement_texture(prev_data[prev_data.size() - 1].type)
	current_effect = null
	
	get_child(1).update()
	get_child(2).update()
	get_child(3).update()

func add_c_effs(need_cond_effects):
	if need_cond_effects:
		reels.add_symbol_position_to_update(grid_position)
		add_conditional_effects()
	if need_cond_effects:
		reels.add_symbol_position_to_update(grid_position)
		for adj_icon in get_adjacent_icons():
			reels.add_symbol_position_to_update(adj_icon.grid_position)
			adj_icon.add_conditional_effects()
			adj_icon.update_value_text()
		if type == "flower" or type == "seed" or $"/root/Main".group_database.symbols["night"].has(type):
			var clear_sky_essence = false
			if $"/root/Main/Items".has_unmodded_item("clear_sky") or items_destroyed_this_spin.has("clear_sky_essence") or $"/root/Main/Items".destroyed_item_types.has("clear_sky_essence"):
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x].type == "sun" or reels.displayed_icons[y][x].type == "moon":
							reels.add_symbol_position_to_update(Vector2(x, y))
						else:
							for p in reels.displayed_icons[y][x].prev_data:
								if p.type == "sun" or p.type == "moon":
									reels.add_symbol_position_to_update(Vector2(x, y))
									break

func destroy():
	var target = self
	if not target.destroyed and target.type != "empty":
		target.tbd = false
		target.changed_value = true
		target.destroyed = true
		$"/root/Main/Reels".destroyed_symbols.push_back(target.type)
		$"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.push_back(target.type)
		$"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types_size = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.size()
		$"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin += 1.0
		$"/root/Main/Pop-up Sprite/Pop-up".compost_heap_symbols_destroyed += 1
		if $"/root/Main".group_database.symbols["fossillikes"].has(target.type):
			$"/root/Main/Pop-up Sprite/Pop-up".fossil_diff += 1.0
		target.being_destroyed = true
		target.change_type("empty", false)
		target.being_destroyed = false

func update():
	rect_global_position = global_position
	rect_size = Vector2((get_child(5).texture.get_size().x + 2) * get_child(5).scale.x, (get_child(5).texture.get_size().y + 2) * get_child(5).scale.y)
	selectable = active and not reels.effects_playing and not reels.spinning and ($"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0 or ($"/root/Main/Pop-up Sprite/Pop-up".emails[0].prompt and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type != "inventory" and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type != "removal_token_prompt")) and not $"/root/Main/Options Sprite/Options".visible and type != "empty"
	if is_inside_tree() and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and $"/root/Main/Selector Sprite/Selector".visible:
		tts()
	if selectable and $"/root/Main".hide_selector and is_processing_input():
		if hovering and (not OS.is_window_focused() or get_global_mouse_position().x < global_position.x + get_child(5).scale.x or get_global_mouse_position().x > global_position.x + (get_child(5).texture.get_size().x + 1) * get_child(5).scale.x or get_global_mouse_position().y < global_position.y + get_child(5).scale.y or get_global_mouse_position().y > global_position.y + (get_child(5).texture.get_size().y + 1) * get_child(5).scale.y):
			unhover()
			hovering = false
		elif not hovering and OS.is_window_focused() and not (get_global_mouse_position().x < global_position.x + get_child(5).scale.x or get_global_mouse_position().x > global_position.x + (get_child(5).texture.get_size().x + 1) * get_child(5).scale.x or get_global_mouse_position().y < global_position.y + get_child(5).scale.y or get_global_mouse_position().y > global_position.y + (get_child(5).texture.get_size().y + 1) * get_child(5).scale.y):
			hover()
		if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type != "oil_can_prompt":
			if $"/root/Main".press_timer > 0 and (((not ($"/root/Main".mouse_position.x < global_position.x or $"/root/Main".mouse_position.x > global_position.x + get_child(5).texture.get_size().x * get_child(5).scale.x or $"/root/Main".mouse_position.y < global_position.y or $"/root/Main".mouse_position.y > global_position.y + get_child(5).texture.get_size().y * get_child(5).scale.y)))):
				press()
	if queued_anims.size() > 0:
		if not queued_anims[0].ignore_speed and $"/root/Main/Options Sprite/Options".animation_speed + $"/root/Main/Options Sprite/Options".animation_speed_offset >= 1:
			for i in range($"/root/Main/Options Sprite/Options".animation_speed + $"/root/Main/Options Sprite/Options".animation_speed_offset - 1):
				animate()
		if $"/root/Main/Options Sprite/Options".animation_speed == 0 and not queued_anims[0].ignore_speed:
			while queued_anims.size() > 0:
				animate()
		elif $"/root/Main/Options Sprite/Options".animation_speed + $"/root/Main/Options Sprite/Options".animation_speed_offset < 1:
			if $"/root/Main/Options Sprite/Options".animation_speed == 0.75:
				if $"/root/Main".frame_timer % 3 != 0:
					animate()
			elif $"/root/Main/Options Sprite/Options".animation_speed == 0.5:
				if $"/root/Main".frame_timer % 2 != 0:
					animate()
			else:
				animate()
		else:
			animate()
	if delayed_sfx.size() > 0 and reels.sfx_timer == 0:
		play_sfx(delayed_sfx[0][0], delayed_sfx[0][1])
		delayed_sfx.remove(0)

func play_sfx(symbol, sfx_type):
	if $"/root/Main/Options Sprite/Options".animation_speed == 0 and reels.sfx_timer > 0:
		delayed_sfx.push_back([symbol, sfx_type])
		return
	
	var player = symbol.sfx_player
	var sfx_total_num = 0
	var db = $"/root/Main".sfx_database
	
	if db.has(sfx_type):
		sfx_total_num = db[sfx_type]
	
	var sfx_string = sfx_type + str(floor(rand_range(0, sfx_total_num)))
	var sfx = load("res://sfx/%s.wav" % str(sfx_string))
	
	if sfx == null:
		sfx = $"/root/Main/Music Player".loadfile($"/root/Main".modded_sfx_paths[sfx_type] + str(sfx_string) + ".wav")
	
	if sfx != null:
		player.set_stream(sfx)
		if sfx_type == "dogpet":
			player.stream.loop_begin = 15159
			player.stream.loop_end = 46494
		elif sfx_type == "jumploop":
			player.stream.loop_begin = 0
			player.stream.loop_end = 4114
		else:
			player.stream.loop_begin = 0
			player.stream.loop_end = 0
		player.volume_db = $"/root/Main/Options Sprite/Options".sfx.goal_volume
		if player.volume_db > -80 and not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not $"/root/Main".window_focus):
			player.play()
			reels.sfx_timer = 1

func start_animation(anim):
	var anim_timer = 0
	
	match anim.anim:
		"circle":
			anim_timer = 35
		"rotate":
			anim_timer = 33
		"bounce":
			anim_timer = 31
		"shake":
			anim_timer = 17
		"rand_texture_cycle":
			anim_timer = 17
		"ordered_texture_cycle":
			anim_timer = 30
	var vtc
	var gt
	var g
	if anim.has("value_to_change"):
		vtc = anim.value_to_change
	if anim.has("giver_texture"):
		gt = anim.giver_texture
		g = anim.giver
	queued_anims.push_front({"anim_type": anim.anim, "anim_timer": anim_timer, "anim_texture": anim.anim_texture, "anim_comps": anim.comparisons, "anim_vtc": vtc, "giver_texture": gt, "giver": g, "unconditional": anim.has("unconditional"), "ignore_speed": false})
	if anim.has("anim_result"):
		queued_anims[0]["anim_result"] = anim.anim_result - 1

func animate():
	var d5 = $"/root/Main".get_appended_steam_id("d5", "symbol")
	var d3 = $"/root/Main".get_appended_steam_id("d3", "symbol")
	var bronze_arrow = $"/root/Main".get_appended_steam_id("bronze_arrow", "symbol")
	var silver_arrow = $"/root/Main".get_appended_steam_id("silver_arrow", "symbol")
	var golden_arrow = $"/root/Main".get_appended_steam_id("golden_arrow", "symbol")
	if queued_anims.size() > 0 and queued_anims[0].anim_timer > 0:
		var anim_t
		if $"/root/Main/Options Sprite/Options".animation_speed == 0 and not queued_anims[0].ignore_speed:
			queued_anims[0].anim_timer = 0
			anim_t = 0
		else:
			queued_anims[0].anim_timer -= 1
			anim_t = queued_anims[0].anim_timer
			if queued_anims[0].has("dog_petting"):
				$"/root/Main/Stats Sprite/Stats".add_stat("time_spent_petting_dog", $"/root/Main/Pop-up Sprite/Pop-up".current_floor, 1.0 / 3600.0, false)
			elif queued_anims[0].has("rabbit_petting"):
				$"/root/Main/Stats Sprite/Stats".add_stat("rabbit_hops", $"/root/Main/Pop-up Sprite/Pop-up".current_floor, 3.0 / 31.0, false)
		if queued_anims[0].giver != null and queued_anims[0].giver == self and queued_anims[0].giver_texture != "empty":
			get_child(5).texture = $"/root/Main".get_replacement_texture(queued_anims[0].giver_texture)
		else:
			var can_break = false
			for a in queued_anims[0].anim_comps:
				if (typeof(a.a) == TYPE_STRING and ((a.a == "type" and a.b == type) or (a.a == "groups" and $"/root/Main".group_database.symbols[a.b].has(type))) or queued_anims[0].unconditional) and type != "empty" and type != d5 and type != d3 and type != bronze_arrow and type != silver_arrow and type != golden_arrow and queued_anims[0].anim_type != "rand_texture_cycle" and queued_anims[0].anim_type != "ordered_texture_cycle":
					get_child(5).texture = $"/root/Main".get_replacement_texture(type)
					can_break = true
					break
			if not can_break:
				for p in range(prev_data.size()):
					for a in queued_anims[0].anim_comps:
						if (typeof(a.a) == TYPE_STRING and (((a.a == "type" and a.b == prev_data[prev_data.size() - 1 - p].type) or (a.a == "groups" and $"/root/Main".group_database.symbols[a.b].has(prev_data[prev_data.size() - 1 - p].type)))) or queued_anims[0].unconditional) and prev_data[prev_data.size() - 1 - p].type != "empty":
							get_child(5).texture = $"/root/Main".get_replacement_texture(prev_data[prev_data.size() - 1 - p].type)
							can_break = true
							break
					if can_break:
						break
		if texture != $"/root/Main".get_replacement_texture("empty"):
			match queued_anims[0].anim_type:
				"circle":
					if anim_t % 2 == 0:
						var x = -1
						var y = -1
						if queued_anims[0].anim_timer > 0:
							offset_num += 1
						else:
							offset_num = 0
							x = 0
							y = 0
						match offset_num % 8:
							1:
								x = 0
							2:
								x = 1
							3:
								x = 1
								y = 0
							4:
								x = 1
								y = 1
							5:
								x = 0
								y = 1
							6:
								x = -1
								y = 1
							7:
								x = -1
								y = 0
						
						anim_offset = Vector2(x, y)
						get_child(5).offset = Vector2(base_offset.x + anim_offset.x, base_offset.y + anim_offset.y)
				"rotate":
					if anim_t % 2 == 0:
						rotate((int((33 - queued_anims[0].anim_timer) / 4) % 4) * 90)
				"bounce":
					if anim_t % 2 == 0:
						get_child(5).offset.y = base_offset.y - (int(queued_anims[0].anim_timer / 2) % 5)
				"shake":
					if anim_t % 2 == 0:
						anim_offset = Vector2(floor(rand_range(-1, 2)), floor(rand_range(-1, 2)))
						get_child(5).offset = Vector2(base_offset.x + anim_offset.x, base_offset.y + anim_offset.y)
				"rand_texture_cycle":
					if anim_t % 2 == 0:
						if queued_anims[0].anim_timer == 0:
							match type:
								d5:
									for v in value_bonus_arr:
										if v.source.type == d5 and (not v.source_eff.has("from_item") or (v.source_eff.has("from_item") and (v.source_eff.from_item == "reroll" or v.source_eff.from_item == "reroll_essence"))) and v.value > 0:
											get_child(5).texture = extra_textures[int(v.value) - 1]
											sprite_after_anim = int(v.value)
											if ((not $"/root/Main/Items".has_unmodded_item("reroll") and not $"/root/Main/Items".has_unmodded_item("reroll_essence")) or tried_to_give_rand_eff) and int(v.value) == 1:
												for x in range(reels.reel_width):
													for y in range(reels.reel_height):
														if reels.displayed_icons[y][x].type == "gambler":
															reels.add_symbol_position_to_update(Vector2(x, y))
															add_effect_to_symbol(y, x, {"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["gambler"], "not_prev": true}, {"a": "destroyed", "b": false, "not_prev": true}], "anim": "shake", "value_to_change": "destroyed", "giver": reels.displayed_icons[y][x], "diff": true})
															add_effect_to_symbol(y, x, {"comparisons": [{"a": "type", "b": "gambler"}, {"a": "tbd", "b": true}], "value_to_change": "achievement_value", "value_num": 0, "target": v.source, "diff": 1})
											break
									if tried_to_give_rand_eff:
										if $"/root/Main/Items".has_unmodded_item("reroll_essence"):
											items[item_types.find("reroll_essence")].saved_value += 1
								d3:
									for v in value_bonus_arr:
										if v.source.type == d3 and (not v.source_eff.has("from_item") or (v.source_eff.has("from_item") and (v.source_eff.from_item == "reroll" or v.source_eff.from_item == "reroll_essence"))) and v.value > 0:
											get_child(5).texture = extra_textures[int(v.value) - 1]
											sprite_after_anim = int(v.value)
											if ((not $"/root/Main/Items".has_unmodded_item("reroll") and not $"/root/Main/Items".has_unmodded_item("reroll_essence")) or tried_to_give_rand_eff) and int(v.value) == 1:
												for x in range(reels.reel_width):
													for y in range(reels.reel_height):
														if reels.displayed_icons[y][x].type == "gambler":
															reels.add_symbol_position_to_update(Vector2(x, y))
															add_effect_to_symbol(y, x, {"comparisons": [{"a": "type", "b": "gambler", "not_prev": true}, {"a": "destroyed", "b": false, "not_prev": true}], "anim": "shake", "value_to_change": "destroyed", "giver": reels.displayed_icons[y][x], "diff": true})
															add_effect_to_symbol(y, x, {"comparisons": [{"a": "type", "b": "gambler"}, {"a": "tbd", "b": true}], "value_to_change": "achievement_value", "value_num": 0, "target": v.source, "diff": 1})
											break
									if tried_to_give_rand_eff:
										if $"/root/Main/Items".has_unmodded_item("reroll_essence"):
											items[item_types.find("reroll_essence")].saved_value += 1
								_:
									if extra_textures.size() > 0:
										randomize()
										var texture_arr = extra_textures.duplicate(true)
										texture_arr.erase(texture)
										var n = floor(rand_range(0, texture_arr.size()))
										get_child(5).texture = texture_arr[n]
										sprite_after_anim = n + 1
							for x in range(reels.reel_width):
								for y in range(reels.reel_height):
									if reels.displayed_icons[y][x].modded:
										for e in reels.conditional_effects[y][x]:
											for c in e.comparisons:
												if typeof(c.a) == TYPE_STRING and c.a == "sprite_after_anim":
													reels.add_symbol_position_to_update(Vector2(x, y))
							for i in items:
								if i.modded:
									for e in i.c_effects:
										for c in e.comparisons:
											if typeof(c.a) == TYPE_STRING and c.a == "sprite_after_anim":
												i.check_conditional_effects()
						else:
							if extra_textures.size() > 0:
								randomize()
								var texture_arr = extra_textures.duplicate(true)
								texture_arr.erase(texture)
								var n = floor(rand_range(0, texture_arr.size()))
								get_child(5).texture = texture_arr[n]
								sprite_after_anim = n + 1
				"ordered_texture_cycle":
					if anim_t % 3 == 0 and extra_textures.size() > 0 and queued_anims[0].has("anim_result"):
						var arrow_order
						var without_id = type.substr(0, type.find("_STEAM_ID_"))
						var n
						if without_id == "bronze_arrow" or without_id == "silver_arrow" or without_id == "golden_arrow":
							arrow_order = [1, 2, 3, 5, 8, 7, 6, 4]
							n = arrow_order[int(queued_anims[0].anim_result + floor(queued_anims[0].anim_timer / 3)) % int(extra_textures.size())] - 1
						else:
							n = int(queued_anims[0].anim_result + floor(queued_anims[0].anim_timer / 3)) % int(extra_textures.size())
						get_child(5).texture = extra_textures[n]
						sprite_after_anim = n + 1
	elif queued_anims.size() > 0:
		texture_effect = null
		if (queued_anims.size() == 1 and (queued_anims[0].anim_vtc == "destroyed" or did_destroyed_anim) and (queued_anims[0].giver == null or queued_anims[0].giver.type != type)) or flagged_for_empty_texture or removed or destroyed or tbd:
			did_destroyed_anim = true
			get_child(5).texture = $"/root/Main".get_replacement_texture("empty")
			flagged_for_empty_texture = false
		elif type != "empty" and type != d5 and type != d3 and type != bronze_arrow and type != silver_arrow and type != golden_arrow and queued_anims[0].anim_type != "rand_texture_cycle" and queued_anims[0].anim_type != "ordered_texture_cycle" and not did_destroyed_anim:
			get_child(5).texture = $"/root/Main".get_replacement_texture(type)
			queued_anims[0].anim_texture = null
		elif pointing_directions.size() > 1:
			if queued_anims[0].anim_type == "bounce":
				tried_to_give_rand_eff = true
			elif tried_to_give_rand_eff:
				done_spinning = true
				reels.add_symbol_position_to_update(grid_position)
				for i in get_directional_icons(pointing_directions):
					reels.add_symbol_position_to_update(i.grid_position)
					add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [], "value_to_change": "value_multiplier", "diff": values[0], "unconditional": true})
					add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "target"}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
		queued_anims.remove(0)
		offset_num = 0
		anim_offset = Vector2(0, 0)
		get_child(5).offset = base_offset
		update_value_text()

func stop_animations():
	queued_anims.clear()
	offset_num = 0
	anim_offset = Vector2(0, 0)
	get_child(5).offset = base_offset

func stop_sfx():
	sfx_player.stop()

func can_add_tooltip():
	if tooltips.get_children().size() == 0:
		return true
	else:
		return false

func hover():
	if can_add_tooltip():
		if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0 and not reels.effects_playing and not reels.checking_effects and not reels.counting_effects:
			if type == $"/root/Main".existing_symbols["dog"]:
				queued_anims.push_back({"anim_type": "circle", "anim_timer": 100000, "anim_texture": "dog", "anim_comps": [], "anim_vtc": null, "giver_texture": null, "giver": null, "unconditional": false, "ignore_speed": true, "dog_petting": true})
				if not sfx_player.playing:
					play_sfx(self, "dogpet")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x] != self:
							reels.displayed_icons[y][x].unhover()
							reels.displayed_icons[y][x].hovering = false
			elif type == $"/root/Main".existing_symbols["rabbit"]:
				queued_anims.push_back({"anim_type": "bounce", "anim_timer": 100000, "anim_texture": "rabbit", "anim_comps": [], "anim_vtc": null, "giver_texture": null, "giver": null, "unconditional": false, "ignore_speed": true, "rabbit_petting": true})
				if not sfx_player.playing:
					play_sfx(self, "jumploop")
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.displayed_icons[y][x] != self:
							reels.displayed_icons[y][x].unhover()
							reels.displayed_icons[y][x].hovering = false
			tts()
		hovering = true
		var tooltip = load("res://Tooltip.tscn").instance()
		if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and $"/root/Main/Selector Sprite/Selector".visible:
			tooltip.controller_tooltip = true
		tooltip.get_child(0).data = $"/root/Main/".tile_database[type]
		tooltip.source = self
		tooltips.add_child(tooltip)

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	var t_label = preload("res://Outline Label.tscn").instance()
	t_label.visible = false
	add_child(t_label)
	t_label.raw_string = tr(type) + "\n"
	if $"Value Text".raw_string != "":
		t_label.raw_string += $"Value Text".raw_string + "\n"
	if $"Multiplier Text".raw_string != "":
		t_label.raw_string += $"Multiplier Text".raw_string + "\n"
	if $"Bonus Text".raw_string != "":
		t_label.raw_string += $"Bonus Text".raw_string + "\n"
	if rarity != "none":
		t_label.raw_string += tr(rarity) + "\n"
	t_label.raw_string += tr("value") + "\n"
	t_label.values = [value]
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
		$"/root/Main".tts(start + tr(type), [], self)
	else:
		$"/root/Main".tts(start + tr(type + "_desc"), values, self)

func unhover():
	if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and $"/root/Main/Selector Sprite/Selector".visible:
		return
	if (type == $"/root/Main".existing_symbols["dog"] or type == $"/root/Main".existing_symbols["rabbit"]) and $"/root/Main/Pop-up Sprite/Pop-up".emails.size() == 0:
		stop_animations()
		sfx_player.stop()
	for t in tooltips.get_children():
		if t.locked_pos == null:
			t.queue_free()

func add_permanent_bonus(b, c, do_prev):
	var data_arr = [self]
	if do_prev:
		data_arr += prev_data
	for p in data_arr:
		var can_apply = false
		if b.has("type"):
			if $"/root/Main".existing_symbols[b.type] == p.type:
				can_apply = true
		elif b.has("groups"):
			if $"/root/Main".group_database["symbols"].has(b.groups) and $"/root/Main".group_database["symbols"][b.groups].has(p.type):
				can_apply = true
				
		if can_apply:
			if b.has("bonus"):
				p.permanent_bonus += b.bonus
			elif b.has("multiplier"):
				p.permanent_multiplier *= b.multiplier

func add_init_permanent_bonuses():
	var can_apply
	for b in $"/root/Main/Pop-up Sprite/Pop-up".permanent_bonuses:
		can_apply = false
		if b.has("type"):
			if b.type == type:
				can_apply = true
		elif b.has("groups"):
			if $"/root/Main".group_database["symbols"].has(b.groups) and $"/root/Main".group_database["symbols"][b.groups].has(type):
				can_apply = true
		if can_apply:
			if b.has("bonus"):
				permanent_bonus += b.bonus
			elif b.has("multiplier"):
				permanent_multiplier *= b.multiplier
	update_value_text()

func wc_update(s):
	if s == "flat_value_bonus":
		for adj_icon in get_adjacent_icons():
			if adj_icon.wildcarded and adj_icon.flat_value_bonus < flat_value_bonus:
				adj_icon.flat_value_bonus = flat_value_bonus
				adj_icon.wc_update("flat_value_bonus")
	elif s == "queued_wc_increase":
		for adj_icon in get_adjacent_icons():
			if adj_icon.wildcarded and adj_icon.get_value("coin") + adj_icon.queued_wc_increase < get_value("coin") + queued_wc_increase:
				adj_icon.queued_wc_increase += (get_value("coin") + queued_wc_increase) - (adj_icon.get_value("coin") + adj_icon.queued_wc_increase)
				adj_icon.wc_update("queued_wc_increase")

func get_non_flat_value(currency):
	if drained:
		return 0
		
	var value_bonus = 0
	var value_multiplier = 1
	var prev_final_value = 0
	
	var v_str = "value"
	var vb_arr_str = "value_bonus_arr"
	var vm_arr_str = "value_multiplier_arr"
	var pb_str = "permanent_bonus"
	var pm_str = "permanent_multiplier"
	var fvb_str = "flat_value_bonus"
	
	match currency:
		"reroll_token":
			v_str = "reroll_token_value"
			vb_arr_str = "reroll_token_value_bonus_arr"
			vm_arr_str = "reroll_token_value_multiplier_arr"
			pb_str = "reroll_token_permanent_bonus"
			pm_str = "reroll_token_permanent_multiplier"
			fvb_str = "reroll_token_flat_value_bonus"
		"removal_token":
			v_str = "removal_token_value"
			vb_arr_str = "removal_token_value_bonus_arr"
			vm_arr_str = "removal_token_value_multiplier_arr"
			pb_str = "removal_token_permanent_bonus"
			pm_str = "removal_token_permanent_multiplier"
			fvb_str = "removal_token_flat_value_bonus"
		"essence_token":
			v_str = "essence_token_value"
			vb_arr_str = "essence_token_value_bonus_arr"
			vm_arr_str = "essence_token_value_multiplier_arr"
			pb_str = "essence_token_permanent_bonus"
			pm_str = "essence_token_permanent_multiplier"
			fvb_str = "essence_token_flat_value_bonus"
	
	for p in prev_data:
		var p_value_bonus = 0
		var p_value_multiplier = 1
		for v in p[vb_arr_str]:
			p_value_bonus += v.value
		for v in p[vm_arr_str]:
			p_value_multiplier *= v.value
			
		if (int(p.value) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]) < 0:
			prev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])))
		else:
			prev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]))
	
	if (int(self[v_str]) + int(value_bonus) + int(permanent_bonus)) * float(value_multiplier) < 0:
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str]) + int(prev_final_value)))
	else:
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) * float(value_multiplier) * float(self[pm_str]) + int(prev_final_value))

func get_non_prev_value(currency):
	if drained:
		return 0

	var v_str = "value"
	var vb_arr_str = "value_bonus_arr"
	var vm_arr_str = "value_multiplier_arr"
	var pb_str = "permanent_bonus"
	var pm_str = "permanent_multiplier"
	var fvb_str = "flat_value_bonus"

	var value_bonus = 0
	var value_multiplier = 1

	for v in self[vb_arr_str]:
		value_bonus += v.value
	for v in self[vm_arr_str]:
		value_multiplier *= v.value

	if (int(self[v_str]) + int(value_bonus)) * float(value_multiplier) * float(self[pm_str]) < 0:
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) + int(self[fvb_str]))
	else:
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) * float(value_multiplier) * float(self[pm_str]) + int(self[fvb_str]))

func get_relevant_final_value(p, goal_eff, vb, vm):
	var value_bonus = 0
	var value_multiplier = 1
	for v in p.value_bonus_arr:
		value_bonus += v.value
	for v in p.value_multiplier_arr:
		value_multiplier *= v.value
	var ddm = 1
	if goal_eff.has("dynamic_diff_multiplier"):
		ddm = goal_eff.dynamic_diff_multiplier
	return round(round((int(p.value) + int(value_bonus) + int(p.permanent_bonus)) * float(value_multiplier) * float(p.permanent_multiplier)) * ddm)

func get_value(currency):
	if drained:
		return 0
			
	var value_bonus = 0
	var value_multiplier = 1
	var prev_final_value = 0
	
	var v_str = "value"
	var vb_arr_str = "value_bonus_arr"
	var vm_arr_str = "value_multiplier_arr"
	var pb_str = "permanent_bonus"
	var pm_str = "permanent_multiplier"
	var fvb_str = "flat_value_bonus"
	
	if wildcarded and reels.true_final_value:
		v_str = "flat_value_bonus"
	
	match currency:
		"reroll_token":
			v_str = "reroll_token_value"
			vb_arr_str = "reroll_token_value_bonus_arr"
			vm_arr_str = "reroll_token_value_multiplier_arr"
			pb_str = "reroll_token_permanent_bonus"
			pm_str = "reroll_token_permanent_multiplier"
			fvb_str = "reroll_token_flat_value_bonus"
		"removal_token":
			v_str = "removal_token_value"
			vb_arr_str = "removal_token_value_bonus_arr"
			vm_arr_str = "removal_token_value_multiplier_arr"
			pb_str = "removal_token_permanent_bonus"
			pm_str = "removal_token_permanent_multiplier"
			fvb_str = "removal_token_flat_value_bonus"
		"essence_token":
			v_str = "essence_token_value"
			vb_arr_str = "essence_token_value_bonus_arr"
			vm_arr_str = "essence_token_value_multiplier_arr"
			pb_str = "essence_token_permanent_bonus"
			pm_str = "essence_token_permanent_multiplier"
			fvb_str = "essence_token_flat_value_bonus"
	
	for v in self[vb_arr_str]:
		value_bonus += v.value
	for v in self[vm_arr_str]:
		value_multiplier *= v.value
	for p in prev_data:
		var p_value_bonus = 0
		var p_value_multiplier = 1
		for v in p[vb_arr_str]:
			p_value_bonus += v.value
		for v in p[vm_arr_str]:
			p_value_multiplier *= v.value
			
		if (int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]) < 0:
			prev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])))
		else:
			prev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]))
		check_symbol_value(p, prev_final_value)
			
	if (int(self[v_str]) + int(value_bonus) + int(permanent_bonus)) * float(value_multiplier) * float(self[pm_str]) < 0:
		check_symbol_value(self, round(int(self[v_str]) + int(value_bonus) + int(self[pb_str])))
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) + int(prev_final_value))
	else:
		check_symbol_value(self, round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) * float(value_multiplier) * float(self[pm_str])))
		return round((int(self[v_str]) + int(value_bonus) + int(self[pb_str])) * float(value_multiplier) * float(self[pm_str]) + int(prev_final_value))

func get_adjacent_icons():
	var arr = []
	var telescope
	var telescope_essence
	var protractor
	var protractor_essence
	var clear_sky
	if $"/root/Main/Items".has_unmodded_item("telescope"):
		telescope = items[item_types.find("telescope")]
	if $"/root/Main/Items".has_unmodded_item("protractor"):
		protractor = items[item_types.find("protractor")]
	if $"/root/Main/Items".has_unmodded_item("clear_sky") or items_destroyed_this_spin.has("clear_sky_essence"):
		clear_sky = $"/root/Main".item_database["clear_sky"]
	if $"/root/Main/Items".has_unmodded_item("telescope_essence"):
		telescope_essence = $"/root/Main".item_database["telescope_essence"]
	if $"/root/Main/Items".has_unmodded_item("protractor_essence"):
		protractor_essence = $"/root/Main".item_database["protractor_essence"]
	if $"/root/Main/Items".destroyed_item_types.has("clear_sky_essence"):
		clear_sky = $"/root/Main".item_database["clear_sky_essence"]
	if (telescope != null and telescope.saved_value >= telescope.values[0]) or (telescope_essence != null) or (((protractor != null and protractor.saved_value >= protractor.values[0]) or protractor_essence != null) and (grid_position == Vector2(0, 0) or grid_position == Vector2(0, reels.reel_height - 1) or grid_position == Vector2(reels.reel_width - 1, 0) or grid_position == Vector2(reels.reel_width - 1, reels.reel_height - 1))) or (clear_sky != null and (type == "moon" or type == "sun")):
		for y in range(reels.reel_height):
			arr += reels.displayed_icons[y]
		arr.erase(self)
	else:
		var checker_x
		var checker_y
		var x = grid_position.x
		var y = grid_position.y
		
		var fp_22 = false
		
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num == 22:
				fp_22 = true
				break
		
		for n in range(9):
			checker_x = (n % 3) - 1
			checker_y = -1 + floor(n / 3)
			if fp_22 and (n == 1 or n == 7):
				pass
			elif x + checker_x >= 0 and x + checker_x < reels.reel_width and y + checker_y >= 0 and y + checker_y < reels.reel_height and not (checker_x == 0 and checker_y == 0):
				arr.push_back(reels.displayed_icons[y + checker_y][x + checker_x])
		
		if (protractor != null and protractor.saved_value >= protractor.values[0]) or protractor_essence != null:
			if not arr.has(reels.displayed_icons[0][0]):
				arr.push_back(reels.displayed_icons[0][0])
			if not arr.has(reels.displayed_icons[reels.reel_height - 1][0]):
				arr.push_back(reels.displayed_icons[reels.reel_height - 1][0])
			if not arr.has(reels.displayed_icons[0][reels.reel_width - 1]):
				arr.push_back(reels.displayed_icons[0][reels.reel_width - 1])
			if not arr.has(reels.displayed_icons[reels.reel_height - 1][reels.reel_width - 1]):
				arr.push_back(reels.displayed_icons[reels.reel_height - 1][reels.reel_width - 1])
		arr.erase(self)
	return arr

func get_directional_icons(dir_arr):
	var arr = []
	var arrow_order = [1, 2, 3, 5, 8, 7, 6, 4]
	for direction in dir_arr:
		var x_mod = 0
		var y_mod = 0
		var x_diff = 0
		var y_diff = 0
		match int(arrow_order[direction - 1]):
			1:
				x_diff = -1
				y_diff = -1
			2:
				y_diff = -1
			3:
				x_diff = 1
				y_diff = -1
			4:
				x_diff = -1
			5:
				x_diff = 1
			6:
				x_diff = -1
				y_diff = 1
			7:
				y_diff = 1
			8:
				x_diff = 1
				y_diff = 1
		x_mod += x_diff
		y_mod += y_diff
		while grid_position.x + x_mod >= 0 and grid_position.y + y_mod >= 0 and grid_position.x + x_mod <= reels.reel_width - 1 and grid_position.y + y_mod <= reels.reel_height - 1:
			arr.push_back(reels.displayed_icons[grid_position.y + y_mod][grid_position.x + x_mod])
			x_mod += x_diff
			y_mod += y_diff
	return arr

func decide_extra_target(symbol, original):
	if symbol.getting_extra:
		return symbol
	else:
		return original

func update_value_text():
	var text_value = 0
	var reset_value = 0
	var color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">"
	if not modded or (modded and inherit_effects):
		var t = type.substr(0, type.find("_STEAM_ID_"))
		match t:
			"thief", "gambler":
				text_value = times_displayed * values[1]
				color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_up_text"] + ">"
			"snail", "turtle", "sloth", "magpie", "robin_hood", "owl":
				var checkered_flag_diff = 0
				if $"/root/Main/Items".has_unmodded_item("checkered_flag"):
					checkered_flag_diff = items[item_types.find("checkered_flag")].values[0] * items[item_types.find("checkered_flag")].item_count
				for fp in $"/root/Main/Landlord".fine_print:
					if fp.num == 12 and fp.dynamic_icon == t:
						checkered_flag_diff -= fp.values[0]
						break
				text_value = values[1] - checkered_flag_diff - times_displayed
				reset_value = values[1] - checkered_flag_diff
				if $"/root/Main/Items".just_added_items.has("checkered_flag") and text_value == 0:
					text_value -= items[item_types.find("checkered_flag")].item_count
					reset_value += items[item_types.find("checkered_flag")].item_count
			"spirit":
				var undertaker
				if $"/root/Main/Items".has_unmodded_item("undertaker"):
					undertaker = items[item_types.find("undertaker")]
				if undertaker == null:
					text_value = values[0] - times_coins_given
			"coal":
				var time_machine_diff = 0
				if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
					time_machine_diff = 1000000
				elif $"/root/Main/Items".has_unmodded_item("time_machine"):
					time_machine_diff = items[item_types.find("time_machine")].values[0] * items[item_types.find("time_machine")].item_count
				text_value = values[0] - time_machine_diff - times_displayed
			"matryoshka_doll_1", "matryoshka_doll_2", "matryoshka_doll_3", "matryoshka_doll_4", "golem":
				var time_machine_diff = 0
				if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
					time_machine_diff = 1000000
				elif $"/root/Main/Items".has_unmodded_item("time_machine"):
					time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
				text_value = values[0] - time_machine_diff - times_displayed
			"mine", "bubble", "bar_of_soap":
				text_value = values[0] - times_coins_given
			"present":
				var time_machine_diff = 0
				if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
					time_machine_diff = 1000000
				elif $"/root/Main/Items".has_unmodded_item("time_machine"):
					time_machine_diff = items[item_types.find("time_machine")].values[2] * items[item_types.find("time_machine")].item_count
				text_value = values[0] - time_machine_diff - times_displayed
			"crow":
				text_value = values[1] - times_displayed
				reset_value = values[1]
			"frozen_fossil":
				var time_machine_diff = 0
				if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
					time_machine_diff = 1000000
				elif $"/root/Main/Items".has_unmodded_item("time_machine"):
					time_machine_diff = items[item_types.find("time_machine")].values[2] * items[item_types.find("time_machine")].item_count
				text_value = values[0] - time_machine_diff - $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[1] - times_displayed
			"rabbit", "wine":
				text_value = values[1] - times_displayed
			"dud":
				text_value = values[0] - times_displayed
			"light_bulb":
				text_value = values[1] - saved_value
	for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.symbols:
		if type == m.type:
			if typeof(m.value_text) == TYPE_DICTIONARY and m.value_text.has("color"):
				if $"/root/Main/Options Sprite/Options".colors3.has(m.value_text.color):
					color_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3[m.value_text.color] + ">"
				else:
					color_string = "<color_" + m.value_text.color + ">"
				if m.value_text.has("value") and typeof(m.value_text.value) == TYPE_DICTIONARY and (m.value_text.value.has("var_math") or m.value_text.value.has("starting_value")):
					text_value = parse_var_math(m.value_text.value, self, null)
				else:
					text_value = m.value_text.value
	
	if text_value > 0 and text_value != reset_value and not destroyed and not tbd:
		get_child(1).raw_string = color_string + get_child(1).parse_num_str(str(text_value)) + "<end>"
		get_child(1).force_update = true
		get_child(1).update()
		displayed_text_value = get_child(1).parse_num_str(str(text_value))
	else:
		get_child(1).raw_string = ""
		displayed_text_value = ""
	if permanent_multiplier != 1:
		if permanent_multiplier >= 10:
			get_child(2).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + get_child(2).parse_num_str(str(round(permanent_multiplier))) + "x<end>"
		else:
			get_child(2).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + get_child(2).parse_num_str(str(stepify(permanent_multiplier, 0.1))) + "x<end>"
		get_child(2).force_update = true
		get_child(2).update()
		if $"/root/Main/Options Sprite/Options".CJK_lang or get_child(2).forced_font != null:
			get_child(2).rect_position.x = round(108 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui - get_child(2).get_font("font").get_string_size(get_child(2).get_child(0).text).x * get_child(2).current_scale)
		elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
			get_child(2).rect_position.x = round(108 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui - get_child(2).get_child(0).get_font("font").get_string_size(get_child(2).get_child(0).text).x * get_child(2).current_scale)
		else:
			get_child(2).rect_position.x = round(108 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui - get_child(2).get_font("font").get_string_size(get_child(2).text).x * get_child(2).current_scale * 4.0)
		if permanent_multiplier >= 10:
			displayed_multiplier_value = get_child(2).parse_num_str(str(round(permanent_multiplier))) + "x"
		elif permanent_multiplier > 0:
			displayed_multiplier_value = get_child(2).parse_num_str(str(stepify(permanent_multiplier, 0.1))) + "x"
		else:
			displayed_multiplier_value = ""
	else:
		get_child(2).raw_string = ""
	if type == "eldritch_beast" and permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0] > 0:
		if permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0] > 0:
			get_child(3).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + get_child(3).parse_num_str(str(permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0])) + "<end>"
			get_child(3).force_update = true
		else:
			get_child(3).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + get_child(3).parse_num_str(str(permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0])) + "<end>"
			get_child(3).force_update = true
		displayed_bonus_value = get_child(3).parse_num_str(str(permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0]))
	elif permanent_bonus != 0:
		if permanent_bonus > 0:
			get_child(3).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + get_child(3).parse_num_str(str(permanent_bonus)) + "<end>"
			get_child(3).force_update = true
		else:
			get_child(3).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + get_child(3).parse_num_str(str(permanent_bonus)) + "<end>"
			get_child(3).force_update = true
		displayed_bonus_value = get_child(3).parse_num_str(str(permanent_bonus))
	else:
		get_child(3).raw_string = ""
		displayed_bonus_value = ""
	get_child(1).update()
	get_child(2).update()
	get_child(3).update()

func add_effect_to_symbol(y, x, effect):
	if not effect.has("giver"):
		effect["giver"] = self
		effect["giver_texture"] = texture_type
	if effect.has("target_self") and effect.target_self:
		effect.erase("target_self")
		effect["target"] = self
	reels.displayed_icons[y][x].add_effect(effect)

func get_source_effect_hash(effect):
	var c = effect.duplicate(true)
	
	c.erase("anim_targets")
	c.erase("target")
	c.erase("source")
	if c.has("giver"):
		c["pos"] = c.giver.grid_position
		c.erase("giver")
	c.erase("giver_texture")
	c.erase("anim_texture")
	
	return c.hash()

func get_prev_cleaned_effect(effect):
	var c = effect.duplicate(true)
	
	if not c.has("unconditional") or (c.has("unconditional") and c.has("anim")):
		c.erase("source")
		c.erase("giver")
		c.erase("pdi")
	c.erase("target")
	
	return get_cleaned_effect(c)

func get_fully_cleaned_effect(effect):
	var c = effect.duplicate(true)
	
	if c.has("one_time") and modded:
		c.comparisons.clear()
		c.erase("diff")
		c.erase("item_adding_effects")
		c.erase("tile_adding_effects")
	
	c.erase("source")
	c.erase("giver")
	c.erase("target")
	
	if c.comparisons.size() > 0 and typeof(c.comparisons[0].a) == TYPE_STRING and c.comparisons[0].a == "destroyed_giver_on_destroy":
		c.comparisons[0] = {"a": "dove_destroyed", "b": true}
	
	return get_cleaned_effect(c)

func get_cleaned_effect(effect):
	if effect == null:
		return {}
	var c = effect.duplicate(true)
	
	var comp_num = 0
	var c_tbe = []
	if c.has("comparisons"):
		for comparison in c.comparisons:
			if comparison.has("rand") or comparison.has("dynamic_a_target") or comparison.has("dynamic_b_target"):
				c_tbe.push_back(comparison)
			for k in comparison.keys():
				if typeof(comparison[k]) == TYPE_DICTIONARY and (comparison[k].has("var_math") or comparison[k].has("starting_value")):
					if c.has("from_item"):
						c.comparisons[comp_num][k] = items[item_types.find(c.from_item)].parse_var_math(comparison[k], items[item_types.find(c.from_item)], c)
					else:
						c.comparisons[comp_num][k] = parse_var_math(comparison[k], self, c)
					if str(effect.comparisons[comp_num]).find("rand_num:") != -1:
						c_tbe.push_back(c.comparisons[comp_num])
			comp_num += 1
	if c.has("anim_targets"):
		c.erase("anim_targets")
	if c.has("anim") and c.anim == "rand_texture_cycle":
		c.erase("diff")
		c.erase("source")
	if c.has("anim_result"):
		c.erase("anim_result")
	if c.has("dynamic_diff_target"):
		c.erase("dynamic_diff_target")
		c.erase("dynamic_diff_key")
		c.erase("diff")
	if c.has("hex_eff"):
		c.erase("target")
		c.erase("hex_eff")
	if c.has("one_time"):
		c.erase("source")
		c.erase("giver")
	if c.has("giver") and getting_extra and not c.has("unconditional"):
		c.erase("source")
		c.erase("giver")
	if c.has("raritymod"):
		c.erase("source")
		c.erase("target")
	if c.has("anim_texture"):
		c.erase("anim_texture")
	if c.has("giver_texture"):
		c.erase("giver_texture")
	if c.has("emails_to_add"):
		c.erase("emails_to_add")
	if c.has("tiles_to_add") and not c.has("can_add_after_destroy"):
		c.erase("pdi")
	if c.has("from_symbol_trigger"):
		c.comparisons = []
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY and (c.diff.has("var_math") or c.diff.has("starting_value")):
		if c.has("from_item") and (not c.has("effect_type") or (c.has("effect_type") and c.effect_type != "symbols")):
			c.diff = items[item_types.find(c.from_item)].parse_var_math(c.diff, items[item_types.find(c.from_item)], c)
		else:
			c.diff = parse_var_math(c.diff, self, c)
		if str(effect.diff).find("rand_num:") != -1:
			c.erase("diff")
	if c.has("tiles_to_add"):
		var t_tbe = []
		for t in c.tiles_to_add:
			if typeof(t) == TYPE_DICTIONARY and t.has("group"):
				t_tbe.push_back(t)
		for t in t_tbe:
			c.tiles_to_add.erase(t)
	if c.has("items_to_add"):
		var i_tbe = []
		for i in c.items_to_add:
			if typeof(i) == TYPE_DICTIONARY and i.has("group"):
				i_tbe.push_back(i)
		for i in i_tbe:
			c.items_to_add.erase(i)
	for comparison in c_tbe:
		if comparison.has("value_num"):
			c.comparisons[c.comparisons.find(comparison)] = {"value_num": comparison.value_num}
		else:
			c.comparisons.erase(comparison)
	return c

func parse_var_math(data, giver, eff):
	var num = 0
	var targ = self
	if data.has("starting_value"):
		var a = data.starting_value
		if typeof(data) == TYPE_DICTIONARY and data.has("target_self") and data.target_self:
			if eff.has("giver"):
				targ = eff.giver
			elif eff.has("from_item"):
				targ = items[item_types.find(eff.from_item)]
			elif giver != null:
				targ = giver
		if targ.prev_data_obj != null and prev_data_obj != null:
			targ = prev_data_obj
		match a:
			"times_displayed":
				num = targ[num]
			"value_bonus":
				for v in targ.value_bonus_arr:
					num += v.value
			"value_multiplier":
				num = 1
				for v in targ.value_multiplier_arr:
					num *= v.value
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
			"grid_position_x":
				num = targ.grid_position.x
			"grid_position_y":
				num = targ.grid_position.y
			"hotfix_num":
				num = $"/root/Main".hotfix_num
			"symbols_destroyed_this_spin":
				num = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
			"items_destroyed_this_spin":
				num = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
			"non_singular_symbols":
				num = $"/root/Main/Reels".get_non_singular_symbols()
			"extra_symbol_choices":
				num = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
			"extra_item_choices":
				num = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices
			"symbols_to_choose_from":
				num = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
			"items_to_choose_from":
				num = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
			"var_math", "starting_value":
				num = parse_var_math(a, giver, eff)
			_:
				if typeof(a) == TYPE_STRING:
					num = targ[a]
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
						if item_types.has(with_id):
							num = items[item_types.find(with_id)].item_count
					elif a.has("counted_destroyed_items"):
						num = 0
						var with_id = a.counted_destroyed_items
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(a.counted_destroyed_items):
							with_id = $"/root/Main".append_steam_id(a.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(a.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[a.counted_destroyed_items])]
							if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = a.counted_destroyed_items
						num = $"/root/Main/Items".destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
					elif a.has("counted_symbols"):
						num = 0
						reels.count_symbols(true)
						var with_id = a.counted_symbols
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(a.counted_symbols):
							with_id = $"/root/Main".append_steam_id(a.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[a.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(a.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[a.counted_symbols])]
							if $"/root/Main".mod_data.symbols.has(with_id) and $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = a.counted_symbols
						if reels.counted_symbols.has(with_id):
							num = reels.counted_symbols[with_id]
					elif a.has("saved_values"):
						var p_id = type.substr(type.find("_STEAM_ID_") + 10, -1)
						p_id = p_id.substr(0, p_id.find("_PACK_"))
						var id = get_author_id(null, p_id, null, targ, a.saved_values.value_num)
						eff["v_num"] = [id, a.saved_values.value_num].hash()
						num = targ.saved_values[id][a.saved_values.value_num]
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
			targ = self
			if typeof(a) == TYPE_DICTIONARY and a.has("target_self") and a.target_self:
				if eff.has("giver"):
					targ = eff.giver
				elif eff.has("from_item"):
					targ = items[item_types.find(eff.from_item)]
				elif giver != null:
					targ = giver
			if targ.prev_data_obj != null and prev_data_obj != null:
				targ = prev_data_obj
			var v = a[a.keys()[0]]
			if typeof(v) == TYPE_STRING or typeof(v) == TYPE_DICTIONARY:
				match v:
					"times_displayed":
						v = targ[v]
					"value_bonus":
						v = 0
						for n in targ.value_bonus_arr:
							num += n.value
					"value_multiplier":
						v = 1
						for n in targ.value_multiplier_arr:
							v *= n.value
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
					"grid_position_x":
						v = targ.grid_position.x
					"grid_position_y":
						v = targ.grid_position.y
					"hotfix_num":
						v = $"/root/Main".hotfix_num
					"symbols_destroyed_this_spin":
						v = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
					"items_destroyed_this_spin":
						v = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
					"non_singular_symbols":
						v = $"/root/Main/Reels".get_non_singular_symbols()
					"extra_symbol_choices":
						v = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
					"extra_item_choices":
						v = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices
					"symbols_to_choose_from":
						v = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
					"items_to_choose_from":
						v = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
					"var_math", "starting_value":
						v = parse_var_math(v, giver, eff)
					_:
						if typeof(v) == TYPE_STRING:
							v = targ[v]
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
								if item_types.has(with_id):
									v = items[item_types.find(with_id)].item_count
								else:
									v = 0
							elif v.has("counted_destroyed_items"):
								var with_id = v.counted_destroyed_items
								if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(v.counted_destroyed_items):
									with_id = $"/root/Main".append_steam_id(v.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(v.counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[v.counted_destroyed_items])]
									if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
										with_id = v.counted_destroyed_items
								v = $"/root/Main/Items".destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
							elif v.has("counted_symbols"):
								reels.count_symbols(true)
								var with_id = v.counted_symbols
								if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(v.counted_symbols):
									with_id = $"/root/Main".append_steam_id(v.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[v.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(v.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[v.counted_symbols])]
									if $"/root/Main".mod_data.symbols.has(with_id) and $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
										with_id = v.counted_symbols
								if reels.counted_symbols.has(with_id):
									v = reels.counted_symbols[with_id]
								else:
									v = 0
							elif v.has("saved_values"):
								var p_id = type.substr(type.find("_STEAM_ID_") + 10, -1)
								p_id = p_id.substr(0, p_id.find("_PACK_"))
								var id = get_author_id(null, p_id, null, targ, v.saved_values.value_num)
								eff["v_num"] = [id, v.saved_values.value_num].hash()
								v = targ.saved_values[id][v.saved_values.value_num]
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

func check_dove_conditionals(c):
	if c.has("giver") and (c.has("destroy_giver_on_destroy") or destroyed_giver_on_destroy):
		var adjacent_dove = false
		if c.giver.dove_destroyed or dove_destroyed:
			if not dove_destroyed:
				reels.dove_prevention = true
			c.giver.dove_destroyed = true
			dove_destroyed = true
			adjacent_dove = true
		else:
			for a in c.giver.get_adjacent_icons():
				if a.type == "dove":
					if not dove_destroyed:
						reels.dove_prevention = true
					dove_destroyed = true
					c.giver.dove_destroyed = true
					if a.get_adjacent_icons().has(self):
						add_effect_to_symbol(grid_position.y, grid_position.x, {"comparisons": [{"a": "dove_destroyed", "b": true}], "anim": "circle", "anim_targets": [self, a], "sfx_override": "coo", "target": a, "value_to_change": "permanent_bonus", "diff": a.values[0]})
					c.giver.add_effect_to_symbol(c.giver.grid_position.y, c.giver.grid_position.x, {"comparisons": [{"a": "dove_destroyed", "b": true}], "anim": "circle", "anim_targets": [c.giver, a], "sfx_override": "coo", "target": a, "value_to_change": "permanent_bonus", "diff": a.values[0], "one_time": true})
					reels.add_symbol_position_to_update(c.giver.grid_position)
					adjacent_dove = true
			if destroyed_giver_on_destroy:
				for a in get_adjacent_icons():
					if a.type == "dove":
						if not dove_destroyed:
							reels.dove_prevention = true
						dove_destroyed = true
						c.giver.dove_destroyed = true
						c.giver.add_effect_to_symbol(c.giver.grid_position.y, c.giver.grid_position.x, {"comparisons": [{"a": "dove_destroyed", "b": true}], "anim": "circle", "anim_targets": [self, a], "sfx_override": "coo", "target": a, "value_to_change": "permanent_bonus", "diff": a.values[0], "one_time": true})
						reels.add_symbol_position_to_update(c.giver.grid_position)
						adjacent_dove = true
		if adjacent_dove:
			return false
	return true

func update_dynamic_diffs(multiplier, p_type, pdo):
	if multiplier:
		for adj_icon in get_adjacent_icons():
			if adj_icon.type == p_type:
				var p_arr = [self]
				p_arr += prev_data
				for p in p_arr:
					var made_it = false
					var vtc = []
					var flagged_values = []
					for v in adj_icon.value_bonus_arr:
						if not flagged_values.has(v.hash()):
							for comp in v.source_eff.comparisons:
								if typeof(comp.a) == TYPE_STRING and (((comp.a == "type" and comp.b == p.type) or (comp.a == "groups" and $"/root/Main".group_database["symbols"][comp.b].has(p.type)))):
									var pdp = prev_data.find(p)
									if typeof(p) != TYPE_DICTIONARY:
										if pdo != null:
											pdp = prev_data.find(prev_data_obj)
										else:
											pdp = adj_icon.value_bonus_arr.size()
											pdp -= 1
									if v.ddt.type == p.type and v.ddt.grid_position == p.grid_position:
										if p_arr.find(p) == 0 or p.effect_hashes.has(get_prev_cleaned_effect(v.source_eff).hash()):
											var pos = adj_icon.value_bonus_arr.find(v)
											if pdp == null:
												pos = adj_icon.value_bonus_arr.size() - 1
											vtc.push_back({"pos": pos, "vb": { "source": self, "value": get_relevant_final_value(p, v.source_eff, null, null), "unconditional": false, "source_eff": v.source_eff, "giver": v.source_eff.giver, "ddt": {"type": p.type, "grid_position": p.grid_position, "prev_data_pos": pdp} }})
											flagged_values.push_back(v.hash())
									if made_it:
										break
								if made_it:
									break
						if made_it:
							break
					if vtc.size() > 0:
						for val in vtc:
							adj_icon.value_bonus_arr[val.pos] = val.vb
						reels.add_symbol_position_to_update(adj_icon.grid_position)
	else:
		for adj_icon in get_adjacent_icons():
			for t in adj_icon.dynamic_diff_targets:
				var target_match = false
				if t.target.type == type and t.target.grid_position == grid_position:
					target_match = true
				if target_match:
					var p_arr = [self]
					p_arr += prev_data
					for p in p_arr:
						var made_it = false
						var vtc = []
						var flagged_values = []
						for v in t.eff.giver.value_bonus_arr:
							if v.source_eff.hash() == t.eff.hash() and not flagged_values.has(v.hash()):
								for comp in v.source_eff.comparisons:
									if typeof(comp.a) == TYPE_STRING and ((comp.a == "type" and comp.b == p.type) or (comp.a == "groups" and $"/root/Main".group_database["symbols"][comp.b].has(p.type))):
										var pdp = prev_data.find(p)
										if typeof(p) != TYPE_DICTIONARY:
											if prev_data_obj != null:
												pdp = prev_data.find(prev_data_obj)
											else:
												pdp = t.eff.giver.value_bonus_arr.size()
												pdp -= 1
										if v.ddt.type == p.type and v.ddt.grid_position == p.grid_position and v.ddt.prev_data_pos == pdp:
											if p_arr.find(p) == 0 or p.effect_hashes.has(get_prev_cleaned_effect(v.source_eff).hash()):
												var pos = t.eff.giver.value_bonus_arr.find(v)
												if pdp == null:
													pos = t.eff.giver.value_bonus_arr.size() - 1
												vtc.push_back({"pos": pos, "vb": { "source": self, "value": get_relevant_final_value(p, v.source_eff, null, null), "unconditional": false, "source_eff": v.source_eff, "giver": v.source_eff.giver, "ddt": {"type": p.type, "grid_position": p.grid_position, "prev_data_pos": pdp} }})
												flagged_values.push_back(v.hash())
										if made_it:
											break
									if made_it:
										break
							if made_it:
								break
						if vtc.size() > 0:
							for val in vtc:
								t.eff.giver.value_bonus_arr[val.pos] = val.vb
							reels.add_symbol_position_to_update(t.eff.giver.grid_position)

func get_author_id(c, p_id, comp, target, v_num):
	var id
	if p_id != null and p_id != "0" and p_id != "":
		id = p_id
	elif c != null and c.has("giver"):
		if not $"/root/Main".mod_data.symbols.has(c.giver.type):
			id = 0
		else:
			id = $"/root/Main".mod_data.symbols[c.giver.type].author_id
	else:
		if not $"/root/Main".mod_data.symbols.has(target.type):
			id = 0
		else:
			id = $"/root/Main".mod_data.symbols[target.type].author_id
	id = str(id)
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
	return str(id)

func do_diff(c, target, c_tbe):
	if typeof(target) == TYPE_OBJECT and target.has_method("get_value"):
		target.current_effect = c.duplicate(true)
		if (c.has("value_to_change") and c.value_to_change == "type" and (not c.has("diff") or c.diff != "empty")) or c.has("giver") and c.giver.type == "midas_bomb" and c.has("value_to_change") and c.value_to_change == "destroyed":
			target.texture_effect = target.type
	
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY:
		if c.diff.has("var_math") or c.diff.has("starting_value"):
			if c.has("from_item") and (not c.has("effect_type") or (c.has("effect_type") and c.effect_type != "symbols")):
				c.diff = items[item_types.find(c.from_item)].parse_var_math(c.diff, items[item_types.find(c.from_item)], c)
			else:
				c.diff = parse_var_math(c.diff, self, c)
	
	if prev_data_obj != null:
		prev_data_obj.effect_hashes.push_back(get_prev_cleaned_effect(c).hash())
	
	if c.has("tiles_to_add") and (c.has("from_item") or not target.tile_adding_effects.has(get_cleaned_effect(c).hash())):
		var donezo = false
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num == 13 and fp.dynamic_icon == c.source.type:
				for comp in c.comparisons:
					if comp.has("rand"):
						c.tiles_to_add.clear()
						donezo = true
						break
			if donezo:
				break
		if not c.has("from_item"):
			target.tile_adding_effects.push_back(get_cleaned_effect(c).hash())
		var destroyed_symbols = []
		var symbol_arr = []
		var rarity_counts = []
		if c.tiles_to_add.has("prev_destroyed_symbol"):
			destroyed_symbols = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.duplicate(true)
			var d_tbe = []
			for d in destroyed_symbols:
				if d == "time_capsule" or $"/root/Main".group_database["symbols"]["time_capsule_effects"].has(d) or $"/root/Main".rarity_database["symbols"]["none"].has(d) or (not reels.can_add_highlander() and d == "highlander"):
					d_tbe.push_back(d)
			for x in range(reels.reel_width):
				for y in range(reels.reel_height):
					var s = reels.displayed_icons[y][x]
					if s.tbd:
						destroyed_symbols.push_back(s.type)
						if s.type == "time_capsule" or $"/root/Main".group_database["symbols"]["time_capsule_effects"].has(s.type) or $"/root/Main".rarity_database["symbols"]["none"].has(s.type) or (not reels.can_add_highlander() and s.type == "highlander"):
							d_tbe.push_back(s.type)
			for d in d_tbe:
				destroyed_symbols.erase(d)
		var syms = []
		for t in c.tiles_to_add:
			if typeof(t) == TYPE_STRING and t == "prev_destroyed_symbol":
				if destroyed_symbols.size() > 0:
					symbol_arr.push_back(destroyed_symbols[floor(rand_range(0, destroyed_symbols.size()))])
					if target.type == "time_capsule" and $"/root/Main".group_database["symbols"]["capsule"].has(symbol_arr[symbol_arr.size() - 1]):
						reels.add_queued_achievement(136)
			elif typeof(t) == TYPE_STRING and t == "current_type":
				if prev_data.size() > 0:
					symbol_arr.push_back(prev_data[prev_data.size() - 1].type)
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
				
				if possible_symbol_counts["common"] == 0 and possible_symbol_counts["uncommon"] == 0 and possible_symbol_counts["rare"] == 0 and possible_symbol_counts["very_rare"] == 0:
					rar = "none"
				else:
					rarities.erase(rar)
				
				if t.has("min_rarity"):
					rarities.clear()
				
				while possible_symbols.size() == 0 and rar != null:
					for z in group_db:
						if $"/root/Main".rarity_database["symbols"][rar].has(z):
							possible_symbols.push_back(z)
					if possible_symbols.size() > 0:
						var sym = possible_symbols[floor(rand_range(0, possible_symbols.size()))]
						rarity_counts.push_back($"/root/Main".tile_database[sym].rarity)
						if sym == "martini" and target.type == "bartender":
							reels.add_queued_achievement(7)
						elif sym == "diamond" and target.type == "ore" and not $"/root/Main/Items".has_unmodded_item("x_ray_machine_essence"):
							reels.add_queued_achievement(103)
						elif target.type == "big_ore":
							syms.push_back(sym)
						reels.symbol_queue.push_back($"/root/Main".existing_symbols[sym])
						break
					if rarities.size() > 0:
						rar = rarities[0]
						rarities.remove(0)
					else:
						rar = null
				if syms.count("sapphire") >= 2:
					reels.add_queued_achievement(123)
				elif syms.count("shiny_pebble") >= 2:
					reels.add_queued_achievement(125)
			else:
				var did_it = false
				if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t.type):
					var with_id = $"/root/Main".append_steam_id(t.type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]) + "_PACK_" + $"/root/Main".mod_pack_nums[t.type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]]
					if $"/root/Main".mod_data.symbols.has(with_id) and not $"/root/Main".mod_data.symbols[with_id].art_replacement and not $"/root/Main".is_mod_disabled(with_id):
						reels.symbol_queue.push_back($"/root/Main".append_steam_id(t.type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]) + "_PACK_" + $"/root/Main".mod_pack_nums[t.type + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t.type]])
						did_it = true
				if not did_it:
					reels.symbol_queue.push_back($"/root/Main".existing_symbols[t.type])
					if t.type == "milk":
						reels.queued_milk += 1
					elif t.type == "honey":
						reels.queued_honey += 1
					elif t.type == "banana_peel":
						reels.queued_banana_peels += 1
					elif t.type == "seed" and c.anim_texture == "peach":
						for p in target.prev_data:
							if p.type == "peach" and p.destroyed_or_removed_by.has("mrs_fruit"):
								reels.queued_seeds += 1
								break
					elif t.type == "golden_egg" and target.type == "goose" and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 1:
						reels.add_queued_achievement(64)
					elif t.type == "spirit" and c.anim_texture == "tomb" and not $"/root/Main/Items".has_unmodded_item("grave_robber_essence") and not $"/root/Main/Items".destroyed_item_types.has("grave_robber_essence") and not items_destroyed_this_spin.has("grave_robber_essence"):
						target.achievement_values[0] += 1
						if target.achievement_values[0] >= 5:
							reels.add_queued_achievement(138)
					elif (t.type == "egg" or t.type == "golden_egg") and target.type == "chicken":
						target.achievement_values[0] += 1
						if t.type == "egg" and target.achievement_values[1] > 0:
							reels.add_queued_achievement(50)
						if target.achievement_values[0] >= 2:
							reels.add_queued_achievement(29)
					elif t.type == "pearl":
						var oyster = target.type == "oyster"
						for p in target.prev_data:
							if p.type == "oyster":
								oyster = true
						if oyster:
							target.achievement_values[0] += 1
							if target.achievement_values[0] >= 2:
								reels.add_queued_achievement(105)
			if (not c.has("from_item") and target.groups.has("spawner0")) or target.type == "rabbit":
				if $"/root/Main/Items".has_unmodded_item("conveyor_belt_essence"):
					items[item_types.find("conveyor_belt_essence")].saved_value += 1
		for s in symbol_arr:
			rarity_counts.push_back($"/root/Main".tile_database[s].rarity)
			reels.symbol_queue.push_back(s)
		if rarity_counts.count("rare") >= 2 and target.type == "big_ore" and not $"/root/Main/Items".has_unmodded_item("x_ray_machine"):
			reels.add_queued_achievement(13)
		for x in range(reels.reel_width):
			for y in range(reels.reel_height):
				reels.add_symbol_position_to_update(Vector2(x, y))
	
	if c.has("items_to_add") and not target.item_adding_effects.has(get_cleaned_effect(c).hash()):
		target.item_adding_effects.push_back(get_cleaned_effect(c).hash())
		reels.items_being_added_during_spin = c.items_to_add.size()
		var item_num = 0
		var i
		var special_arr = false
		var dont_reset_num = false
		if typeof(c.items_to_add[0]) != TYPE_REAL:
			item_num = c.items_to_add.size() - 1
		while item_num > -1:
			if item_num > c.items_to_add.size() - 1:
				i = c.items_to_add[c.items_to_add.size() - 1]
			else:
				i = c.items_to_add[item_num]
			if typeof(i) != TYPE_REAL and i.has("type") and i.type.find("_STEAM_ID_") != -1:
				if $"/root/Main".mod_pack_nums.has(i.type) and not $"/root/Main".is_mod_disabled(i.type + "_PACK_" + $"/root/Main".mod_pack_nums[i.type]):
					i.type += "_PACK_" + $"/root/Main".mod_pack_nums[i.type]
			if typeof(i) == TYPE_REAL:
				if not special_arr:
					item_num = int(i) + 1
					special_arr = true
			elif i.has("rarity"):
				var item_pool = $"/root/Main/".rarity_database["items"][i.rarity].duplicate(true)
				for z in $"/root/Main/Items".items:
					if z.type.substr(z.type.length() - 3, -1) == "_d":
						item_pool.erase(0, -3)
					else:
						item_pool.erase(z.type)
				var i_tbe = []
				for c in item_pool:
					if $"/root/Main".is_mod_disabled(c):
						c_tbe.push_back(c)
				for c in i_tbe:
					item_pool.erase(c)
				randomize()
				if item_pool.size() > 0:
					var added_item = item_pool[floor(rand_range(0, item_pool.size()))]
					$"/root/Main/Items".add_item(added_item)
					if added_item == "pool_ball" and target.type == "item_capsule":
						reels.add_queued_achievement(78)
				else:
					var t = $"/root/Main/".rarity_database["items"][i.rarity][rand_range(0, $"/root/Main/".rarity_database["items"][i.rarity].size())]
					if t == "pool_ball" and target.type == "item_capsule":
						reels.add_queued_achievement(78)
					if special_arr:
						if $"/root/Main/Items".item_types.find(t) == -1:
							$"/root/Main/Items".add_item(t)
							item_num -= 1
						var item_pos = $"/root/Main/Items".item_types.find(t)
						var z
						if item_pos != -1:
							z = $"/root/Main/Items".items[item_pos]
						else:
							z = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(t + "_d")]
						z.item_count += item_num
						z.get_child(0).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_count_text"] + ">" + z.get_child(0).parse_num_str(str(z.item_count)) + "<end>"
						z.get_child(0).force_update = true
						z.get_child(0).update()
						z.update_value_text()
						break
					else:
						$"/root/Main/Items".add_item(t)
			else:
				if special_arr:
					if $"/root/Main/Items".item_types.find(i.type) == -1:
						$"/root/Main/Items".add_item(i.type)
						item_num -= 1
					var item_pos = $"/root/Main/Items".item_types.find(i.type)
					var z
					if item_pos != -1:
						z = $"/root/Main/Items".items[item_pos]
					else:
						z = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find(i.type + "_d")]
					z.item_count += item_num
					z.get_child(0).raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_count_text"] + ">" + z.get_child(0).parse_num_str(str(z.item_count)) + "<end>"
					z.get_child(0).force_update = true
					z.get_child(0).update()
					z.update_value_text()
					break
				else:
					if $"/root/Main".existing_items.has(i.type):
						$"/root/Main/Items".add_item($"/root/Main".existing_items[i.type])
					else:
						$"/root/Main/Items".add_item(i.type)
			item_num -= 1
	
	if c.has("stat_to_change"):
		$"/root/Main/Stats Sprite/Stats".add_stat(c["stat_to_change"], $"/root/Main/Pop-up Sprite/Pop-up".current_floor, c["stat_diff"], false)
	if c.has("stat_to_change_2"):
		$"/root/Main/Stats Sprite/Stats".add_stat(c["stat_to_change_2"], $"/root/Main/Pop-up Sprite/Pop-up".current_floor, c["stat_diff_2"], false)

	if c.has("dynamic_diff_target"):
		if prev_data_obj != null and prev_data_obj.has(c.dynamic_diff_key):
			c.diff = prev_data_obj[c.dynamic_diff_key]
			target.dynamic_diff_targets.push_back({"target": c.dynamic_diff_target, "eff": c, "diff": c.diff, "prev_symbol": {"type": prev_data_obj.type, "grid_position": prev_data_obj.grid_position, "prev_data_pos": null}})
		else:
			c.diff = c.dynamic_diff_target[c.dynamic_diff_key]
			if not c.has("from_item"):
				var dd_target = {"type": type, "grid_position": grid_position, "prev_data_pos": null}
				var arr = reels.displayed_icons[c.dynamic_diff_target.grid_position.y][c.dynamic_diff_target.grid_position.x].prev_data
				for p in range(arr.size() - 1, -1, -1):
					for comp in c.comparisons:
						if typeof(comp.a) == TYPE_STRING and ((comp.a == "type" and comp.b == arr[p].type) or (comp.a == "groups" and $"/root/Main".group_database["symbols"][comp.b].has(arr[p].type))):
							var made_it = true
							for d in target.dynamic_diff_targets:
								if d.prev_symbol.type == arr[p].type:
									made_it = false
									break
							if made_it:
								dd_target = {"type": arr[p].type, "grid_position": grid_position, "prev_data_pos": p}
								break
				target.dynamic_diff_targets.push_back({"target": c.dynamic_diff_target, "eff": c, "diff": c.diff, "prev_symbol": dd_target})
		if c.has("dynamic_diff_multiplier"):
			c.diff *= c.dynamic_diff_multiplier
			if not c.has("from_item"):
				target.dynamic_diff_targets[target.dynamic_diff_targets.size() - 1].diff = c.diff
	
	if not c.has("value_to_change"):
		pass
	elif c.value_to_change == "rarity_bonuses":
		for k in c.diff.keys():
			target[k] *= c.diff[k]
	elif c.value_to_change == "achievement_value":
		target.achievement_values[c.value_num] += c.diff
		if target.type == "watermelon" and target.achievement_values[0] > 0:
			reels.add_queued_achievement(124)
		elif target.type == "egg" and target.achievement_values[0] > 0:
			reels.add_queued_achievement(61)
		elif target.type == "golem" and target.achievement_values[0] > 0:
			reels.add_queued_achievement(63)
		elif target.type == "turtle" and target.achievement_values[0] > 0:
			reels.add_queued_achievement(140)
		elif target.type == "cheese" and target.achievement_values[0] > 0 and target.achievement_values[1] > 0 and target.achievement_values[2] > 0:
			reels.add_queued_achievement(24)
		elif target.type == "crab" and target.achievement_values[0] >= 4:
			reels.add_queued_achievement(37)
		elif target.type == "dame" and target.achievement_values[0] > 0 and target.achievement_values[1] > 0:
			reels.add_queued_achievement(43)
		elif target.type == "mouse" and target.achievement_values[0] > 0 and target.achievement_values[1] > 0:
			reels.add_queued_achievement(98)
		elif target.type == "king_midas" and target.achievement_values[0] > 0:
			reels.add_queued_achievement(82)
		elif (target.type == "apple" or target.type == "strawberry" or target.type == "pear") and target.achievement_values[0] > 0:
			for t in target.get_adjacent_icons():
				if t.type == "farmer":
					reels.add_queued_achievement(55)
					break
		elif target.type == "peach" and target.achievement_values[0] > 0:
			for p in target.prev_data:
				if p.type == "seed" and p.added_by == "peach":
					reels.add_queued_achievement(106)
		elif target.type == "flower" and target.achievement_values[0] > 0:
			for t in target.get_adjacent_icons():
				if t.type == "rain":
					reels.add_queued_achievement(115)
					break
		elif target.type == "sloth" and target.achievement_values[0] > 0 and target.achievement_values[1] > 0:
			reels.add_queued_achievement(127)
		elif target.type == "d3" and target.achievement_values[0] >= 2:
			reels.add_queued_achievement(41)
		elif target.type == "d5" and target.achievement_values[0] >= 2:
			reels.add_queued_achievement(42)
	elif c.value_to_change == "saved_achievement_value":
		target.saved_achievement_values[c.value_num] += c.diff
		if target.type == "bar_of_soap" and target.saved_achievement_values[0] >= 4:
			reels.add_queued_achievement(6)
	elif c.value_to_change == "texture":
		target.get_child(5).texture = extra_textures[c.diff - 1]
	elif c.value_to_change == "saved_values":
		var id = target.get_author_id(c, null, null, target, null)
		if c.has("overwrite") and c.overwrite:
			target.saved_values[id][c.value_num] = c.diff
		else:
			target.saved_values[id][c.value_num] += c.diff
		if c.has("from_item"):
			target.add_conditional_effects()
			target.check_conditional_effects()
	elif c.value_to_change == "bonus_values":
		if c.has("from_item"):
			c.diff *= items[item_types.find(c.from_item)].item_count
		if c.bonus_value_num < target[c.value_to_change].size():
			target[c.value_to_change][c.bonus_value_num] += c.diff
		else:
			target[c.value_to_change].push_back(c.diff)
	elif c.value_to_change == "bonus_value_multipliers":
		if c.has("from_item"):
			c.diff = pow(c.diff, items[item_types.find(c.from_item)].item_count)
		if c.bonus_value_num < target[c.value_to_change].size():
			target[c.value_to_change][c.bonus_value_num] *= c.diff
	elif c.value_to_change == "value_bonus":
		var arr = target.value_bonus_arr
		if c.has("currency"):
			match c.currency:
				"reroll_token":
					arr = target.reroll_token_value_bonus_arr
				"removal_token":
					arr = target.removal_token_value_bonus_arr
				"essence_token":
					arr = target.essence_token_value_bonus_arr
		var prev_target = target
		if prev_data_obj != null and target == self and not c.has("unconditional"):
			prev_target = target
			target = prev_data_obj
			if c.has("currency"):
				match c.currency:
					"reroll_token":
						arr = target.reroll_token_value_bonus_arr
					"removal_token":
						arr = target.removal_token_value_bonus_arr
					"essence_token":
						arr = target.essence_token_value_bonus_arr
			else:
				arr = target.value_bonus_arr
		if c.has("overwrite"):
			arr.clear()
		var can_init_add = true
		var giver = self
		if c.has("giver"):
			giver = c.giver
		elif c.has("from_item"):
			giver = c.from_item
		var d = self
		var pd = reels.displayed_icons[grid_position.y][grid_position.x].prev_data
		var nvm = false
		for comp in c.comparisons:
			if typeof(comp.a) == TYPE_STRING:
				if (comp.a == "type" and comp.b == type) or (comp.a == "groups" and $"/root/Main".group_database["symbols"][comp.b].has(type)):
					nvm = true
				if comp.a == "void_arr" and not c.has("from_item"):
					target.void_arr.push_back(c.giver)
					break
		if nvm:
			pass
		else:
			for p in range(pd.size() - 1, -1, -1):
				var donezo = false
				for comp in c.comparisons:
					if (comp.a == "type" and comp.b == pd[p].type) or (comp.a == "groups" and $"/root/Main".group_database["symbols"][comp.b].has(pd[p].type)):
						d = pd[p]
						donezo = true
						break
				if donezo:
					break
		var p_d_pos
		if prev_data_obj != null:
			p_d_pos = prev_target.prev_data.find(prev_data_obj)
		elif not c.has("from_item") and giver != self:
			p_d_pos = giver.value_bonus_arr.size()
		var c_symbol_eff = null
		if c.has("counted_symbol_eff"):
			c_symbol_eff = c.counted_symbol_eff
		for b in arr:
			var a = b.duplicate(true)
			a.erase("source_eff")
			if a.hash() == { "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "counted_symbol_eff": c_symbol_eff, "source_eff": c, "giver": giver, "ddt": {"type": d.type, "grid_position": grid_position, "prev_data_pos": p_d_pos} }.hash():
				can_init_add = false
		if can_init_add:
			var a_tbe = []
			for a in arr:
				if a.counted_symbol_eff != null and a.counted_symbol_eff == c_symbol_eff:
					a_tbe.push_back(a)
			for a in a_tbe:
				arr.erase(a)
			arr.push_back({ "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "counted_symbol_eff": c_symbol_eff, "source_eff": c, "giver": giver, "ddt": {"type": d.type, "grid_position": grid_position, "prev_data_pos": p_d_pos} })
			if not c.has("from_item") and (target.type == "amethyst" or target.type == "pear"):
				target.permanent_bonus += target.values[0]
				if target.type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
					reels.add_queued_achievement(0)
				elif target.type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
					reels.add_queued_achievement(107)
		target = prev_target
		if c.has("unconditional"):
			for p in prev_target.prev_data:
				var can_add = true
				for vb in p.value_bonus_arr:
					if vb.hash() == { "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "counted_symbol_eff": c_symbol_eff, "source_eff": c, "giver": giver, "ddt": {"type": d.type, "grid_position": d.grid_position, "prev_data_pos": prev_target.prev_data.find(p)} }.hash():
						can_add = false
						break
				if can_add:
					p.value_bonus_arr.push_back({ "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "counted_symbol_eff": c_symbol_eff, "source_eff": c, "giver": giver, "ddt": {"type": d.type, "grid_position": d.grid_position, "prev_data_pos": prev_target.prev_data.find(p)} })
					p.effect_hashes.push_back(get_prev_cleaned_effect(c).hash())
					if not c.has("from_item") and (p.type == "amethyst" or p.type == "pear"):
						p.permanent_bonus += $"/root/Main".tile_database[p.type].values[0]
						if p.type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
							reels.add_queued_achievement(0)
						elif p.type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
							reels.add_queued_achievement(107)
	elif c.value_to_change == "value_multiplier":
		var arr = target.value_multiplier_arr
		if c.has("currency"):
			match c.currency:
				"reroll_token":
					arr = target.reroll_token_value_multiplier_arr
				"removal_token":
					arr = target.removal_token_value_multiplier_arr
				"essence_token":
					arr = target.essence_token_value_multiplier_arr
		var prev_target = target
		if prev_data_obj != null and target == self and not c.has("unconditional"):
			prev_target = target
			target = prev_data_obj
			if c.has("currency"):
				match c.currency:
					"reroll_token":
						arr = target.reroll_token_value_multiplier_arr
					"removal_token":
						arr = target.removal_token_value_multiplier_arr
					"essence_token":
						arr = target.essence_token_value_multiplier_arr
			else:
				arr = target.value_multiplier_arr
		if c.has("overwrite"):
			arr.clear()
		var can_init_add = true
		var giver = null
		if c.has("giver"):
			giver = c.giver
		elif c.has("from_item"):
			giver = c.from_item
		var src_eff = c.duplicate(true)
		src_eff.erase("anim_texture")
		for b in arr:
			var a = b.duplicate(true)
			a.erase("source_eff")
			if a.hash() == { "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "giver": giver}.hash():
				can_init_add = false
		if can_init_add:
			arr.push_back({ "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "source_eff": src_eff, "giver": giver })
			if c.has("giver"):
				if c.giver.type == "light_bulb":
					c.giver.achievement_values[0] += 1
					if c.giver.achievement_values[0] >= 5:
						reels.add_queued_achievement(84)
				elif c.giver.type == "joker":
					c.giver.achievement_values[0] += 1
					if c.giver.achievement_values[0] >= 5:
						reels.add_queued_achievement(80)
				elif c.giver.type == "beastmaster":
					c.giver.achievement_values[0] += 1
					if c.giver.achievement_values[0] >= 5:
						reels.add_queued_achievement(9)
				elif c.giver.type == "chef":
					c.giver.achievement_values[0] += 1
					if c.giver.achievement_values[0] >= 5:
						reels.add_queued_achievement(25)
			if not c.has("from_item") and (target.type == "amethyst" or target.type == "pear"):
				if giver.type == "buffing_powder":
					var multi = $"/root/Main".tile_database[target.type].values[0]
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						multi *= items[item_types.find("capsule_machine")].values[0]
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						multi *= items[item_types.find("capsule_machine_essence")].values[0]
					permanent_bonus += multi
					giver.achievement_values[0] += 1
					if giver.achievement_values[0] >= 2:
						reels.add_queued_achievement(20)
				else:
					permanent_bonus += $"/root/Main".tile_database[target.type].values[0]
				if target.type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
					reels.add_queued_achievement(0)
				elif target.type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
					reels.add_queued_achievement(107)
			if not c.has("from_item") and not $"/root/Main".demo:
				if $"/root/Main".group_database["symbols"]["anvillikes"].has(target.type) and target.destroyed_or_removed_by.has("dwarf"):
					reels.add_queued_achievement(49)
				elif $"/root/Main".group_database["symbols"]["monkeylikes"].has(target.type) and target.destroyed_or_removed_by.has("monkey"):
					reels.add_queued_achievement(96)
		target = prev_target
		if c.has("unconditional"):
			for p in prev_target.prev_data:
				var can_add = true
				for vm in p.value_multiplier_arr:
					var t_vm = vm.duplicate(true)
					t_vm.erase("source_eff")
					if t_vm.hash() == { "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "giver": giver }.hash():
						can_add = false
						break
				if can_add:
					p.value_multiplier_arr.push_back({ "source": self, "value": c.diff, "unconditional": c.has("unconditional"), "source_eff": src_eff, "giver": giver })
					p.effect_hashes.push_back(get_prev_cleaned_effect(c).hash())
					if not $"/root/Main".demo:
						if $"/root/Main".group_database["symbols"]["anvillikes"].has(p.type) and p.destroyed_or_removed_by.has("dwarf"):
							reels.add_queued_achievement(49)
						elif $"/root/Main".group_database["symbols"]["monkeylikes"].has(p.type) and p.destroyed_or_removed_by.has("monkey"):
							reels.add_queued_achievement(96)
					if not c.has("from_item") and (p.type == "amethyst" or p.type == "pear"):
						if giver.type == "buffing_powder":
							var multi = $"/root/Main".tile_database[p.type].values[0]
							if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
								multi *= items[item_types.find("capsule_machine")].values[0]
							if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
								multi *= items[item_types.find("capsule_machine_essence")].values[0]
							p.permanent_bonus += multi
							giver.achievement_values[0] += 1
							if giver.achievement_values[0] >= 2:
								reels.add_queued_achievement(20)
						else:
							p.permanent_bonus += $"/root/Main".tile_database[p.type].values[0]
						if p.type == "amethyst" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
							reels.add_queued_achievement(0)
						elif p.type == "pear" and permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
							reels.add_queued_achievement(107)
	elif c.value_to_change == "flat_value_bonus":
		target[c.value_to_change] = c.diff
		for t in target.get_adjacent_icons():
			reels.add_symbol_position_to_update(t.grid_position)
	elif c.has("multiply") and not c.has("overwrite"):
		target[c.value_to_change] *= c.diff
	elif c.value_to_change == "type":
		if c.has("group"):
			randomize()
			var rand_num = rand_range(0, 1)
			var r_chances = $"/root/Main/".rarity_chances["symbols"].duplicate(true)
			r_chances["uncommon"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["uncommon"]
			r_chances["rare"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["rare"]
			r_chances["very_rare"] *= $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]["very_rare"]
			
			var possible_symbol_counts = { "common": 0, "uncommon": 0, "rare": 0, "very_rare": 0 }
			
			var group_db = $"/root/Main".group_database["symbols"][c.group].duplicate(true)
			
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
			if c.has("min_rarity"):
				rar = c.min_rarity
			if rand_num < r_chances.very_rare and possible_symbol_counts["very_rare"] > 0:
				rar = "very_rare"
			elif rand_num < r_chances.very_rare + r_chances.rare and rar != "very_rare" and possible_symbol_counts["rare"] > 0:
				rar = "rare"
			elif rand_num < r_chances.very_rare + r_chances.rare + r_chances.uncommon and rar != "rare" and rar != "very_rare" and possible_symbol_counts["uncommon"] > 0:
				rar = "uncommon"
			
			var possible_symbols = []
			var rarities = ["common", "uncommon", "rare", "very_rare"]
			
			for t in group_db:
				if $"/root/Main".rarity_database["symbols"][rar].has(t):
					possible_symbols.push_back(t)
			
			rarities.erase(rar)
			
			if c.has("min_rarity"):
				rarities.clear()
			
			var new_type
			
			if possible_symbols.size() > 0:
				new_type = possible_symbols[floor(rand_range(0, possible_symbols.size()))]
			else:
				while possible_symbols.size() == 0 and rar != null:
					for z in group_db:
						if $"/root/Main".rarity_database["symbols"][rar].has(z):
							possible_symbols.push_back(z)
					if possible_symbols.size() > 0:
						new_type = possible_symbols[floor(rand_range(0, possible_symbols.size()))]
						break
					if rarities.size() > 0:
						rar = rarities[0]
						rarities.remove(0)
					else:
						rar = null
			
			if target.type == "seed" and $"/root/Main/Items".has_unmodded_item("watering_can_essence"):
				items[item_types.find("watering_can_essence")].temp_destroy()
			if new_type != null:
				target.change_type(new_type, true)
		else:
			var new_type = c.diff
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(new_type):
				var with_id = $"/root/Main".append_steam_id(new_type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[new_type]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(new_type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[new_type])]
				if $"/root/Main".mod_data.symbols.has(with_id) and not $"/root/Main".mod_data.symbols[with_id].art_replacement and not $"/root/Main".is_mod_disabled(with_id):
					new_type = with_id
				if $"/root/Main".is_mod_disabled(with_id):
					new_type = with_id.substr(0, with_id.find("_STEAM_ID_"))
			if new_type == "diamond" and target.type == "coal" and not $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
				$"/root/Main/Pop-up Sprite/Pop-up".transformed_coals += 1
			target.change_type(new_type, true)
		reels.symbol_transformed_during_spin = true
	elif c.has("add_to_array"):
		if c.value_to_change == "permanent_bonuses":
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
	elif c.value_to_change == "extra_symbol_choices":
		$"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices += c.diff
	elif c.value_to_change == "extra_item_choices":
		$"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices += c.diff
	elif c.value_to_change == "symbols_to_choose_from":
		$"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from_from_mods += c.diff
	elif c.value_to_change == "items_to_choose_from":
		$"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from_from_mods += c.diff
	elif c.value_to_change == "spins_left":
		$"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] += c.diff
	elif c.value_to_change == "forced_add":
		if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1 and not $"/root/Main/Pop-up Sprite/Pop-up".hex_of_emptiness_trigger:
			$"/root/Main/Pop-up Sprite/Pop-up".hex_of_hoarding_trigger = c.diff
	elif c.value_to_change == "forced_skip":
		if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1 and not $"/root/Main/Pop-up Sprite/Pop-up".hex_of_hoarding_trigger:
			$"/root/Main/Pop-up Sprite/Pop-up".hex_of_emptiness_trigger = c.diff
	elif typeof(c.diff) == TYPE_BOOL or c.has("overwrite"):
		if c.value_to_change == "destroyed" and c.has("overwrite_prev_data"):
			for d in target.prev_data:
				d.destroyed = c.diff
			if not target.indestructible:
				target[c.value_to_change] = c.diff
		elif c.value_to_change == "drained":
			if target.get_value("coin") < 0:
				reels.add_queued_achievement(68)
			target[c.value_to_change] = c.diff
		elif c.value_to_change == "destroyed":
			if not target.destroyed and target.type != "empty" and not target.tbd:
				if target.indestructible:
					target.dove_destroyed = true
					check_item_triggers(c, target)
				else:
					reels.add_symbol_position_tbd(target.grid_position)
					if target.indestructible:
						target.dove_destroyed = true
						check_item_triggers(c, target)
					else:
						target.tbd = true
						if c.has("giver"):
							c.giver.symbols_destroyed.push_back(target.type)
							if c.giver.type == "monkey" and c.giver.symbols_destroyed.count("coconut") >= 1 and c.giver.symbols_destroyed.count("coconut_half") >= 2:
								reels.add_queued_achievement(32)
							elif c.giver.type == "toddler" and c.giver.symbols_destroyed.size() >= 6:
								reels.add_queued_achievement(137)
							elif c.giver.type == "banana_peel" and c.giver.symbols_destroyed.count("thief") >= 2:
								reels.add_queued_achievement(5)
							elif c.giver.type == "bounty_hunter" and c.giver.symbols_destroyed.count("thief") >= 2:
								reels.add_queued_achievement(16)
							elif c.giver.type == "key" and c.giver.symbols_destroyed.size() >= 2:
								reels.add_queued_achievement(81)
							elif c.giver.type == "hooligan" and c.giver.symbols_destroyed.size() >= 3:
								reels.add_queued_achievement(76)
							if c.has("destroy_giver_on_destroy") and not c.giver.indestructible:
								c.giver.tbd = true
								reels.add_symbol_position_tbd(c.giver.grid_position)
					target.get_child(1).visible = false
					target.get_child(2).visible = false
					target.get_child(3).visible = false
			if target.tbd or target.removed:
				if c.has("giver") and not target.destroyed_or_removed_by.has(c.giver.type):
					target.destroyed_or_removed_by.push_back(c.giver.type)
					check_shared_symbol(target)
				check_destroyed_symbol(target)
			if c.has("giver") and c.has("destroy_giver_on_destroy") and not c.giver.indestructible:
				if not c.giver.destroyed_or_removed_by.has(target.type):
					c.giver.destroyed_or_removed_by.push_back(target.type)
					check_shared_symbol(c.giver)
				check_destroyed_symbol(c.giver)
		elif c.value_to_change == "removed":
			if not target.removed and target.type != "empty" and can_be_removed:
				$"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.push_back(target.type)
				if c.has("giver") and not target.destroyed_or_removed_by.has(c.giver.type):
					target.destroyed_or_removed_by.push_back(c.giver.type)
					check_shared_symbol(target)
				target[c.value_to_change] = c.diff
				if $"/root/Main".group_database.symbols["fossillikes"].has(target.type):
					$"/root/Main/Pop-up Sprite/Pop-up".fossil_diff += 1
		elif c.value_to_change == "wildcarded":
			if c.has("giver") and c.giver.type == "card_shark":
				c.giver.achievement_values[0] += 1
				if c.giver.achievement_values[0] >= 5:
					reels.add_queued_achievement(22)
			target[c.value_to_change] = c.diff
		else:
			target[c.value_to_change] = c.diff
	elif c.value_to_change == "permanent_bonus" or c.value_to_change == "reroll_token_permanent_bonus" or c.value_to_change == "removal_token_permanent_bonus" or c.value_to_change == "essence_token_permanent_bonus":
		var prev_target = target
		for t in target.prev_data:
			for comparison in c.comparisons:
				if typeof(comparison.a) == TYPE_STRING:
					var the_bool = comparison.a == "type" and t.type == comparison.b and t.effect_hashes.find(get_prev_cleaned_effect(c).hash()) == -1
					var the_bool2 = comparison.a == "groups" and $"/root/Main".group_database["symbols"][comparison.b].has(t.type) and t.effect_hashes.find(get_prev_cleaned_effect(c).hash()) == -1
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						prev_data_obj = t
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						prev_data_obj = t
						break
		if prev_data_obj != null and target == self:
			prev_target = target
			target = prev_data_obj
		elif c.has("giver"):
			for t in c.giver.prev_data:
				if t.type == c.giver_texture:
					prev_target = target
					target = t
					break
		target[c.value_to_change] += c.diff
		if c.value_to_change == "permanent_bonus" and target.permanent_bonus >= 20 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12:
			match target.type:
				"archaeologist":
					reels.add_queued_achievement(3)
				"diver":
					reels.add_queued_achievement(46)
				"dove":
					reels.add_queued_achievement(48)
				"mrs_fruit":
					reels.add_queued_achievement(99)
				"pirate":
					reels.add_queued_achievement(110)
		target = prev_target
	elif c.value_to_change == "permanent_multiplier" or c.value_to_change == "reroll_token_permanent_multiplier" or c.value_to_change == "removal_token_permanent_multiplier" or c.value_to_change == "essence_token_permanent_multiplier":
		var prev_target = target
		for t in target.prev_data:
			for comparison in c.comparisons:
				if typeof(comparison.a) == TYPE_STRING:
					var the_bool = comparison.a == "type" and t.type == comparison.b and t.effect_hashes.find(get_prev_cleaned_effect(c).hash()) == -1
					var the_bool2 = comparison.a == "groups" and $"/root/Main".group_database["symbols"][comparison.b].has(t.type) and t.effect_hashes.find(get_prev_cleaned_effect(c).hash()) == -1
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						prev_data_obj = t
						break
					elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
						prev_data_obj = t
						break
		if prev_data_obj != null and target == self:
			prev_target = target
			target = prev_data_obj
		elif c.has("giver"):
			for t in c.giver.prev_data:
				if t.type == c.giver_texture:
					prev_target = target
					target = t
					break
		target[c.value_to_change] *= c.diff
		target = prev_target
	elif c.value_to_change == "pointing_directions":
		if typeof(c.diff) == TYPE_DICTIONARY:
			var dir_arr = []
			if c.diff.directions[0] == "ALL":
				dir_arr = [1, 2, 3, 4, 5, 6, 7, 8]
				pointing_directions = dir_arr.duplicate()
			else:
				var tmp_arr = []
				for d in c.diff.directions:
					match d:
						"N":
							tmp_arr.push_back(2)
						"NE":
							tmp_arr.push_back(3)
						"E":
							tmp_arr.push_back(4)
						"SE":
							tmp_arr.push_back(5)
						"S":
							tmp_arr.push_back(6)
						"SW":
							tmp_arr.push_back(7)
						"W":
							tmp_arr.push_back(8)
						"NW":
							tmp_arr.push_back(1)
						"RAND":
							var arr = [1, 2, 3, 4, 5, 6, 7, 8]
							for t in tmp_arr:
								arr.erase(t)
							randomize()
							tmp_arr.push_back(arr[floor(rand_range(0, arr.size()))])
				dir_arr = tmp_arr.duplicate(true)
				pointing_directions.clear()
				for n in c.diff.directions:
					randomize()
					var dir = dir_arr[floor(rand_range(0, dir_arr.size()))]
					dir_arr.erase(dir)
					pointing_directions.push_back(dir)
		else:
			target[c.value_to_change] = c.diff
			var pointed_symbols = get_directional_icons(target.pointing_directions)
			for i in pointed_symbols:
				reels.add_symbol_position_to_update(i.grid_position)
				add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [], "value_to_change": "value_multiplier", "diff": target.values[0], "unconditional": true})
				add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "target"}, {"a": null, "b": true, "dynamic_a_target": self, "dynamic_a_key": "done_spinning"}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
			if pointed_symbols.size() == 0:
				reels.bad_arrows.push_back(target.type)
				if $"/root/Main/Items".has_unmodded_item("quiver_essence"):
					items[item_types.find("quiver_essence")].add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true})
					items[item_types.find("quiver_essence")].check_conditional_effects()
	elif c.value_to_change == "destroyed_or_removed_by":
		if not target.destroyed_or_removed_by.has(c.diff):
			target.destroyed_or_removed_by.push_back(c.diff)
			check_shared_symbol(target)
	elif target[c.value_to_change] != null:
		target[c.value_to_change] += c.diff
		
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
				if steam_id != "" and pack_num != "":
					e["type"] = e.type + "_STEAM_ID_" + steam_id + "_PACK" + pack_num
				if e.has("extra_values"):
					$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], e.extra_values)
				elif e.type == "add_item" and not e.has("extra_values"):
					$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], $"/root/Main/Pop-up Sprite/Pop-up".get_forced_item_rarities($"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from))
				elif e.type == "add_tile" and not e.has("extra_values"):
					$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], $"/root/Main/Pop-up Sprite/Pop-up".get_forced_rarities($"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from))
				else:
					$"/root/Main/Pop-up Sprite/Pop-up".add_event(e["type"], {})
	
	check_item_triggers(c, target)

func check_destroyed_symbol(target):
	match target.type:
		"pinata":
			if $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 2:
				reels.add_queued_achievement(109)
		"present":
			var time_machine_diff = 0
			if $"/root/Main/Items".has_unmodded_item("time_machine"):
				time_machine_diff = items[item_types.find("time_machine")].values[0] * items[item_types.find("time_machine")].item_count
			if times_displayed == 11 - time_machine_diff:
				reels.add_queued_achievement(111)
		"bubble":
			var break_out = false
			for a in target.get_adjacent_icons():
				if a.type == "pufferfish":
					reels.add_queued_achievement(112)
					break
				for p in a.prev_data:
					if p.type == "pufferfish":
						reels.add_queued_achievement(112)
						break_out = true
						break
				if break_out:
					break
		"witch":
			if target.destroyed_or_removed_by.has("eldritch_beast"):
				reels.add_queued_achievement(148)
		"comedian":
			if target.destroyed_or_removed_by.has("general_zaroff"):
				reels.add_queued_achievement(35)
		"martini":
			var break_out = false
			for a in target.get_adjacent_icons():
				if a.type == "dwarf":
					reels.add_queued_achievement(89)
					break
				for p in a.prev_data:
					if p.type == "dwarf":
						reels.add_queued_achievement(89)
						break_out = true
						break
				if break_out:
					break
		"beer":
			var break_out = false
			for a in target.get_adjacent_icons():
				if a.type == "miner":
					reels.add_queued_achievement(95)
					break
				for p in a.prev_data:
					if p.type == "miner":
						reels.add_queued_achievement(95)
						break_out = true
						break
				if break_out:
					break
		"matryoshka_doll_1", "matryoshka_doll_2", "matryoshka_doll_3", "matryoshka_doll_4":
			if target.destroyed_or_removed_by.size() > 0:
				reels.add_queued_achievement(90)
		"moon":
			reels.add_queued_achievement(97)
		"reroll_capsule", "removal_capsule", "lucky_capsule":
			target.saved_achievement_values[0] = 0
		"apple":
			if target.destroyed_or_removed_by.has("robin_hood") and grid_position.y < reels.reel_height - 1:
				if reels.displayed_icons[grid_position.y + 1][grid_position.x].type == "toddler":
					reels.add_queued_achievement(119)
				for p in reels.displayed_icons[grid_position.y + 1][grid_position.x].prev_data:
					if p.type == "toddler":
						reels.add_queued_achievement(119)
						break
		"milk":
			if target.destroyed_or_removed_by.has("cat") and added_by == "cow":
				reels.add_queued_achievement(36)
		"honey":
			if target.destroyed_or_removed_by.has("bear") and added_by == "beehive":
				reels.add_queued_achievement(11)
		"thief":
			if target.destroyed_or_removed_by.has("banana_peel"):
				var break_out = false
				for a in target.get_adjacent_icons():
					if a.type == "banana_peel" and a.added_by == "banana":
						reels.add_queued_achievement(4)
						break
					for p in a.prev_data:
						if p.type == "banana_peel" and p.added_by == "banana":
							reels.add_queued_achievement(4)
							break_out = true
							break
					if break_out:
						break
		"target":
			var break_out = false
			var adj_icons = target.get_adjacent_icons()
			for x in range(reels.reel_width):
				for y in range(reels.reel_height):
					if not adj_icons.has(reels.displayed_icons[y][x]) and reels.displayed_icons[y][x].groups.has("arrow") and reels.displayed_icons[y][x].get_directional_icons(reels.displayed_icons[y][x].pointing_directions).has(target):
						reels.add_queued_achievement(133)
						break_out = true
						break
				if break_out:
					break
		"void_creature":
			if $"/root/Main/Items".has_unmodded_item("shrine"):
				var break_out = false
				for a in target.get_adjacent_icons():
					if a.type == "beastmaster":
						reels.add_queued_achievement(142)
						break
					for p in a.prev_data:
						if p.type == "beastmaster":
							reels.add_queued_achievement(142)
							break_out = true
							break
					if break_out:
						break
	if target.groups.has("chest") and target.destroyed_or_removed_by.has("key"):
		var break_out = false
		for a in target.get_adjacent_icons():
			if a.type == "magic_key":
				reels.add_queued_achievement(87)
				break
			for p in a.prev_data:
				if p.type == "magic_key":
					reels.add_queued_achievement(87)
					break_out = true
					break
			if break_out:
				break

func check_symbol_value(target, num):
	match target.type:
		"coin":
			if num >= 20:
				reels.add_queued_achievement(34)
		"honey":
			if num >= 20:
				reels.add_queued_achievement(75)
		"omelette":
			if num >= 20:
				reels.add_queued_achievement(101)
		"flower":
			if num >= 19073486328125:
				reels.add_queued_achievement(56)
		"gambler":
			if num >= 200 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12 and target.destroyed:
				reels.add_queued_achievement(58)
		"thief":
			if num >= 500 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid < 12 and target.destroyed:
				reels.add_queued_achievement(135)
		"wildcard":
			if num >= 1000000 and not reels.big_wildcards.has(grid_position):
				reels.big_wildcards.push_back(grid_position)
		"cat":
			if num >= 999999999:
				reels.add_queued_achievement(23)
		"bee":
			if num >= 6:
				reels.add_queued_achievement(10)
		"snail":
			if num >= 20:
				reels.add_queued_achievement(128)
		"owl":
			if num >= 12:
				reels.add_queued_achievement(104)
		"void_stone":
			if num >= 50:
				reels.add_queued_achievement(144)

func check_shared_symbol(target):
	var t_types = [target.type]
	for p in target.prev_data:
		t_types.push_back(p.type)
	for t in t_types:
		match t:
			"anchor":
				if target.destroyed_or_removed_by.has("diver") and target.destroyed_or_removed_by.has("pirate"):
					reels.add_queued_achievement(1)
					break
			"beer":
				if target.destroyed_or_removed_by.has("dwarf") and target.destroyed_or_removed_by.has("pirate"):
					reels.add_queued_achievement(12)
					break
			"coconut_half":
				if target.destroyed_or_removed_by.has("mrs_fruit") and target.destroyed_or_removed_by.has("monkey"):
					reels.add_queued_achievement(33)
					break
			"bubble":
				if target.destroyed_or_removed_by.has("goldfish") and target.destroyed_or_removed_by.has("toddler"):
					reels.add_queued_achievement(62)
					break
			"orange":
				if target.destroyed_or_removed_by.has("mrs_fruit") and target.destroyed_or_removed_by.has("pirate"):
					reels.add_queued_achievement(102)
					break
			"pearl":
				if target.destroyed_or_removed_by.has("diver") and target.destroyed_or_removed_by.has("archaeologist"):
					reels.add_queued_achievement(108)
					break

func do_comp(comparison, c, target, c_effects, c_tbe):
	var comparison_target = self
	var b_mod = 0

	if comparison.has("target_self") and c.has("giver"):
		comparison_target = c.giver
	elif typeof(comparison.a) == TYPE_STRING and not comparison.has("not_prev") and comparison.a != "destroyed" and comparison.a != "removed" and comparison.a != "type" and comparison.a != "groups" and comparison.a != "tbd" and comparison.a != "void_arr":
		if t_prev_data.size() > 0 and t_prev_data[0].has(comparison.a):
			for p in comparison_target.t_prev_data:
				if p[comparison.a] == comparison.b:
					comparison_target = p
					break
	
	if comparison.has("dynamic_a_target"):
		comparison.a = comparison.dynamic_a_key
		comparison_target = comparison.dynamic_a_target
	if comparison.has("dynamic_b_target"):
		comparison.b = comparison.dynamic_b_target[comparison.dynamic_b_key]
	if comparison.has("dynamic_b_mod_target"):
		b_mod = comparison.dynamic_b_mod_target[comparison.dynamic_b_mod_key]
		if comparison.has("dynamic_b_mod_multiplier"):
			b_mod *= comparison.dynamic_b_mod_multiplier
	if c.has("one_time") and target.one_times.has(get_fully_cleaned_effect(c).hash()):
		c_effects.erase(c)
		return false
	if (c.has("items_to_add") and target.item_adding_effects.has(get_cleaned_effect(c).hash())) or (c.has("tiles_to_add") and target.tile_adding_effects.has(get_cleaned_effect(c).hash())):
		return false
	
	for k in comparison.keys():
		if typeof(comparison[k]) == TYPE_DICTIONARY and (comparison[k].has("var_math") or comparison[k].has("starting_value")):
			if c.has("from_item"):
				comparison[k] = items[item_types.find(c.from_item)].parse_var_math(comparison[k], items[item_types.find(c.from_item)], c)
			else:
				comparison[k] = parse_var_math(comparison[k], null, c)
	
	if typeof(comparison.b) == TYPE_DICTIONARY and comparison.b.has("counted_symbols"):
		reels.count_symbols(true)
		var with_id = comparison.b.counted_symbols
		if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comparison.b.counted_symbols):
			with_id = $"/root/Main".append_steam_id(comparison.b.counted_symbols, $"/root/Main".mod_data.symbols[comparison.b.counted_symbols].author_id) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comparison.b.counted_symbols, $"/root/Main".mod_data.symbols[comparison.b.counted_symbols].author_id)]
			if $"/root/Main".mod_data.symbols.has(with_id) and $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
				with_id = comparison.b.counted_symbols
		var the_bool = reels.counted_symbols[with_id] != -1
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			comparison.b = reels.counted_symbols[comparison.b.counted_symbols]
		else:
			return false

	if typeof(comparison.a) == TYPE_STRING and comparison.a == "values":
		if comparison.has("rand"):
			var prev_comp_t = comparison_target
			if comparison.has("value_target_override"):
				comparison_target = comparison.value_target_override
			randomize()
			var conveyor_belt_essence_multiplier = 1
			var item_multiplier = 1
			var add_mod = 1
			if comparison_target.type == "rabbit":
				add_mod = 0
			if groups.has("spawner0") and c.has("tiles_to_add"):
				for i in $"/root/Main/Items".destroyed_items:
					if i == "conveyor_belt_essence":
						conveyor_belt_essence_multiplier *= $"/root/Main".item_database["conveyor_belt_essence"].values[1]
			if c.has("from_item"):
				item_multiplier = items[item_types.find(c.from_item)].item_count
			var fp_13 = false
			for fp in $"/root/Main/Landlord".fine_print:
				if fp.num == 13 and fp.dynamic_icon == comparison_target.type:
					fp_13 = true
					break
			if fp_13 or comparison_target.values.size() <= comparison.value_num or (comparison_target.values[comparison.value_num] * add_mod * item_multiplier + comparison_target.bonus_values[comparison.value_num]) * comparison_target.bonus_value_multipliers[comparison.value_num] * conveyor_belt_essence_multiplier < rand_range(0, 100):
				var cleaned_c = get_cleaned_effect(c)
				erased_effects.push_back(cleaned_c)
				erased_effect_hashes.push_back(cleaned_c.hash())
				current_effect_hashes.erase(cleaned_c.hash())
				if given_effect_hashes.find(get_cleaned_effect(current_effect).hash()) != -1:
					given_effects.remove(given_effect_hashes.find(get_cleaned_effect(current_effect).hash()))
				given_effect_hashes.erase(cleaned_c.hash())
				c_tbe.push_back(c)
				return false
			elif not comparison_target.gained_saved_achievement_value and not erased_effects.has(get_cleaned_effect(c)):
				if comparison_target.type == "hex_of_destruction":
					comparison_target.saved_achievement_values[0] += 1
					comparison_target.gained_saved_achievement_value = true
					if comparison_target.saved_achievement_values[0] >= 3:
						reels.add_queued_achievement(67)
				elif comparison_target.type == "hex_of_emptiness":
					comparison_target.saved_achievement_values[0] += 1
					comparison_target.gained_saved_achievement_value = true
					if comparison_target.saved_achievement_values[0] >= 3:
						reels.add_queued_achievement(69)
				elif comparison_target.type == "hex_of_hoarding":
					comparison_target.saved_achievement_values[0] += 1
					comparison_target.gained_saved_achievement_value = true
					if comparison_target.saved_achievement_values[0] >= 3:
						reels.add_queued_achievement(70)
				elif comparison_target.type == "hex_of_midas":
					comparison_target.saved_achievement_values[0] += 1
					comparison_target.gained_saved_achievement_value = true
					if comparison_target.saved_achievement_values[0] >= 3:
						reels.add_queued_achievement(71)
				elif comparison_target.type == "hex_of_thievery":
					comparison_target.saved_achievement_values[0] += 1
					comparison_target.gained_saved_achievement_value = true
					if comparison_target.saved_achievement_values[0] >= 3:
						reels.add_queued_achievement(73)
		elif comparison.has("greater_than_eq"):
			var the_bool = comparison_target.values[comparison.value_num] + comparison_target.bonus_values[comparison.value_num] < comparison.b
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
		else:
			var the_bool = (comparison_target.values[comparison.value_num] + comparison_target.bonus_values[comparison.value_num]) * comparison_target.bonus_value_multipliers[comparison.value_num] != comparison.b
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "final_value":
		var fv
		if typeof(comparison_target) == TYPE_DICTIONARY:
			fv = comparison_target["final_value"]
		else:
			fv = comparison_target.get_value("coin")
		if comparison.has("less_than"):
			var the_bool = fv >= int(comparison.b)
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
		elif comparison.has("greater_than"):
			var the_bool = fv <= int(comparison.b)
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
		elif comparison.has("less_than_eq"):
			var the_bool = fv > int(comparison.b)
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
		elif comparison.has("greater_than_eq"):
			var the_bool = fv < int(comparison.b)
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
		else:
			var the_bool = fv != int(comparison.b)
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "value_bonus":
		var value_bonus = 0
		var arr = comparison_target.value_bonus_arr
		if comparison.has("currency"):
			match c.currency:
				"reroll_token":
					arr = target.reroll_token_value_bonus_arr
				"removal_token":
					arr = target.removal_token_value_bonus_arr
				"essence_token":
					arr = target.essence_token_value_bonus_arr
		for v in arr:
			value_bonus += v.value
		var the_bool = (value_bonus <= int(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (value_bonus < int(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (value_bonus >= int(comparison.b) and comparison.has("less_than") and comparison.less_than) or (value_bonus > int(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "value_multiplier":
		var value_multiplier = 1
		var arr = comparison_target.value_multiplier_arr
		if comparison.has("currency"):
			match c.currency:
				"reroll_token":
					arr = target.reroll_token_value_multiplier_arr
				"removal_token":
					arr = target.removal_token_value_multiplier_arr
				"essence_token":
					arr = target.essence_token_value_bonus_arr
		for v in arr:
			value_multiplier *= v.value
		var the_bool = (value_multiplier <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (value_multiplier < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (value_multiplier >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (value_multiplier > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "type" and not comparison.has("not_prev"):
		var eff = c.duplicate(true)
		var p_d_obj
		var has_prev_type = false
		
		if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comparison.b):
			var with_id = $"/root/Main".append_steam_id(comparison.b, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comparison.b]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comparison.b, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comparison.b])]
			if $"/root/Main".mod_data.symbols.has(with_id) and not $"/root/Main".mod_data.symbols[with_id].art_replacement:
				comparison.b = with_id
			if $"/root/Main".is_mod_disabled(with_id):
				comparison.b = with_id.substr(0, with_id.find("_STEAM_ID_"))
		
		for t in comparison_target.t_prev_data:
			if t.type == comparison.b and t.effect_hashes.find(get_prev_cleaned_effect(eff).hash()) == -1:
				p_d_obj = t
				has_prev_type = true
				break
			if has_prev_type:
				break
		var the_bool = not has_prev_type and not comparison_target.type == comparison.b
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif not check_dove_conditionals(c):
			return false
		elif p_d_obj != null:
			prev_data_obj = p_d_obj
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "destroyed" and not comparison.has("not_prev"):
		var eff = c.duplicate(true)
		var was_prev_destroyed = false
		var p_d_obj

		for t in comparison_target.t_prev_data:
			if t.destroyed and t.effect_hashes.find(get_prev_cleaned_effect(eff).hash()) == -1:
				var type_to_check
				var group_to_check
				var any = true
				for comp in c.comparisons:
					if typeof(comp.a) == TYPE_STRING:
						if comp.a == "type":
							type_to_check = comp.b
							any = false
							break
						elif comp.a == "groups":
							group_to_check = comp.b
							any = false
							break
				if type_to_check == t.type or (group_to_check != null and $"/root/Main".group_database["symbols"][group_to_check].has(t.type)) or (type_to_check == null and group_to_check == null) or (any and eff.has("unconditional")):
					p_d_obj = t
					was_prev_destroyed = true
					break
			if was_prev_destroyed:
				break
		var tmp_adj_icons = get_adjacent_icons()
		for x in range(reels.reel_width):
			for y in range(reels.reel_height):
				if reels.displayed_icons[y][x].type == "dove" and tmp_adj_icons.has(reels.displayed_icons[y][x]):
					add_effect_to_symbol(grid_position.y, grid_position.x, {"comparisons": [{"a": "dove_destroyed", "b": true}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[y][x]], "sfx_override": "coo", "target": reels.displayed_icons[y][x], "value_to_change": "permanent_bonus", "diff": reels.displayed_icons[y][x].values[0]})
		var the_bool = false
		if typeof(comparison.b) == TYPE_BOOL:
			if c.has("from_item") and comparison.has("target_self"):
				var destroyed_item = items[item_types.find(c.from_item)]
				the_bool = ((comparison.b and destroyed_item.destroyed != comparison.b and not $"/root/Main/Items".just_destroyed_items.has(c.from_item)) or (not comparison.b and ($"/root/Main/Items".items_destroyed_this_spin.has(c.from_item) or destroyed_item.destroyed)))
			else:
				the_bool = ((comparison.b and not was_prev_destroyed and comparison_target.destroyed != comparison.b) or (not comparison.b and (was_prev_destroyed or comparison_target.destroyed))) and not comparison_target.tbd
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
		elif p_d_obj != null:
			if prev_data_obj == null:
				prev_data_obj = p_d_obj
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "removed" and not comparison.has("not_prev"):
		var eff = c.duplicate(true)
		var was_prev_removed = false
		var p_d_obj
		for t in comparison_target.t_prev_data:
			if t.removed and t.effect_hashes.find(get_prev_cleaned_effect(eff).hash()) == -1:
				var type_to_check
				var group_to_check
				for comp in c.comparisons:
					if typeof(comp.a) == TYPE_STRING:
						if comp.a == "type":
							type_to_check = comp.b
							break
						elif comp.a == "groups":
							group_to_check = comp.b
							break
				if type_to_check == t.type or (group_to_check != null and $"/root/Main".group_database["symbols"][group_to_check].has(t.type)) or (type_to_check == null and group_to_check == null):
					p_d_obj = t
					was_prev_removed = true
					break
			if was_prev_removed:
				break
		var the_bool = ((comparison.b and not was_prev_removed and comparison_target.removed != comparison.b) or (not comparison.b and (was_prev_removed or comparison_target.removed)))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif p_d_obj != null:
			if prev_data_obj == null:
				prev_data_obj = p_d_obj
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "destroyed" and comparison.has("not_prev"):
		var the_bool = false
		if typeof(comparison.b) == TYPE_BOOL:
			the_bool = comparison_target.destroyed != comparison.b
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "groups" and not comparison.has("not_prev"):
		var eff = c.duplicate(true)
		var p_d_obj
		var has_prev_group = false

		for t in comparison_target.t_prev_data:
			if $"/root/Main".group_database["symbols"].has(comparison.b) and $"/root/Main".group_database["symbols"][comparison.b].has(t.type) and t.effect_hashes.find(get_prev_cleaned_effect(eff).hash()) == -1:
				p_d_obj = t
				has_prev_group = true
				break
			if has_prev_group:
				break
		var the_bool = not has_prev_group and (not $"/root/Main".group_database["symbols"].has(comparison.b) or not $"/root/Main".group_database["symbols"][comparison.b].has(comparison_target.type))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif p_d_obj != null:
			prev_data_obj = p_d_obj
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "pointing_directions":
		var the_bool = false
		if typeof(comparison.a) == TYPE_STRING and typeof(comparison_target[comparison.a]) == TYPE_ARRAY and typeof(comparison.b) == TYPE_ARRAY:
			the_bool = comparison_target[comparison.a] != comparison.b
		elif typeof(comparison.a) == TYPE_STRING:
			the_bool = comparison_target[comparison.a].size() != comparison.b
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "non_singular_symbols":
		var stcf = $"/root/Main/Reels".get_non_singular_symbols()
		var the_bool = (stcf <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (stcf < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (stcf >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (stcf > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = stcf != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "symbols_to_choose_from":
		var stcf = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
		var the_bool = (stcf <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (stcf < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (stcf >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (stcf > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = stcf != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "symbols_destroyed_this_spin":
		var sdts = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
		var the_bool = (sdts <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (sdts < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (sdts >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (sdts > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = sdts != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "items_destroyed_this_spin":
		var sdts = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
		var the_bool = (sdts <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (sdts < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (sdts >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (sdts > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = sdts != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("destroyed_symbol_type_count"):
		var count = $"/root/Main/Pop-up Sprite/Pop-up".destroyed_symbol_types.count(comparison.a.destroyed_symbol_type_count)
		var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("removed_symbol_type_count"):
		var count = $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(comparison.a.removed_symbol_type_count)
		var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("destroyed_symbol_group_count"):
		var count = 0
		for g in $"/root/Main".group_database.symbols[comparison.a.destroyed_symbol_group_count]:
			count += $"/root/Main/Pop-up Sprite/Pop-up".detroyed_symbol_types.count(g)
		var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_DICTIONARY and comparison.a.has("removed_symbol_group_count"):
		var count = 0
		for g in $"/root/Main".group_database.symbols[comparison.a.removed_symbol_group_count]:
			count += $"/root/Main/Pop-up Sprite/Pop-up".removed_symbol_types.count(g)
		var the_bool = (count <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (count < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (count >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (count > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = count != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "grid_position_x":
		var the_bool = (comparison_target.grid_position.x <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (comparison_target.grid_position.x < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (comparison_target.grid_position.x >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (comparison_target.grid_position.x > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = comparison_target.grid_position.x != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "grid_position_y":
		var the_bool = (comparison_target.grid_position.y <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (comparison_target.grid_position.y < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (comparison_target.grid_position.y >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (comparison_target.grid_position.y > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = comparison_target.grid_position.y != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison.a == "saved_values":
		var id = target.get_author_id(c, null, comparison, target, null)
		var the_bool = (target.saved_values[id][comparison.value_num] <= float(comparison.b) and comparison.has("greater_than") and comparison.greater_than) or (target.saved_values[id][comparison.value_num] < float(comparison.b) and comparison.has("greater_than_eq") and comparison.greater_than_eq) or (target.saved_values[id][comparison.value_num] >= float(comparison.b) and comparison.has("less_than") and comparison.less_than) or (target.saved_values[id][comparison.value_num] > float(comparison.b) and comparison.has("less_than_eq") and comparison.less_than_eq)
		var the_bool2 = target.saved_values[id][comparison.value_num] != comparison.b and (((comparison.has("greater_than") and not comparison.greater_than) or not comparison.has("greater_than")) and ((comparison.has("greater_than_eq") and not comparison.greater_than_eq) or not comparison.has("greater_than_eq")) and ((comparison.has("less_than") and not comparison.less_than) or not comparison.has("less_than")) and ((comparison.has("less_than_eq") and not comparison.less_than_eq) or not comparison.has("less_than_eq")))
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
		elif the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"]):
			return false
	elif typeof(comparison.a) == TYPE_STRING and typeof(comparison_target[comparison.a]) == TYPE_ARRAY:
		var the_bool2
		if comparison.a == "groups":
			the_bool2 = not $"/root/Main".group_database.symbols[comparison.b].has(comparison_target.type)
		else:
			the_bool2 = not comparison_target[comparison.a].has(comparison.b)
		if comparison.has("not_have"):
			if typeof(comparison.a) == TYPE_STRING and comparison.a == "void_arr":
				for g in comparison_target[comparison.a]:
					var the_bool = g.grid_position == comparison.b.grid_position and g.giver.prev_data.size() == comparison.b.prev_data.size()
					if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
						return false
			elif typeof(comparison.a) == TYPE_STRING and comparison_target[comparison.a].has(comparison.b):
				return false
		elif typeof(comparison.a) == TYPE_STRING and (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
			return false
		elif not check_dove_conditionals(c):
			return false
	elif comparison.has("rand"):
		randomize()
		var item_multiplier = 1
		if c.has("from_item"):
			item_multiplier = items[item_types.find(c.from_item)].item_count
		var fp_13 = false
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num == 13 and fp.dynamic_icon == comparison_target.type:
				fp_13 = true
				break
		if fp_13 or (typeof(comparison.a) == TYPE_STRING and comparison_target[comparison.a] * item_multiplier < rand_range(0, 100)):
			var cleaned_c = get_cleaned_effect(c)
			erased_effects.push_back(cleaned_c)
			erased_effect_hashes.push_back(cleaned_c.hash())
			current_effect_hashes.erase(cleaned_c.hash())
			given_effects.remove(given_effect_hashes.find(get_cleaned_effect(current_effect).hash()))
			given_effect_hashes.erase(cleaned_c.hash())
			c_tbe.push_back(c)
			return false
	elif comparison.has("less_than"):
		var the_bool = false
		if typeof(comparison.a) == TYPE_STRING:
			the_bool = int(comparison_target[comparison.a]) >= int(comparison.b)
		var the_bool2 = false
		if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
			the_bool2 = int(comparison.a) >= int(comparison.b)
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
		elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
			return false
	elif comparison.has("less_than_eq"):
		var the_bool = false
		if typeof(comparison.a) == TYPE_STRING:
			the_bool = int(comparison_target[comparison.a]) > int(comparison.b)
		var the_bool2 = false
		if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
			the_bool2 = int(comparison.a) > int(comparison.b)
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
		elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
			return false
	elif comparison.has("greater_than"):
		var the_bool = false
		if typeof(comparison.a) == TYPE_STRING:
			the_bool = int(comparison_target[comparison.a]) <= int(comparison.b) + b_mod
		var the_bool2 = false
		if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
			the_bool2 =int(comparison.a) <= int(comparison.b)
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
		elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
			return false
	elif comparison.has("greater_than_eq"):
		var the_bool = false
		if typeof(comparison.a) == TYPE_STRING:
			the_bool = int(comparison_target[comparison.a]) < int(comparison.b) + b_mod
		var the_bool2 = false
		if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
			the_bool2 = int(comparison.a) < int(comparison.b)
		if ((the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"])):
			return false
		elif (the_bool2 or (not the_bool2 and comparison.has("not") and comparison["not"])):
			return false
	elif typeof(comparison.a) == TYPE_STRING and comparison_target[comparison.a] != comparison.b:
		var adjacent_dove = false
		var destroyer
		for comp in c.comparisons:
			if comp.hash() == {"a": "destroyed", "b": true}.hash():
				destroyer = self
				break
		if c.has("destroy_giver_on_destroy") and c.destroy_giver_on_destroy and c.has("giver") and comparison_target.dove_destroyed and comparison_target.tbd:
			c.giver.destroyed_giver_on_destroy = true
			destroyer = c.giver
		if comparison.a == "type":
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comparison.b):
				var with_id = $"/root/Main".append_steam_id(comparison.b, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comparison.b]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comparison.b, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[comparison.b])]
				if $"/root/Main".mod_data.symbols.has(with_id) and not $"/root/Main".mod_data.symbols[with_id].art_replacement:
					comparison.b = with_id
				if $"/root/Main".is_mod_disabled(with_id):
					comparison.b = with_id.substr(0, with_id.find("_STEAM_ID_"))
		if typeof(comparison.a) == TYPE_STRING and comparison.a == "indestructible" and ((c.has("value_to_change") and c.value_to_change == "destroyed") or destroyer != null):
			var tmp_adj_icons
			if destroyer != null:
				tmp_adj_icons = destroyer.get_adjacent_icons()
			else:
				tmp_adj_icons = get_adjacent_icons()
			for x in range(reels.reel_width):
				for y in range(reels.reel_height):
					if reels.displayed_icons[y][x].type == "dove":
						if tmp_adj_icons.has(reels.displayed_icons[y][x]):
							if destroyer != null:
								destroyer.add_effect({"comparisons": [{"a": "destroyed_giver_on_destroy", "b": true}], "anim": "circle", "anim_targets": [destroyer, reels.displayed_icons[y][x]], "sfx_override": "coo", "target": reels.displayed_icons[y][x], "value_to_change": "permanent_bonus", "diff": reels.displayed_icons[y][x].values[0], "one_time": true, "t_pdi": destroyer.t_index})
							adjacent_dove = true
			if comparison_target.dove_destroyed:
				adjacent_dove = true
			if destroyer != null and destroyer.destroyed_giver_on_destroy and destroyer.dove_destroyed:
				destroyer.check_dove_conditionals(c)
		elif typeof(comparison.a) == TYPE_STRING and comparison.a == "type":
			var the_bool = not comparison_target.type == comparison.b
			if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
				return false
			else:
				return true
		return adjacent_dove
	else:
		var the_bool = false
		if (typeof(comparison.a) == TYPE_INT or typeof(comparison.a) == TYPE_REAL):
			the_bool = (typeof(comparison.b) == TYPE_INT or typeof(comparison.b) == TYPE_REAL) and comparison.a != comparison.b
		if (the_bool and (not comparison.has("not") or not comparison["not"])) or (not the_bool and comparison.has("not") and comparison["not"]):
			return false
	return true

func check_item_triggers(c, target):
	if c.has("item_to_destroy") and $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(c.item_to_destroy):
		c["item_to_destroy"] += "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[c.item_to_destroy]
		if $"/root/Main".mod_pack_nums.has(c.item_to_destroy):
			c["item_to_destroy"] += "_PACK_" + $"/root/Main".mod_pack_nums[c["item_to_destroy"]]
		if $"/root/Main".is_mod_disabled(c["item_to_destroy"]) and $"/root/Main".item_database.has(c["item_to_destroy"].substr(0, c["item_to_destroy"].find("_STEAM_ID_"))):
			c["item_to_destroy"] = c["item_to_destroy"].substr(0, c["item_to_destroy"].find("_STEAM_ID_"))

	if c.has("item_to_destroy") and not items_destroyed_this_spin.has(c.item_to_destroy):
		var time_to_break = false
		if c.has("value_to_change") and c.value_to_change == "destroyed":
			for i in get_adjacent_icons():
				if i.type == "dove":
					time_to_break = true
					break
			if time_to_break:
				return
		var num = -1
		if $"/root/Main".existing_items.has(c.item_to_destroy):
			num = item_types.find($"/root/Main".existing_items[c.item_to_destroy])
		if num != -1:
			var i = items[num]
			if i.type == c.item_to_destroy and not i.destroyed:
				i.destroyed = true
				items_destroyed_this_spin.push_back(i.type)
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if reels.checking_effects:
							reels.add_symbol_position_to_update(Vector2(x, y))
						reels.displayed_icons[y][x].update_value_text()
				for z in items:
					z.add_conditional_effects()
				$"/root/Main/Items".add_cond_effects()
				reels.destroyed_item_this_spin = true
	if c.has("item_to_add_saved_value"):
		if $"/root/Main/Items".has_unmodded_item(c.item_to_add_saved_value):
			items[item_types.find(c.item_to_add_saved_value)].saved_value += 1
			items[item_types.find(c.item_to_add_saved_value)].update_value_text()

func add_effect(c):
	if c.has("giver") and not c.has("reverse_eff"):
		if c.giver.destroyed or c.giver.removed:
			var t = 0
			for p in c.giver.prev_data:
				t += 1
				if p.type == c.giver.type:
					c["t_pdi"] = t
					break
		else:
			c["t_pdi"] = c.giver.t_index
	if c.has("value_to_change"):
		match c.value_to_change:
			"reroll_value":
				c.value_to_change = "reroll_token_value"
			"removal_value":
				c.value_to_change = "removal_token_value"
			"essence_value":
				c.value_to_change = "essence_token_value"
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY:
		if c.diff.has("counted_symbols"):
			var with_id = c.diff.counted_symbols
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(c.diff.counted_symbols):
				with_id = $"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(c.diff.counted_symbols, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c.diff.counted_symbols])]
				if $"/root/Main".mod_data.symbols.has(with_id) and $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
					with_id = c.diff.counted_symbols
			reels.count_symbols(true)
			c["counted_symbol_eff"] = c.diff.counted_symbols
			c.diff = reels.counted_symbols[with_id]
	
	if c.has("capsule_effect") and c.capsule_effect:
		var capsule_machine_multiplier = 1
		if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
			capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
		if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
			capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
		if not c.has("cmm"):
			if c.has("diff"):
				c.diff *= capsule_machine_multiplier
			if c.has("items_to_add"):
				var temp_diff = c.items_to_add.duplicate(true)
				for i in range(capsule_machine_multiplier - 1):
					c.items_to_add += temp_diff
			if c.has("tiles_to_add"):
				var temp_diff = c.tiles_to_add.duplicate(true)
				for i in range(capsule_machine_multiplier - 1):
					c.tiles_to_add += temp_diff
			add_effect({"comparisons": [{"a": "type", "b": type}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
		c["cmm"] = true
	if c.has("anim_targets") and typeof(c.anim_targets) == TYPE_STRING:
		if c.anim_targets == "all_adjacent_symbols":
			c.anim_targets = [self]
			c.anim_targets += get_adjacent_icons()
		elif c.anim_targets == "adjacent_symbol":
			if c.has("target"):
				c.anim_targets = [self, c.target]
			elif c.has("giver"):
				c.anim_targets = [self, c.giver]
	var comp_num = 0
	
	if c.has("giver") and c.has("from_item") and (c.from_item == "void_party" or c.from_item == "mobius_strip"):
		c["p_d_pos"] = c.giver.prev_data.size()
	
	if c.has("comparisons"):
		for comp in c.comparisons:
			if comp.has("a") and comp.has("b") and typeof(comp.a) == TYPE_STRING and comp.a == "type" and typeof(comp.b) == TYPE_STRING and comp.b == "dynamic_symbol":
				for fp in $"/root/Main/Landlord".fine_print:
					if tmp_fp_num == fp.num:
						comp.b = fp.dynamic_icon
						break
			for k in comp.keys():
				if typeof(comp[k]) == TYPE_STRING and k == "a":
					match comp[k]:
						"void_check":
							c.comparisons[comp_num][k] = "dummy"
							var destroy_self = true
							for i in get_adjacent_icons():
								if i.type == "empty":
									destroy_self = false
							c.comparisons[comp_num]["b"] = destroy_self
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
						"extra_symbol_choices":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".extra_symbol_choices
						"extra_item_choices":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".extra_item_choices
						"symbols_destroyed_this_spin":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".symbols_destroyed_this_spin
						"items_destroyed_this_spin":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".items_destroyed_this_spin
						"non_singular_symbols":
							c.comparisons[comp_num]["a"] = $"/root/Main/Reels".get_non_singular_symbols()
						"symbols_to_choose_from":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".symbols_to_choose_from
						"items_to_choose_from":
							c.comparisons[comp_num]["a"] = $"/root/Main/Pop-up Sprite/Pop-up".items_to_choose_from
						"type":
							if $"/root/Main".existing_symbols.has(c.comparisons[comp_num]["b"]):
								c.comparisons[comp_num]["b"] = $"/root/Main".existing_symbols[c.comparisons[comp_num]["b"]]
						"dove_destroyed":
							if c.has("giver") and c.giver.type != "dove":
								c.giver.dove_checker = true
				elif typeof(comp[k]) == TYPE_DICTIONARY:
					if comp[k].has("counted_symbols"):
						var with_id = comp[k].counted_symbols
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comp[k].counted_symbols):
							if $"/root/Main".mod_data.symbols.has(with_id) and $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = comp[k].counted_symbols
						reels.count_symbols(true)
						comp[k] = reels.counted_symbols[with_id]
					elif comp[k].has("counted_items"):
						var with_id = comp[k].counted_items
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(comp[k].counted_items):
							with_id = $"/root/Main".append_steam_id(comp[k].counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_items])]
							if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = comp[k].counted_items
						if item_types.has(with_id):
							c.comparisons[comp_num][k] = items[item_types.find(with_id)].item_count
					elif comp[k].has("counted_destroyed_items"):
						var with_id = comp[k].counted_destroyed_items
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(comp[k].counted_destroyed_items):
							with_id = $"/root/Main".append_steam_id(comp[k].counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_destroyed_items]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(comp[k].counted_destroyed_items, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[comp[k].counted_destroyed_items])]
							if $"/root/Main".mod_data.items[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = comp[k].counted_destroyed_items
						c.comparisons[comp_num][k] = $"/root/Main/Items".destroyed_item_types.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id) + $"/root/Main/Items".just_destroyed_items.count(with_id)
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
			comp_num += 1
	
		if c.comparisons.size() == 1 and not c.has("unconditional") and (c.comparisons[0].hash() == {"a": "destroyed", "b": true}.hash() or c.comparisons[0].hash() == {"a": "removed", "b": true}.hash()):
			c.comparisons.push_front({"a": "type", "b": type})
		if c.comparisons.size() >= 2 and c.comparisons[1].hash() == {"a": "destroyed", "b": true}.hash() and c.comparisons[0].hash() == {"a": "type", "b": type}.hash() and c.has("items_to_add"):
			c.comparisons[1] = {"a": "tbd", "b": true}
		if c.has("value_to_change") and (c.value_to_change == "destroyed" or c.value_to_change == "removed"):
			for comp in c.comparisons:
				comp["not_prev"] = true
	
	var can_add = true
	
	if c.has("required_items"):
		for i in c.required_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not item_types.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if not item_types.has(with_id):
					can_add = false
					break
			elif not item_types.has(i):
				can_add = false
			if not can_add:
				break
	if c.has("required_disabled_items"):
		for i in c.required_disabled_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not item_types.has(m_i + "_d"):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if not item_types.has(with_id + "_d"):
					can_add = false
					break
			elif not item_types.has(i + "_d"):
				can_add = false
				break
			if not can_add:
				break
	if c.has("required_destroyed_items"):
		for i in c.required_destroyed_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if not $"/root/Main/Items".destroyed_item_types.has(m_i) and not items_destroyed_this_spin.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if not $"/root/Main/Items".destroyed_item_types.has(with_id):
					can_add = false
					break
			elif not $"/root/Main/Items".destroyed_item_types.has(i) and not items_destroyed_this_spin.has(i):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_items"):
		for i in c.forbidden_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if item_types.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if item_types.has(with_id):
					can_add = false
					break
			elif item_types.has(i):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_disabled_items"):
		for i in c.forbidden_disabled_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if item_types.has(m_i + "_d"):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if item_types.has(with_id):
					can_add = false
					break
			elif item_types.has(i + "_d"):
				can_add = false
				break
			if not can_add:
				break
	if c.has("forbidden_destroyed_items"):
		for i in c.forbidden_destroyed_items:
			if $"/root/Main".modded_existing_base_types.items.has(i):
				for m_i in $"/root/Main".modded_existing_base_types.items[i]:
					if $"/root/Main/Items".destroyed_item_types.has(m_i) or items_destroyed_this_spin.has(m_i):
						can_add = false
						break
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(i):
				var with_id = i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i] + "_PACK_" + $"/root/Main".mod_pack_nums[i + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[i]]
				if $"/root/Main".is_mod_disabled(with_id):
					with_id = i
				if $"/root/Main/Items".destroyed_item_types.has(with_id):
					can_add = false
					break
			elif $"/root/Main/Items".destroyed_item_types.has(i) or items_destroyed_this_spin.has(i):
				can_add = false
				break
			if not can_add:
				break
	if c.has("value_to_change") and c.value_to_change == "type" and c.has("diff") and $"/root/Main".existing_symbols.has(c.diff):
		c["diff"] = $"/root/Main".existing_symbols[c.diff]
	if c.has("item_to_destroy") and $"/root/Main".existing_items.has(c.item_to_destroy):
		c["item_to_destroy"] = $"/root/Main".existing_items[c.item_to_destroy]
	
	if not c.has("from_item"):
		var add_comp = true
		if c.has("comparisons"):
			for comp in c.comparisons:
				if typeof(comp.a) == TYPE_STRING:
					if comp.a == "type" or comp.a == "groups" or (c.has("giver") and (c.giver.type == "hex_of_destruction" or c.giver.type == "hex_of_draining" or c.giver.type == "midas_bomb" or (c.has("effect_type") and (c.effect_type == "rand_adjacent_symbol" or c.effect_type == "same_rand_adjacent_symbol")))):
						add_comp = false
						break
			if add_comp and (not c.has("unconditional") or (c.has("unconditional") and c.has("anim"))) and (not c.has("one_time") or (c.has("one_time") and not c.one_time)):
				c.comparisons.push_front({"a": "type", "b": type, "not_prev": true})
			var destroyed_comp = false
			var targeting_self = true
			for comp in c.comparisons:
				if comp.has("a") and comp.has("b") and typeof(comp.a) == TYPE_STRING and comp.a == "destroyed" and typeof(comp.b) == TYPE_BOOL and comp.b and not c.has("giver"):
					destroyed_comp = true
					if (c.has("effect_type") and c.effect_type != "self") or (c.has("giver") and c.giver != self):
						targeting_self = false
					break
			if c.has("giver") and c.giver != self and c.giver.destroyed_giver_on_destroy:
				targeting_self = false
			if (c.has("value_to_change") and c.value_to_change == "destroyed" and (not c.has("giver") or (c.has("giver") and c.giver.type != "midas_bomb"))) or destroyed_comp:
				var add_ind_comp = true
				for comp in c.comparisons:
					if typeof(comp.a) == TYPE_STRING and comp.a == "indestructible":
						add_ind_comp = false
						break
				if add_ind_comp:
					if targeting_self and destroyed_giver_on_destroy:
						c.comparisons.push_front({"a": "indestructible", "b": false, "target_self": true})
					else:
						c.comparisons.push_front({"a": "indestructible", "b": false})

	if c.has("comparisons"):
		for comp in c.comparisons:
			if typeof(comp.a) == TYPE_STRING and comp.a == "destroyed" and comp.b:
				var can_add_tbd = true
				for co in c.comparisons:
					var pass_value = 0
					for k in co.keys():
						if k == "a" and typeof(co[k]) == TYPE_STRING and co[k] == "tbd":
							pass_value += 1
							if pass_value == 2:
								break
						elif k == "b" and typeof(co[k]) == TYPE_BOOL and not co[k]:
							pass_value += 1
							if pass_value == 2:
								break
					if pass_value == 2:
						can_add_tbd = false
						break
				if not $"/root/Main".demo:
					if can_add_tbd and not $"/root/Main".group_database["symbols"]["anvillikes"].has(type) and not $"/root/Main".group_database["symbols"]["monkeylikes"].has(type):
						c.comparisons.push_back({"a": "tbd", "b": false})
				break
	if not c.has("source"):
		if c.has("giver"):
			c["source"] = c.giver
		else:
			c["source"] = self
	if not c.has("anim_texture"):
		if texture_type == null:
			c["anim_texture"] = type
		else:
			c["anim_texture"] = texture_type
	
	if c.has("comparisons"):
		if c.comparisons.size() == 0:
			c.comparisons.push_back({"a": "dummy", "b": true})
	
	var num = -1
	for p in prev_data:
		if p.type == type and p.effect_hashes.has(get_prev_cleaned_effect(c).hash()):
			num = p.pdi
			break
	if num != -1:
		c["pdi"] = num
	
	var cleaned_c = get_cleaned_effect(c)
	
	var erase_rand_eff = false
	
	if c.has("diff") and typeof(c.diff) == TYPE_DICTIONARY and (c.diff.has("var_math") or c.diff.has("starting_value")):
		if c.has("from_item") and (not c.has("effect_type") or (c.has("effect_type") and c.effect_type != "symbols")):
			c.diff = items[item_types.find(c.from_item)].parse_var_math(c.diff, items[item_types.find(c.from_item)], c)
		else:
			c.diff = parse_var_math(c.diff, null, c)
	
	comp_num = -1
	
	var target = self
	if c.has("target"):
		target = c.target

	if cleaned_c.has("while") or erased_effect_hashes.has(cleaned_c.hash()) or current_effect_hashes.has(cleaned_c.hash()) or given_effect_hashes.has(cleaned_c.hash()):
		can_add = false

	if erase_rand_eff and not erased_effect_hashes.has(cleaned_c.hash()):
		erased_effects.push_back(cleaned_c)
		erased_effect_hashes.push_back(cleaned_c.hash())
		current_effect_hashes.erase(cleaned_c.hash())
		given_effects.remove(given_effect_hashes.find(c.hash()))
		given_effect_hashes.erase(cleaned_c.hash())

	if can_add:
		if not in_reels:
			get_parent().tmp_effects.push_back(c)
		elif c.has("effect_type") and c.effect_type == "counted_adjacent_symbols":
			var tmp_c = c.duplicate(true)
			tmp_c.erase("effect_type")
			for s in affected_symbols:
				add_effect_to_symbol(s.grid_position.y, s.grid_position.x, tmp_c)
		elif c.has("push_front") or (c.has("value_to_change") and (c.value_to_change == "indestructible")):
			reels.conditional_effects[grid_position.y][grid_position.x].push_front(c)
		else:
			reels.conditional_effects[grid_position.y][grid_position.x].push_back(c)
		if c.has("giver"):
			if c.giver.type == "hex_of_destruction" or c.giver.type == "hex_of_draining" or c.giver.type == "midas_bomb" or (c.has("effect_type") and (c.effect_type == "rand_adjacent_symbol" or c.effect_type == "same_rand_adjacent_symbol")):
				var can_add_hex = true
				for h in hex_effects:
					if get_cleaned_effect(h).hash() == get_cleaned_effect(c).hash():
						can_add_hex = false
						break
				if can_add_hex:
					hex_effects.push_back(c)
			if target is Sprite and not target.given_effect_hashes.has(get_cleaned_effect(c).hash()):
				target.given_effects.push_back(c)
				target.given_effect_hashes.push_back(get_cleaned_effect(c).hash())
		current_effect_hashes.push_back(get_cleaned_effect(c).hash())

func check_last_effects(c_effects):
	for c in c_effects:
		if c.has("last") and c.last:
			check_conditional_effects([c])

func check_conditional_effects(c_effects):
	changed_value = false
	var c_tbe = []
	var extra_targets = []
	var break_out = false
	var inc = 0
	for c in c_effects:
		inc += 1
		prev_data_obj = null
		var target = self
		var change_value = true
		if c.has("target"):
			target = c["target"]
		if c.has("last_effect") and inc != c_effects.size():
			var skip_eff = false
			if $"/root/Main/Items".has_unmodded_item("frying_pan") or $"/root/Main/Items".has_unmodded_item("frying_pan_essence"):
				for erased_eff in target.erased_effects:
					if erased_eff.has("from_item") and (erased_eff.from_item == "frying_pan" or erased_eff.from_item == "frying_pan_essence"):
						skip_eff = true
			if skip_eff:
				continue
		elif ((c.has("last") and c.last and not reels.checking_last_effects) or (reels.checking_last_effects and not c.has("last"))):
			continue
		while true:
			if c.has("comparisons"):
				var comp_num = 0
				for comparison in c.comparisons:
					for k in comparison.keys():
						if typeof(comparison[k]) == TYPE_DICTIONARY:
							if comparison[k].has("var_math") or comparison[k].has("starting_value"):
								if c.has("from_item"):
									c.comparisons[comp_num][k] = items[item_types.find(c.from_item)].parse_var_math(comparison[k], items[item_types.find(c.from_item)], c)
								else:
									c.comparisons[comp_num][k] = parse_var_math(comparison[k], self, c)
					if c.has("value_to_change") and (c.value_to_change == "type" or c.value_to_change == "destroyed" or c.value_to_change == "removed") and reels.change_type_checking:
						change_value = false
						break
					if not do_comp(c.comparisons[comp_num].duplicate(true), c, target, c_effects, c_tbe):
						change_value = false
						break
					comp_num += 1
					
				if change_value and c.has("giver") and change_value and not c.has("one_time") and not c.has("no_extra_targets"):
					var adj_icons = get_adjacent_icons()
					if (type == "flower" or type == "seed" and c.giver.type == "sun") or ($"/root/Main".group_database.symbols["night"].has(type) and c.giver.type == "moon"):
						if $"/root/Main/Items".has_unmodded_item("clear_sky") or items_destroyed_this_spin.has("clear_sky_essence") or $"/root/Main/Items".destroyed_item_types.has("clear_sky_essence"):
							for x in range(reels.reel_width):
								for y in range(reels.reel_height):
									if reels.displayed_icons[y][x].type == "sun" or reels.displayed_icons[y][x].type == "moon":
										adj_icons.push_back(reels.displayed_icons[y][x])
									else:
										for p in reels.displayed_icons[y][x].prev_data:
											if p.type == "sun" or p.type == "moon":
												adj_icons.push_back(reels.displayed_icons[y][x])
												break
					for icon in adj_icons:
						var data_arr = [icon]
						for a in data_arr:
							for eff in c_effects:
								if eff.has("giver") and eff.giver == a and c.giver.type == a.type and get_fully_cleaned_effect(eff).hash() == get_fully_cleaned_effect(c).hash():
									var can_add = true
									for a_comp in eff.comparisons:
										var c_target = self
										if eff.has("target"):
											c_target = eff.target
										if not do_comp(a_comp.duplicate(true), eff, c_target, c_effects, c_tbe):
											can_add = false
											break
									if can_add:
										if c.has("target") and typeof(c.target) == typeof(a) and c.target == a:
											can_add = false
										elif get_cleaned_effect(eff).hash() == get_cleaned_effect(c).hash():
											can_add = false
										elif not check_dove_conditionals(eff):
											can_add = false
									for t in extra_targets:
										if t.target == a:
											can_add = false
											break
									if can_add and c.giver.type == a.type:
										if c.has("target") and c.target != a:
											var can_be_extra = true
											if can_be_extra:
												a.getting_extra = true
										extra_targets.push_back({"target": a, "eff": eff})
			if change_value and not check_dove_conditionals(c):
				change_value = false
			if change_value:
				changed_value = true
				
				do_diff(c, target, c_tbe)
				for e in range(extra_targets.size()):
					do_diff(extra_targets[e].eff, decide_extra_target(extra_targets[e].target, target), c_tbe)
				if typeof(target) == TYPE_OBJECT and target.has_method("get_value"):
					target.final_value = target.get_value("coin")
					target.non_flat_final_value = target.get_non_flat_value("coin")
					target.non_prev_final_value = target.get_non_prev_value("coin")
					
					target.reroll_token_final_value = target.get_value("reroll_token")
					target.reroll_token_non_flat_final_value = target.get_non_flat_value("reroll_token")
					
					target.removal_token_final_value = target.get_value("removal_token")
					target.removal_token_non_flat_final_value = target.get_non_flat_value("removal_token")
					
					target.essence_token_final_value = target.get_value("essence_token")
					target.essence_token_non_flat_final_value = target.get_non_flat_value("essence_token")
				for e in extra_targets:
					var t = decide_extra_target(e.target, target)
					if typeof(t) == TYPE_OBJECT and t.has_method("get_value"):
						t.final_value = t.get_value("coin")
						t.non_flat_final_value = t.get_non_flat_value("coin")
						t.non_prev_final_value = t.get_non_prev_value("coin")
						
						t.reroll_token_final_value = t.get_value("reroll_token")
						t.reroll_token_non_flat_final_value = t.get_non_flat_value("reroll_token")
						
						t.essence_token_final_value = t.get_value("essence_token")
						t.essence_token_non_flat_final_value = t.get_non_flat_value("essence_token")
						
				if c.has("anim"):
					anim_targets.clear()
					if c.has("anim_targets") and c.anim_targets != null and typeof(c.anim_targets) == TYPE_ARRAY:
						anim_targets = c.anim_targets
					else:
						anim_targets = [self]
					if anim_targets.size() > 0:
						var anim_types = [anim_targets[0].type]
						var no_anims = false
						for e in extra_targets:
							anim_types.push_back(e.target.type)
							if e.target.dove_destroyed and c.has("value_to_change") and c.value_to_change == "destroyed":
								no_anims = true
								break
						for a in anim_targets:
							if a.dove_destroyed and c.has("value_to_change") and c.value_to_change == "destroyed":
								no_anims = true
								break
						if not no_anims:
							for a in range(anim_targets.size()):
								var can_anim = true
								for e in extra_targets:
									if e.target == anim_targets[a]:
										can_anim = false
										break
								if can_anim:
									anim_targets[a].changed_value = true
									var c_eff = c.duplicate(true)
									if anim_targets[a].texture_effect != null or (a == 0 and anim_targets.size() > 1):
										anim_targets[a].get_child(5).texture = $"/root/Main".get_replacement_texture(anim_targets[a].type)
									if anim_targets[a].tbd:
										anim_targets[a].flagged_for_empty_texture = true
									anim_targets[a].start_animation(c_eff)
									if a > 0 and anim_targets[0].tbd:
										anim_targets[a].queued_anims[0].anim_vtc = null
									for adj_icon in anim_targets[a].get_adjacent_icons():
										reels.add_symbol_position_to_update(adj_icon.grid_position)
							if anim_types.count("cat") >= 2 and target.type == "milk":
								reels.add_queued_achievement(93)
							if anim_types.count("sun") >= 3 and target.type == "flower":
								reels.add_queued_achievement(132)
							if anim_types.count("bear") >= 3 and target.type == "honey":
								reels.add_queued_achievement(8)
							anim_types.clear()
							for e in extra_targets:
								var c_eff = c.duplicate(true)
								c_eff.anim_texture = e.target.type
								e.target.get_child(5).texture = $"/root/Main".get_replacement_texture(e.target.texture_type)
								if e.target.tbd:
									e.target.flagged_for_empty_texture = true
								e.target.start_animation(c_eff)
								for adj_icon in e.target.get_adjacent_icons():
									reels.add_symbol_position_to_update(adj_icon.grid_position)
							if c.has("sfx_override"):
								play_sfx(anim_targets[0], c.sfx_override)
							elif c.has("sfx_type"):
								if anim_targets[0].sfx_values.size() > c.sfx_type:
									play_sfx(anim_targets[0], anim_targets[0].sfx_values[c.sfx_type])
							elif c.has("value_to_change") and c.value_to_change == "type" and anim_targets[0].prev_data.size() > 0 and anim_targets[0].prev_data[anim_targets[0].prev_data.size() - 1].sfx_values.size() > 0:
								play_sfx(anim_targets[0], anim_targets[0].prev_data[anim_targets[0].prev_data.size() - 1].sfx_values[0])
							elif anim_targets[0].sfx_values.size() > 0:
								play_sfx(anim_targets[0], anim_targets[0].sfx_values[0])
				for q in extra_targets:
					if not q.has("while"):
						var e = q.eff.duplicate(true)
						if e.has("source"):
							e.source = e.source.type
						if e.has("target") and e.target is Node and not e.target is Control:
							e.target = e.target.type
						if e.has("dynamic_a_target") and e.dynamic_a_target is Node and not e.dynamic_a_target is Control:
							e.dynamic_a_target = e.dynamic_a_target.type
						if e.has("dynamic_diff_target") and e.dynamic_diff_target is Node and not e.dynamic_diff_target is Control:
							e.dynamic_diff_target = e.dynamic_diff_target.type
						if e.has("comparisons"):
							for comp in e.comparisons:
								if comp.b is Node and not comp.b is Control:
									comp.b = comp.b.type
						if e.has("giver"):
							e.giver = e.giver.type
						if e.has("carry_over"):
							e.erase("carry_over")
						if e.has("cmm"):
							e.erase("cmm")
						if e.has("source"):
							e.erase("source")
						if e.has("anim"):
							e.erase("anim")
						if e.has("anim_targets"):
							e.erase("anim_targets")
						if e.has("anim_result"):
							e.erase("anim_result")
						if e.has("anim_texture"):
							e.erase("anim_texture")
						if e.has("giver_texture"):
							e.erase("giver_texture")
						if e.has("sfx_type"):
							e.erase("sfx_type")
						if e.has("sfx_override"):
							e.erase("sfx_override")
						if e.has("no_extra_targets"):
							e.erase("no_extra_targets")
						if e.has("hex_eff"):
							e.erase("hex_eff")
						if e.has("pdi"):
							e.erase("pdi")
						if e.has("v_num"):
							e.erase("v_num")
						if e.has("t_pdi"):
							e.erase("t_pdi")
						if e.has("reverse_eff"):
							e.erase("reverse_eff")
						if not e.has("achievement_value") and not e.has("saved_achievement_value"):
							$"/root/Main".write_log("Effect - " + type + " (x:" + str(grid_position.x) + ", y:" + str(grid_position.y) + "): " + str(e))
						var cleaned_c = get_cleaned_effect(q.eff)
						if q.eff.has("one_time"):
							target.one_times.push_back(get_fully_cleaned_effect(q.eff).hash())
				if not c.has("while"):
					var eff = c.duplicate(true)
					if eff.has("source"):
						eff.source = eff.source.type
					if eff.has("target") and eff.target is Node and not eff.target is Control and not eff.target.get_path() == "/root/Main/Reels":
						eff.target = eff.target.type
					if eff.has("dynamic_a_target") and eff.dynamic_a_target is Node and not eff.dynamic_a_target is Control:
						eff.dynamic_a_target = eff.dynamic_a_target.type
					if eff.has("dynamic_diff_target") and eff.dynamic_diff_target is Node and not eff.dynamic_diff_target is Control:
						eff.dynamic_diff_target = eff.dynamic_diff_target.type
					if eff.has("comparisons"):
						for e in eff.comparisons:
							if e.b is Node and not e.b is Control:
								e.b = e.b.type
					if eff.has("giver"):
						eff.giver = eff.giver.type
					if eff.has("carry_over"):
						eff.erase("carry_over")
					if eff.has("cmm"):
						eff.erase("cmm")
					if eff.has("source"):
						eff.erase("source")
					if eff.has("anim"):
						eff.erase("anim")
					if eff.has("anim_targets"):
						eff.erase("anim_targets")
					if eff.has("anim_result"):
						eff.erase("anim_result")
					if eff.has("anim_texture"):
						eff.erase("anim_texture")
					if eff.has("giver_texture"):
						eff.erase("giver_texture")
					if eff.has("sfx_type"):
						eff.erase("sfx_type")
					if eff.has("sfx_override"):
						eff.erase("sfx_override")
					if eff.has("no_extra_targets"):
						eff.erase("no_extra_targets")
					if eff.has("hex_eff"):
						eff.erase("hex_eff")
					if eff.has("pdi"):
						eff.erase("pdi")
					if eff.has("v_num"):
						eff.erase("v_num")
					if eff.has("t_pdi"):
						eff.erase("t_pdi")
					if eff.has("reverse_eff"):
						eff.erase("reverse_eff")
					if not eff.has("achievement_value") and not eff.has("saved_achievement_value") and in_reels:
						$"/root/Main".write_log("Effect - " + type + " (x:" + str(grid_position.x) + ", y:" + str(grid_position.y) + "): " + str(eff))
					c_tbe.push_back(c)
					var cleaned_c = get_cleaned_effect(c)
					erased_effects.push_back(cleaned_c)
					erased_effect_hashes.push_back(cleaned_c.hash())
					current_effect_hashes.erase(cleaned_c.hash())
					if given_effect_hashes.find(get_cleaned_effect(current_effect).hash()) != -1:
						given_effects.remove(given_effect_hashes.find(get_cleaned_effect(current_effect).hash()))
					given_effect_hashes.erase(cleaned_c.hash())
					if c.has("one_time"):
						target.one_times.push_back(get_fully_cleaned_effect(c).hash())
					break
			else:
				break
		if changed_value or break_out:
			break
	if not break_out:
		var extra_c_tbe = []
		for a in extra_targets:
			extra_c_tbe.push_back(a.eff)
		for e in extra_c_tbe:
			if e.has("giver"):
				var target = self
				if e.has("target"):
					target = e.target
				target.hex_effects.erase(e)
			reels.conditional_effects[grid_position.y][grid_position.x].erase(e)
		for c in c_tbe:
			if c.has("giver"):
				hex_effects.erase(c)
			c_effects.erase(c)
		for a in extra_targets:
			a.target.getting_extra = false
		extra_targets.clear()

func add_conditional_effects():
	var adj_icons
	var adj_positions
	
	adj_icons = get_adjacent_icons()
	
	anim_targets.clear()
	
	var types = []
	
	for p in prev_data:
		types.push_back(p.type)
	
	types.push_back(type)
	
	var incrementer = 0
	var current_data = {}
	
	t_index = 0
	
	if prev_data.size() > 0:
		for p in prev_data[0].keys():
			current_data[p] = self[p]
	
	for t in types:
		t_index += 1
		var t_groups = groups.duplicate(true)
		if prev_data.size() > 0 and incrementer != prev_data.size():
			for p in prev_data[incrementer].keys():
				self[p] = prev_data[incrementer][p]
			t_groups += $"/root/Main".tile_database[prev_data[incrementer].type].groups
			incrementer += 1
		elif prev_data.size() > 0:
			for p in prev_data[0].keys():
				self[p] = current_data[p]
			t_groups += $"/root/Main".tile_database[prev_data[0].type].groups
		t_prev_data = prev_data.slice(0, incrementer, true)
		values = $"/root/Main".tile_database[t].values
		texture_type = t
		
		var old_t = t
		t = t.substr(0, t.find("_STEAM_ID_"))
		var no_eff = false
		
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.dynamic_icon != null and old_t == fp.dynamic_icon:
				match int(fp.num):
					8:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}], "value_to_change": "bonus_value_multipliers", "bonus_value_num": 0, "diff": fp.values[0], "push_front": true})
					9:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}, {"a": "destroyed", "b": true}], "value_to_change": "value_bonus", "diff": -fp.values[0]})
					10, 36:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}], "value_to_change": "indestructible", "diff": true, "push_front": true})
					19, 28, 32:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}], "from_item": true, "value_to_change": "value_multiplier", "diff": fp.values[0] / 100.0})
					27, 29, 33, 35:
						add_effect({"comparisons": [{"a": "type", "b": fp.dynamic_icon}], "value_to_change": "value_bonus", "diff": -fp.values[0]})
					15, 37:
						no_eff = true
			else:
				match int(fp.num):
					16:
						add_effect({"comparisons": [{"a": "non_prev_final_value", "b": 0, "less_than": true}], "value_to_change": "value_bonus", "diff": -fp.values[0], "push_front": true})
					20:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["coin"]}], "value_to_change": "indestructible", "diff": true, "push_front": true})
					21:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["egg"]}], "value_to_change": "indestructible", "diff": true, "push_front": true})
					26:
						add_effect({"comparisons": [{"a": "rarity", "b": "very_rare"}], "value_to_change": "value_bonus", "diff": -fp.values[0]})
					28:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["dwarf"]}], "value_to_change": "value_multiplier", "diff": fp.values[0] / 100.0})
					32:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["monkey"]}], "value_to_change": "value_multiplier", "diff": fp.values[0] / 100.0})
					29:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["d3"]}], "value_to_change": "value_bonus", "diff": -fp.values[0]})
					35:
						add_effect({"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["d5"]}], "value_to_change": "value_bonus", "diff": -fp.values[0]})
		if no_eff:
			continue
		if t_groups.has("doglikes"):
			for i in adj_icons:
				add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["dog"], "not_prev": true}], "one_time": true, "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_bonus", "sfx_override": "dogpant", "stat_to_change": "time_spent_petting_dog", "stat_diff": 35.0 / 3600.0, "diff": $"/root/Main".tile_database[$"/root/Main".existing_symbols["dog"]].values[0], "reverse_eff": true})
		if t_groups.has("beelikes"):
			for i in adj_icons:
				add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["bee"], "not_prev": true}], "value_to_change": "value_bonus", "diff": $"/root/Main".tile_database[$"/root/Main".existing_symbols["bee"]].values[1], "reverse_eff": true})
		if t_groups.has("omelettestuff") and not $"/root/Main".demo:
			for i in adj_icons:
				add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["omelette"], "not_prev": true}], "one_time": true, "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_bonus", "sfx_override": "sizzle", "diff": $"/root/Main".tile_database[$"/root/Main".existing_symbols["omelette"]].values[0], "reverse_eff": true})
			if $"/root/Main/Items".has_unmodded_item("frying_pan") or $"/root/Main/Items".has_unmodded_item("frying_pan_essence"):
				for i in adj_icons:
					add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": $"/root/Main".existing_symbols["egg"], "not_prev": true}], "anim": "rotate", "sfx_type": 1, "value_to_change": "destroyed", "item_to_destroy": "frying_pan_essence", "diff": true, "one_time": true, "reverse_eff": true})
		for reverse in $"/root/Main".mod_reverse_effects:
			if reverse.keys().has("groups"):
				for g in reverse.groups:
					if t_groups.has(g):
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, reverse.eff.duplicate(true))
						break
			elif reverse.keys().has("type") and (t == reverse.type or ($"/root/Main".existing_symbols.has(t) and reverse.type == $"/root/Main".existing_symbols[t])):
				for i in adj_icons:
					add_effect_to_symbol(i.grid_position.y, i.grid_position.x, reverse.eff.duplicate(true))
		if not modded or (modded and inherit_effects):
			match t:
				"d5", "d3":
					var lucky_dice = false
					if $"/root/Main/Items".has_unmodded_item("lucky_dice") or $"/root/Main/Items".has_unmodded_item("lucky_dice_essence"):
						lucky_dice = true
					if not lucky_dice:
						randomize()
						add_effect({"comparisons": [], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": floor(rand_range(values[0], values[1] + 1))})
					else:
						add_effect({"comparisons": [], "anim": "rand_texture_cycle", "value_to_change": "value_bonus", "diff": values[1]})
				"joker":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "suit"}], "anim": "rotate", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
				"seed":
					var fertilizer
					var compost_heap
					var fertilizer_essence
					var fp_34 = false
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 34:
							fp_34 = true
							break
					if $"/root/Main/Items".has_unmodded_item("fertilizer"):
						fertilizer = items[item_types.find("fertilizer")]
					if $"/root/Main/Items".has_unmodded_item("compost_heap"):
						compost_heap = items[item_types.find("compost_heap")]
					if $"/root/Main/Items".has_unmodded_item("fertilizer_essence"):
						fertilizer_essence = items[item_types.find("fertilizer_essence")]
					if not fp_34:
						if fertilizer_essence != null:
							randomize()
							add_effect({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "item_to_destroy": "fertilizer_essence", "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "very_rare"})
						elif fertilizer != null:
							randomize()
							add_effect({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "rare"})
						elif compost_heap != null:
							randomize()
							add_effect({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "value_to_change": "type", "group": "plant", "min_rarity": "uncommon"})
						else:
							randomize()
							add_effect({"comparisons": [{"a": "type", "b": "seed", "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "value_to_change": "type", "group": "plant"})
				"ore":
					var x_ray_machine
					var x_ray_machine_essence
					if $"/root/Main/Items".has_unmodded_item("x_ray_machine"):
						x_ray_machine = items[item_types.find("x_ray_machine")]
					if $"/root/Main/Items".has_unmodded_item("x_ray_machine_essence"):
						x_ray_machine_essence = items[item_types.find("x_ray_machine_essence")]
					if x_ray_machine_essence != null:
						add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "ore"}], "item_to_destroy": "x_ray_machine_essence", "tiles_to_add": [{"group": "gem", "min_rarity": "very_rare"}]})
					elif x_ray_machine != null:
						add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "ore"}], "tiles_to_add": [{"group": "gem", "min_rarity": "rare"}]})
					else:
						add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "ore"}], "tiles_to_add": [{"group": "gem"}]})
				"coal":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[0] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "item_to_add_saved_value": "time_machine_essence", "value_to_change": "type", "diff": "diamond"})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
				"diamond":
					add_effect({"comparisons": [{"a": "type", "b": "diamond"}, {"a": {"counted_symbols": "diamond"}, "b": 0, "greater_than": true}], "value_to_change": "value_bonus", "diff": {"counted_symbols": "diamond"}})
				"bounty_hunter":
					var zaroffs_contract
					if $"/root/Main/Items".has_unmodded_item("zaroffs_contract"):
						zaroffs_contract = items[item_types.find("zaroffs_contract")]
					if zaroffs_contract != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "human"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "item_to_destroy": "zaroffs_contract_essence", "value_to_change": "destroyed", "diff": true})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "human"}], "target": self, "value_to_change": "value_bonus", "diff": zaroffs_contract.values[0] * zaroffs_contract.item_count})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "thief"}], "target": self, "value_to_change": "value_bonus", "item_to_destroy": "wanted_poster_essence", "diff": values[0]})
					else:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "thief"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "item_to_destroy": "zaroffs_contract_essence", "value_to_change": "destroyed", "diff": true})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "thief"}], "target": self, "value_to_change": "value_bonus", "item_to_destroy": "wanted_poster_essence", "diff": values[0]})
				"midas_bomb":
					if not destroyed:
						var empty_symbol = false
						var anim_arr = [self]
						for i in adj_icons:
							if i.type == "empty":
								empty_symbol = true
							anim_arr.push_back(i)
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": null, "b": true, "dynamic_a_target": self, "dynamic_a_key": "destroyed"}], "value_to_change": "destroyed", "diff": true})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": i.type, "not_prev": true}, {"a": null, "b": true, "dynamic_a_target": self, "dynamic_a_key": "destroyed"}], "value_to_change": "value_multiplier", "diff": values[0]})
						add_effect({"comparisons": [], "anim": "shake", "anim_targets": anim_arr, "value_to_change": "destroyed", "diff": true, "unconditional": true})
						if anim_arr.size() > 18 and not empty_symbol:
							reels.add_queued_achievement(92)
				"thief":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "thief"}], "value_to_change": "value_bonus", "diff": times_displayed * values[1]})
				"ninja":
					reels.ninja_timer = 0
					var ninja_and_mouse
					var ninja_and_mouse_essence
					var cursed_katana_diff = 0
					if $"/root/Main/Items".has_unmodded_item("ninja_and_mouse"):
						ninja_and_mouse = items[item_types.find("ninja_and_mouse")]
					if $"/root/Main/Items".has_unmodded_item("ninja_and_mouse_essence"):
						ninja_and_mouse_essence = items[item_types.find("ninja_and_mouse_essence")]
					if $"/root/Main/Items".has_unmodded_item("cursed_katana"):
						cursed_katana_diff = items[item_types.find("cursed_katana")].values[0] * items[item_types.find("cursed_katana")].item_count
					reels.count_symbols(true)
					add_effect({"comparisons": [{"a": "type", "b": "ninja"}, {"a": {"counted_symbols": "ninja"}, "b": 0, "greater_than": true}], "value_to_change": "value_bonus", "diff": (-values[0] + cursed_katana_diff) * reels.counted_symbols["ninja"]})
					if ninja_and_mouse != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "mouse"}], "one_time": true, "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": pow(ninja_and_mouse.values[0], ninja_and_mouse.item_count)})
					if ninja_and_mouse_essence != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "mouse"}], "one_time": true, "item_to_destroy": "ninja_and_mouse_essence"})
				"bear":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "honey"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "honey"}], "target": self, "value_to_change": "value_bonus", "item_to_destroy": "maxwell_the_bear_essence", "diff": values[0]})
				"bee":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "beelikes"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
				"beehive":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "honey"}]})
				"rain":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "flower"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "item_to_destroy": "rain_cloud_essence", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "bonus_values", "bonus_value_num": 0, "diff": values[1]})
				"lockbox":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "lockbox"}], "value_to_change": "value_bonus", "diff": values[0]})
				"beastmaster":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "animal"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
				"wildcard":
					add_effect({"comparisons": [{"a": "type", "b": "wildcard"}], "value_to_change": "wildcarded", "diff": true})
				"treasure_chest":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "treasure_chest"}], "value_to_change": "value_bonus", "diff": values[0]})
				"safe":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "safe"}], "value_to_change": "value_bonus", "diff": values[0]})
				"pinata":
					var symbol_arr = []
					for i in range(values[0]):
						symbol_arr.push_back({"type": "candy"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "pinata"}], "tiles_to_add": symbol_arr})
				"lucky_capsule":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "lucky_capsule"}], "item_to_destroy": "capsule_machine_essence", "value_to_change": "value_bonus", "diff": int(values[0] * capsule_machine_multiplier)})
				"moon":
					var wolves = 0
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "night"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
						if i.type == "wolf":
							wolves += 1
					if wolves >= 3:
						reels.add_queued_achievement(149)
					var symbol_arr = []
					for i in range(values[0]):
						symbol_arr.push_back({"type": "cheese"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "moon"}], "tiles_to_add": symbol_arr})
				"sun":
					var clear_sky_essence
					if $"/root/Main/Items".has_unmodded_item("clear_sky_essence"):
						clear_sky_essence = items[item_types.find("clear_sky_essence")]
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "flower"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "bonus_values", "bonus_value_num": 0, "diff": values[1]})
					if clear_sky_essence != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "moon"}], "item_to_destroy": "clear_sky_essence"})
				"chef":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "food"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
				"mega_chest":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "mega_chest"}], "value_to_change": "value_bonus", "diff": values[0]})
				"cultist":
					add_effect({"comparisons": [{"a": "type", "b": "cultist"}, {"a": {"counted_symbols": "cultist"}, "b": 0, "greater_than": true}], "value_to_change": "value_bonus", "diff": {"counted_symbols": "cultist"}})
					add_effect({"comparisons": [{"a": "type", "b": "cultist"}, {"a": {"counted_symbols": "cultist"}, "b": values[2] - 1, "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[1]})
				"spirit":
					if $"/root/Main/Items".has_unmodded_item("shrine_essence") and not $"/root/Main/Items".has_unmodded_item("undertaker"):
						add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "greater_than_eq": true}, {"a": "indestructible", "b": false}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "tiles_to_add": [{"group": "organism"}], "diff": true})
					elif not $"/root/Main/Items".has_unmodded_item("undertaker"):
						add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "greater_than_eq": true}, {"a": "indestructible", "b": false}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"bubble":
					add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "greater_than_eq": true}, {"a": "indestructible", "b": false}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"tomb":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "spirit"}]})
					var grave_robber_essence_multiplier = 1
					var fp_mod = 0
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 11 and fp.dynamic_icon == t:
							fp_mod -= fp.values[0]
							break
					for i in items:
						if i.type == "grave_robber_essence" and not i.destroyed and not i.disabled:
							grave_robber_essence_multiplier *= i.values[0]
					var gre_arr = $"/root/Main/Items".destroyed_item_types
					gre_arr += items_destroyed_this_spin
					for i in gre_arr:
						if i == "grave_robber_essence":
							grave_robber_essence_multiplier *= $"/root/Main".item_database["grave_robber_essence"].values[0]
					var symbol_arr = []
					for i in range(values[1] * grave_robber_essence_multiplier - fp_mod):
						symbol_arr.push_back({"type": "spirit"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "tomb"}], "tiles_to_add": symbol_arr, "item_to_destroy": "grave_robber_essence"})
				"urn":
					var grave_robber_essence_multiplier = 1
					var fp_mod = 0
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 11 and fp.dynamic_icon == t:
							fp_mod -= fp.values[0]
							break
					for i in items:
						if i.type == "grave_robber_essence" and not i.destroyed and not i.disabled:
							grave_robber_essence_multiplier *= i.values[0]
					var gre_arr = $"/root/Main/Items".destroyed_item_types
					gre_arr += items_destroyed_this_spin
					for i in gre_arr:
						if i == "grave_robber_essence":
							grave_robber_essence_multiplier *= $"/root/Main".item_database["grave_robber_essence"].values[0]
					var symbol_arr = []
					for i in range(grave_robber_essence_multiplier - fp_mod):
						symbol_arr.push_back({"type": "spirit"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "urn"}], "item_to_destroy": "grave_robber_essence", "tiles_to_add": symbol_arr})
				"big_urn":
					var grave_robber_essence_multiplier = 1
					var fp_mod = 0
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 11 and fp.dynamic_icon == t:
							fp_mod -= fp.values[0]
							break
					for i in items:
						if i.type == "grave_robber_essence" and not i.destroyed and not i.disabled:
							grave_robber_essence_multiplier *= i.values[0]
					var gre_arr = $"/root/Main/Items".destroyed_item_types
					gre_arr += items_destroyed_this_spin
					for i in gre_arr:
						if i == "grave_robber_essence":
							grave_robber_essence_multiplier *= $"/root/Main".item_database["grave_robber_essence"].values[0]
					var symbol_arr = []
					for i in range(values[0] * grave_robber_essence_multiplier - fp_mod):
						symbol_arr.push_back({"type": "spirit"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "big_urn"}], "tiles_to_add": symbol_arr, "item_to_destroy": "grave_robber_essence"})
				"cat":
					var copycat
					var lucky_cat
					var destroyed_copycat_essence = false
					if $"/root/Main/Items".has_unmodded_item("copycat"):
						copycat = $"/root/Main".item_database["copycat"]
					if $"/root/Main/Items".has_unmodded_item("lucky_cat"):
						lucky_cat = $"/root/Main".item_database["lucky_cat"]
					if $"/root/Main/Items".has_unmodded_item("copycat_essence") and (items_destroyed_this_spin.has("copycat_essence") or items[item_types.find("copycat_essence")].symbol_trigger):
						destroyed_copycat_essence = true
					if $"/root/Main/Items".destroyed_item_types.has("copycat_essence"):
						destroyed_copycat_essence = true
					if lucky_cat != null:
						var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
						add_effect({"comparisons": [{"a": "type", "b": "cat"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "uncommon", "diff": lucky_cat.values[0] * items[item_types.find("lucky_cat")].item_count})
						add_effect({"comparisons": [{"a": "type", "b": "cat"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "rare", "diff": lucky_cat.values[0] * items[item_types.find("lucky_cat")].item_count})
						add_effect({"comparisons": [{"a": "type", "b": "cat"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "very_rare", "diff": lucky_cat.values[0] * items[item_types.find("lucky_cat")].item_count})
					if not reels.adding_rarity_effects:
						if copycat != null or destroyed_copycat_essence:
							wildcarded = true
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "milk"}], "item_to_destroy": "pizza_the_cat_essence", "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "milk"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"toddler":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "candy"}, {"a": "destroyed", "b": true}], "item_to_destroy": "jackolantern_essence"})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "toddlerlikes"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "toddlerlikes"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"general_zaroff":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "human"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "item_to_destroy": "zaroffs_contract_essence", "stat_to_change": "humans_murdered_by_general_zaroff", "stat_diff": 1, "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "human"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"miner":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "minerlikes"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "minerlikes"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"rabbit_fluff":
					var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
					add_effect({"comparisons": [{"a": "type", "b": "rabbit_fluff"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "uncommon", "diff": values[0]})
					add_effect({"comparisons": [{"a": "type", "b": "rabbit_fluff"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "rare", "diff": values[0]})
					add_effect({"comparisons": [{"a": "type", "b": "rabbit_fluff"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "very_rare", "diff": values[0]})
				"chicken":
					add_effect({"comparisons": [{"a": "type", "b": "egg"}, {"a": "type", "b": "chick"}], "value_to_change": "achievement_value", "value_num": 1, "diff": 1})
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "egg"}]})
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 1, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "golden_egg"}]})
					add_effect({"comparisons": [{"a": "type", "b": "egg"}, {"a": "type", "b": "chick"}], "item_to_destroy": "chicken_coop_essence"})
				"chick":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "value_to_change": "type", "diff": "chicken"})
				"egg":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "golden_egg"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
					randomize()
					add_effect({"comparisons": [{"a": "type", "b": "egg", "not_prev": true}, {"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}, {"a": "destroyed", "b": false}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "type", "diff": "chick", "last_effect": true})
				"cheese":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "milk"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "omelette"}], "target": self, "value_to_change": "achievement_value", "value_num": 1, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "egg"}], "target": self, "value_to_change": "achievement_value", "value_num": 2, "diff": 1})
				"mouse":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "cheese"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "cheese"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "cheese"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "ninja"}], "target": self, "value_to_change": "achievement_value", "value_num": 1, "diff": 1})
					var ninja_and_mouse
					var ninja_and_mouse_essence
					if $"/root/Main/Items".has_unmodded_item("ninja_and_mouse"):
						ninja_and_mouse = items[item_types.find("ninja_and_mouse")]
					if $"/root/Main/Items".has_unmodded_item("ninja_and_mouse"):
						ninja_and_mouse_essence = items[item_types.find("ninja_and_mouse_essence")]
					if ninja_and_mouse != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "ninja"}], "one_time": true, "value_to_change": "value_multiplier", "diff": pow(ninja_and_mouse.values[0], ninja_and_mouse.item_count)})
					if ninja_and_mouse_essence != null:
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "ninja"}], "one_time": true, "item_to_destroy": "ninja_and_mouse_essence"})
				"chemical_seven":
					var item_arr = []
					for i in range(values[1]):
						item_arr.push_back({"type": "lucky_seven"})
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true, "anim": "shake"})
					add_effect({"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": "chemical_seven"}], "value_to_change": "value_bonus", "diff": int(values[0]), "items_to_add": item_arr})
				"hustler":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					var item_arr = [values[0] * capsule_machine_multiplier, {"type": "pool_ball"}]
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true, "anim": "shake"})
					add_effect({"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": "hustler"}], "item_to_destroy": "capsule_machine_essence", "items_to_add": item_arr})
					add_effect({"comparisons": [{"a": "type", "b": "hustler"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"witch":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "witchlikes"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
				"hex_of_tedium":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
					if holy_water == null:
						var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
						add_effect({"comparisons": [{"a": "type", "b": "hex_of_tedium"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "uncommon", "diff": 1.0 + (1.0 - values[0])})
						add_effect({"comparisons": [{"a": "type", "b": "hex_of_tedium"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "rare", "diff": 1.0 + (1.0 - values[0])})
						add_effect({"comparisons": [{"a": "type", "b": "hex_of_tedium"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "very_rare", "diff": 1.0 + (1.0 - values[0])})
				"hex_of_thievery":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					if holy_water == null:
						randomize()
						add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "rotate", "value_to_change": "value_bonus", "diff": -values[1]})
				"hex_of_destruction":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					if holy_water == null and not tried_to_give_rand_eff:
						var possible_icons = []
						var icon_to_be_destroyed
						for i in adj_icons:
							if i.type != "empty":
								possible_icons.push_back(i)
						if possible_icons.size() > 0:
							randomize()
							icon_to_be_destroyed = possible_icons[floor(rand_range(0, possible_icons.size()))]
						if icon_to_be_destroyed != null:
							randomize()
							add_effect_to_symbol(icon_to_be_destroyed.grid_position.y, icon_to_be_destroyed.grid_position.x, {"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "dynamic_a_target": self, "dynamic_a_key": "values", "rand": true}, {"a": "destroyed", "b": false, "not_prev": true}, {"a": "destroyed", "b": false, "not_prev": true, "dynamic_a_target": self, "dynamic_a_key": "destroyed"}, {"a": "indestructible", "b": false}], "anim": "rotate", "anim_targets": [self, icon_to_be_destroyed], "value_to_change": "destroyed", "hex_eff": true, "diff": true})
							tried_to_give_rand_eff = true
				"hex_of_emptiness":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					for i in $"/root/Main/Items".destroyed_items:
						if i == "holy_water_essence":
							holy_water = i
							break
					if holy_water == null and $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1:
						randomize()
						add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}, {"a": null, "b": false, "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "hex_of_hoarding_trigger"}], "anim": "rotate", "anim_targets": [self], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "hex_of_emptiness_trigger", "diff": true})
				"dwarf":
					var dwarven_anvil
					if $"/root/Main/Items".has_unmodded_item("dwarven_anvil"):
						dwarven_anvil = items[item_types.find("dwarven_anvil")]
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "dwarflikes"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "item_to_destroy": "dwarven_anvil_essence", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "dwarflikes"}], "target": self, "value_to_change": "value_bonus", "dynamic_diff_target": i, "dynamic_diff_key": "non_prev_final_value", "dynamic_diff_multiplier": values[0]})
						if dwarven_anvil != null:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "minerlikes", "not_prev": true}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "item_to_destroy": "dwarven_anvil_essence", "diff": true, "sfx_type": 1})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "minerlikes"}], "target": self, "value_to_change": "value_bonus", "dynamic_diff_target": i, "dynamic_diff_key": "non_prev_final_value", "dynamic_diff_multiplier": values[0]})
				"bartender":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"group": "booze"}]})
				"king_midas":
					add_effect({"comparisons": [], "anim": "shake", "tiles_to_add": [{"type": "coin"}]})
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "golden_egg"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "coin"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0], "sfx_type": 1})
				"farmer":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "farmerlikes"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "bonus_values", "bonus_value_num": 0, "diff": values[1]})
				"buffing_powder":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					var anim_arr = [self]
					for i in adj_icons:
						if reels.displayed_icons[i.grid_position.y][i.grid_position.x].type != "empty":
							anim_arr.push_back(reels.displayed_icons[i.grid_position.y][i.grid_position.x])
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [], "value_to_change": "value_multiplier", "diff": pow(values[0], capsule_machine_multiplier), "unconditional": true})
					add_effect({"comparisons": [], "anim": "bounce", "anim_targets": anim_arr, "value_to_change": "destroyed", "diff": true, "unconditional": true})
					add_effect({"comparisons": [{"a": "type", "b": "buffing_powder"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"snail", "magpie", "owl":
					var checkered_flag_diff = 0
					if $"/root/Main/Items".has_unmodded_item("checkered_flag"):
						checkered_flag_diff = items[item_types.find("checkered_flag")].values[0] * items[item_types.find("checkered_flag")].item_count
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 12 and fp.dynamic_icon == t:
							checkered_flag_diff -= fp.values[0]
							break
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
				"sloth":
					var checkered_flag_diff = 0
					if $"/root/Main/Items".has_unmodded_item("checkered_flag"):
						checkered_flag_diff = items[item_types.find("checkered_flag")].values[0] * items[item_types.find("checkered_flag")].item_count
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 12 and fp.dynamic_icon == t:
							checkered_flag_diff -= fp.values[0]
							break
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "snail"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "turtle"}], "target": self, "value_to_change": "achievement_value", "value_num": 1, "diff": 1})
				"turtle":
					var checkered_flag_diff = 0
					if $"/root/Main/Items".has_unmodded_item("checkered_flag"):
						checkered_flag_diff = items[item_types.find("checkered_flag")].values[0] * items[item_types.find("checkered_flag")].item_count
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 12 and fp.dynamic_icon == t:
							checkered_flag_diff -= fp.values[0]
							break
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
					add_effect({"comparisons": [{"a": "type", "b": "turtle"}, {"a": "grid_position_x", "b": 0}], "value_to_change": "saved_achievement_value", "value_num": 0, "diff": 1})
					if saved_achievement_values[0] >= 1:
						add_effect({"comparisons": [{"a": "type", "b": "turtle"}, {"a": "grid_position_x", "b": reels.reel_width - 1}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						saved_achievement_values[0] = 0
				"crow":
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1], "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1], "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
				"rarity_capsule":
					var rarity_arr = []
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					for i in range(values[0] * capsule_machine_multiplier):
						rarity_arr.push_back("rare")
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "type", "b": "rarity_capsule"}], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "forced_rarities", "diff": {"forced_rarity": rarity_arr, "or_better": true}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "type", "b": "rarity_capsule"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"shiny_pebble":
					var symbol_rarity = $"/root/Main/Pop-up Sprite/Pop-up".rarity_bonuses["symbols"]
					add_effect({"comparisons": [{"a": "type", "b": "shiny_pebble"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "uncommon", "diff": values[0]})
					add_effect({"comparisons": [{"a": "type", "b": "shiny_pebble"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "rare", "diff": values[0]})
					add_effect({"comparisons": [{"a": "type", "b": "shiny_pebble"}], "target": symbol_rarity, "multiply": true, "raritymod": true, "value_to_change": "very_rare", "diff": values[0]})
				"goose":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "golden_egg"}]})
				"monkey":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "monkeylikes"}], "item_to_destroy": "oswald_the_monkey_essence", "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "monkeylikes"}], "target": self, "value_to_change": "value_bonus", "dynamic_diff_target": i, "dynamic_diff_key": "non_prev_final_value", "dynamic_diff_multiplier": values[0]})
				"banana_peel":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "thief", "not_prev": true}], "anim": "rotate", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true, "destroy_giver_on_destroy": true})
						if $"/root/Main/Items".has_unmodded_item("dark_humor_essence"):
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "comedian", "not_prev": true}], "anim": "rotate", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
				"item_capsule":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					var item_arr = [values[0] * capsule_machine_multiplier, {"rarity": "common"}]
					add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true, "anim": "shake"})
					add_effect({"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": "item_capsule"}], "items_to_add": item_arr})
					add_effect({"comparisons": [{"a": "type", "b": "item_capsule"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"banana":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "banana"}], "tiles_to_add": [{"type": "banana_peel"}]})
				"hex_of_draining":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					if holy_water == null:
						var possible_icons = []
						var icon_to_be_drained
						for i in adj_icons:
							if i.type != "empty":
								possible_icons.push_back(i)
						if possible_icons.size() > 0:
							randomize()
							possible_icons.shuffle()
							icon_to_be_drained = possible_icons[0]
						if icon_to_be_drained != null:
							randomize()
							add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "target": icon_to_be_drained, "anim": "rotate", "anim_targets": [self, icon_to_be_drained], "value_to_change": "drained", "hex_eff": true, "diff": true})
				"big_ore":
					var x_ray_machine
					var x_ray_machine_essence
					if $"/root/Main/Items".has_unmodded_item("x_ray_machine"):
						x_ray_machine = items[item_types.find("x_ray_machine")]
					if $"/root/Main/Items".has_unmodded_item("x_ray_machine_essence"):
						x_ray_machine_essence = items[item_types.find("x_ray_machine_essence")]
					var symbol_arr = []
					for i in range(values[0]):
						if x_ray_machine_essence != null:
							symbol_arr.push_back({"group": "gem", "min_rarity": "very_rare"})
						elif x_ray_machine != null:
							symbol_arr.push_back({"group": "gem", "min_rarity": "rare"})
						else:
							symbol_arr.push_back({"group": "gem"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "big_ore"}], "item_to_destroy": "x_ray_machine_essence", "tiles_to_add": symbol_arr})
				"void_creature":
					var destroy_self = true
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "empty"}], "value_to_change": "value_bonus", "diff": values[0]})
						if i.type == "empty":
							destroy_self = false
					if destroy_self:
						add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "void_creature"}], "value_to_change": "value_bonus", "diff": values[2]})
				"void_stone":
					var destroy_self = true
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "empty"}], "value_to_change": "value_bonus", "diff": values[0]})
						if i.type == "empty":
							destroy_self = false
					if destroy_self:
						add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "void_stone"}], "value_to_change": "value_bonus", "diff": values[2]})
				"void_fruit":
					var destroy_self = true
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "empty"}], "value_to_change": "value_bonus", "diff": values[0]})
						if i.type == "empty":
							destroy_self = false
					if destroy_self:
						add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "void_fruit"}], "value_to_change": "value_bonus", "diff": values[2]})
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"mine":
					add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "less_than": true}], "anim": "shake", "tiles_to_add": [{"type": "ore"}]})
					add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "greater_than_eq": true}], "anim": "shake", "tiles_to_add": [{"type": "ore"}], "value_to_change": "destroyed", "diff": true})
					var item_arr = []
					for i in range(values[1]):
						item_arr.push_back({"type": "mining_pick"})
					add_effect({"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": "mine"}], "items_to_add": item_arr})
				"golem":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					for i in range(values[0]):
						symbol_arr.push_back({"type": "ore"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "golem"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"dame":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "gem"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "martini"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "sfx_type": 1, "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "martini"}], "target": self, "value_to_change": "value_bonus", "diff": values[1]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "martini"}], "target": self, "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "diamond"}], "target": self, "value_to_change": "achievement_value", "value_num": 1, "diff": 1})
				"key":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "chest", "not_prev": true}, {"a": "tbd", "b": false}], "no_extra_targets": true, "anim": "shake", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true, "destroy_giver_on_destroy": true})
				"coconut":
					var symbol_arr = []
					for i in range(values[0]):
						symbol_arr.push_back({"type": "coconut_half"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "coconut"}], "tiles_to_add": symbol_arr})
				"crab":
					for x in range(reels.reel_width):
						if reels.displayed_icons[grid_position.y][x] != self:
							add_effect_to_symbol(grid_position.y, x, {"comparisons": [{"a": "type", "b": "crab"}], "value_to_change": "value_bonus", "diff": values[0]})
							add_effect_to_symbol(grid_position.y, x, {"comparisons": [{"a": "type", "b": "crab"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"archaeologist":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "archlikes"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "archlikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "removed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "archlikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "removed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "archlikes"}], "value_to_change": "destroyed_or_removed_by", "diff": t})
				"mrs_fruit":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "fruitlikes", "not_prev": true}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "fruitlikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
				"clubs", "spades":
					var fifth_ace
					if $"/root/Main/Items".has_unmodded_item("fifth_ace"):
						fifth_ace = items[item_types.find("fifth_ace")]
					reels.count_symbols(true)
					if reels.counted_symbols[$"/root/Main".get_appended_steam_id("clubs", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("diamonds", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("hearts", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("spades", "symbol")] >= values[2]:
						add_effect({"comparisons": [], "value_to_change": "value_bonus", "diff": values[1]})
					for i in adj_icons:
						if fifth_ace:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "diamonds"}], "value_to_change": "value_bonus", "diff": values[0] * fifth_ace.item_count})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "hearts"}], "value_to_change": "value_bonus", "diff": values[0] * fifth_ace.item_count})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "clubs"}], "value_to_change": "value_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "spades"}], "value_to_change": "value_bonus", "diff": values[0]})
				"diamonds", "hearts":
					var fifth_ace
					if $"/root/Main/Items".has_unmodded_item("fifth_ace"):
						fifth_ace = items[item_types.find("fifth_ace")]
					reels.count_symbols(true)
					if reels.counted_symbols[$"/root/Main".get_appended_steam_id("clubs", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("diamonds", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("hearts", "symbol")] + reels.counted_symbols[$"/root/Main".get_appended_steam_id("spades", "symbol")] >= values[2]:
						add_effect({"comparisons": [], "value_to_change": "value_bonus", "diff": values[1]})
					for i in adj_icons:
						if fifth_ace:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "clubs"}], "value_to_change": "value_bonus", "diff": values[0] * fifth_ace.item_count})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "spades"}], "value_to_change": "value_bonus", "diff": values[0] * fifth_ace.item_count})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "diamonds"}], "value_to_change": "value_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "hearts"}], "value_to_change": "value_bonus", "diff": values[0]})
				"matryoshka_doll_1":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					symbol_arr.push_back({"type": "matryoshka_doll_2"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "matryoshka_doll_1"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"matryoshka_doll_2":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					symbol_arr.push_back({"type": "matryoshka_doll_3"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "matryoshka_doll_2"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"matryoshka_doll_3":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					symbol_arr.push_back({"type": "matryoshka_doll_4"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "matryoshka_doll_3"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"matryoshka_doll_4":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[1] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					symbol_arr.push_back({"type": "matryoshka_doll_5"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "matryoshka_doll_4"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"oyster":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "pearl"}]})
					add_effect({"comparisons": [{"a": "removed", "b": true}, {"a": "type", "b": "oyster"}], "tiles_to_add": [{"type": "pearl"}]})
				"card_shark":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "suit"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "wildcarded", "diff": true})
				"diver":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "poslikes"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "removed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "removed", "b": true}, {"a": "groups", "b": "poslikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
				"bronze_arrow", "silver_arrow", "golden_arrow":
					randomize()
					var direction_arr = [int(floor(rand_range(1, 9)))]
					if $"/root/Main/Items".has_unmodded_item("quiver") or $"/root/Main/Items".has_unmodded_item("quiver_essence"):
						var directions = [1, 2, 3, 4, 5, 6, 7, 8]
						directions.erase(direction_arr[0])
						randomize()
						direction_arr.push_back(directions[floor(rand_range(0, 7))])
					add_effect({"comparisons": [{"a": "pointing_directions", "b": 0}, {"a": "destroyed", "b": false, "not_prev": true}], "anim": "ordered_texture_cycle", "anim_result": direction_arr[0], "value_to_change": "pointing_directions", "diff": direction_arr})
					if direction_arr.size() >= 2:
						add_effect({"comparisons": [{"a": "destroyed", "b": false, "not_prev": true}], "anim": "bounce"})
						add_effect({"comparisons": [{"a": "destroyed", "b": false, "not_prev": true}], "anim": "ordered_texture_cycle", "anim_result": direction_arr[1]})
					elif direction_arr.size() == 1:
						done_spinning = true
					if pointing_directions.size() > 0 and done_spinning:
						for i in get_directional_icons(pointing_directions):
							reels.add_symbol_position_to_update(i.grid_position)
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [], "value_to_change": "value_multiplier", "diff": values[0], "unconditional": true})
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "target"}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"reroll_capsule":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "reroll_capsule"}], "item_to_destroy": "capsule_machine_essence", "value_to_change": "value_bonus", "currency": "reroll_token", "diff": int(values[0] * capsule_machine_multiplier)})
				"removal_capsule":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "removal_capsule"}], "item_to_destroy": "capsule_machine_essence", "value_to_change": "value_bonus", "currency": "removal_token", "diff": int(values[0] * capsule_machine_multiplier)})
				"hooligan":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "spiritbox"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "spiritbox"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"tedium_capsule":
					var rarity_arr = []
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					for i in range(values[1] * capsule_machine_multiplier):
						rarity_arr.push_back("common")
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "tedium_capsule"}], "value_to_change": "value_bonus", "diff": int(values[0] * capsule_machine_multiplier)})
					add_effect({"comparisons": [{"a": "type", "b": "tedium_capsule"}], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "forced_rarities", "diff": {"forced_rarity": rarity_arr, "or_better": false}, "add_to_array": true})
					add_effect({"comparisons": [{"a": "type", "b": "tedium_capsule"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"target":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "target"}], "value_to_change": "value_bonus", "diff": values[0]})
				"billionaire":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "richlikes"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "billionaire"}], "value_to_change": "value_bonus", "diff": values[1]})
				"magic_key":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "chest", "not_prev": true}, {"a": "tbd", "b": false}], "no_extra_targets": true, "anim": "shake", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true, "destroy_giver_on_destroy": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "chest"}, {"a": "destroyed", "b": true}], "no_extra_targets": true, "one_time": true, "value_to_change": "value_multiplier", "diff": values[0]})
				"pirate":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "piratelikes", "not_prev": true}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "piratelikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "removed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "piratelikes"}], "target": self, "value_to_change": "permanent_bonus", "diff": values[0]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "removed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "piratelikes"}], "value_to_change": "destroyed_or_removed_by", "diff": t})
				"bar_of_soap":
					add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "less_than": true}], "anim": "shake", "tiles_to_add": [{"type": "bubble"}]})
					add_effect({"comparisons": [{"a": "times_coins_given", "b": values[0] - 1, "greater_than_eq": true}], "anim": "shake", "tiles_to_add": [{"type": "bubble"}], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [], "value_to_change": "saved_achievement_value", "value_num": 0, "diff": 1})
				"anchor":
					add_effect({"comparisons": [{"a": "grid_position_x", "b": 0}, {"a": "grid_position_y", "b": 0}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "grid_position_x", "b": 0}, {"a": "grid_position_y", "b": reels.reel_height - 1}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "grid_position_x", "b": reels.reel_width - 1}, {"a": "grid_position_y", "b": 0}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "grid_position_x", "b": reels.reel_width - 1}, {"a": "grid_position_y", "b": reels.reel_height - 1}], "value_to_change": "value_bonus", "diff": values[0]})
				"hex_of_hoarding":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					if holy_water == null and $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] != 1:
						randomize()
						add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}, {"a": null, "b": false, "dynamic_a_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_a_key": "hex_of_emptiness_trigger"}], "anim": "rotate", "anim_targets": [self], "target": $"/root/Main/Pop-up Sprite/Pop-up", "value_to_change": "hex_of_hoarding_trigger", "diff": true})
				"hex_of_midas":
					var holy_water
					if $"/root/Main/Items".has_unmodded_item("holy_water") or $"/root/Main/Items".destroyed_item_types.has("holy_water_essence"):
						holy_water = true
						saved_achievement_values[0] = 0
					if holy_water == null:
						randomize()
						add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "rotate", "anim_targets": [self], "tiles_to_add": [{"type": "coin"}]})
				"cow":
					randomize()
					add_effect({"comparisons": [{"a": "values", "b": rand_range(0, 100), "value_num": 0, "rand": true}], "anim": "shake", "tiles_to_add": [{"type": "milk"}]})
				"frozen_fossil":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[2] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true, "dynamic_b_mod_target": $"/root/Main/Pop-up Sprite/Pop-up", "dynamic_b_mod_key": "fossil_diff", "dynamic_b_mod_multiplier": -values[1]}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					var symbol_arr = []
					symbol_arr.push_back({"type": "eldritch_beast"})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "frozen_fossil"}], "item_to_add_saved_value": "time_machine_essence", "tiles_to_add": symbol_arr})
				"eldritch_beast":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "fossillikes"}, {"a": "destroyed", "b": false}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [], "value_to_change": "value_bonus", "diff": $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * values[0], "overwrite": true})
				"robin_hood":
					var checkered_flag_diff = 0
					if $"/root/Main/Items".has_unmodded_item("checkered_flag"):
						checkered_flag_diff = items[item_types.find("checkered_flag")].values[0] * items[item_types.find("checkered_flag")].item_count
					for fp in $"/root/Main/Landlord".fine_print:
						if fp.num == 12 and fp.dynamic_icon == t:
							checkered_flag_diff -= fp.values[0]
							break
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1] - checkered_flag_diff, "greater_than_eq": true}], "value_to_change": "times_displayed", "diff": 0, "overwrite": true})
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "robinlikes"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_bonus", "diff": values[2]})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "robinhates"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "sfx_type": 1, "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "groups", "b": "robinhates"}], "target": self, "value_to_change": "value_bonus", "diff": values[3]})
				"rabbit":
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1]}], "anim": "bounce", "value_to_change": "permanent_bonus", "stat_to_change": "rabbit_hops", "stat_diff": 3, "diff": values[0]})
					if $"/root/Main/Items".has_unmodded_item("shedding_season_essence"):
						var fluff_arr = []
						for z in range(items[item_types.find("shedding_season_essence")].values[1]):
							fluff_arr.push_back({"type": "rabbit_fluff"})
						add_effect({"comparisons": [], "anim": "bounce", "tiles_to_add": fluff_arr, "stat_to_change": "rabbit_fluff_shed", "stat_diff": fluff_arr.size() * 0.01, "item_to_destroy": "shedding_season_essence"})
						add_effect({"comparisons": [], "stat_to_change": "rabbit_hops", "stat_diff": 3})
					if $"/root/Main/Items".has_unmodded_item("turtle_and_rabbit_essence"):
						for i in adj_icons:
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "turtle"}], "item_to_destroy": "turtle_and_rabbit_essence"})
				"present":
					var time_machine_diff = 0
					if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
						time_machine_diff = 1000000
					elif $"/root/Main/Items".has_unmodded_item("time_machine"):
						time_machine_diff = items[item_types.find("time_machine")].values[2] * items[item_types.find("time_machine")].item_count
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0] - time_machine_diff, "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "present"}], "item_to_add_saved_value": "time_machine_essence", "value_to_change": "value_bonus", "diff": values[1]})
				"watermelon":
					add_effect({"comparisons": [{"a": "type", "b": "watermelon"}, {"a": {"counted_symbols": "watermelon"}, "b": 0, "greater_than": true}], "value_to_change": "value_bonus", "diff": {"counted_symbols": "watermelon"}})
					if not $"/root/Main/Items".has_unmodded_item("fertilizer_essence"):
						add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"flower":
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"essence_capsule":
					var capsule_machine_multiplier = 1
					if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
					if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
						capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
					add_effect({"comparisons": [], "value_to_change": "destroyed", "anim": "shake", "diff": true})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "essence_capsule"}], "item_to_destroy": "capsule_machine_essence", "value_to_change": "value_bonus", "currency": "essence_token", "diff": int(values[0] * capsule_machine_multiplier)})
				"dud":
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[0], "greater_than_eq": true}], "anim": "shake", "value_to_change": "destroyed", "diff": true})
				"dog":
					var quigley_the_wolf_essence = false
					if $"/root/Main/Items".destroyed_item_types.has("quigley_the_wolf_essence"):
						quigley_the_wolf_essence = true
					elif $"/root/Main/Items".has_unmodded_item("quigley_the_wolf_essence") and items_destroyed_this_spin.has("quigley_the_wolf_essence"):
						quigley_the_wolf_essence = true
					if quigley_the_wolf_essence:
						add_effect({"comparisons": [{"a": "type", "b": "dog", "not_prev": true}], "anim": "shake", "value_to_change": "type", "diff": "wolf"})
				"comedian":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "funny"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
						if $"/root/Main/Items".has_unmodded_item("dark_humor"):
							add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "darkhumor"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": pow(items[item_types.find("dark_humor")].values[1], items[item_types.find("dark_humor")].item_count)})
					if $"/root/Main/Items".has_unmodded_item("dark_humor_essence"):
						add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "comedian"}], "item_to_destroy": "dark_humor_essence"})
				"light_bulb":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "gem"}], "value_to_change": "saved_value", "target": self, "diff": 1})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "groups", "b": "gem"}], "anim": "circle", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "value_multiplier", "diff": values[0]})
					add_effect({"comparisons": [{"a": "saved_value", "b": values[1], "greater_than_eq": true}, {"a": "indestructible", "b": false}, {"a": "tbd", "b": false}], "anim": "shake", "value_to_change": "destroyed", "sfx_type": 1, "diff": true})
				"time_capsule":
					if not destroyed:
						add_effect({"comparisons": [], "value_to_change": "destroyed", "diff": true, "anim": "shake"})
						var capsule_machine_multiplier = 1
						if $"/root/Main/Items".has_unmodded_item("capsule_machine"):
							capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine")].values[0], items[item_types.find("capsule_machine")].item_count)
						if $"/root/Main/Items".has_unmodded_item("capsule_machine_essence"):
							capsule_machine_multiplier *= pow(items[item_types.find("capsule_machine_essence")].values[0], items[item_types.find("capsule_machine_essence")].item_count)
						var symbol_arr = []
						for i in range(values[0] * capsule_machine_multiplier):
							symbol_arr.push_back("prev_destroyed_symbol")
						add_effect({"comparisons": [{"a": "tbd", "b": true}, {"a": "type", "b": "time_capsule", "not_prev": true}], "tiles_to_add": symbol_arr})
					add_effect({"comparisons": [{"a": "type", "b": "time_capsule"}, {"a": "destroyed", "b": true}], "item_to_destroy": "capsule_machine_essence"})
				"peach":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "peach"}], "tiles_to_add": [{"type": "seed"}]})
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"apple":
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "target": $"/root/Main/Reels", "value_to_change": "grown_apples", "diff": 1})
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"strawberry":
					add_effect({"comparisons": [{"a": "type", "b": t}, {"a": {"counted_symbols": t}, "b": values[1], "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "target": $"/root/Main/Reels", "value_to_change": "grown_strawberries", "diff": 1})
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"pear":
					add_effect({"comparisons": [{"a": "type", "b": "seed"}], "value_to_change": "achievement_value", "value_num": 0, "diff": 1})
				"ruby", "emerald":
					add_effect({"comparisons": [{"a": "type", "b": t}, {"a": {"counted_symbols": t}, "b": values[1], "greater_than_eq": true}], "value_to_change": "value_bonus", "diff": values[0]})
				"wine":
					add_effect({"comparisons": [{"a": "times_displayed", "b": values[1]}], "anim": "shake", "value_to_change": "permanent_bonus", "diff": values[0]})
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "wine"}], "stat_to_change": "alcohol_consumed", "stat_diff": 0.1906514})
				"beer":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "beer"}], "stat_to_change": "alcohol_consumed", "stat_diff": 0.1200954})
				"goldfish":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "type", "b": "bubble"}], "anim": "bounce", "anim_targets": [self, reels.displayed_icons[i.grid_position.y][i.grid_position.x]], "value_to_change": "destroyed", "diff": true})
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [{"a": "destroyed", "b": true}, {"a": "tbd", "b": false}, {"a": "type", "b": "bubble"}], "target": self, "value_to_change": "value_bonus", "diff": values[0]})
				"gambler":
					add_effect({"comparisons": [{"a": "destroyed", "b": true}, {"a": "type", "b": "gambler"}], "value_to_change": "value_bonus", "diff": times_displayed * values[1]})
				"dove":
					for i in adj_icons:
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, {"comparisons": [], "value_to_change": "indestructible", "diff": true, "push_front": true})
				"sand_dollar":
					add_effect({"comparisons": [{"a": "removed", "b": true}, {"a": "type", "b": "sand_dollar"}], "value_to_change": "value_bonus", "diff": values[0]})
				"jellyfish":
					add_effect({"comparisons": [{"a": "removed", "b": true}, {"a": "type", "b": "jellyfish"}], "value_to_change": "value_bonus", "currency": "removal_token", "diff": values[0]})
				"pufferfish":
					add_effect({"comparisons": [{"a": "removed", "b": true}, {"a": "type", "b": "pufferfish"}], "value_to_change": "value_bonus", "currency": "reroll_token", "diff": values[0]})
		var fp_effects = []
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num > 37:
				for r in fp.effects:
					if not fp.for_items:
						var fp_types = fp.reliant_types
						var fp_groups = fp.reliant_groups
						if fp.reliant_types != "" and $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(fp.reliant_types):
							fp_types = fp.reliant_types + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[fp.reliant_types] + "_PACK_" + $"/root/Main".mod_pack_nums[fp.reliant_types + "_STEAM_ID_" + $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[fp.reliant_types]]
						var with_id = t
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(t):
							with_id = $"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t]) + "_PACK_" + $"/root/Main".mod_pack_nums[$"/root/Main".append_steam_id(t, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[t])]
							if $"/root/Main".mod_data.symbols[with_id].art_replacement or $"/root/Main".is_mod_disabled(with_id):
								with_id = t
						if (fp_types != "" and fp_types == with_id) or (fp_groups != "" and t_groups.has(fp_groups)) or (fp_types == "" and fp_groups == ""):
							var eff = r.duplicate(true)
							eff["fp_num"] = fp.num
							fp_effects.push_back(eff)
		for m in $"/root/Main/Pop-up Sprite/Pop-up".mods.symbols:
			if old_t == m.type:
				for eff in m.effects:
					add_modded_effect(eff, adj_icons)
		for f in fp_effects:
			tmp_fp_num = f.fp_num
			add_modded_effect(f, adj_icons)
		for k in $"/root/Main".inherited_effects_database.keys():
			for i in inherited_effects:
				if "inherited_effects_" + i + "_STEAM_ID_" + str(k.substr(k.find("_STEAM_ID_") + 10, -1)) == k:
					for eff in $"/root/Main".inherited_effects_database[k]:
						add_modded_effect(eff, adj_icons)
					break
		if $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
			for f in $"/root/Main/Pop-up Sprite/Pop-up".current_modded_floor.symbol_effects:
				add_modded_effect(f, adj_icons)
	if type != "empty" and can_be_removed:
		add_effect({"comparisons": [{"a": "removed", "b": true, "not_prev": true}], "value_to_change": "type", "diff": "empty", "push_front": true})
	adj_icons.clear()
	for g in given_effects:
		add_effect(g)

func add_modded_effect(eff, adj_icons):
	if not eff.has("effect_type"):
		if groups.has("raritymod"):
			if reels.adding_rarity_effects and eff.has("rarity_mod"):
				add_effect(eff.duplicate(true))
			elif not reels.adding_rarity_effects and not eff.has("rarity_mod"):
				add_effect(eff.duplicate(true))
		else:
			add_effect(eff.duplicate(true))
	else:
		match eff["effect_type"]:
			"self", "counted_adjacent_symbols":
				if groups.has("raritymod"):
					if reels.adding_rarity_effects and eff.has("rarity_mod"):
						add_effect(eff.duplicate(true))
					elif not reels.adding_rarity_effects and not eff.has("rarity_mod"):
						add_effect(eff.duplicate(true))
				else:
					add_effect(eff.duplicate(true))
			"symbols":
				for x in range(reels.reel_width):
					for y in range(reels.reel_height):
						if grid_position != Vector2(x, y):
							add_effect_to_symbol(y, x, eff.duplicate(true))
			"adjacent_symbols":
				for i in adj_icons:
					add_effect_to_symbol(i.grid_position.y, i.grid_position.x, eff.duplicate(true))
			"pointed_symbols":
				if pointing_directions.size() > 0:
					for i in get_directional_icons(pointing_directions):
						add_effect_to_symbol(i.grid_position.y, i.grid_position.x, eff.duplicate(true))
						reels.add_symbol_position_to_update(i.grid_position)
			"rand_adjacent_symbol":
				if not tried_to_give_rand_eff:
					var possible_icons = []
					var icon_to_be_destroyed
					for i in adj_icons:
						if i.type != "empty":
							possible_icons.push_back(i)
					if possible_icons.size() > 0:
						randomize()
						icon_to_be_destroyed = possible_icons[floor(rand_range(0, possible_icons.size()))]
					if icon_to_be_destroyed != null:
						randomize()
						var dest_eff = eff.duplicate(true)
						dest_eff["hex_eff"] = true
						add_effect_to_symbol(icon_to_be_destroyed.grid_position.y, icon_to_be_destroyed.grid_position.x, dest_eff)
						tried_to_give_rand_eff = true
			"same_rand_adjacent_symbol":
				if not tried_to_give_rand_eff or same_rand_adjacent_symbol != null:
					if same_rand_adjacent_symbol == null:
						var possible_icons = []
						for i in adj_icons:
							if i.type != "empty":
								possible_icons.push_back(i)
						if possible_icons.size() > 0:
							randomize()
							same_rand_adjacent_symbol = possible_icons[floor(rand_range(0, possible_icons.size()))]
					if same_rand_adjacent_symbol != null:
						randomize()
						var dest_eff = eff.duplicate(true)
						dest_eff["hex_eff"] = true
						add_effect_to_symbol(same_rand_adjacent_symbol.grid_position.y, same_rand_adjacent_symbol.grid_position.x, dest_eff)
						tried_to_give_rand_eff = true
