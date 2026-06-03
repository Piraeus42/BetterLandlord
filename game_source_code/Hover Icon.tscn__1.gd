extends Control

var pos
var dont_remove = false
var sprite
var type
var active = false
var card
var button
var tooltips
var hovering = false
var rect_size_mod
var fine_print = false
var count = 1
var value_text = ""
var permanent_bonus = ""
var permanent_multiplier = ""
var item_value_text = ""
var inv_pos = ""
var item = false
var selectable = true
var off_screen = false
var source
var main
var popup
var tmp_effects = []

var cant_go_dirs = []
var selector_alignment = "dont"

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _input(event):
	if hovering and event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and not $"/root/Main".lmb_down and type != "empty" and type != "dud" and type != $"/root/Main".get_empty_data():
		if Steam.isSteamRunningOnSteamDeck():
			$"/root/Main".press_timer = 3
		else:
			press()
	elif hovering and item and event is InputEventKey and event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["enable_disable_item"][0] and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		toggle_disabled()
	elif hovering and item and event is InputEventMouseButton and event.button_index == $"/root/Main/Options Sprite/Options".hotkeys["enable_disable_item"][0] and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		toggle_disabled()

func _ready():
	sprite = $"Icon"
	card = get_parent().get_parent().get_parent()
	if not $"/root/Main/Options Sprite/Options".CJK_lang:
		button = get_parent().get_parent()
		if get_parent().get_parent().get_parent() is TextureButton:
			rect_size_mod = 0.25
		elif $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and (($"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "chili_powder_essence_prompt" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "add_item_prompt" or (($"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "comrade_help" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "init_comrade_help" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "comrade_help_no_essence" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "init_comrade_help_no_essence" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "rent_due") and $"/root/Main/Pop-up Sprite/Pop-up".deck_button != null and $"/root/Main/Pop-up Sprite/Pop-up".deck_button.call != "undraw_deck")) and card.get_parent() != null and card.get_parent().get_parent() != null and card.get_parent().get_parent().get_path() != "/root/Main/Tooltips"):
			rect_size_mod = 0.25
		elif get_parent().get_parent().get_parent() == $"/root/Main/Pop-up Sprite/Pop-up/Container":
			if get_parent().get_parent().get_parent().get_parent().emails[0].type == "add_tile_prompt":
				rect_size_mod = 0.25
			else:
				rect_size_mod = 0.625
		else:
			rect_size_mod = 1.0
	else:
		button = get_parent().get_parent().get_parent()
		rect_size_mod = 2.0
	rect_size_mod = 1.0
	tooltips = $"/root/Main/Tooltips"
	if str(get_parent().get_path()).find("Background/Description") != -1 or str(get_parent().get_path()).find("Tooltips") != -1 or str(get_parent().get_path()).find("Pop-up Sprite/Pop-up/Container/") != -1 or ($"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "inventory"):
		selector_alignment = "hover_icon"
	if $"/root/Main".non_symbol_icons.has(type) or (not $"/root/Main/Options Sprite/Options".CJK_lang and get_parent().get_parent() is TextureButton) or get_parent().get_parent().get_parent() is TextureButton:
		selectable = false

func update():
	if is_processing_input() and visible and active:
		if is_inside_tree() and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and $"/root/Main/Selector Sprite/Selector".visible:
			tts()
			if $"/root/Main".down_keys["inspect"] == 1:
				$"/root/Main".down_keys["inspect"] += 1
				if not $"/root/Main/Selector Sprite/Selector".visible:
					$"/root/Main/Selector Sprite/Selector".visible = true
				else:
					if tooltips.get_children().size() < 10:
						hover()
						if tooltips.get_children().size() > 0:
							$"/root/Main".down_keys["inspect"] = 1
							$"/root/Main".selected_node = tooltips.get_child(tooltips.get_children().size() - 1)
						return
			elif $"/root/Main".down_keys["deny_cancel"] == 1 or $"/root/Main".down_keys["deny_cancel"] >= 25:
				$"/root/Main".down_keys["deny_cancel"] += 1
				if not $"/root/Main/Selector Sprite/Selector".visible:
					$"/root/Main/Selector Sprite/Selector".visible = true
				else:
					if tooltips.get_children().size() > 0:
						$"/root/Main".selected_node = tooltips.get_child(tooltips.get_children().size() - 1)
					else:
						$"/root/Main".selected_node = source
					return
			elif $"/root/Main".down_keys["confirm_select"] == 1:
				$"/root/Main".down_keys["confirm_select"] += 1
				if not $"/root/Main/Selector Sprite/Selector".visible:
					$"/root/Main/Selector Sprite/Selector".visible = true
				elif type != "empty" and type != "dud" and type != $"/root/Main".get_empty_data():
					press()
		if is_inside_tree():
			var popup_rect = $"/root/Main/Pop-up Sprite/Pop-up/Container"
			if active and hovering and not $"/root/Main/Options Sprite/Options".visible and (not OS.is_window_focused() or $"/root/Main".mouse_position.x < rect_global_position.x or $"/root/Main".mouse_position.x > rect_global_position.x + rect_size.x * rect_scale.x * get_parent().rect_scale.x or $"/root/Main".mouse_position.y < rect_global_position.y or $"/root/Main".mouse_position.y > rect_global_position.y + rect_size.y * rect_scale.y * get_parent().rect_scale.y or (card != null and card.get_parent() == $"/root/Main/Pop-up Sprite/Pop-up/Container" and card.active and ($"/root/Main".mouse_position.x < popup_rect.rect_global_position.x or $"/root/Main".mouse_position.x > popup_rect.rect_global_position.x + popup_rect.rect_size.x or $"/root/Main".mouse_position.y < popup_rect.rect_global_position.y or $"/root/Main".mouse_position.y > popup_rect.rect_global_position.y + popup_rect.rect_size.y))):
				unhover()
				hovering = false
			elif active and not hovering and OS.is_window_focused() and not ($"/root/Main".mouse_position.x < rect_global_position.x or $"/root/Main".mouse_position.x > rect_global_position.x + rect_size.x * rect_scale.x * get_parent().rect_scale.x or $"/root/Main".mouse_position.y < rect_global_position.y or $"/root/Main".mouse_position.y > rect_global_position.y + rect_size.y * rect_scale.y * get_parent().rect_scale.y) and (not (($"/root/Main".mouse_position.x < popup_rect.rect_global_position.x or $"/root/Main".mouse_position.x > popup_rect.rect_global_position.x + popup_rect.rect_size.x or $"/root/Main".mouse_position.y < popup_rect.rect_global_position.y or $"/root/Main".mouse_position.y > popup_rect.rect_global_position.y + popup_rect.rect_size.y) and (card != null and card.get_parent() == $"/root/Main/Pop-up Sprite/Pop-up/Container" and card.active)) or (card == null or card.get_parent() == $"/root/Main/Pop-up Sprite/Pop-up/Container")):
				hover()
		if is_inside_tree() and $"/root/Main".press_timer > 0 and (((not ($"/root/Main".mouse_position.x < rect_global_position.x or $"/root/Main".mouse_position.x > rect_global_position.x + rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < rect_global_position.y or $"/root/Main".mouse_position.y > rect_global_position.y + rect_size.y * rect_scale.y)))) and type != "empty" and type != "dud" and type != $"/root/Main".get_empty_data():
			press()

func hover():
	if active and (button.visible or button == null) and visible:
		if card != null and card.get_parent() == $"/root/Main/Pop-up Sprite/Pop-up/Container" and card.active and $"/root/Main".down_keys["inspect"] == 0 and not (card.get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container" and ((rect_global_position.y + rect_size.y >= card.get_parent().rect_global_position.y + card.get_parent().rect_size.y) or (rect_global_position.y <= card.get_parent().rect_global_position.y))):
			card.hover()
		if can_add_tooltip():
			hovering = true
			var tooltip = load("res://Tooltip.tscn").instance()
			var database = $"/root/Main/".item_database
			if not database.has(type):
				database = $"/root/Main/".tile_database
			if type == "reroll_token" or type == "removal_token" or type == "essence_token":
				tooltip.get_child(0).data = {"text": tr(type + "_reminder"), "rarity": null, "values": [], "type": type, "modded": false}
			elif type == "hover_coin":
				tooltip.get_child(0).data = database["coin"]
			elif database.has(type):
				tooltip.get_child(0).data = database[type]
			elif database.has("item_missing"):
				tooltip.get_child(0).data = database["item_missing"]
			else:
				tooltip.get_child(0).data = database["missing"]
			tooltip.source = self
			tooltip.origin = self
			if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and $"/root/Main/Selector Sprite/Selector".visible:
				tooltip.controller_tooltip = true
			tooltips.add_child(tooltip)
			if tooltips.get_children().size() == 10:
				var highlanders = true
				for t in tooltips.get_children():
					if t.source.type != "highlander":
						highlanders = false
						break
				if highlanders:
					$"/root/Main/Stats Sprite/Stats".unlock_achievement(74, true)
			tts()

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	if (active or type == "removal_token" or type == "reroll_token" or type == "essence_token") and visible:
		if ($"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and ($"/root/Main/Pop-up Sprite/Pop-up".inv_open or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "inventory" or $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "removal_token_prompt")):
			if type == "removal_token":
				$"/root/Main".tts(tr(type) + str($"/root/Main/Pop-up Sprite/Pop-up".removal_tokens), [], self)
			elif type == "reroll_token":
				$"/root/Main".tts(tr(type) + str($"/root/Main/Pop-up Sprite/Pop-up".reroll_tokens), [], self)
			elif type == "essence_token":
				$"/root/Main".tts(tr(type) + str($"/root/Main/Pop-up Sprite/Pop-up".essence_tokens), [], self)
			else:
				var t_label = load("res://Outline Label.tscn").instance()
				t_label.visible = false
				add_child(t_label)
				t_label.raw_string = str(count) + "\n" + tr(type) + "\n"
				var start = ""
				var z_text = ""
				var z_values = []
				if item:
					if item_value_text != "":
						t_label.raw_string += item_value_text + "\n"
					z_values = $"/root/Main".item_database[type].values
				else:
					if value_text != "":
						t_label.raw_string += value_text + "\n"
					if permanent_multiplier != "":
						t_label.raw_string += permanent_multiplier + "\n"
					if permanent_bonus != "":
						t_label.raw_string += permanent_bonus + "\n"
					t_label.values = []
					if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
						t_label.get_child(0).custom_max_width = 10000000
					else:
						t_label.custom_max_width = 10000000
					t_label.tts = true
					t_label.update()
					start = t_label.raw_string
					var z = load("res://Slot Icon.tscn").instance()
					z.type = type
					z.in_reels = false
					$"/root/Main".add_child(z)
					z.soft_changing = true
					z.change_type(type, false)
					$"/root/Main".remove_child(z)
					z.queue_free()
					t_label.raw_string = ""
					if z.rarity != "none":
						t_label.raw_string += tr(z.rarity) + "\n"
					t_label.raw_string += tr("value")
					t_label.values = [z.value]
					t_label.update()
					if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
						z_text = t_label.get_child(0).text
					else:
						z_text = t_label.text
					z_values = z.values
				remove_child(t_label)
				t_label.queue_free()
				if tr(type + "_desc") == type + "_desc":
					$"/root/Main".tts(inv_pos + start + "\n" + z_text, [], self)
				else:
					$"/root/Main".tts(inv_pos + start + z_text + "\n" + tr(type + "_desc") + "\n", z_values, self)
		else:
			$"/root/Main".tts(type, [], self)

func unhover():
	for t in tooltips.get_children():
		if t.locked_pos == null and (t.source != card or t.origin == self):
			t.queue_free()

func toggle_disabled():
	for i in $"/root/Main/Items".items:
		if i.type == type:
			i.toggle_disabled()
			break
	for z in $"/root/Main/Tooltips".get_children():
		z.queue_free()
	$"/root/Main/Pop-up Sprite/Pop-up".reset_deck()

func press():
	if (not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0 and card.get_path() != "/root/Main/Pop-up Sprite/Pop-up") or (($"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0) and card.get_path() != "/root/Main/Pop-up Sprite/Pop-up/Container") or type == "reroll_token" or type == "removal_token" or type == "essence_token" or type == "yes" or type == "no" or $"/root/Main/Landlord".anim_time > 0 or $"/root/Main/Sums/HP Sum".adding:
		return
	if Steam.isSteamRunningOnSteamDeck():
		$"/root/Main".press_timer = 0
	popup = $"/root/Main/Pop-up Sprite/Pop-up"
	var buttons_menu = $"/root/Main/Menus".buttons_menu
	var reels = $"/root/Main/Reels"
	main = $"/root/Main"
	var p_type = type
	var icon_arr
	
	if popup.removing:
		var q = load("res://Slot Icon.tscn").instance()
		if type == "hover_coin":
			q.type = "coin"
		else:
			q.type = type
		q.in_reels = false
		add_child(q)
		q.soft_changing = true
		q.change_type(q.type, false)
		
		if not q.can_be_removed:
			remove_child(q)
			q.queue_free()
			return
		else:
			remove_child(q)
			q.queue_free()
	
	var parent = get_parent()
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		parent = parent.get_parent()
	
	if parent.texts.size() > 7:
		icon_arr = parent.texts[8].icons
	else:
		icon_arr = parent.get_child(0).icons
	
	var icon_pos = 0
	
	if type == "hover_coin":
		p_type = "coin"
	if popup.removing:
		if item:
			return
		var break_out = false
		
		var time_machine_diff = 0
		if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
			time_machine_diff = 1000000
		elif $"/root/Main/Items".has_unmodded_item("time_machine"):
			time_machine_diff = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("time_machine")].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("time_machine")].item_count
		
		var tmp = load("res://Outline Label.tscn").instance()
		add_child(tmp)
		
		for r in reels.reels:
			var inc = -1
			for t in range(r.icon_types_to_be_added.size()):
				inc += 1
				if r.icon_types_to_be_added[t] == p_type and (r.icon_types_tba_bonus_texts[inc][2] == value_text and r.icon_types_tba_bonus_texts[inc][0] == permanent_bonus and r.icon_types_tba_bonus_texts[inc][1] == permanent_multiplier or (value_text == null or (r.icon_types_to_be_added[t] == "frozen_fossil" and value_text == "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">" + tmp.parse_num_str(str(main.tile_database["frozen_fossil"].values[0] - time_machine_diff - popup.fossil_diff * main.tile_database["frozen_fossil"].values[1])) + "<end>") or (r.icon_types_to_be_added[t] == "eldritch_beast" and value_text == "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + tmp.parse_num_str(str((popup.fossil_diff - 1) * main.tile_database["eldritch_beast"].values[0])) + "<end>" or (popup.fossil_diff) * main.tile_database["eldritch_beast"].values[0]))):
					for z in $"/root/Main/Tooltips".get_children():
						z.queue_free()
					r.icon_types_to_be_added.remove(t)
					
					var vt = value_text
					var pb = permanent_bonus
					var pm = permanent_multiplier
					
					if value_text == null:
						vt = ""
					if permanent_bonus == null:
						pb = ""
					if permanent_multiplier == null:
						pm = ""
					
					var icon
					icon_pos = icon_arr.find(self)
					if popup.saved_symbol_counts[p_type + vt + pb + pm].count == 1:
						for s in popup.saved_symbol_data:
							if s.type == p_type and s.value_text == vt and s.permanent_bonus == pb and s.permanent_multiplier == pm:
								icon = s
								popup.saved_symbol_data.erase(s)
								break
						popup.saved_symbol_counts.erase(p_type + vt + pb + pm)
					else:
						popup.saved_symbol_counts[p_type + vt + pb + pm].count -= 1
					if pos >= icon_arr.size():
						pos -= 1
					popup.removed_symbol_types.push_back(p_type)
					if main.group_database.symbols["fossillikes"].has(p_type):
						popup.fossil_diff += 1
						update_eldritch()
						for reel in reels.reels:
							if reel.icon_types.has("eldritch_beast"):
								$"/root/Main/Stats Sprite/Stats".unlock_achievement(51, true)
								break
					popup.removal_tokens -= popup.removal_cost
					check_removal_triggers(icon)
					popup.check_spend_triggers("spend_removal_token")
					if p_type == "crow" and value_text == "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">1<end>":
						$"/root/Main/Stats Sprite/Stats".unlock_achievement(39, true)
					elif p_type == "jellyfish":
						$"/root/Main/Stats Sprite/Stats".unlock_achievement(79, true)
					elif p_type == "sand_dollar" and $"/root/Main/Sums/Coin Sum".value >= 40:
						$"/root/Main/Stats Sprite/Stats".unlock_achievement(122, true)
					if popup.removal_tokens > popup.removal_cost - 1:
						buttons_menu.removal_button.text_node.values = [popup.removal_tokens]
						buttons_menu.removal_button.update_size()
						buttons_menu.removal_button.text_node.force_update = true
						buttons_menu.removal_button.text_node.update()
						buttons_menu.removal_button.correct_size()
						buttons_menu.removal_button.visible = true
						add_empty()
					else:
						buttons_menu.removal_button.visible = false
					break_out = true
					for z in reels.reels:
						for f in z.icons:
							f.update_value_text()
					reels.update_icon_types()
					if popup.removal_tokens > popup.removal_cost - 1:
						popup.reset_deck()
						main.save_game()
					else:
						popup.resolve_event(null)
					break
			if break_out:
				break
		for r in reels.reels:
			if break_out:
				break
			else:
				for icon in r.icons:
					icon.update_value_text()
					if icon.type == p_type and icon.get_child(1).raw_string == value_text and icon.get_child(3).raw_string == permanent_bonus and icon.get_child(2).raw_string == permanent_multiplier:
						for z in $"/root/Main/Tooltips".get_children():
							z.queue_free()
						icon.removed = true
						icon.change_type("empty", false)
						icon.prev_data.clear()
						icon.update_value_text()
						
						var vt = value_text
						var pb = permanent_bonus
						var pm = permanent_multiplier
						
						if value_text == null:
							vt = ""
						if permanent_bonus == null:
							pb = ""
						if permanent_multiplier == null:
							pm = ""
						
						icon_pos = icon_arr.find(self)
						if popup.saved_symbol_counts[p_type + vt + pb + pm].count == 1:
							for s in popup.saved_symbol_data:
								if s.type == p_type and s.value_text == vt and s.permanent_bonus == pb and s.permanent_multiplier == pm:
									popup.saved_symbol_data.erase(s)
									break
							popup.saved_symbol_counts.erase(p_type + vt + pb + pm)
						else:
							popup.saved_symbol_counts[p_type + vt + pb + pm].count -= 1
						
						if pos >= icon_arr.size():
							pos -= 1
						
						popup.removed_symbol_types.push_back(p_type)
						if main.group_database.symbols["fossillikes"].has(p_type):
							popup.fossil_diff += 1
							update_eldritch()
							for reel in reels.reels:
								if reel.icon_types.has("eldritch_beast"):
									$"/root/Main/Stats Sprite/Stats".unlock_achievement(51, true)
									break
						popup.removal_tokens -= popup.removal_cost
						check_removal_triggers(icon)
						popup.check_spend_triggers("spend_removal_token")
						if p_type == "crow" and value_text == "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">1<end>":
							$"/root/Main/Stats Sprite/Stats".unlock_achievement(39, true)
						elif p_type == "jellyfish":
							$"/root/Main/Stats Sprite/Stats".unlock_achievement(79, true)
						elif p_type == "sand_dollar" and $"/root/Main/Sums/Coin Sum".value >= 40:
							$"/root/Main/Stats Sprite/Stats".unlock_achievement(122, true)
						if popup.removal_tokens > popup.removal_cost - 1:
							buttons_menu.removal_button.text_node.values = [popup.removal_tokens]
							buttons_menu.removal_button.update_size()
							buttons_menu.removal_button.text_node.force_update = true
							buttons_menu.removal_button.text_node.update()
							buttons_menu.removal_button.correct_size()
							buttons_menu.removal_button.visible = true
							
							add_empty()
						else:
							buttons_menu.removal_button.visible = false
						break_out = true
						for z in reels.reels:
							for f in z.icons:
								f.update_value_text()
						reels.update_icon_types()
						if popup.removal_tokens > popup.removal_cost - 1:
							popup.reset_deck()
							main.save_game()
						else:
							popup.resolve_event(null)
						break
					if break_out:
						break
		remove_child(tmp)
		tmp.queue_free()
		if icon_arr.size() > icon_pos:
			main.selected_node = icon_arr[icon_pos]
	elif popup.emails.size() > 0:
		if popup.emails[0].type == "chili_powder_essence_prompt" or popup.emails[0].type == "add_item_prompt":
			$"/root/Main/Items".add_item(p_type)
			popup.resolve_event(null)
		elif popup.emails[0].type == "add_tile_prompt":
			reels.add_tile([p_type])
			if not $"/root/Main/".group_database.symbols.taken.has(p_type) and p_type != "coin":
				$"/root/Main/".group_database.symbols.taken.push_back(p_type)
				$"/root/Main/".group_database.symbols.passed.erase(p_type)
			popup.resolve_event(null)

func check_removal_triggers(icon):
	match type.substr(0, type.find("_STEAM_ID_")):
		"sand_dollar":
			$"/root/Main/Sums/Coin Sum".add_value($"/root/Main".tile_database[type].values[0])
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value($"/root/Main".tile_database[type].values[0])
			$"/root/Main/Sums/HP Sum".adding = true
		"jellyfish":
			$"/root/Main/Sums/Extra Sum".add_value(0, $"/root/Main".tile_database[type].values[0], 0)
			$"/root/Main/Sums/Extra Sum".adding = true
			popup.removal_tokens += $"/root/Main".tile_database[type].values[0]
		"pufferfish":
			$"/root/Main/Sums/Extra Sum".add_value($"/root/Main".tile_database[type].values[0], 0, 0)
			$"/root/Main/Sums/Extra Sum".adding = true
			popup.reroll_tokens += $"/root/Main".tile_database[type].values[0]
		"oyster":
			$"/root/Main/Reels".add_tile([$"/root/Main".get_appended_steam_id("pearl", "symbol")])
			popup.resolve_event(null)
			if popup.removal_tokens > popup.removal_cost - 1:
				popup.draw_deck()
	for m in popup.mods.symbols:
		if type == m.type:
			var currency_values = {"coins": 0, "reroll": 0, "removal": 0, "essence": 0}
			for effect in m.effects:
				if effect.has("comparisons"):
					var correct_comp = false
					for comp in effect.comparisons:
						if comp.hash() == {"a": "removed", "b": true}.hash():
							correct_comp = true
							break
					if correct_comp:
						var z = $"/root/Main/Reels".generate_icon(type, null)
						var eff = effect.duplicate(true)
						
						$"/root/Main/Reels".symbol_arr.erase(z)
						
						z["grid_position"] = Vector2(-1, -1)
						
						if icon != null:
							for p in ["type", "destroyed", "indestructible", "coins_earned", "times_coins_given", "times_displayed", "value_bonus_arr", "value_multiplier_arr", "permanent_bonus", "displayed_text_value", "final_value", "non_flat_final_value", "non_prev_final_value", "tried_to_give_rand_eff", "permanent_bonus", "reroll_token_permanent_bonus", "removal_token_permanent_bonus", "permanent_multiplier", "reroll_token_permanent_multiplier", "removal_token_permanent_multiplier", "essence_token_permanent_multiplier", "saved_value", "saved_values", "achievement_values", "saved_achievement_values", "grid_position"]:
								if p in icon:
									z[p] = icon[p]
						z.removed = true
						z.in_reels = false
						add_child(z)
						z.soft_changing = true
						
						if not eff.has("comparisons"):
							eff["comparisons"] = []
						eff["target"] = z
						
						z.add_effect(eff)
						z.check_conditional_effects(tmp_effects)
						tmp_effects.clear()
						
						if eff.has("value_to_change") and eff.value_to_change == "value_bonus":
							z.value = 0
							if eff.has("currency") and eff.currency != "coin":
								var c = z.get_value(eff.currency)
								match eff.currency:
									"reroll_token":
										$"/root/Main/Sums/Extra Sum".add_value(c, 0, 0)
									"removal_token":
										$"/root/Main/Sums/Extra Sum".add_value(0, c, 0)
									"essence_token":
										$"/root/Main/Sums/Extra Sum".add_value(0, 0, c)
								$"/root/Main/Sums/Extra Sum".adding = true
								popup[eff.currency + "s"] += c
							else:
								var c = z.get_value("coin")
								$"/root/Main/Sums/Coin Sum".add_value(c)
								$"/root/Main/Sums/Coin Sum".adding = true
								$"/root/Main/Sums/HP Sum".add_value(c)
								$"/root/Main/Sums/HP Sum".adding = true
						
						if $"/root/Main/Reels".symbol_queue.size() > 0:
							$"/root/Main/Reels".add_tile($"/root/Main/Reels".symbol_queue)
							$"/root/Main/Reels".symbol_queue.clear()
							popup.resolve_event(null)
							if popup.removal_tokens > popup.removal_cost - 1:
								popup.draw_deck()
						
						remove_child(z)
						z.queue_free()

func add_empty():
	var z = load("res://Slot Icon.tscn").instance()
	z.type = "empty"
	z.in_reels = false
	main.add_child(z)
	z.soft_changing = true
	z.change_type("empty", false)
	
	if not popup.saved_symbol_counts.has("empty" + z.get_child(1).raw_string + z.get_child(3).raw_string + z.get_child(2).raw_string):
		popup.saved_symbol_counts["empty" + z.get_child(1).raw_string + z.get_child(3).raw_string + z.get_child(2).raw_string] = {"count": 1, "value_text": z.get_child(1).raw_string}
		popup.saved_symbol_data.push_back({"type": "empty", "rarity": z.rarity, "value": z.value, "value_text": z.get_child(1).raw_string, "permanent_bonus": z.get_child(3).raw_string, "permanent_multiplier": z.get_child(2).raw_string, "times_displayed": 0})
	else:
		popup.saved_symbol_counts["empty" + z.get_child(1).raw_string + z.get_child(3).raw_string + z.get_child(2).raw_string].count += 1
	main.remove_child(z)
	z.queue_free()

func update_eldritch():
	$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts.clear()
	for r in $"/root/Main/Reels".reels:
		if r.icon_types.has("frozen_fossil"):
			$"/root/Main/Stats Sprite/Stats".unlock_achievement(57, true)
			break
	
	var tmp = load("res://Outline Label.tscn").instance()
	add_child(tmp)
	var total_symbols = 0
	
	var time_machine_diff = 0
	if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
		time_machine_diff = 1000000
	elif $"/root/Main/Items".has_unmodded_item("time_machine"):
		time_machine_diff = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("time_machine")].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("time_machine")].item_count
	
	for r in $"/root/Main/Reels".reels:
		for icon in r.icons:
			icon.update_value_text()
			if not $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts.has(icon.type + icon.get_child(1).raw_string + icon.get_child(3).raw_string + icon.get_child(2).raw_string):
				$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[icon.type + icon.get_child(1).raw_string + icon.get_child(3).raw_string + icon.get_child(2).raw_string] = {"count": 1, "value_text": "", "permanent_bonus": icon.get_child(3).raw_string, "permanent_multiplier": icon.get_child(2).raw_string}
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[icon.type + icon.get_child(1).raw_string + icon.get_child(3).raw_string + icon.get_child(2).raw_string].count += 1
			total_symbols += 1
	
	for r in $"/root/Main/Reels".reels:
		for t in range(r.icon_types_to_be_added.size()):
			var vt = ""
			var vt_num = 0
			var pb = ""
			var pb_num = 0
			var pm = ""
			var pm_num = 0
			var color = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">"
			
			var to_be_updated = []
			
			var inc = -1
			
			if r.icon_types_to_be_added[t] == "frozen_fossil":
				for s in $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data:
					inc += 1
					if s.type == r.icon_types_to_be_added[t] and (s.value_text == "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">" + tmp.parse_num_str(str($"/root/Main".tile_database["frozen_fossil"].values[0] - time_machine_diff - ($"/root/Main/Pop-up Sprite/Pop-up".fossil_diff - 1) * $"/root/Main".tile_database["frozen_fossil"].values[1])) + "<end>" or $"/root/Main".tile_database["frozen_fossil"].values[0] - time_machine_diff - ($"/root/Main/Pop-up Sprite/Pop-up".fossil_diff - 1) * $"/root/Main".tile_database["frozen_fossil"].values[1] <= 0):
						var z = load("res://Slot Icon.tscn").instance()
						z.type = s.type
						z.in_reels = false
						add_child(z)
						z.soft_changing = true
						z.change_type(s.type, false)
						var fvt = ""
						var fpb = ""
						var fpm = ""
						if z.values[0] - time_machine_diff - $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[1] - z.times_displayed > 0:
							fvt = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">" + tmp.parse_num_str(str(z.values[0] - time_machine_diff - $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[1] - z.times_displayed)) + "<end>"
						elif not $"/root/Main/Pop-up Sprite/Pop-up".fossil_combined:
							$"/root/Main/Pop-up Sprite/Pop-up".fossil_combined = true
							r.icon_types_tba_bonus_texts[t] = ["", "", ""]
						if z.permanent_bonus > 0:
							fpb = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + tmp.parse_num_str(str(z.permanent_bonus)) + "<end>"
						elif z.permanent_bonus < 0:
							fpb = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + tmp.parse_num_str(str(z.permanent_bonus)) + "<end>"
						if z.permanent_multiplier != 1:
							if z.permanent_multiplier >= 10:
								fpm = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(round(z.permanent_multiplier))) + "x<end>"
							else:
								fpm = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(stepify(z.permanent_multiplier, 0.1))) + "x<end>"
						s = {"type": "frozen_fossil", "rarity": $"/root/Main".tile_database["frozen_fossil"].rarity, "value": $"/root/Main".tile_database["frozen_fossil"].value, "value_text": fvt, "permanent_bonus": fpb, "permanent_multiplier": fpm, "times_displayed": 0}
						vt = fvt
						vt_num = $"/root/Main".tile_database["frozen_fossil"].values[0] - time_machine_diff - ($"/root/Main/Pop-up Sprite/Pop-up".fossil_diff) * $"/root/Main".tile_database["frozen_fossil"].values[1]
						to_be_updated.push_back({"data": s, "num": inc})
						pb_num = pb
						pm_num = pm
						pb = fpb
						pm = fpm
						remove_child(z)
						z.queue_free()
			elif r.icon_types_to_be_added[t] == "eldritch_beast":
				for s in $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data:
					inc += 1
					if s.type == r.icon_types_to_be_added[t]:
						var z = load("res://Slot Icon.tscn").instance()
						z.type = s.type
						z.in_reels = false
						add_child(z)
						z.soft_changing = true
						z.change_type(s.type, false)
						
						var fvt = z.displayed_text_value
						var fpb = ""
						var fpm = ""
						if z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0] > 0:
							fpb = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + tmp.parse_num_str(str(z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0])) + "<end>"
						elif z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0] < 0:
							fpb = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + tmp.parse_num_str(str(z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0])) + "<end>"
						if z.permanent_multiplier != 1:
							if z.permanent_multiplier >= 10:
								fpm = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(round(z.permanent_multiplier))) + "x<end>"
							else:
								fpm = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_multiplier_text"] + ">" + tmp.parse_num_str(str(stepify(z.permanent_multiplier, 1))) + "x<end>"
						s = {"type": "eldritch_beast", "rarity": $"/root/Main".tile_database["eldritch_beast"].rarity, "value": $"/root/Main".tile_database["eldritch_beast"].value, "value_text": fvt, "permanent_bonus": fpb, "permanent_multiplier": fpm, "times_displayed": 0}
						vt = fvt
						vt_num = ($"/root/Main/Pop-up Sprite/Pop-up".fossil_diff) * $"/root/Main".tile_database["eldritch_beast"].values[0]
						to_be_updated.push_back({"data": s, "num": inc})
						pb_num = pb
						pm_num = pm
						pb = fpb
						pm = fpm
						remove_child(z)
						z.queue_free()
						
			if r.icon_types_to_be_added[t] != "frozen_fossil" and r.icon_types_to_be_added[t] != "eldritch_beast":
				vt = r.icon_types_tba_bonus_texts[t][2]
				pb = r.icon_types_tba_bonus_texts[t][0]
				pm = r.icon_types_tba_bonus_texts[t][1]
			
			for u in to_be_updated:
				$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data[u.num] = u.data
			
			if not $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts.has(r.icon_types_to_be_added[t] + vt + pb + pm):
				$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[r.icon_types_to_be_added[t] + vt + pb + pm] = {"count": 1, "value_text": vt, "permanent_bonus": pb, "permanent_multiplier": pm}
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[r.icon_types_to_be_added[t] + vt + pb + pm].count += 1
		total_symbols += 1
	
	var devils_deal = false
	
	var e_str = $"/root/Main".get_empty_data()
	
	if $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts.has(e_str) and not devils_deal:
		if total_symbols - $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[e_str].count >= 20:
			for s in range($"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data.size()):
				if $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data[s].type == e_str:
					$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data.remove(s)
					break
			$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts.erase(e_str)
			$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_order.erase(e_str)
		else:
			$"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[e_str].count = 20 - (total_symbols - $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_counts[e_str].count)
	
	for icon in $"/root/Main/Pop-up Sprite/Pop-up".saved_symbol_data:
		var z = load("res://Slot Icon.tscn").instance()
		z.type = icon.type
		z.in_reels = false
		add_child(z)
		z.soft_changing = true
		z.change_type(icon.type, false)
		
		if icon.type == "eldritch_beast" or icon.type == "frozen_fossil":
			if z.permanent_bonus > 0 or (z.type == "eldritch_beast" and z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0] > 0):
				icon.permanent_bonus = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">+" + z.displayed_bonus_value + "<end>"
			elif z.permanent_bonus < 0 or (z.type == "eldritch_beast" and z.permanent_bonus + $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * z.values[0] < 0):
				icon.permanent_bonus = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_bonus_text"] + ">" + z.displayed_bonus_value + "<end>"
			else:
				icon.permanent_bonus = ""
		if icon.type == "frozen_fossil":
			if $"/root/Main".tile_database["frozen_fossil"].values[0] - time_machine_diff - $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * $"/root/Main".tile_database["frozen_fossil"].values[1] - icon.times_displayed > 0:
				icon.value_text = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">" + tmp.parse_num_str(str($"/root/Main".tile_database["frozen_fossil"].values[0] - time_machine_diff - $"/root/Main/Pop-up Sprite/Pop-up".fossil_diff * $"/root/Main".tile_database["frozen_fossil"].values[1] - icon.times_displayed)) + "<end>"
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".fossil_combined = true
				icon.value_text = ""
			icon.permanent_bonus = z.displayed_bonus_value
			icon.permanent_multiplier = z.displayed_multiplier_value
		remove_child(z)
		z.queue_free()
	remove_child(tmp)
	tmp.queue_free()

func can_add_tooltip():
	if tooltips.get_children().size() < 10 and type != "item_missing" and not $"/root/Main".non_symbol_icons.has(type):
		if card == null or (card.get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container" and ((rect_global_position.y + rect_size.y >= card.get_parent().rect_global_position.y + card.get_parent().rect_size.y) or (rect_global_position.y <= card.get_parent().rect_global_position.y))):
			return false
		else:
			for t in tooltips.get_children():
				if (t != null and t.source == card) or card == null or t.hover_timer < 80 or t.source == null or t.source.get_parent().get_path() == "/root/Main" or card.get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container" or not card.tooltip_card or (card.get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container" and ((rect_global_position.y + rect_size.y >= card.get_parent().rect_global_position.y + card.get_parent().rect_size.y) or (rect_global_position.y <= card.get_parent().rect_global_position.y))):
					return false
			return true
	else:
		return false

func update_hitbox():
	if $"/root/Main".non_symbol_icons.has(type) or (($"/root/Main/Options Sprite/Options".CJK_lang or $"/root/Main/Options Sprite/Options".display_font > 0) and (get_parent().get_parent().get_parent().get_path() == "/root/Main/Sums" or get_parent().get_parent().effect_text)) or ((not $"/root/Main/Options Sprite/Options".CJK_lang and $"/root/Main/Options Sprite/Options".display_font == 0) and (get_parent().get_parent().get_path() == "/root/Main/Sums" or get_parent().effect_text)):
		active = false
	elif card != null and card.get_children().size() > 1 and card.get_child(1) == $"/root/Main/Pop-up Sprite/Pop-up/Container" and type != "coin":
		rect_size = Vector2(sprite.texture.get_size().x * sprite.scale.x, sprite.texture.get_size().y * sprite.scale.y)
		active = true
	elif type != "coin":
		rect_size = Vector2(sprite.texture.get_size().x * sprite.scale.x, sprite.texture.get_size().y * sprite.scale.y)
		active = true
	else:
		rect_size = Vector2(0, 0)
		selectable = false
