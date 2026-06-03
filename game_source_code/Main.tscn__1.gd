extends Node2D

var d_time = 0.0

var steam_id = 0
var s_id = 0
var steam_mods
var icon_texture_database = {}
var tile_database = {}
var item_database = {}
var fine_print_database = {}
var apartment_floor_database = {}
var inherited_effects_database = {}
var sfx_database = { "symbols": {}, "items": {}, "misc": {} }
var modded_sfx_paths = {}
var rarity_database = { "symbols": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "none": [] }, "items": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "essence": [], "none": [] } }
var rarity_chances = { "symbols": { "uncommon": 0, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
var group_database = { "symbols": {}, "items": {} }
var init_config = {}
var need_config = false
var lmb_down = false
var loading_without_quitting = false
var updated_setting_timer = 10
var osx_setting_timer_offset = 0
var demo = false
var save_string
var window_focus = true
var are_you_sure_displayed = false
var log_queue = []
var error_queue = []
var content_patch_num = 2
var hotfix_num = 24
var version_str = "--- v1." + str(content_patch_num) + "." + str(hotfix_num) + " ---"
var last_pressed_key_code = -1
var down_scancodes = []
var guillotine_essence_anim = 0
var frame_timer = 0
var selected_node
var tts_node
var current_menu_path
var mod_names = {"symbols": [], "items": []}
var mod_data = {"symbols": {}, "items": {}, "emails": {}}
var mod_groups = {"symbols": {}, "items": {}}
var modded_existing = {"symbols": {}, "items": {}}
var modded_existing_base_types = {"symbols": {}, "items": {}}
var starting = {"symbols": [], "items": []}
var mod_packs = {}
var mod_pack_nums = {}
var base_rarities = { "symbols": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "none": [] }, "items": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "essence": [], "none": [] } }
var base_mod_fields = {"type": "", "display_name": "", "localized_names": {}, "localized_descriptions": {}, "value": null, "description": "", "values": [], "rarity": "", "groups": [], "sfx": [], "value_text": {}, "modded": true, "effects": [], "symbol_triggers": [], "symbols_removed_pre_spin": [], "manually_destroyable": false, "can_be_destroyed_before_rent": false, "skip_rent_on_destroy": false, "author_id": "0", "inherit_effects": false, "inherit_art": false, "inherit_groups": false, "inherit_description": false, "count_at_start": 0, "cannot_be_disabled": false, "header_text": "", "localized_header_text": {}, "text": "", "localized_text": {}, "replies": [], "localized_replies": {}, "prompt": false, "reply_results": [], "difficulty": 0, "relevant_type": "", "relevant_group": "", "for_items": false, "floor_num": 1, "locked": false, "has_bossfight": true, "landlord_hp": 750, "landlord_max_hp": 750, "starting_coins": 1, "starting_symbols": ["base"], "starting_items": [], "dud_timer": 0, "comrade_removal_tokens": 2, "comrade_reroll_tokens": 2, "comrade_essence_tokens": 2, "consistent_spins": false, "fine_print_multiplier": 1, "fine_print": [], "symbol_packs": ["base", "self"], "included_symbols": [], "excluded_symbols": [], "item_packs": ["base", "self"], "included_items": [], "excluded_items": [], "intro_emails": [], "ending_emails": [], "email_packs": ["base", "self"], "included_emails": [], "excluded_emails": [], "rent_values": ["base"], "rent_payments": 12, "symbol_effects": [], "item_effects": [], "inherited_effects": []}
var base_types = {"symbols": [], "items": [], "emails": []}

var non_symbol_icons = []

var sandbox_mode = false
var sandbox_icons = [[], [], [], [], []]
var sandbox_reloading = false
var sandbox_consistent = true
var testing_fine_print = false

var mod_reverse_effects = []
var mod_multiple_effects = []
var mod_on_symbol_add_effects = []
var mod_on_item_add_effects = []
var mod_on_rent_paid_effects = []
var modded_fine_print_nums = []
var modded_apartment_floors = {}
var art_replacement_nums = {}
var counted_symbols = {}

var queued_errors = []
var ui_reset_timer = 0
var holding_9 = false
var holding_d = false
var holding_u = false
var holding_n = false
var holding_y = false
var holding_a = false
var screen_reader_timer = 0
var endless_toggle_timer = 0
var endless_toggle_counter = 0
var dunya_timer = 0
var holding_endless = false
var holding_screen_reader = false
var mouse_position = Vector2(0, 0)
var press_timer = 0
var down_keys = {}
var down_keys_to_clear = []
var down_key_delay = 4
var hide_selector = true
var controller_type = "generic"
var cursor_timer = 0
var prev_selector_node
var prev_selector_node_data = {}
var hotkey_button_strings = []
var selector_buttons = []
var displayed_hotkey_sources = []
var last_input_was_controller
var reloading_scene = false
var reload_scene_timer = 0
var controllers = 0
var achievement_data = false
var axis_change_0 = 0
var axis_change_1 = 0
var axis_change_3 = 0

var existing_symbols = {}
var existing_items = {}
var tt_data

func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	if INIT.status == 1:
		s_id = Steam.getSteamID()

func _input(event):
	if event is InputEventKey and event.scancode == KEY_F8 and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		OS.shell_open(OS.get_user_data_dir() + "/run_logs")
	if event is InputEventKey and (event.scancode == KEY_F9 or event.scancode == KEY_9) and event.is_pressed():
		holding_9 = true
	else:
		holding_9 = false
	if event is InputEventKey and event.scancode == KEY_D and event.is_pressed():
		holding_d = true
	elif event is InputEventKey and event.scancode == KEY_D and not event.is_pressed():
		holding_d = false
	if event is InputEventKey and event.scancode == KEY_U and event.is_pressed():
		holding_u = true
	elif event is InputEventKey and event.scancode == KEY_U and not event.is_pressed():
		holding_u = false
	if event is InputEventKey and event.scancode == KEY_N and event.is_pressed():
		holding_n = true
	elif event is InputEventKey and event.scancode == KEY_N and not event.is_pressed():
		holding_n = false
	if event is InputEventKey and event.scancode == KEY_Y and event.is_pressed():
		holding_y = true
	elif event is InputEventKey and event.scancode == KEY_Y and not event.is_pressed():
		holding_y = false
	if event is InputEventKey and event.scancode == KEY_A and event.is_pressed():
		holding_a = true
	elif event is InputEventKey and event.scancode == KEY_A and not event.is_pressed():
		holding_a = false
	if ((event is InputEventKey and (event.scancode == KEY_F7 or event.scancode == KEY_7)) or (event is InputEventJoypadButton and event.is_pressed() and event.button_index == JOY_BUTTON_9)) and event.is_pressed() and $"Title".visible:
		holding_endless = true
	else:
		holding_endless = false
	if ((event is InputEventKey and (event.scancode == KEY_F3 or event.scancode == KEY_3)) or (event is InputEventJoypadButton and event.is_pressed() and event.button_index == JOY_BUTTON_4)) and event.is_pressed() and ($"Title".visible or need_config):
		holding_screen_reader = true
	else:
		holding_screen_reader = false
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.is_pressed() and not event.is_echo()):
		$"Selector Sprite/Selector".visible = false
		hide_selector = true
	if event is InputEventKey and event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.scancode == $"Options Sprite/Options".hotkeys[k][0]:
				down_keys[k] += 1
				last_input_was_controller = false
				break
	if event is InputEventMouseButton and event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.button_index == $"Options Sprite/Options".hotkeys[k][0]:
				down_keys[k] += 1
				last_input_was_controller = false
				break
	if event is InputEventJoypadButton and event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.button_index == $"Options Sprite/Options".hotkeys[k][1]:
				down_keys[k] += 1
				last_input_was_controller = true
				if $"Options Sprite/Options".input_type == 1:
					$"Options Sprite/Options".input_type = 0
					save_options()
				break
	if event is InputEventKey and not event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.scancode == $"Options Sprite/Options".hotkeys[k][0]:
				if down_keys[k] < down_key_delay:
					down_keys[k] = down_key_delay - 1
					down_keys_to_clear.push_back(k)
				else:
					down_keys[k] = 0
				break
	if event is InputEventMouseButton and not event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.button_index == $"Options Sprite/Options".hotkeys[k][0]:
				if down_keys[k] < down_key_delay:
					down_keys[k] = down_key_delay - 1
					down_keys_to_clear.push_back(k)
				else:
					down_keys[k] = 0
				break
	if event is InputEventJoypadButton and not event.is_pressed() and OS.is_window_focused():
		for k in down_keys.keys():
			if event.button_index == $"Options Sprite/Options".hotkeys[k][1]:
				if down_keys[k] < down_key_delay:
					down_keys[k] = down_key_delay - 1
					down_keys_to_clear.push_back(k)
				else:
					down_keys[k] = 0
				break
	if event is InputEventJoypadMotion and (event.axis == JOY_AXIS_0 or event.axis == JOY_AXIS_1 or event.axis == JOY_AXIS_3) and OS.is_window_focused():
		if event.axis == JOY_AXIS_0 and abs(axis_change_0 - event.axis_value) >= 0.1:
			axis_change_0 = event.axis_value
			if event.axis_value < -0.45:
				down_keys["left"] += 1
				last_input_was_controller = true
			elif event.axis_value > 0.45:
				down_keys["right"] += 1
				last_input_was_controller = true
			if event.axis_value < 0.2:
				down_keys_to_clear.push_back("right")
			if event.axis_value > -0.2:
				down_keys_to_clear.push_back("left")
		if event.axis == JOY_AXIS_1 and abs(axis_change_1 - event.axis_value) >= 0.1:
			axis_change_1 = event.axis_value
			if event.axis_value < -0.45:
				down_keys["up"] += 1
				last_input_was_controller = true
			elif event.axis_value > 0.45:
				down_keys["down"] += 1
				last_input_was_controller = true
			if event.axis_value < 0.2:
				down_keys_to_clear.push_back("down")
			if event.axis_value > -0.2:
				down_keys_to_clear.push_back("up")
		if event.axis == JOY_AXIS_3 and abs(axis_change_3 - event.axis_value) >= 0.1:
			axis_change_3 = event.axis_value
			if event.axis_value < -0.45:
				down_keys["scroll_up"] += 1
				last_input_was_controller = true
			elif event.axis_value > 0.45:
				down_keys["scroll_down"] += 1
				last_input_was_controller = true
			if event.axis_value < 0.2:
				down_keys_to_clear.push_back("scroll_down")
			if event.axis_value > -0.2:
				down_keys_to_clear.push_back("scroll_up")
	if ((event is InputEventKey and event.scancode == $"Options Sprite/Options".hotkeys["fast_forward"][0]) or (event is InputEventJoypadButton and event.button_index == $"Options Sprite/Options".hotkeys["fast_forward"][1])) and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		if $"Options Sprite/Options".spin_speed >= 1:
			$"Options Sprite/Options".spin_speed_offset = 2
		elif $"Options Sprite/Options".spin_speed != 0:
			$"Options Sprite/Options".spin_speed_offset = 2 - $"Options Sprite/Options".spin_speed
		if $"Options Sprite/Options".animation_speed >= 1:
			$"Options Sprite/Options".animation_speed_offset = 2
		elif $"Options Sprite/Options".animation_speed != 0:
			$"Options Sprite/Options".animation_speed_offset = 2 - $"Options Sprite/Options".animation_speed
		if $"Options Sprite/Options".counting_speed >= 1:
			$"Options Sprite/Options".counting_speed_offset = 2
		elif $"Options Sprite/Options".counting_speed != 0:
			$"Options Sprite/Options".counting_speed_offset = 2 - $"Options Sprite/Options".counting_speed
		if $"Options Sprite/Options".menu_speed >= 1:
			$"Options Sprite/Options".menu_speed_offset = 2
		elif $"Options Sprite/Options".menu_speed != 0:
			$"Options Sprite/Options".menu_speed_offset = 2 - $"Options Sprite/Options".menu_speed
	elif ((event is InputEventKey and event.scancode == $"Options Sprite/Options".hotkeys["fast_forward"][0]) or (event is InputEventJoypadButton and event.button_index == $"Options Sprite/Options".hotkeys["fast_forward"][1])) and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		$"Options Sprite/Options".spin_speed_offset = 0
		$"Options Sprite/Options".animation_speed_offset = 0
		$"Options Sprite/Options".counting_speed_offset = 0
		$"Options Sprite/Options".menu_speed_offset = 0
	elif event is InputEventMouseButton and event.button_index == $"Options Sprite/Options".hotkeys["fast_forward"][0] and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		if $"Options Sprite/Options".spin_speed >= 1:
			$"Options Sprite/Options".spin_speed_offset = 2
		elif $"Options Sprite/Options".spin_speed != 0:
			$"Options Sprite/Options".spin_speed_offset = 2 - $"Options Sprite/Options".spin_speed
		if $"Options Sprite/Options".animation_speed >= 1:
			$"Options Sprite/Options".animation_speed_offset = 2
		elif $"Options Sprite/Options".animation_speed != 0:
			$"Options Sprite/Options".animation_speed_offset = 2 - $"Options Sprite/Options".animation_speed
		if $"Options Sprite/Options".counting_speed >= 1:
			$"Options Sprite/Options".counting_speed_offset = 2
		elif $"Options Sprite/Options".counting_speed != 0:
			$"Options Sprite/Options".counting_speed_offset = 2 - $"Options Sprite/Options".counting_speed
		if $"Options Sprite/Options".menu_speed >= 1:
			$"Options Sprite/Options".menu_speed_offset = 2
		elif $"Options Sprite/Options".menu_speed != 0:
			$"Options Sprite/Options".menu_speed_offset = 2 - $"Options Sprite/Options".menu_speed
	elif event is InputEventMouseButton and event.button_index == $"Options Sprite/Options".hotkeys["fast_forward"][0] and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		$"Options Sprite/Options".spin_speed_offset = 0
		$"Options Sprite/Options".animation_speed_offset = 0
		$"Options Sprite/Options".counting_speed_offset = 0
		$"Options Sprite/Options".menu_speed_offset = 0
	elif (event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_echo()) and event.is_pressed() and OS.is_window_focused() and ((not event is InputEventScreenTouch and not Steam.isSteamRunningOnSteamDeck()) or (event is InputEventScreenTouch and Steam.isSteamRunningOnSteamDeck() and not event.is_pressed())):
		lmb_down = true
	elif ((event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_echo()) or event is InputEventScreenTouch) and not event.is_pressed() and OS.is_window_focused():
		lmb_down = false
	for h in $"Options Sprite/Options".assignable_hotkeys:
		if event is InputEventKey and event.scancode == $"Options Sprite/Options".hotkeys[h][0] and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			if $"Options Sprite/Options".input_type == 1:
				down_scancodes.erase(event.scancode)
		elif event is InputEventKey and event.scancode == $"Options Sprite/Options".hotkeys[h][0] and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			if $"Options Sprite/Options".input_type == 0:
				down_scancodes.erase(event.scancode)
		elif event is InputEventMouseButton and event.button_index == $"Options Sprite/Options".hotkeys[h][0] and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			if $"Options Sprite/Options".input_type == 1:
				down_scancodes.erase(event.button_index)
		elif event is InputEventMouseButton and event.button_index == $"Options Sprite/Options".hotkeys[h][0] and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
			if $"Options Sprite/Options".input_type == 0:
				down_scancodes.erase(event.button_index)

func _init():
	if demo:
		save_string = "user://LBAL-Demo.save"
	else:
		save_string = "user://LBAL.save"
	
	preload_config(save_string)
	preload_config("user://LBAL-Settings.save")
	
	if OS.get_name() == "OSX":
		OS.window_borderless = false
	
	if not init_config.has("language") or init_config["language"] == null:
		need_config = true
		TranslationServer.set_locale("en")
	else:
		Engine.target_fps = init_config.max_fps
		OS.vsync_enabled = init_config.vsync
		TranslationServer.set_locale(init_config.language)
		OS.set_window_title(tr("Title translation"))
	
	load_data(false, false, false)

func _ready():
	_initialize_Steam()
	
	var options = $"Options Sprite/Options"
	
	Input.connect("joy_connection_changed", self, "check_controller_type")
	
	if not need_config:
		var save_game = File.new()
		if not save_game.file_exists("user://errors.log"):
			save_game.open("user://errors.log", File.WRITE)
			save_game.close()
		if not save_game.file_exists(save_string):
			save_game()
		if not save_game.file_exists("user://LBAL-Settings.save"):
			save_options()
		if not save_game.file_exists("user://LBAL-Stats.save") and not save_game.file_exists("user://LBAL-Stats.bak"):
			save_stats()
		load_game()
		init_sandbox()
		load_sandbox()
		load_options()
		if TranslationServer.get_locale() == "zh_HK":
			options.language = "zh_TW"
			TranslationServer.set_locale("zh_TW")
			save_options()
		if Steam.isSteamRunningOnSteamDeck() and options.input_type == 1:
			options.input_type = 0
			save_options()
		load_stats()
		$"/root/Main/Stats Sprite/Stats".landlord_fates_not_seen.clear()
		for l in $"Pop-up Sprite/Pop-up".landlord_fates_data:
			if $"/root/Main/Stats Sprite/Stats".landlord_fates_seen.find(float(l)) == -1:
				$"/root/Main/Stats Sprite/Stats".landlord_fates_not_seen.push_back(l)
		$"Stats Sprite/Stats".check_if_essences_unlocked()
		$"Stats Sprite/Stats".check_if_stats_unlocked()
		$"Stats Sprite/Stats".check_if_bossfight_unlocked()
		save_stats()
		$"Stats Sprite/Stats".unlock_local_chievos()
		options.changing_osx_fullscreen = true
		if OS.get_name() == "OSX":
			updated_setting_timer = 0
	else:
		options.reset_to_default("input", false)
		save_game()
	
	var deck_fine = false
	
	if Steam.isSteamRunningOnSteamDeck():
		if options.resolution_x == 1280 and options.resolution_y == 800:
			deck_fine = true
		else:
			options.resolution_x = 1280
			options.resolution_y = 800
	
	for node in get_tree().get_nodes_in_group("Background X"):
		node.rect_size.x = options.resolution_x
	for node in get_tree().get_nodes_in_group("Background Y"):
		node.rect_size.y = options.resolution_y
	for node in get_tree().get_nodes_in_group("Background Y Scaling"):
		node.rect_size.y = options.resolution_y - node.rect_position.y
	for node in get_tree().get_nodes_in_group("Scroll Bar"):
		node.bottom = node.base_bottom + options.resolution_y - 576

	$"Pop-up Sprite/Pop-up".load_emails()
	
	$"Pop-up Sprite/Pop-up".label_text.values = $"Pop-up Sprite/Pop-up".rent_values.duplicate(true)
	
	if need_config:
		if Steam.isSteamRunningOnSteamDeck():
			options.resolution_x = 1280
			options.resolution_y = 800
		options.get_spacing()
		options.set_max_scaling()
		options.first_menu = true
		options.open(null)
		change_current_menu_path("init")
	else:
		$"Language Sprite".visible = false
		title()
		change_current_menu_path("/root/Main/Title")
	if options.music.goal_volume > -80 and not $"Music Player/Music".playing and not $"Music Player/Music2".playing and not need_config:
		$"Music Player".play_rand_music()
		$"Music Player".fade_in()
	$"Menus".buttons_menu.add_item_buttons()
	$"Items".update_page_buttons()
	options.reset_buttons()
	if options.CJK_lang:
		$"Sums/Coin Sum".scale_mod = 1 + -floor((1 - options.ui_scaling.text) / 0.25)
		$"Sums/Extra Sum".scale_mod = 1 + -floor((1 - options.ui_scaling.text) / 0.25)
		$"Sums/HP Sum".scale_mod = 1 + -floor((1 - options.ui_scaling.text) / 0.25)
		if options.ui_scaling.text > 1:
			$"Sums/Coin Sum".scale_mod -= -floor((1 - options.ui_scaling.text) / 0.25)
			$"Sums/Extra Sum".scale_mod -= -floor((1 - options.ui_scaling.text) / 0.25)
			$"Sums/HP Sum".scale_mod -= -floor((1 - options.ui_scaling.text) / 0.25)
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Sums/Coin Sum".remove_texts()
		$"Sums/Coin Sum".icon_z_index = 4
		$"Sums/Coin Sum".change_font_size(0.09375, false)
		$"Sums/Coin Sum".offset_num = 8
		$"Sums/Extra Sum".remove_texts()
		$"Sums/Extra Sum".icon_z_index = 4
		$"Sums/Extra Sum".change_font_size(0.09375, false)
		$"Sums/Extra Sum".offset_num = 8
		$"Sums/HP Sum".remove_texts()
		$"Sums/HP Sum".icon_z_index = 4
		$"Sums/HP Sum".change_font_size(0.09375, false)
		$"Sums/HP Sum".offset_num = 8
		if int($"/root/Main/Options Sprite/Options".display_font) == 1:
			$"Sums/Coin Sum".rect_position.y -= 9 * $"Options Sprite/Options".ui_scaling.text
			$"Sums/Coin Sum".rect_position.x -= 6
			$"Sums/Extra Sum".rect_position.y -= 9 * $"Options Sprite/Options".ui_scaling.text
			$"Sums/Extra Sum".rect_position.x -= 6
			$"Sums/HP Sum".rect_position.y -= 9 * $"Options Sprite/Options".ui_scaling.text
			$"Sums/HP Sum".rect_position.x -= 6
		elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
			$"Sums/Coin Sum".rect_position.y -= 10 * $"Options Sprite/Options".ui_scaling.text
			$"Sums/Extra Sum".rect_position.y -= 10 * $"Options Sprite/Options".ui_scaling.text
			$"Sums/HP Sum".rect_position.y -= 10 * $"Options Sprite/Options".ui_scaling.text
	options.deck_setting = true
	options.reset_text()
	options.deck_setting = false
	if not need_config and not options.init_scaling_set:
		options.auto_set_scaling()
		options.close()
	var non_controller_hotkeys = ["add_symbol_1", "add_symbol_2", "add_symbol_3", "lock_tooltip", "scroll_up", "scroll_down"]
	for k in options.assignable_hotkeys:
		if options.hotkeys[k][1] == -1 and not non_controller_hotkeys.has(k):
			options.deck_setting = true
			options.reset_to_default("input", true)
			options.close()
			options.deck_setting = false
			break
	load_data(true, false, true)
	if Steam.isSteamRunningOnSteamDeck() and not need_config:
		if not deck_fine:
			options.deck_setting = true
			options.update_setting("resolution", 2)
			options.deck_setting = false
	elif options.resolution_y > OS.get_screen_size(OS.current_screen).y and not need_config:
		options.fullscreen = false
		options.bordered_window = false
		options.update_setting("resolution", 0)
		get_tree().reload_current_scene()
	elif options.fullscreen and OS.get_screen_size(OS.current_screen) != Vector2(options.resolution_x, options.resolution_y) and not need_config:
		options.deck_setting = true
		options.update_setting("fullscreen", true)
		options.deck_setting = false
	if TranslationServer.get_locale() == "ru" and int(options.display_font) == 2:
		options.deck_setting = true
		options.update_setting("font", 0)
		options.deck_setting = false
	for k in options.assignable_hotkeys:
		down_keys[k] = 0
	options.deck_setting = true
	check_controller_type(0, true)
	options.deck_setting = false
	$"Selector Sprite/Selector/N Sprite/N Button".icon_z_index = 25
	$"Selector Sprite/Selector/S Sprite/S Button".icon_z_index = 25
	$"Selector Sprite/Selector/W Sprite/W Button".icon_z_index = 25
	for d in $"Options Sprite/Options".disabled_mods:
		if existing_symbols.has(d) or existing_items.has(d):
			icon_texture_database[d.substr(0, d.find("_STEAM_"))] = load("res://icons/%s.png" % str(d.substr(0, d.find("_STEAM_"))))
	$"HTTPRequest".connect("request_completed", self, "_http_request_completed")
	$"HTTPRequest".request("https://TrampolineTales.com/data.json")

func _http_request_completed(result, response_code, headers, body):
	if response_code == 200 and body != null:
		tt_data = parse_json(body.get_string_from_utf8())
		if tt_data.has("lbal") and tt_data.lbal.has("text") and tt_data.lbal.text != null and tt_data.lbal.text != tr(tt_data.lbal.text):
			tt_data = tt_data.lbal
			if $"Title".visible and not $"Options Sprite/Options".visible:
				$"Title".draw()
		else:
			tt_data = null

func _process(delta):
	Steam.run_callbacks()
	d_time += delta
	mouse_position = get_global_mouse_position()
	while d_time >= 1.0/60.0:
		d_time -= 1.0/60.0
		if reload_scene_timer > 0:
			reload_scene_timer -= 1
			if reload_scene_timer == 0:
				get_tree().reload_current_scene()
			continue
		if press_timer > 0:
			press_timer -= 1
		if $"Options Sprite/Options".are_you_sure_timer > 0:
			$"Options Sprite/Options".are_you_sure_timer -= 1
		if guillotine_essence_anim > 0:
			guillotine_essence_anim -= 1
			for node in get_tree().get_nodes_in_group("Anim Update"):
				node.call("update")
			if guillotine_essence_anim == 599:
				if $"Tooltips".get_children().size() > 0:
					for t in $"Tooltips".get_children():
						t.queue_free()
				if $"Options Sprite/Options".music.goal_volume > -80:
					$"Music Player".fully_fade_out()
			elif guillotine_essence_anim == 330:
				$"Execution Sprite".visible = true
				$"Reels/sfx0".set_stream(preload("res://sfx/guillotine0.wav"))
				$"Reels/sfx0".volume_db = $"Options Sprite/Options".sfx.goal_volume
				if $"Reels/sfx0".volume_db > -80 and not ($"Options Sprite/Options".mute_while_in_background and not window_focus):
					$"Reels/sfx0".play()
			elif guillotine_essence_anim == 0:
				$"Stats Sprite/Stats".add_stat("billionaires_guillotined", $"Pop-up Sprite/Pop-up".current_floor, 1, true)
				$"Stats Sprite/Stats".add_stat("times_executed", $"Pop-up Sprite/Pop-up".current_floor, 1, true)
				var total_executions = $"Stats Sprite/Stats".get_converted_stat("times_executed", "all")
				if total_executions >= 2:
					$"Stats Sprite/Stats".unlock_achievement(178, true)
				if total_executions >= 3:
					$"Stats Sprite/Stats".unlock_achievement(179, true)
				if total_executions >= 4:
					$"Stats Sprite/Stats".unlock_achievement(180, true)
				if total_executions >= 5:
					$"Stats Sprite/Stats".unlock_achievement(181, true)
				if total_executions >= 10:
					$"Stats Sprite/Stats".unlock_achievement(182, true)
				if total_executions >= 25:
					$"Stats Sprite/Stats".unlock_achievement(183, true)
				if total_executions >= 50:
					$"Stats Sprite/Stats".unlock_achievement(184, true)
				if total_executions >= 77:
					$"Stats Sprite/Stats".unlock_achievement(185, true)
				save_stats()
				reset_values()
				title()
				if $"Options Sprite/Options".music.goal_volume > -80:
					$"Music Player".play_rand_music()
					$"Music Player".fade_in()
				$"Stats Sprite/Stats".unlock_achievement(65, true)
			break
		if holding_9:
			ui_reset_timer += 1
		else:
			ui_reset_timer = 0
		if holding_endless:
			endless_toggle_timer += 1
		else:
			endless_toggle_timer = 0
		if holding_screen_reader:
			screen_reader_timer += 1
		else:
			screen_reader_timer = 0
		if holding_d and holding_u and holding_n and holding_y and holding_a:
			dunya_timer += 1
		else:
			dunya_timer = 0
			
		if ui_reset_timer >= 300:
			ui_reset_timer = 0
			$"Options Sprite/Options".deck_setting = true
			$"Options Sprite/Options".reset_to_default("graphics", true)
			$"Options Sprite/Options".close()
			$"Options Sprite/Options".deck_setting = false
		if endless_toggle_timer >= 300 or endless_toggle_counter >= 5:
			endless_toggle_timer = 0
			endless_toggle_counter = 0
			$"Options Sprite/Options".old_endless_mode = !$"Options Sprite/Options".old_endless_mode
			if $"Options Sprite/Options".old_endless_mode:
				display_error("endless", tr("endless") + "=" + tr("old"))
			else:
				display_error("endless", tr("endless") + "=" + tr("new"))
			save_options()
		if screen_reader_timer >= 300:
			screen_reader_timer = 0
			$"Options Sprite/Options".screen_reader = !$"Options Sprite/Options".screen_reader
			if $"Options Sprite/Options".screen_reader:
				display_error("endless", tr("screen_reader"))
			else:
				display_error("endless", tr("screen_reader"))
			save_options()
		if dunya_timer >= 300 and OS.get_date().day == 30 and OS.get_date().month == 1:
			dunya_timer = 0
			display_error("endless", "Shoutout to Dunya. I never met you but you seem like you were a really cool rabbit. Godspeed you funky little bun.")
		if $"Options Sprite/Options".done_assigning_timer < 2:
			$"Options Sprite/Options".done_assigning_timer += 1
			if $"Options Sprite/Options".done_assigning_timer == 2:
				$"Options Sprite/Options".done_assigning = true
		if $"Options Sprite/Options".mute_while_in_background and OS.is_window_focused() != window_focus:
			window_focus = OS.is_window_focused()
			if not window_focus:
				$"Music Player".tween_in.remove_all()
				$"Music Player".tween_out.remove_all()
				$"Music Player".current_music_node.volume_db = -80
				for i in range(8):
					get_node("Reels/sfx" + str(i)).volume_db = -80
				for r in $"Reels".reels:
					for i in r.icons:
						i.sfx_player.volume_db = -80
			else:
				$"Music Player".current_music_node.volume_db = $"Options Sprite/Options".music.goal_volume
				for i in range(8):
					get_node("Reels/sfx" + str(i)).volume_db = $"Options Sprite/Options".sfx.goal_volume
				for r in $"Reels".reels:
					for i in r.icons:
						i.sfx_player.volume_db = $"Options Sprite/Options".sfx.goal_volume
		if updated_setting_timer < 18 + osx_setting_timer_offset:
			if updated_setting_timer == 13:
				if OS.get_name() != "OSX":
					OS.window_borderless = false
				if need_config:
					OS.set_window_size(Vector2($"Options Sprite/Options".resolution_x, $"Options Sprite/Options".resolution_y))
				else:
					if OS.get_name() != "OSX" or (OS.get_name() == "OSX" and $"Options Sprite/Options".changing_osx_fullscreen):
						OS.set_window_fullscreen($"Options Sprite/Options".fullscreen)
						$"Options Sprite/Options".changing_osx_fullscreen = false
					if OS.get_name() != "OSX" or OS.window_borderless != $"Options Sprite/Options".bordered_window:
						OS.window_borderless = $"Options Sprite/Options".bordered_window
					if not OS.window_fullscreen:
						OS.set_window_size(Vector2($"Options Sprite/Options".resolution_x, $"Options Sprite/Options".resolution_y))
						OS.set_window_size(Vector2(OS.window_size.x, OS.window_size.y + 1))
			if updated_setting_timer == 5 + osx_setting_timer_offset and OS.get_name() == "OSX" and not OS.window_fullscreen and not $"Options Sprite/Options".changing_osx_fullscreen:
				OS.set_window_size(Vector2($"Options Sprite/Options".resolution_x, $"Options Sprite/Options".resolution_y))
			if updated_setting_timer == 17 + osx_setting_timer_offset:
				if not OS.window_fullscreen:
					OS.set_window_size(Vector2(OS.window_size.x, OS.window_size.y - 1))
					OS.set_window_position(OS.get_screen_size(OS.current_screen) * 0.5 - OS.get_window_size() * 0.5)
				update_alignments()
				$"Items".update_positions()
			updated_setting_timer += 1
		else:
			for node in get_tree().get_nodes_in_group("Pause Update"):
				node.call("update")
			if not $"Options Sprite/Options".visible and not $"Title".visible:
				for node in get_tree().get_nodes_in_group("Visible Update"):
					if node.visible:
						node.call("update")
				for node in get_tree().get_nodes_in_group("Update"):
					node.call("update")
			if guillotine_essence_anim <= 0:
				if $"Options Sprite/Options".menu_speed + $"Options Sprite/Options".menu_speed_offset >= 1:
					$"Pop-up Sprite/Pop-up".update()
				elif $"Options Sprite/Options".menu_speed == 0.75:
					if frame_timer % 3 != 0:
						$"Pop-up Sprite/Pop-up".update()
				elif $"Options Sprite/Options".menu_speed == 0.5:
					if frame_timer % 2 != 0:
						$"Pop-up Sprite/Pop-up".update()
				else:
					while $"Options Sprite/Options".menu_speed == 0 and ($"Pop-up Sprite/Pop-up".delay_timer > 0 or (not $"Pop-up Sprite/Pop-up".locked_in_position and $"Pop-up Sprite/Pop-up".visible)):
						$"Pop-up Sprite/Pop-up".update()
					$"Pop-up Sprite/Pop-up".update()
			elif $"Options Sprite/Options".menu_speed == 0.75:
				if frame_timer % 3 != 0:
					$"Pop-up Sprite/Pop-up".update()
			elif $"Options Sprite/Options".menu_speed == 0.5:
				if frame_timer % 2 != 0:
					$"Pop-up Sprite/Pop-up".update()
			else:
				while $"Options Sprite/Options".menu_speed == 0 and ($"Pop-up Sprite/Pop-up".delay_timer > 0 or (not $"Pop-up Sprite/Pop-up".locked_in_position and $"Pop-up Sprite/Pop-up".visible)):
					$"Pop-up Sprite/Pop-up".update()
				$"Pop-up Sprite/Pop-up".update()
			if $"Options Sprite/Options".counting_speed + $"Options Sprite/Options".counting_speed_offset >= 1:
				$"Coins".update()
				$"Sums/Coin Sum".update()
				$"Sums/Extra Sum".update()
				$"Sums/HP Sum".update()
			elif $"Options Sprite/Options".counting_speed == 0.75:
				if frame_timer % 3 != 0:
					$"Coins".update()
					$"Sums/Coin Sum".update()
					$"Sums/Extra Sum".update()
					$"Sums/HP Sum".update()
			elif $"Options Sprite/Options".counting_speed == 0.5:
				if frame_timer % 2 != 0:
					$"Coins".update()
					$"Sums/Coin Sum".update()
					$"Sums/Extra Sum".update()
					$"Sums/HP Sum".update()
			else:
				$"Coins".update()
				$"Sums/Coin Sum".update()
				$"Sums/Extra Sum".update()
				$"Sums/HP Sum".update()
		update_alignments()
		for node in get_tree().get_nodes_in_group("Pause Update 2"):
			node.call("update")
		for node in get_tree().get_nodes_in_group("Visible Update 2"):
			if visible:
				node.call("update")
		for e in queued_errors:
			$"Error Sprite/Errors".add_error(e)
		if queued_errors.size() > 0:
			save_errors()
			queued_errors.clear()
		$"Error Sprite/Errors".display()
		$"Options Sprite/Options".can_update_scrollables = true
		frame_timer += 1
		if frame_timer == 60:
			frame_timer = 0
		$"Background".color = $"Options Sprite/Options".colors3["background"]
		$"Title/Background".color = $"Options Sprite/Options".colors3["background"]
		for k in down_keys.keys():
			if down_keys[k] > 0:
				down_keys[k] += 1
		var prev_sn = selected_node
		if (down_keys.up == down_key_delay or (down_keys.up >= 25 and down_keys.up % 5 == 0)) and (down_keys.left == 0 or down_keys.left >= down_key_delay) and (down_keys.right == 0 or down_keys.right >= down_key_delay):
			move_cursor("up")
		if prev_sn == selected_node and (down_keys.down == down_key_delay or (down_keys.down >= 25 and down_keys.down % 5 == 0)) and (down_keys.left == 0 or down_keys.left >= down_key_delay) and (down_keys.right == 0 or down_keys.right >= down_key_delay):
			move_cursor("down")
		if prev_sn == selected_node and (down_keys.left == down_key_delay or (down_keys.left >= 25 and down_keys.left % 5 == 0)) and (down_keys.up == 0 or down_keys.up >= down_key_delay) and (down_keys.down == 0 or down_keys.down >= down_key_delay):
			move_cursor("left")
		if prev_sn == selected_node and (down_keys.right == down_key_delay or (down_keys.right >= 25 and down_keys.right % 5 == 0)) and (down_keys.up == 0 or down_keys.up >= down_key_delay) and (down_keys.down == 0 or down_keys.down >= down_key_delay):
			move_cursor("right")
		if down_keys.confirm_select == down_key_delay:
			hide_selector = false
		if selected_node != null and is_instance_valid(selected_node) and selected_node.get("rect_size") != null and (selected_node.visible or selected_node.off_screen) and selected_node.selectable and not hide_selector:
			if (prev_selector_node != selected_node or (selected_node.selector_alignment != "hyperlink" and prev_selector_node_data.rect_size != selected_node.rect_size) or (selected_node.selector_alignment == "hyperlink" and prev_selector_node_data.rect_size != selected_node.background.rect_size) or prev_selector_node_data.rect_global_position != selected_node.rect_global_position) and cursor_timer == 0:
				cursor_timer = 5
				get_selector_buttons()
			if selected_node.selector_alignment == "hyperlink":
				$"Selector Sprite/Selector".rect_size = Vector2(selected_node.background.rect_size.x + (prev_selector_node_data.rect_size.x - selected_node.background.rect_size.x) * (cursor_timer / 5.0), selected_node.background.rect_size.y * selected_node.get_parent().rect_scale.y + (prev_selector_node_data.rect_size.y - selected_node.background.rect_size.y * selected_node.get_parent().rect_scale.y) * (cursor_timer / 5.0))
			else:
				$"Selector Sprite/Selector".rect_size = Vector2(selected_node.rect_size.x + (prev_selector_node_data.rect_size.x - selected_node.rect_size.x) * (cursor_timer / 5.0), selected_node.rect_size.y + (prev_selector_node_data.rect_size.y - selected_node.rect_size.y) * (cursor_timer / 5.0))
			$"Selector Sprite/Selector".rect_global_position = Vector2(selected_node.rect_global_position.x + (prev_selector_node_data.rect_global_position.x - selected_node.rect_global_position.x) * (cursor_timer / 5.0), selected_node.rect_global_position.y + (prev_selector_node_data.rect_global_position.y - selected_node.rect_global_position.y) * (cursor_timer / 5.0))
			$"Selector Sprite/Selector/NE".position.x = $"Selector Sprite/Selector".rect_size.x
			$"Selector Sprite/Selector/SW".position.y = $"Selector Sprite/Selector".rect_size.y
			$"Selector Sprite/Selector/SE".position.x = $"Selector Sprite/Selector".rect_size.x
			$"Selector Sprite/Selector/SE".position.y = $"Selector Sprite/Selector".rect_size.y
			var mod = 20
			if selected_node.selector_alignment == "hover_icon" or  selected_node.selector_alignment == "tooltip":
				mod = 0
			if $"Selector Sprite/Selector/N Sprite/N Button".texts.size() > 7:
				if $"Selector Sprite/Selector/N Sprite/N Button".texts[8].icons.size() > 0:
					$"Selector Sprite/Selector/N Sprite/N Button".rect_position = Vector2($"Selector Sprite/Selector".rect_size.x / 2 - ($"Selector Sprite/Selector/N Sprite/N Button".texts[8].icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/N Sprite/N Button".texts[8].icons[0].sprite.scale.x) / 2 + 3, -($"Selector Sprite/Selector/N Sprite/N Button".texts[8].icons[0].sprite.texture.get_size().y * $"Selector Sprite/Selector/N Sprite/N Button".texts[8].icons[0].sprite.scale.y) + mod)
				if $"Selector Sprite/Selector/S Sprite/S Button".texts[8].icons.size() > 0:
					$"Selector Sprite/Selector/S Sprite/S Button".rect_position = Vector2($"Selector Sprite/Selector".rect_size.x / 2 - ($"Selector Sprite/Selector/S Sprite/S Button".texts[8].icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/S Sprite/S Button".texts[8].icons[0].sprite.scale.x) / 2 + 3, $"Selector Sprite/Selector".rect_size.y - mod)
				if $"Selector Sprite/Selector/W Sprite/W Button".texts[8].icons.size() > 0:
					$"Selector Sprite/Selector/W Sprite/W Button".rect_position = Vector2(mod + -($"Selector Sprite/Selector/W Sprite/W Button".texts[8].icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/W Sprite/W Button".texts[8].icons[0].sprite.scale.x), $"Selector Sprite/Selector".rect_size.y / 2 - ($"Selector Sprite/Selector/W Sprite/W Button".texts[8].icons[0].sprite.texture.get_size().y * $"Selector Sprite/Selector/W Sprite/W Button".texts[8].icons[0].sprite.scale.y) / 2 + 3)
			else:
				if $"Selector Sprite/Selector/N Sprite/N Button".get_child(0).icons.size() > 0:
					$"Selector Sprite/Selector/N Sprite/N Button".rect_position = Vector2($"Selector Sprite/Selector".rect_size.x / 2 - ($"Selector Sprite/Selector/N Sprite/N Button".get_child(0).icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/N Sprite/N Button".get_child(0).icons[0].sprite.scale.x) / 2, -($"Selector Sprite/Selector/N Sprite/N Button".get_child(0).icons[0].sprite.texture.get_size().y * $"Selector Sprite/Selector/N Sprite/N Button".get_child(0).icons[0].sprite.scale.y) + mod)
				if $"Selector Sprite/Selector/S Sprite/S Button".get_child(0).icons.size() > 0:
					$"Selector Sprite/Selector/S Sprite/S Button".rect_position = Vector2($"Selector Sprite/Selector".rect_size.x / 2 - ($"Selector Sprite/Selector/S Sprite/S Button".get_child(0).icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/S Sprite/S Button".get_child(0).icons[0].sprite.scale.x) / 2, $"Selector Sprite/Selector".rect_size.y - mod)
				if $"Selector Sprite/Selector/W Sprite/W Button".get_child(0).icons.size() > 0:
					$"Selector Sprite/Selector/W Sprite/W Button".rect_position = Vector2(mod + -($"Selector Sprite/Selector/W Sprite/W Button".get_child(0).icons[0].sprite.texture.get_size().x * $"Selector Sprite/Selector/W Sprite/W Button".get_child(0).icons[0].sprite.scale.x), $"Selector Sprite/Selector".rect_size.y / 2 - ($"Selector Sprite/Selector/W Sprite/W Button".get_child(0).icons[0].sprite.texture.get_size().y * $"Selector Sprite/Selector/W Sprite/W Button".get_child(0).icons[0].sprite.scale.y) / 2)
			if not hide_selector:
				$"Selector Sprite/Selector".visible = true
			if cursor_timer > 0:
				cursor_timer -= 1
				if cursor_timer == 0:
					prev_selector_node = selected_node
					if prev_selector_node.selector_alignment == "hyperlink":
						prev_selector_node_data["rect_size"] = prev_selector_node.background.rect_size
					else:
						prev_selector_node_data["rect_size"] = prev_selector_node.rect_size
					prev_selector_node_data["rect_global_position"] = prev_selector_node.rect_global_position
		elif selected_node == null or (is_instance_valid(selected_node) and ((not selected_node.visible and not selected_node.off_screen) or not selected_node.selectable)):
			$"Selector Sprite/Selector".visible = false
		elif selected_node != null and not is_instance_valid(selected_node):
			selected_node = null
		for k in down_keys_to_clear:
			down_keys[k] = 0
		down_keys_to_clear.clear()
		var n = 0
		var null_nums = []
		for k in displayed_hotkey_sources:
			if k == null or not is_instance_valid(k) or not k.is_inside_tree() or k.is_queued_for_deletion():
				null_nums.push_back(n)
			if $"/root/Main/Tooltips".get_children().size() > 0 or k == null or not is_instance_valid(k) or not k.selectable or not k.active or not k.visible or not $"Selector Sprite/Selector".visible or not last_input_was_controller:
				$"Hotkeys".get_child(n).visible = false
			else:
				$"Hotkeys".get_child(n).visible = true
				if $"Hotkeys".get_child(n).texts.size() > 7:
					if k == $"Options Sprite/Options".back_button:
						$"Hotkeys".get_child(n).rect_global_position = Vector2(k.rect_global_position.x + k.rect_size.x + 8 - ($"Hotkeys".get_child(n).texts[8].icons[0].sprite.texture.get_size().x * $"Hotkeys".get_child(n).texts[8].icons[0].sprite.scale.x), k.rect_global_position.y - ($"Hotkeys".get_child(n).texts[8].icons[0].sprite.texture.get_size().y * $"Hotkeys".get_child(n).texts[8].icons[0].sprite.scale.y) + k.rect_size.y + 26)
					else:
						$"Hotkeys".get_child(n).rect_global_position = Vector2(k.rect_global_position.x + k.rect_size.x + 8 - ($"Hotkeys".get_child(n).texts[8].icons[0].sprite.texture.get_size().x * $"Hotkeys".get_child(n).texts[8].icons[0].sprite.scale.x), k.rect_global_position.y - ($"Hotkeys".get_child(n).texts[8].icons[0].sprite.texture.get_size().y * $"Hotkeys".get_child(n).texts[8].icons[0].sprite.scale.y) + 18)
				else:
					if k == $"Options Sprite/Options".back_button:
						$"Hotkeys".get_child(n).rect_global_position = Vector2(k.rect_global_position.x + k.rect_size.x - ($"Hotkeys".get_child(n).get_child(0).icons[0].sprite.texture.get_size().x * $"Hotkeys".get_child(n).get_child(0).icons[0].sprite.scale.x), k.rect_global_position.y - ($"Hotkeys".get_child(n).get_child(0).icons[0].sprite.texture.get_size().y * $"Hotkeys".get_child(n).get_child(0).icons[0].sprite.scale.y) + k.rect_size.y + 26)
					else:
						$"Hotkeys".get_child(n).rect_global_position = Vector2(k.rect_global_position.x + k.rect_size.x - ($"Hotkeys".get_child(n).get_child(0).icons[0].sprite.texture.get_size().x * $"Hotkeys".get_child(n).get_child(0).icons[0].sprite.scale.x), k.rect_global_position.y - ($"Hotkeys".get_child(n).get_child(0).icons[0].sprite.texture.get_size().y * $"Hotkeys".get_child(n).get_child(0).icons[0].sprite.scale.y) + 18)
			n += 1
		for i in range(null_nums.size()):
			$"Hotkeys".remove_child($"Hotkeys".get_child(null_nums[i] - i))
			displayed_hotkey_sources.remove(null_nums[i] - i)
		null_nums.clear()
		if not reloading_scene and frame_timer == 59:
			Utils.free_orphaned_nodes()

func check_controller_type(device_id, connected):
	controller_type = "generic"
	if connected:
		var controller_name = str(Input.get_joy_name(0)).to_lower()
		if controller_name.find("xbox") != -1 or controller_name.find("xinput") != -1:
			controller_type = "xbox"
		elif controller_name.find("sony") != -1 or controller_name.find("playstation") != -1 or controller_name.find("dualshock") != -1 or controller_name.find("ps1") != -1 or controller_name.find("ps2") != -1 or controller_name.find("ps3") != -1 or controller_name.find("ps4") != -1 or controller_name.find("ps5") != -1:
			controller_type = "playstation"
		elif controller_name.find("nintendo") != -1 or controller_name.find("switch") != -1 or controller_name.find("wii u") != -1:
			controller_type = "switch"
	if controller_type != "generic" or (controller_type == "generic" and Steam.isSteamRunningOnSteamDeck()):
		if connected:
			controllers += 1
		else:
			controllers -= 1
	var tmp_strings = hotkey_button_strings.duplicate(true)
	hotkey_button_strings.clear()
	for h in tmp_strings:
		if h != null and is_instance_valid(h):
			h.update()
			if h.get_parent() is TextureButton:
				h.get_parent().correct_size()

func update_alignments():
	for node in get_tree().get_nodes_in_group("Aligned"):
		if not node.aligned:
			node.aligned = true
			if node.alignment_tags.has("dont"):
				continue
			if node is TextureButton and node.down:
				node.rect_position.x = node.base_x
			if node.alignment_tags.centered:
				if node.get("rect_size") != null:
					node.rect_position.x += ($"Options Sprite/Options".resolution_x - node.saved_resolution.x) / 2
				else:
					node.position.x += ($"Options Sprite/Options".resolution_x - node.saved_resolution.x) / 2
			elif node.alignment_tags.right:
				node.rect_position.x += $"Options Sprite/Options".resolution_x - node.saved_resolution.x
			if node.alignment_tags.v_centered:
				if node.get("rect_size") != null:
					node.rect_position.y += ($"Options Sprite/Options".resolution_y - node.saved_resolution.y) / 2
				else:
					node.position.y += ($"Options Sprite/Options".resolution_y - node.saved_resolution.y) / 2
			elif node.alignment_tags.bottom:
				node.rect_position.y += $"Options Sprite/Options".resolution_y - node.saved_resolution.y
			if node is TextureButton:
				node.base_x = node.rect_position.x
			node.saved_resolution = Vector2($"Options Sprite/Options".resolution_x, $"Options Sprite/Options".resolution_y)

func get_replacement_texture(type):
	if art_replacement_nums.has(type):
		var textures = []
		for i in art_replacement_nums[type]:
			if not is_mod_disabled(type + i) and type.find(i) == -1:
				textures.push_back(icon_texture_database[type + i])
		if textures.size() > 0:
			return textures[floor(rand_range(0, textures.size()))]
	if mod_pack_nums.has(type):
		return icon_texture_database[type + "_PACK_" + mod_pack_nums[type]]
	else:
		return icon_texture_database[type]

func get_empty_data():
	var z = load("res://Slot Icon.tscn").instance()
	z.type = "empty"
	z.in_reels = false
	add_child(z)
	z.soft_changing = true
	z.change_type("empty", false)
	z.add_init_permanent_bonuses()
	
	var z_str = "empty" + z.get_child(1).raw_string + z.get_child(3).raw_string + z.get_child(2).raw_string
	
	remove_child(z)
	z.queue_free()
	return z_str

func move_cursor(direction):
	if selected_node != null and not $"Selector Sprite/Selector".visible:
		$"Selector Sprite/Selector".visible = true
		hide_selector = false
		get_selector_buttons()
		return
	elif selected_node != null and is_instance_valid(selected_node) and selected_node.cant_go_dirs.has(direction):
		return
	var selectable_nodes = []
	for s in get_tree().get_nodes_in_group("Selectable"):
		if (s.visible or s.off_screen) and s.active and s.selectable:
			if s.selector_alignment == "dont":
				pass
			elif selected_node != null and is_instance_valid(selected_node) and ($"Options Sprite/Options".option_buttons.has(selected_node) or ($"Options Sprite/Options".back_button == s and $"Options Sprite/Options".back_button != selected_node) or ($"Options Sprite/Options".menu_buttons.has(s) and not $"Options Sprite/Options".menu_buttons.has(selected_node))) and (($"Options Sprite/Options".option_buttons.find(selected_node) > 0 and $"Options Sprite/Options".hyperlinks.find(selected_node) > 0) or selected_node.selector_alignment == "godot") and not $"Options Sprite/Options".option_buttons.has(s) and not $"Options Sprite/Options".option_sliders.has(s) and not $"Options Sprite/Options".hyperlinks.has(s):
				pass
			elif selected_node != null and is_instance_valid(selected_node) and selected_node.selector_alignment == "hover_icon" and s.selector_alignment == "above_icons" and $"Pop-up Sprite/Pop-up".icon_arr.size() > 0 and $"Pop-up Sprite/Pop-up".icon_arr.has(selected_node) and $"Pop-up Sprite/Pop-up".icon_arr[0].rect_global_position.y != selected_node.rect_global_position.y:
				pass
			elif selected_node != null and is_instance_valid(selected_node) and selected_node is Control and selected_node.selector_alignment == "card" and s.selector_alignment != "card" and (direction == "left" or direction == "right"):
				pass
			else:
				selectable_nodes.push_back(s)
	var closest_node
	var backup_node
	
	if selected_node != null and is_instance_valid(selected_node) and selected_node.selector_alignment != "hover_icon":
		if $"Tooltips".get_children().size() > 0:
			for t in $"Tooltips".get_children():
				t.queue_free()
	if selectable_nodes.size() > 0:
		if selected_node == null or not is_instance_valid(selected_node):
			get_init_selectable_node()
		else:
			var s_mod = 2
			var selected_node_mod = 2
			var t_mod = 1
			var can_break = false
			
			if selected_node != null and is_instance_valid(selected_node):
				selectable_nodes.erase(selected_node)
				match selected_node.selector_alignment:
					"left":
						selected_node_mod = selected_node.rect_size.x
					"centered":
						selected_node_mod = 2
					"right":
						selected_node_mod = 1
			match direction:
				"up":
					if not selected_node.cant_go_dirs.has("up"):
						if selected_node is Sprite and selected_node.is_icon:
							if down_keys["left"] >= down_key_delay:
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									for y in range(selected_node.grid_position.y - 1, -1, -1):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["right"] >= down_key_delay:
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									for y in range(selected_node.grid_position.y - 1, -1, -1):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["up"] >= down_key_delay:
								for y in range(selected_node.grid_position.y - 1, -1, -1):
									if $"Reels".displayed_icons[y][selected_node.grid_position.x].type != "empty" and $"Reels".displayed_icons[y][selected_node.grid_position.x].selectable:
										closest_node = $"Reels".displayed_icons[y][selected_node.grid_position.x]
										can_break = true
										break
							if closest_node == null:
								can_break = false
								for x in range($"Reels".reel_width):
									for y in range(selected_node.grid_position.y - 1, -1, -1):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].grid_position.y < selected_node.grid_position.y and $"Reels".displayed_icons[y][x].grid_position.x == selected_node.grid_position.x:
											can_break = true
											break
									if can_break:
										break
								if not can_break:
									for i in $"Items".items:
										if i.global_position.y + i.texture.get_size().y * i.scale.y < $"Reels/Reel Border".get_child(0).rect_global_position.y and (closest_node == null or ((i.global_position.y >= closest_node.global_position.y and abs((i.global_position.x + i.texture.get_size().x * i.scale.x / 2) - (selected_node.global_position.x + selected_node.get_child(5).texture.get_size().x / 2)) < abs((closest_node.global_position.x + closest_node.texture.get_size().x / 2) - (selected_node.global_position.x + selected_node.get_child(5).texture.get_size().x / 2))) or i.global_position.y > closest_node.global_position.y)) and i.selectable and i.visible:
											closest_node = i
						elif selected_node is Sprite and not selected_node.is_icon:
							if down_keys["up"] >= down_key_delay or down_keys["left"] >= down_key_delay or down_keys["right"] >= down_key_delay:
								for i in $"Items".items:
									if i.global_position.x == selected_node.global_position.x and i.global_position.y < selected_node.global_position.y and (closest_node == null or (i.global_position.y > closest_node.global_position.y)) and abs(i.global_position.y - selected_node.global_position.y) < i.texture.get_size().y * i.scale.y * 1.5 and i.selectable and i.visible:
										closest_node = i
							if closest_node == null:
								for x in range($"Reels".reel_width):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].global_position.y < selected_node.global_position.y and (closest_node == null or abs($"Reels".displayed_icons[y][x].global_position.x - selected_node.global_position.x) + abs($"Reels".displayed_icons[y][x].global_position.y - selected_node.global_position.y) <= abs(closest_node.global_position.x - selected_node.global_position.x) + abs(closest_node.global_position.y - selected_node.global_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
						else:
							for s in selectable_nodes:
								match s.selector_alignment:
									"left":
										s_mod = s.rect_size.x
									"centered":
										s_mod = 2
									"right":
										s_mod = 1
									"slider", "hyperlink":
										t_mod = 10
								if (selected_node.selector_alignment != "hover_icon" and s.selector_alignment != "hover_icon") or ((selected_node.selector_alignment == "hover_icon" and s.selector_alignment == "hover_icon" and selected_node.get_parent().get_parent() == s.get_parent().get_parent()) or (str(s.get_path()).find("Pop-up Sprite/Pop-up") != -1 and str(s.get_path()).find("Background/Description") == -1 and str(s.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Pop-up Sprite/Pop-up") != -1)):
									if (s.rect_global_position.y < selected_node.rect_global_position.y and ((closest_node == null or s.rect_global_position.y > closest_node.rect_global_position.y or (s.rect_global_position.y == closest_node.rect_global_position.y and selected_node != null and s.rect_global_position.x == selected_node.rect_global_position.x and selected_node is TextureButton and selected_node.hotkey)) and abs((s.rect_global_position.x + s.rect_size.x / s_mod) - (selected_node.rect_global_position.x + selected_node.rect_size.x / selected_node_mod)) * t_mod <= selected_node.rect_size.x)) and s.selectable:
										closest_node = s
									elif (backup_node == null or (s.rect_global_position.y > backup_node.rect_global_position.y)) and abs((s.rect_global_position.y + s.rect_size.y / s_mod) - (selected_node.rect_global_position.y + selected_node.rect_size.y / selected_node_mod)) > 10 and s.rect_global_position.y < selected_node.rect_global_position.y and s.selectable:
										backup_node = s
				"down":
					if not selected_node.cant_go_dirs.has("down"):
						if selected_node is Sprite and selected_node.is_icon:
							if down_keys["left"] >= down_key_delay:
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["right"] >= down_key_delay:
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["down"] >= down_key_delay:
								for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
									if $"Reels".displayed_icons[y][selected_node.grid_position.x].type != "empty" and $"Reels".displayed_icons[y][selected_node.grid_position.x].selectable:
										closest_node = $"Reels".displayed_icons[y][selected_node.grid_position.x]
										can_break = true
										break
							if closest_node == null:
								can_break = false
								for x in range($"Reels".reel_width):
									for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].grid_position.y > selected_node.grid_position.y  and $"Reels".displayed_icons[y][x].grid_position.x == selected_node.grid_position.x:
											can_break = true
											break
									if can_break:
										break
								if not can_break:
									for i in $"Items".items:
										if i.global_position.y > $"Reels/Reel Border".get_child(0).rect_global_position.y + $"Reels/Reel Border".get_child(0).rect_size.y and (closest_node == null or ((i.global_position.y <= closest_node.global_position.y and abs((i.global_position.x + i.texture.get_size().x * i.scale.x / 2) - (selected_node.global_position.x + selected_node.get_child(5).texture.get_size().x / 2)) < abs((closest_node.global_position.x + closest_node.texture.get_size().x / 2) - (selected_node.global_position.x + selected_node.get_child(5).texture.get_size().x / 2))) or i.global_position.y < closest_node.global_position.y)) and i.selectable and i.visible:
											closest_node = i
							if closest_node == null:
								if $"Pop-up Sprite/Pop-up".emails.size() == 0:
									selected_node = $"Menus".buttons_menu.spin_button
								elif $"Pop-up Sprite/Pop-up".emails[0].prompt:
									var icons
									if $"Options Sprite/Options".CJK_lang:
										icons = $"Pop-up Sprite/Pop-up".label_text.icons
									else:
										icons = $"Pop-up Sprite/Pop-up".label_text.texts[8].icons
									var new_node = false
									for i in icons:
										if i.selectable:
											selected_node = i
											new_node = true
											break
									if not new_node and $"Pop-up Sprite/Pop-up".buttons.size() > 0:
										selected_node = $"Pop-up Sprite/Pop-up".buttons[0]
						elif selected_node is Sprite and not selected_node.is_icon:
							if down_keys["down"] >= down_key_delay or down_keys["left"] >= down_key_delay or down_keys["right"] >= down_key_delay:
								for i in $"Items".items:
									if i.global_position.x == selected_node.global_position.x and i.global_position.y > selected_node.global_position.y and (closest_node == null or (i.global_position.y < closest_node.global_position.y)) and abs(i.global_position.y - selected_node.global_position.y) < i.texture.get_size().y * i.scale.y * 1.5 and i.selectable and i.visible:
										closest_node = i
							if closest_node == null:
								for x in range($"Reels".reel_width):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].global_position.y > selected_node.global_position.y and (closest_node == null or abs($"Reels".displayed_icons[y][x].global_position.x - selected_node.global_position.x) + abs($"Reels".displayed_icons[y][x].global_position.y - selected_node.global_position.y) <= abs(closest_node.global_position.x - selected_node.global_position.x) + abs(closest_node.global_position.y - selected_node.global_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
						else:
							for s in selectable_nodes:
								match s.selector_alignment:
									"left":
										s_mod = s.rect_size.x
									"centered":
										s_mod = 2
									"right":
										s_mod = 1
									"slider", "hyperlink":
										t_mod = 0
								if (selected_node.selector_alignment != "hover_icon" and s.selector_alignment != "hover_icon") or ((selected_node.selector_alignment == "hover_icon" and s.selector_alignment == "hover_icon" and selected_node.get_parent().get_parent() == s.get_parent().get_parent()) or (str(s.get_path()).find("Pop-up Sprite/Pop-up") != -1 and str(s.get_path()).find("Background/Description") == -1 and str(s.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Pop-up Sprite/Pop-up") != -1)):
									if (s.rect_global_position.y > selected_node.rect_global_position.y and ((closest_node == null or s.rect_global_position.y < closest_node.rect_global_position.y or (s.rect_global_position.y == closest_node.rect_global_position.y and selected_node != null and s.rect_global_position.x == selected_node.rect_global_position.x and selected_node is TextureButton)) and abs((s.rect_global_position.x + s.rect_size.x / s_mod) - (selected_node.rect_global_position.x + selected_node.rect_size.x / selected_node_mod)) * t_mod <= selected_node.rect_size.x)) and s.selectable:
										closest_node = s
									elif (backup_node == null or (s.rect_global_position.y < backup_node.rect_global_position.y)) and abs((s.rect_global_position.y + s.rect_size.y / s_mod) - (selected_node.rect_global_position.y + selected_node.rect_size.y / selected_node_mod)) > 10 and s.rect_global_position.y > selected_node.rect_global_position.y and s.selectable:
										backup_node = s
				"left":
					if not selected_node.cant_go_dirs.has("left"):
						if selected_node is Sprite and selected_node.is_icon:
							if down_keys["up"] >= down_key_delay:
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									for y in range(selected_node.grid_position.y - 1, -1, -1):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["down"] >= down_key_delay:
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["left"] >= down_key_delay:
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									if $"Reels".displayed_icons[selected_node.grid_position.y][x].type != "empty" and $"Reels".displayed_icons[selected_node.grid_position.y][x].selectable:
										closest_node = $"Reels".displayed_icons[selected_node.grid_position.y][x]
										can_break = true
										break
							if closest_node == null:
								can_break = false
								for x in range(selected_node.grid_position.x - 1, -1, -1):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].grid_position.x < selected_node.grid_position.x and $"Reels".displayed_icons[y][x].grid_position.y == selected_node.grid_position.y:
											can_break = true
											break
									if can_break:
										break
								if not can_break:
									for i in $"Items".items:
										if i.global_position.x + i.texture.get_size().x * i.scale.x < $"Reels/Reel Border".get_child(0).rect_global_position.x and (closest_node == null or ((i.global_position.x >= closest_node.global_position.x and abs((i.global_position.y + i.texture.get_size().y * i.scale.y / 2) - (selected_node.global_position.y + selected_node.get_child(5).texture.get_size().y / 2)) <= abs((closest_node.global_position.y + closest_node.texture.get_size().y / 2) - (selected_node.global_position.y + selected_node.get_child(5).texture.get_size().y / 2))) or i.global_position.x > closest_node.global_position.x)) and i.selectable and i.visible:
											closest_node = i
						elif selected_node is Sprite and not selected_node.is_icon:
							if down_keys["left"] >= down_key_delay or down_keys["up"] >= down_key_delay or down_keys["down"] >= down_key_delay:
								for i in $"Items".items:
									if i.global_position.y == selected_node.global_position.y and i.global_position.x < selected_node.global_position.x and (closest_node == null or (i.global_position.x > closest_node.global_position.x)) and abs(i.global_position.x - selected_node.global_position.x) < i.texture.get_size().x * i.scale.x * 1.5 and i.selectable and i.visible:
										closest_node = i
							if closest_node == null:
								for x in range($"Reels".reel_width):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].global_position.x < selected_node.global_position.x and (closest_node == null or abs($"Reels".displayed_icons[y][x].global_position.x - selected_node.global_position.x) + abs($"Reels".displayed_icons[y][x].global_position.y - selected_node.global_position.y) <= abs(closest_node.global_position.x - selected_node.global_position.x) + abs(closest_node.global_position.y - selected_node.global_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
						else:
							for s in selectable_nodes:
								match s.selector_alignment:
									"left":
										s_mod = s.rect_size.y
									"centered":
										s_mod = 2
									"right":
										s_mod = 1
								if (selected_node.selector_alignment != "hover_icon" and s.selector_alignment != "hover_icon") or ((selected_node.selector_alignment == "hover_icon" and s.selector_alignment == "hover_icon" and selected_node.get_parent().get_parent() == s.get_parent().get_parent()) or (str(s.get_path()).find("Pop-up Sprite/Pop-up") != -1 and str(s.get_path()).find("Background/Description") == -1 and str(s.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Pop-up Sprite/Pop-up") != -1)):
									if (s.rect_global_position.x < selected_node.rect_global_position.x and ((closest_node == null or s.rect_global_position.x > closest_node.rect_global_position.x or (s.rect_global_position.x == closest_node.rect_global_position.x and selected_node != null and s.rect_global_position.y == selected_node.rect_global_position.y and selected_node is TextureButton and selected_node.hotkey)) and abs((s.rect_global_position.y + s.rect_size.y / s_mod) - (selected_node.rect_global_position.y + selected_node.rect_size.y / selected_node_mod)) * t_mod <= selected_node.rect_size.y)) and s.selectable:
										closest_node = s
									elif (backup_node == null or (s.rect_global_position.x > backup_node.rect_global_position.x)) and abs((s.rect_global_position.x + s.rect_size.x / s_mod) - (selected_node.rect_global_position.x + selected_node.rect_size.x / selected_node_mod)) > 10 and s.rect_global_position.x < selected_node.rect_global_position.x and s.selectable:
										backup_node = s
				"right":
					if not selected_node.cant_go_dirs.has("right"):
						if selected_node is Sprite and selected_node.is_icon:
							if down_keys["up"] >= down_key_delay:
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									for y in range(selected_node.grid_position.y - 1, -1, -1):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["down"] >= down_key_delay:
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									for y in range(selected_node.grid_position.y + 1, $"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and (closest_node == null or abs($"Reels".displayed_icons[y][x].grid_position.x - selected_node.grid_position.x) + abs($"Reels".displayed_icons[y][x].grid_position.y - selected_node.grid_position.y) < abs(closest_node.grid_position.x - selected_node.grid_position.x) + abs(closest_node.grid_position.y - selected_node.grid_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
							elif down_keys["right"] >= down_key_delay:
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									if $"Reels".displayed_icons[selected_node.grid_position.y][x].type != "empty" and $"Reels".displayed_icons[selected_node.grid_position.y][x].selectable:
										closest_node = $"Reels".displayed_icons[selected_node.grid_position.y][x]
										can_break = true
										break
							if closest_node == null:
								can_break = false
								for x in range(selected_node.grid_position.x + 1, $"Reels".reel_width):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].grid_position.x > selected_node.grid_position.x and $"Reels".displayed_icons[y][x].grid_position.y == selected_node.grid_position.y:
											can_break = true
											break
									if can_break:
										break
								if not can_break:
									for i in $"Items".items:
										if i.global_position.x > $"Reels/Reel Border5".get_child(0).rect_global_position.x + $"Reels/Reel Border5".get_child(0).rect_size.x and (closest_node == null or ((i.global_position.x <= closest_node.global_position.x and abs((i.global_position.y + i.texture.get_size().y * i.scale.y / 2) - (selected_node.global_position.y + selected_node.get_child(5).texture.get_size().y / 2)) < abs((closest_node.global_position.y + closest_node.texture.get_size().y / 2) - (selected_node.global_position.y + selected_node.get_child(5).texture.get_size().y / 2))) or i.global_position.x < closest_node.global_position.x)) and i.selectable and i.visible:
											closest_node = i
						elif selected_node is Sprite and not selected_node.is_icon:
							if down_keys["right"] >= down_key_delay or down_keys["up"] >= down_key_delay or down_keys["down"] >= down_key_delay:
								for i in $"Items".items:
									if i.global_position.y == selected_node.global_position.y and i.global_position.x > selected_node.global_position.x and (closest_node == null or (i.global_position.x < closest_node.global_position.x)) and abs(i.global_position.x - selected_node.global_position.x) < i.texture.get_size().x * i.scale.x * 1.5 and i.selectable and i.visible:
										closest_node = i
							if closest_node == null:
								for x in range($"Reels".reel_width):
									for y in range($"Reels".reel_height):
										if $"Reels".displayed_icons[y][x].type != "empty" and $"Reels".displayed_icons[y][x].global_position.x > selected_node.global_position.x and (closest_node == null or abs($"Reels".displayed_icons[y][x].global_position.x - selected_node.global_position.x) + abs($"Reels".displayed_icons[y][x].global_position.y - selected_node.global_position.y) <= abs(closest_node.global_position.x - selected_node.global_position.x) + abs(closest_node.global_position.y - selected_node.global_position.y)) and $"Reels".displayed_icons[y][x].selectable:
											closest_node = $"Reels".displayed_icons[y][x]
						else:
							for s in selectable_nodes:
								match s.selector_alignment:
									"left":
										s_mod = s.rect_size.y
									"centered":
										s_mod = 2
									"right":
										s_mod = 1
								if (selected_node.selector_alignment != "hover_icon" and s.selector_alignment != "hover_icon") or ((selected_node.selector_alignment == "hover_icon" and s.selector_alignment == "hover_icon" and selected_node.get_parent().get_parent() == s.get_parent().get_parent()) or (str(s.get_path()).find("Pop-up Sprite/Pop-up") != -1 and str(s.get_path()).find("Background/Description") == -1 and str(s.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Card") == -1 and str(selected_node.get_path()).find("Pop-up Sprite/Pop-up") != -1)):
									if (s.rect_global_position.x > selected_node.rect_global_position.x and ((closest_node == null or s.rect_global_position.x < closest_node.rect_global_position.x or (s.rect_global_position.x == closest_node.rect_global_position.x and selected_node != null and s.rect_global_position.y == selected_node.rect_global_position.y and selected_node is TextureButton and selected_node.hotkey)) and abs((s.rect_global_position.y + s.rect_size.y / s_mod) - (selected_node.rect_global_position.y + selected_node.rect_size.y / selected_node_mod)) * t_mod <= selected_node.rect_size.y)) and s.selectable:
										closest_node = s
									elif (backup_node == null or (s.rect_global_position.x < backup_node.rect_global_position.x)) and abs((s.rect_global_position.x + s.rect_size.x / s_mod) - (selected_node.rect_global_position.x + selected_node.rect_size.x / selected_node_mod)) > 10 and s.rect_global_position.x > selected_node.rect_global_position.x and s.selectable:
										backup_node = s
		if closest_node != null:
			selected_node = closest_node
		elif backup_node != null:
			selected_node = backup_node
	match direction:
		"up":
			for s in get_tree().get_nodes_in_group("Selector Override Up"):
				selected_node = s
				s.remove_from_group("Selector Override Up")
	if selected_node != null:
		$"Selector Sprite/Selector".visible = true
		hide_selector = false

func change_current_menu_path(path):
	selected_node = null
	current_menu_path = path
	down_scancodes.clear()
	if not $"Options Sprite/Options".screen_reader:
		get_init_selectable_node()

func get_selector_buttons():
	selector_buttons.clear()
	if selected_node is TextureButton or (selected_node != null and selected_node.selector_alignment == "hyperlink"):
		selector_buttons = [$"Options Sprite/Options".hotkeys["confirm_select"][1]]
	elif selected_node is Sprite and selected_node.is_icon:
		selector_buttons = [$"Options Sprite/Options".hotkeys["inspect"][1]]
		if $"Pop-up Sprite/Pop-up".emails.size() > 0 and ($"Pop-up Sprite/Pop-up".emails[0].type == "oil_can_prompt" or $"Pop-up Sprite/Pop-up".emails[0].type == "oil_can_essence_prompt" or $"Pop-up Sprite/Pop-up".emails[0].type == "swap_prompt_1"):
			selector_buttons.push_back($"Options Sprite/Options".hotkeys["confirm_select"][1])
	elif selected_node is Sprite and not selected_node.is_icon:
		selector_buttons = [$"Options Sprite/Options".hotkeys["inspect"][1], $"Options Sprite/Options".hotkeys["enable_disable_item"][1]]
		if selected_node.destroyable and not selected_node.disabled:
			selector_buttons.push_back($"Options Sprite/Options".hotkeys["confirm_select"][1])
	elif selected_node != null and selected_node.selector_alignment == "hover_icon":
		selector_buttons = [$"Options Sprite/Options".hotkeys["inspect"][1]]
		if str(selected_node.get_path()).find("Background/Description") != -1 or str(selected_node.get_path()).find("Tooltips") != -1:
			selector_buttons.push_back($"Options Sprite/Options".hotkeys["deny_cancel"][1])
		if $"Pop-up Sprite/Pop-up".emails.size() > 0 and (($"Pop-up Sprite/Pop-up".emails[0].type == "chili_powder_essence_prompt" or $"Pop-up Sprite/Pop-up".emails[0].type == "add_tile_prompt") or ($"Pop-up Sprite/Pop-up".emails[0].type == "removal_token_prompt" and not selected_node.item)):
			selector_buttons.push_back($"Options Sprite/Options".hotkeys["confirm_select"][1])
	elif selected_node != null and selected_node.selector_alignment == "card":
		selector_buttons = [$"Options Sprite/Options".hotkeys["confirm_select"][1], $"Options Sprite/Options".hotkeys["inspect"][1]]
	elif selected_node != null and selected_node.selector_alignment == "tooltip":
		selector_buttons = [$"Options Sprite/Options".hotkeys["inspect"][1], $"Options Sprite/Options".hotkeys["deny_cancel"][1]]
	if selector_buttons.size() > 0 and last_input_was_controller:
		$"Selector Sprite/Selector/N Sprite/N Button".raw_string = "<button_" + str(selector_buttons[0]) + ">"
		$"Selector Sprite/Selector/N Sprite/N Button".force_update = true
		if $"Selector Sprite/Selector/N Sprite/N Button".texts.size() > 7:
			$"Selector Sprite/Selector/N Sprite/N Button".texts[8].icon_z_index = 25
		else:
			$"Selector Sprite/Selector/N Sprite/N Button".scale_mod = -1
		$"Selector Sprite/Selector/N Sprite/N Button".update()
	else:
		$"Selector Sprite/Selector/N Sprite/N Button".raw_string = ""
		$"Selector Sprite/Selector/N Sprite/N Button".force_update = true
		$"Selector Sprite/Selector/N Sprite/N Button".update()
	if selector_buttons.size() > 1 and last_input_was_controller:
		$"Selector Sprite/Selector/S Sprite/S Button".raw_string = "<button_" + str(selector_buttons[1]) + ">"
		$"Selector Sprite/Selector/S Sprite/S Button".force_update = true
		if $"Selector Sprite/Selector/S Sprite/S Button".texts.size() > 7:
			$"Selector Sprite/Selector/S Sprite/S Button".texts[8].icon_z_index = 25
		else:
			$"Selector Sprite/Selector/S Sprite/S Button".scale_mod = -1
		$"Selector Sprite/Selector/S Sprite/S Button".update()
	else:
		$"Selector Sprite/Selector/S Sprite/S Button".raw_string = ""
		$"Selector Sprite/Selector/S Sprite/S Button".force_update = true
		$"Selector Sprite/Selector/S Sprite/S Button".update()
	if selector_buttons.size() > 2 and last_input_was_controller:
		$"Selector Sprite/Selector/W Sprite/W Button".raw_string = "<button_" + str(selector_buttons[2]) + ">"
		$"Selector Sprite/Selector/W Sprite/W Button".force_update = true
		if $"Selector Sprite/Selector/W Sprite/W Button".texts.size() > 7:
			$"Selector Sprite/Selector/W Sprite/W Button".texts[8].icon_z_index = 25
		else:
			$"Selector Sprite/Selector/W Sprite/W Button".scale_mod = -1
		$"Selector Sprite/Selector/W Sprite/W Button".update()
	else:
		$"Selector Sprite/Selector/W Sprite/W Button".raw_string = ""
		$"Selector Sprite/Selector/W Sprite/W Button".force_update = true
		$"Selector Sprite/Selector/W Sprite/W Button".update()

func get_init_selectable_node():
	match current_menu_path:
		"init":
			selected_node = $"Options Sprite/Options".dropdown_buttons[0]
		"/root/Main/Title", "floor_menu":
			if $"Title".buttons.size() > 0:
				selected_node = $"Title".buttons[0]
		"/root/Main/Options Sprite/Options/graphics":
			selected_node = $"Options Sprite/Options".starter_button
		"/root/Main/Options Sprite/Options/audio":
			selected_node = $"Options Sprite/Options".menu_buttons[1]
		"/root/Main/Options Sprite/Options/gameplay":
			selected_node = $"Options Sprite/Options".menu_buttons[2]
		"/root/Main/Options Sprite/Options/input":
			selected_node = $"Options Sprite/Options".menu_buttons[3]
		"/root/Main/Options Sprite/Options/credits":
			selected_node = $"Options Sprite/Options".menu_buttons[4]
		"/root/Main/Options Sprite/Options/mods", "/root/Main/Options Sprite/Options/legal", "/root/Main/Options Sprite/Options/achievements":
			selected_node = $"Options Sprite/Options".back_button
		"stats_menu":
			selected_node = $"Title".floor_buttons[0]
		"email":
			if $"Pop-up Sprite/Pop-up".cards.size() > 0:
				selected_node = $"Pop-up Sprite/Pop-up".cards[ceil($"Pop-up Sprite/Pop-up".cards.size() / 2.0 - 1)]
			elif $"Pop-up Sprite/Pop-up".buttons.size() > 0:
				selected_node = $"Pop-up Sprite/Pop-up".buttons[$"Pop-up Sprite/Pop-up".buttons.size() - 1]
		"inventory":
			selected_node = $"Pop-up Sprite/Pop-up".deck_button
		"slots":
			selected_node = $"Menus".buttons_menu.spin_button
		"dropdown":
			selected_node = $"Options Sprite/Options".dropdown_buttons[0]
		"colors":
			selected_node = $"Options Sprite/Options".option_sliders[0]
	if selected_node != null:
		prev_selector_node = selected_node
		if prev_selector_node.selector_alignment == "hyperlink":
			prev_selector_node_data["rect_size"] = prev_selector_node.background.rect_size
		else:
			prev_selector_node_data["rect_size"] = prev_selector_node.rect_size
		prev_selector_node_data["rect_global_position"] = prev_selector_node.rect_global_position
	if not hide_selector:
		$"Selector Sprite/Selector".visible = true
	get_selector_buttons()

func tts(string, values, node):
	if $"Options Sprite/Options".screen_reader:
		var t_label = preload("res://Outline Label.tscn").instance()
		t_label.visible = false
		add_child(t_label)
		t_label.raw_string = string
		if t_label.raw_string.find(tr("gambler_desc")) != -1 or t_label.raw_string.find(tr("thief_desc")) != -1:
			t_label.raw_string = t_label.raw_string.replace("?", " X ")
		if TranslationServer.get_locale() == "ar":
			pass
		t_label.values = values
		if $"Options Sprite/Options".CJK_lang or int($"Options Sprite/Options".display_font) > 0:
			t_label.get_child(0).custom_max_width = 10000000
		else:
			t_label.custom_max_width = 10000000
		t_label.tts = true
		t_label.update()
		if $"Options Sprite/Options".CJK_lang or int($"Options Sprite/Options".display_font) > 0:
			if (tts_node != node or OS.get_clipboard() != t_label.text) and t_label.get_child(0).text != "":
				OS.set_clipboard(t_label.get_child(0).text)
				tts_node = node
		else:
			if (tts_node != node or str(OS.get_clipboard()).strip_escapes() != str(t_label.text).strip_escapes()) and t_label.text != "":
				OS.set_clipboard(t_label.text)
				tts_node = node
		remove_child(t_label)
		t_label.queue_free()

func title():
	if $"Options Sprite/Options".visible:
		$"Options Sprite/Options".close()
		if $"Pop-up Sprite/Pop-up".spins > 0:
			loading_without_quitting = true
	$"Title".draw()
	sandbox_reloading = false
	load_data(true, false, true)
	var prev_sandbox = sandbox_mode
	load_sandbox()
	if sandbox_mode != prev_sandbox:
		reload()

func reset_values():
	var items = $"Items"
	var reels = $"Reels"
	var popup = $"Pop-up Sprite/Pop-up"
	
	rarity_database = base_rarities.duplicate(true)
	for t in tile_database:
		for k in rarity_database.keys():
			if rarity_database[k].has(t):
				t.rarity = k
				break
	
	rarity_chances = { "symbols": { "uncommon": 0, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
	
	for i in items.items:
		items.remove_child(i)
		i.queue_free()
	items.items.clear()
	items.destroyed_items.clear()
	if not sandbox_mode:
		items.item_types.clear()
	items.item_types_at_end_of_spin.clear()
	items.saved_item_data.clear()
	items.item_count_data.clear()
	items.destroyed_item_types.clear()
	items.saved_destroy_counters.clear()
	items.page = 0
	items.total_peppers = 0
	items.just_added_items.clear()
	items.items_destroyed_this_spin.clear()
	items.recently_destroyed_items.clear()
	items.cond_effects_to_add.clear()
	
	for r in reels.reels:
		for i in r.icons:
			i.queue_free()
		r.spinning = false
		r.spin_offset = 0
		r.max_icons = 5
		r.icons.clear()
		r.icon_types.clear()
		r.icon_types_to_be_added.clear()
		r.icon_types_tba_bonus_texts.clear()
		r.saved_icon_data.clear()
	for i in range(reels.reel_height * reels.reel_width, reels.texts.size()):
		reels.texts[i].queue_free()
	for e in reels.texts:
		e.raw_string = ""
		e.effect_timer = 0
		e.coin_value = 0
		e.visible = false
	for x in range(reels.reel_width):
		for y in range(reels.reel_height):
			reels.conditional_effects[y][x].clear()
	reels.texts.resize(reels.reel_height * reels.reel_width)
	reels.symbol_arr.clear()
	reels.symbol_queue.clear()
	reels.symbol_positions_to_update.clear()
	reels.sfx_queue.clear()
	reels.spinning = false
	reels.checking_effects = false
	reels.effects_playing = false
	$"Coins".queued_increase = 0
	$"Sums/Coin Sum".value = 0
	$"Sums/Coin Sum".raw_string = ""
	$"Sums/Coin Sum".adding = false
	$"Sums/Coin Sum".delay = 25
	$"Sums/Extra Sum".reroll_value = 0
	$"Sums/Extra Sum".removal_value = 0
	$"Sums/Extra Sum".essence_value = 0
	$"Sums/Extra Sum".raw_string = ""
	$"Sums/Extra Sum".adding = false
	$"Sums/Extra Sum".delay = 25
	$"Sums/HP Sum".hp_value = 0
	$"Sums/HP Sum".raw_string = ""
	$"Sums/HP Sum".adding = false
	$"Sums/HP Sum".delay = 25
	if not sandbox_mode:
		$"Coins".coins = 1
		popup.reroll_tokens = 0
		popup.removal_tokens = 0
		popup.essence_tokens = 0
		popup.spins = 0
	popup.extra_symbol_choices = 0
	popup.extra_item_choices = 0
	popup.symbols_to_select = 0
	popup.reels_to_select = 0
	popup.rent_values = [25, 5]
	if popup.current_modded_floor != null and typeof(popup.current_modded_floor) != TYPE_STRING:
		if not popup.current_modded_floor.rent_values.has("base") and popup.current_modded_floor.rent_values.size() > popup.times_rent_paid:
			popup.rent_values = popup.current_modded_floor.rent_values[popup.times_rent_paid].duplicate(true)
		popup.comrade_values = [popup.current_modded_floor.comrade_reroll_tokens, popup.current_modded_floor.comrade_removal_tokens, popup.current_modded_floor.comrade_essence_tokens]
		$"Coins".coins = popup.current_modded_floor.starting_coins
	elif popup.current_floor >= 16:
		popup.comrade_values = [1, 1, 1]
	elif popup.current_floor >= 9:
		popup.comrade_values = [1, 1, 2]
	elif popup.current_floor >= 4:
		popup.comrade_values = [2, 1, 2]
	else:
		popup.comrade_values = [2, 2, 2]
	popup.label_text.values = popup.rent_values.duplicate(true)
	if sandbox_mode and $"Pop-up Sprite/Pop-up".current_modded_floor == null:
		popup.times_rent_paid = 11
		rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.375, "rare": 0.05, "very_rare": 0.015 } }
		for x in range($"Reels".reel_width):
			for y in range($"Reels".reel_height):
				$"Reels".displayed_icons[y][x] = null
	else:
		popup.times_rent_paid = 0
		rarity_chances = { "symbols": { "uncommon": 0, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
	if demo:
		popup.times_to_pay_rent = 6
	elif $"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		popup.times_to_pay_rent = $"Pop-up Sprite/Pop-up".current_modded_floor.rent_payments
	else:
		popup.times_to_pay_rent = 12
	popup.rarity_bonuses = { "symbols": { "uncommon": 1, "rare": 1, "very_rare": 1 }, "items": { "uncommon": 1, "rare": 1, "very_rare": 1 } }
	popup.hex_of_emptiness_trigger = false
	popup.comfy_pillow_triggers = 0
	popup.comfy_pillow_essence_triggers = 0
	popup.queued_essence_emails = 0
	popup.floor_selected = false
	popup.scroll_bar.rect_position.y = popup.scroll_bar.top
	$"Stats Sprite/Stats".saved_ll_fate = null
	popup.offset_y = 128
	popup.emails.clear()
	popup.forced_rarities.clear()
	popup.forced_item_rarities.clear()
	popup.queued_symbols.clear()
	popup.queued_items.clear()
	popup.saved_card_types.clear()
	popup.destroyed_symbol_types.clear()
	popup.destroyed_symbol_types_size = 0
	popup.removed_symbol_types.clear()
	popup.saved_symbol_order.clear()
	popup.saved_symbol_data.clear()
	popup.saved_symbol_counts.clear()
	popup.permanent_bonuses.clear()
	popup.sme_this_spin.clear()
	popup.respun_reel = -1
	popup.respun_essence_reel = -1
	popup.symbols_added_this_spin = 0
	popup.symbols_destroyed_this_spin = 0
	popup.compost_heap_symbols_destroyed = 0
	popup.fossil_diff = 0
	popup.endless_mode = false
	popup.doing_boss_fight = false
	popup.reroll_cost = 1
	popup.removal_cost = 1
	popup.undraw_deck()
	
	popup.symbols_added_this_spin = 0
	popup.symbols_destroyed_this_spin = 0
	popup.transformed_coals = 0
	popup.coffee_essence = false
	for c in reels.counted_symbols.keys():
		reels.counted_symbols[c] = 0
	reels.checked_diff_multis = false
	reels.selected_icons.clear()
	reels.selected_reels.clear()
	reels.symbol_positions_to_update.clear()
	reels.symbol_positions_tbd.clear()
	
	reels.true_final_value = false
	reels.destroyed_item_this_spin = false
	reels.checking_last_effects = false
	reels.symbol_destroyed_during_spin = false
	reels.symbol_removed_during_spin = false
	
	if popup.current_floor >= 13:
		$"Landlord".max_hp = 1500
	elif popup.current_floor >= 11:
		$"Landlord".max_hp = 1000
	else:
		$"Landlord".max_hp = 750
	
	$"Landlord".hp = $"Landlord".max_hp
	$"Landlord".fine_print_counter = 0
	$"Landlord".queued_damage = 0
	$"Landlord".queued_fine_print.clear()
	$"Landlord".fine_print.clear()
	$"Landlord".stolen_symbols.clear()
	$"Landlord".stolen_items.clear()
	$"Landlord/Temp".visible = false
	$"Reels/Landlord Bar".visible = false
	for r in $"Reels".reel_borders:
		r.get_child(1).get_child(1).visible = false
	
	for i in popup.item_info_texts:
		i.get_parent().queue_free()
	popup.item_info_texts.clear()
	
	for s in popup.symbol_info_texts:
		s.get_parent().queue_free()
	popup.symbol_info_texts.clear()
	
	popup.remove(null)
	log_queue.clear()
	error_queue.clear()
	
	save_game()

func new_game():
	if $"Pop-up Sprite/Pop-up".floor_selected or demo:
		change_current_menu_path("/root/Main")
		$"Pop-up Sprite/Pop-up".current_floor = $"Title".temp_floor
		if $"Title".temp_modded_floor != null and typeof($"Title".temp_modded_floor) != TYPE_STRING:
			$"Pop-up Sprite/Pop-up".current_modded_floor = $"Title".temp_modded_floor
		else:
			$"Pop-up Sprite/Pop-up".current_modded_floor = null
			$"Pop-up Sprite/Pop-up".modded_floor_string = null
		reset_values()
		$"Pop-up Sprite/Pop-up".total_runs += 1
		$"Pop-up Sprite/Pop-up".run_timestamp = OS.get_unix_time()
		var log_file = File.new()
		log_file.open("user://run_logs/" + str($"Pop-up Sprite/Pop-up".run_timestamp) + ".log", File.WRITE)
		log_file.close()
		write_log("--- STARTING RUN #" + str($"Pop-up Sprite/Pop-up".total_runs) + " ---")
		write_log(version_str)
		$"Title".remove()
		load_data(true, false, true)
		$"Items".load_items()
		for r in $"Reels".reels:
			if sandbox_mode and $"Pop-up Sprite/Pop-up".current_modded_floor == null:
				for i in r.icons:
					for c in i.get_children():
						i.remove_child(c)
					r.remove_child(i)
					i.queue_free()
			r.load_base_icons()
		if starting.symbols.size() > 0:
			$"Reels".add_tile(starting.symbols)
		for i in starting.items:
			if not is_mod_disabled(i):
				$"Items".add_item(i)
		if $"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
			for i in $"Pop-up Sprite/Pop-up".current_modded_floor.starting_items:
				var a = i
				if $"Pop-up Sprite/Pop-up".saved_mod_ids.items.has(a):
					a += "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.items[a]
				if mod_pack_nums.has(a):
					a += "_PACK_" + mod_pack_nums[a]
				if not is_mod_disabled(a):
					$"Items".add_item(a)
				else:
					$"Items".add_item(a.substr(0, a.find("_STEAM_ID_")))
		$"Items".update_page_buttons()
		$"Pop-up Sprite/Pop-up".label_text.values = $"Pop-up Sprite/Pop-up".rent_values.duplicate(true)
		if $"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
			for e in $"Pop-up Sprite/Pop-up".current_modded_floor.intro_emails:
				var e_type = e.type
				if $"Pop-up Sprite/Pop-up".saved_mod_ids.emails.has(e_type):
					e_type += "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.emails[e_type]
				if mod_pack_nums.has(e_type):
					e_type += "_PACK_" + str(mod_pack_nums[e_type])
				if e.keys().size() > 1:
					var extra_values = e.duplicate(true)
					extra_values.erase("type")
					$"Pop-up Sprite/Pop-up".add_event(e_type, extra_values)
				else:
					$"Pop-up Sprite/Pop-up".add_event(e_type, null)
		elif not sandbox_mode:
			$"Pop-up Sprite/Pop-up".add_event("intro", null)
		elif testing_fine_print:
			$"Pop-up Sprite/Pop-up".add_event("fine_print", null)
		$"Pop-up Sprite/Pop-up".delay_timer = 0
		$"Pop-up Sprite/Pop-up".floor_selected = true
		$"Menus".buttons_menu.removal_button.visible = false
		$"Pop-up Sprite/Pop-up".mods = {"symbols": [], "items": []}
		load_mods()
		var mod_num = 0
		for m in tile_database:
			if tile_database[m].modded and not is_mod_disabled(m):
				mod_num += 1
		for m in item_database:
			if item_database[m].modded and not is_mod_disabled(m):
				mod_num += 1
		for m in fine_print_database:
			if int(m) > 37:
				mod_num += 1
		if $"Pop-up Sprite/Pop-up".current_modded_floor != null:
			mod_num += 1
		$"Pop-up Sprite/Pop-up".modded_run = (mod_num != 0)
		if $"Pop-up Sprite/Pop-up".modded_run:
			write_log("--- MODDED RUN ---")
	elif $"Pop-up Sprite/Pop-up".endless_mode and not are_you_sure_displayed:
		are_you_sure_displayed = true
		display_error("are_you_sure", tr("are_you_sure"))
		$"Title".buttons[0].down = false
	else:
		$"Pop-up Sprite/Pop-up".floor_selected = true
		if $"Stats Sprite/Stats".highest_unlocked_floor > 1 and not sandbox_mode:
			$"Title".floor_menu()
		else:
			var n = $"Pop-up Sprite/Pop-up"
			new_game()
			if n.removal_tokens > n.removal_cost - 1:
				$"Menus".buttons_menu.removal_button.text_node.values = [n.removal_tokens]
				$"Menus".buttons_menu.removal_button.text_node.force_update = true
				$"Menus".buttons_menu.removal_button.text_node.update()
				$"Menus".buttons_menu.removal_button.change_size()
				$"Menus".buttons_menu.removal_button.update_size()
				$"Menus".buttons_menu.removal_button.correct_size()
				$"Menus".buttons_menu.removal_button.visible = true
			change_current_menu_path("slots")

func reload():
	for e in $"Reels".texts:
		if e.coin_value > 0:
			$"Coins".coins += e.coin_value
			e.coin_value = 0
		if e.reroll_value > 0:
			$"Pop-up Sprite/Pop-up".reroll_tokens += e.reroll_value
			e.reroll_value = 0
		if e.removal_value > 0:
			$"Pop-up Sprite/Pop-up".removal_tokens += e.removal_value
			e.removal_value = 0
		if e.essence_value > 0:
			$"Pop-up Sprite/Pop-up".essence_tokens += e.essence_value
			e.essence_value = 0
	if $"Sums/Coin Sum".value > 0:
		$"Coins".coins += $"Sums/Coin Sum".value
		$"Sums/Coin Sum".value = 0
	reloading_scene = true
	reload_scene_timer = 2

func continue_game():
	if not sandbox_mode:
		if $"Pop-up Sprite/Pop-up".spins > 0:
			load_data(false, true, true)
			load_mods()
			if $"Title".temp_modded_floor != null and typeof($"Title".temp_modded_floor) != TYPE_STRING:
				$"Pop-up Sprite/Pop-up".current_modded_floor = $"Title".temp_modded_floor
				$"Landlord".init_fine_print()
			elif $"Pop-up Sprite/Pop-up".modded_floor_string != null:
				$"Pop-up Sprite/Pop-up".current_modded_floor = apartment_floor_database[$"Pop-up Sprite/Pop-up".modded_floor_string]
			else:
				$"Pop-up Sprite/Pop-up".current_modded_floor = null
				$"Pop-up Sprite/Pop-up".modded_floor_string = null
			if $"Pop-up Sprite/Pop-up".passed != null:
				group_database["symbols"]["passed"] = $"Pop-up Sprite/Pop-up".passed
			if $"Pop-up Sprite/Pop-up".taken != null:
				group_database["symbols"]["taken"] = $"Pop-up Sprite/Pop-up".taken
			var mod_num = 0
			for m in tile_database:
				if tile_database[m].modded and not is_mod_disabled(m):
					mod_num += 1
			for m in item_database:
				if item_database[m].modded and not is_mod_disabled(m):
					mod_num += 1
			for m in fine_print_database:
				if int(m) > 37:
					mod_num += 1
			if $"Pop-up Sprite/Pop-up".current_modded_floor != null:
				mod_num += 1
			$"Pop-up Sprite/Pop-up".modded_run = (mod_num != 0)
			if $"Pop-up Sprite/Pop-up".modded_run:
				write_log("--- MODDED RUN ---")
			if $"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
				$"Pop-up Sprite/Pop-up".comrade_values = [$"Pop-up Sprite/Pop-up".current_modded_floor.comrade_reroll_tokens, $"Pop-up Sprite/Pop-up".current_modded_floor.comrade_removal_tokens, $"Pop-up Sprite/Pop-up".current_modded_floor.comrade_essence_tokens]
			elif $"Pop-up Sprite/Pop-up".current_floor >= 16:
				$"Pop-up Sprite/Pop-up".comrade_values = [1, 1, 1]
			elif $"Pop-up Sprite/Pop-up".current_floor >= 9:
				$"Pop-up Sprite/Pop-up".comrade_values = [1, 1, 2]
			elif $"Pop-up Sprite/Pop-up".current_floor >= 4:
				$"Pop-up Sprite/Pop-up".comrade_values = [2, 1, 2]
			else:
				$"Pop-up Sprite/Pop-up".comrade_values = [2, 2, 2]
			$"Pop-up Sprite/Pop-up".floor_selected = true
			write_log("--- CONTINUING RUN #" + str($"Pop-up Sprite/Pop-up".total_runs) + " ---")
			write_log(version_str)
			$"Title".remove()
			if not loading_without_quitting:
				for r in $"Reels".reels:
					for i in r.icons:
						i.queue_free()
				$"Reels".symbol_arr.clear()
				$"Items".load_items()
				for i in $"Items".items:
					if i.type == "rain_cloud" and not i.disabled:
						if rarity_database["symbols"]["uncommon"].has("rain"):
							rarity_database["symbols"]["uncommon"].erase("rain")
							rarity_database["symbols"]["common"].push_back("rain")
							tile_database["rain"].rarity = "common"
					elif i.type == "dark_humor" and not i.disabled:
						if rarity_database["symbols"]["rare"].has("comedian"):
							rarity_database["symbols"]["rare"].erase("comedian")
							rarity_database["symbols"]["uncommon"].push_back("comedian")
							tile_database["comedian"].rarity = "uncommon"
					elif i.type == "void_party" and not i.disabled:
						if rarity_database["symbols"]["uncommon"].has("void_creature"):
							rarity_database["symbols"]["uncommon"].erase("void_creature")
							rarity_database["symbols"]["common"].push_back("void_creature")
							tile_database["void_creature"].rarity = "common"
						if rarity_database["symbols"]["uncommon"].has("void_stone"):
							rarity_database["symbols"]["uncommon"].erase("void_stone")
							rarity_database["symbols"]["common"].push_back("void_stone")
							tile_database["void_stone"].rarity = "common"
						if rarity_database["symbols"]["uncommon"].has("void_fruit"):
							rarity_database["symbols"]["uncommon"].erase("void_fruit")
							rarity_database["symbols"]["common"].push_back("void_fruit")
							tile_database["void_fruit"].rarity = "common"
					elif i.type == "flush" and not i.disabled:
						if rarity_database["symbols"]["uncommon"].has("clubs"):
							rarity_database["symbols"]["uncommon"].erase("clubs")
							rarity_database["symbols"]["common"].push_back("clubs")
							tile_database["clubs"].rarity = "common"
						if rarity_database["symbols"]["uncommon"].has("diamonds"):
							rarity_database["symbols"]["uncommon"].erase("diamonds")
							rarity_database["symbols"]["common"].push_back("diamonds")
							tile_database["diamonds"].rarity = "common"
						if rarity_database["symbols"]["uncommon"].has("hearts"):
							rarity_database["symbols"]["uncommon"].erase("hearts")
							rarity_database["symbols"]["common"].push_back("hearts")
							tile_database["hearts"].rarity = "common"
						if rarity_database["symbols"]["uncommon"].has("spades"):
							rarity_database["symbols"]["uncommon"].erase("spades")
							rarity_database["symbols"]["common"].push_back("spades")
							tile_database["spades"].rarity = "common"
					i.get_child(0).force_update = true
					i.get_child(0).update()
					i.update_value_text()
				for i in $"Items".destroyed_items:
					if i == "lucky_seven_essence":
						if rarity_database["symbols"]["uncommon"].has("chemical_seven"):
							rarity_database["symbols"]["uncommon"].erase("chemical_seven")
							rarity_database["symbols"]["common"].push_back("chemical_seven")
							tile_database["chemical_seven"].rarity = "common"
						break
				$"Reels".load_icons()
				$"Items".update_page_buttons()
				var n = $"Pop-up Sprite/Pop-up"
				if n.emails.size() > 0:
					n.rent_container.get_child(0).values = n.rent_values.duplicate(true)
					match n.emails[0].type:
						"swap_prompt_1":
							n.label_text.values = item_database["swapping_device"].values
						"comrade_help", "init_comrade_help", "comrade_help_no_essence", "init_comrade_help_no_essence":
							n.label_text.values = n.comrade_values
						"comfy_pillow_prompt":
							n.label_text.values = [n.rent_values[0], n.rent_values[1], item_database["comfy_pillow"].values[1]]
						"comfy_pillow_essence_prompt":
							n.label_text.values = [n.rent_values[0], n.rent_values[1], item_database["comfy_pillow_essence"].values[2], item_database["comfy_pillow_essence"].values[1]]
						_:
							n.label_text.values = n.rent_values.duplicate(true)
					n.display()
				if n.removal_tokens > n.removal_cost - 1:
					$"Menus".buttons_menu.removal_button.text_node.values = [n.removal_tokens]
					$"Menus".buttons_menu.removal_button.update_size()
					$"Menus".buttons_menu.removal_button.text_node.force_update = true
					$"Menus".buttons_menu.removal_button.text_node.update()
					$"Menus".buttons_menu.removal_button.correct_size()
					$"Menus".buttons_menu.removal_button.visible = true
				else:
					$"Menus".buttons_menu.removal_button.visible = false
				$"Pop-up Sprite/Pop-up".rent_values.resize(2)
				if $"Pop-up Sprite/Pop-up".doing_boss_fight:
					randomize()
					if rand_range(0, 1) < 0.5:
						$"Music Player".play_set_music("Landlocked")
					else:
						$"Music Player".play_set_music("Mad for Money")
			if $"Pop-up Sprite/Pop-up".doing_boss_fight:
				$"Landlord/Temp".visible = true
			if $"Pop-up Sprite/Pop-up".emails.size() > 0:
				change_current_menu_path("email")
			else:
				change_current_menu_path("slots")

func write_log(string):
	var time = OS.get_datetime()
	var hour_string
	var minute_string
	var second_string
	
	if time.hour >= 10:
		hour_string = str(time.hour) + ":"
	else:
		hour_string = "0" + str(time.hour) + ":"
	if time.minute >= 10:
		minute_string = str(time.minute) + ":"
	else:
		minute_string = "0" + str(time.minute) + ":"
	if time.second >= 10:
		second_string = str(time.second)
	else:
		second_string = "0" + str(time.second)
		
	if achievement_data:
		log_queue.push_back(string + "\n")
	else:
		log_queue.push_back("[" + str(time.month) + "/" + str(time.day) + "/" + str(time.year) + " " + hour_string + minute_string + second_string + "] " + string + "\n")

func save_log():
	var log_file = File.new()
	
	if achievement_data:
		log_file.open("user://achievement_data.vdf", File.WRITE)
	else:
		log_file.open("user://run_logs/" + str($"Pop-up Sprite/Pop-up".run_timestamp) + ".log", File.READ_WRITE)
	log_file.seek_end()
	for l in log_queue:
		log_file.store_string(l)
	log_file.close()
	
	log_queue.clear()

func write_error(string):
	var time = OS.get_datetime()
	var hour_string
	var minute_string
	var second_string
	
	if time.hour >= 10:
		hour_string = str(time.hour) + ":"
	else:
		hour_string = "0" + str(time.hour) + ":"
	if time.minute >= 10:
		minute_string = str(time.minute) + ":"
	else:
		minute_string = "0" + str(time.minute) + ":"
	if time.second >= 10:
		second_string = str(time.second)
	else:
		second_string = "0" + str(time.second)
		
	error_queue.push_back("[" + str(time.month) + "/" + str(time.day) + "/" + str(time.year) + " " + hour_string + minute_string + second_string + "] " + string + "\n")

func save_errors():
	var log_file = File.new()
	
	log_file.open("user://errors.log", File.READ_WRITE)
	log_file.seek_end()
	for l in error_queue:
		log_file.store_string(l)
	log_file.close()
	
	error_queue.clear()

func init_sandbox():
	var sandbox_file = File.new()
	
	if not sandbox_file.file_exists("user://LBAL-Sandbox-Data.save") and not demo:
		sandbox_file.open("user://LBAL-Sandbox-Data.save", File.WRITE)
		sandbox_file.store_string("{\"sandbox\": false, \"fine_print\": false, \"sandbox_consistent\": true, \"apartment_floor_type\": null, \"apartment_floor_num\": 1, \"coins\": 1, \"reroll_tokens\": 0, \"removal_tokens\": 0, \"essence_tokens\": 0, \"items\": []}\n")
		sandbox_file.store_string("{\"symbols1\": [\"coin\", \"coin\", \"coin\", \"coin\", \"coin\"]}\n")
		sandbox_file.store_string("{\"symbols2\": [\"coin\", \"coin\", \"coin\", \"coin\", \"coin\"]}\n")
		sandbox_file.store_string("{\"symbols3\": [\"coin\", \"coin\", \"coin\", \"coin\", \"coin\"]}\n")
		sandbox_file.store_string("{\"symbols4\": [\"coin\", \"coin\", \"coin\", \"coin\", \"coin\"]}\n")
		sandbox_file.close()

func save_game():
	if not sandbox_mode:
		var save_game = File.new()
		save_game.open(save_string, File.WRITE)
		var save_nodes = get_tree().get_nodes_in_group("Persist")
		for node in save_nodes:
			if node.filename.empty():
				print("persistent node '%s' is not an instanced scene, skipped" % node.name)
				continue
				
			if !node.has_method("save"):
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
			
			var node_data = node.call("save")
			save_game.store_line(to_json(node_data))
		save_game.close()

func save_options():
	var save_game = File.new()
	save_game.open("user://LBAL-Settings.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist-Options")
	for node in save_nodes:
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
			
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		
		var node_data = node.call("save")
		save_game.store_line(to_json(node_data))
	save_game.close()

func save_stats():
	if not sandbox_mode:
		var save_game = File.new()
		save_game.open("user://LBAL-Stats.save", File.WRITE)
		var save_nodes = get_tree().get_nodes_in_group("Persist-Stats")
		for node in save_nodes:
			if node.filename.empty():
				print("persistent node '%s' is not an instanced scene, skipped" % node.name)
				continue
				
			if !node.has_method("save"):
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
			
			var node_data = node.call("save")
			save_game.store_line(to_json(node_data))
		save_game.close()

func backup_stats():
	if not sandbox_mode:
		var stat_backup = File.new()
		stat_backup.open("user://LBAL-Stats.bak", File.WRITE)
		var save_nodes = get_tree().get_nodes_in_group("Persist-Stats")
		for node in save_nodes:
			if node.filename.empty():
				print("persistent node '%s' is not an instanced scene, skipped" % node.name)
				continue
				
			if !node.has_method("save"):
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
			
			var node_data = node.call("save")
			stat_backup.store_line(to_json(node_data))
		stat_backup.close()

func preload_config(p_str):
	var save_game = File.new()
	if not save_game.file_exists(p_str):
		return
	
	save_game.open(p_str, File.READ)
	while save_game.get_position() < save_game.get_len():
		var line = save_game.get_line()
		if line.length() == 0 or line.substr(0, 1) == "\u3000":
			var dir = Directory.new()
			dir.remove(p_str)
			break
		var node_data = parse_json(line)
		
		if node_data == null:
			var dir = Directory.new()
			dir.remove(p_str)
			break
		
		if node_data != null:
			var n = node_data["path"]
			
			for i in node_data.keys():
				if i == "path" or i == "pos_x" or i == "pos_y":
					continue
				elif n == "/root/Main/Options Sprite/Options" and p_str == "user://LBAL-Settings.save":
					init_config[i] = node_data[i]
	save_game.close()

func load_sandbox():
	if not demo:
		var sandbox_save = File.new()
		if not sandbox_save.file_exists("user://LBAL-Sandbox-Data.save"):
			return
		
		sandbox_icons = [[], [], [], [], []]
		
		sandbox_save.open("user://LBAL-Sandbox-Data.save", File.READ)
		var tmp_floor_type = ""
		var tmp_floor_num = 1
		while sandbox_save.get_position() < sandbox_save.get_len():
			var node_data = parse_json(sandbox_save.get_line())
			
			if node_data == null:
				continue
			for i in node_data.keys():
				match i:
					"sandbox":
						if not sandbox_reloading:
							sandbox_mode = node_data[i]
					"fine_print":
						if sandbox_mode:
							testing_fine_print = node_data[i]
					"sandbox_consistent":
						if sandbox_mode:
							sandbox_consistent = node_data[i]
					"apartment_floor_type":
						if sandbox_mode and node_data[i] != null:
							tmp_floor_type = node_data[i]
					"apartment_floor_num":
						if sandbox_mode and node_data[i] != null:
							tmp_floor_num = node_data[i]
					"coins":
						if sandbox_mode:
							$"Coins".coins = node_data[i]
					"removal_tokens":
						if sandbox_mode:
							$"Pop-up Sprite/Pop-up".removal_tokens = node_data[i]
					"reroll_tokens":
						if sandbox_mode:
							$"Pop-up Sprite/Pop-up".reroll_tokens = node_data[i]
					"essence_tokens":
						if sandbox_mode:
							$"Pop-up Sprite/Pop-up".essence_tokens = node_data[i]
					"symbols1", "symbols2", "symbols3", "symbols4":
						if sandbox_mode:
							for a in range(5):
								var with_id = node_data[i][a]
								if mod_pack_nums.has(node_data[i][a] + "_STEAM_ID_" + str(steam_id)):
									with_id = node_data[i][a] + "_STEAM_ID_" + str(steam_id) + "_PACK_" + mod_pack_nums[node_data[i][a] + "_STEAM_ID_" + str(steam_id)]
								if mod_names.symbols.has(node_data[i][a]) and mod_data.symbols.has(with_id) and not mod_data.symbols[with_id].art_replacement and not is_mod_disabled(with_id):
									sandbox_icons[a].push_back(with_id)
								else:
									sandbox_icons[a].push_back(node_data[i][a])
					"items":
						if sandbox_mode:
							$"Items".item_types.clear()
							for a in node_data[i]:
								var with_id = a
								if mod_pack_nums.has(a + "_STEAM_ID_" + str(steam_id)):
									with_id = a + "_STEAM_ID_" + str(steam_id) + "_PACK_" + mod_pack_nums[a + "_STEAM_ID_" + str(steam_id)]
								if mod_names.items.has(a) and not is_mod_disabled(with_id):
									$"Items".item_types.push_back(with_id)
								else:
									$"Items".item_types.push_back(a)
		if sandbox_mode and mod_pack_nums.has("apartment_floor_" + tmp_floor_type + "_" + str(tmp_floor_num) + "_STEAM_ID_" + str(steam_id)):
			$"Title".temp_modded_floor = apartment_floor_database["apartment_floor_" + tmp_floor_type + "_" + str(tmp_floor_num) + "_STEAM_ID_" + str(steam_id) + "_PACK_" + mod_pack_nums["apartment_floor_" + tmp_floor_type + "_" + str(tmp_floor_num) + "_STEAM_ID_" + str(steam_id)]]
		var n = $"Pop-up Sprite/Pop-up"
		if n.removal_tokens > n.removal_cost - 1:
			$"Menus".buttons_menu.removal_button.text_node.values = [n.removal_tokens]
			$"Menus".buttons_menu.removal_button.update_size()
			$"Menus".buttons_menu.removal_button.text_node.force_update = true
			$"Menus".buttons_menu.update()
			$"Menus".buttons_menu.removal_button.correct_size()
			$"Menus".buttons_menu.removal_button.visible = true
		sandbox_save.close()

func load_data(save_ids, load_saved_ids, past_init):
	tile_database = {}
	item_database = {}
	fine_print_database = {}
	apartment_floor_database = {}
	inherited_effects_database = {}
	sfx_database = { "symbols": {}, "items": {}, "misc": {} }
	modded_sfx_paths = {}
	rarity_database = { "symbols": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "none": [] }, "items": { "common": [], "uncommon": [], "rare": [], "very_rare": [], "essence": [], "none": [] } }
	group_database = { "symbols": {}, "items": {} }
	mod_names = {"symbols": [], "items": []}
	mod_data = {"symbols": {}, "items": {}, "emails": {}}
	mod_groups = {"symbols": {}, "items": {}}
	modded_existing = {"symbols": {}, "items": {}}
	modded_existing_base_types = {"symbols": {}, "items": {}}
	starting = {"symbols": [], "items": []}
	existing_symbols = {}
	existing_items = {}
	mod_packs = {}
	mod_pack_nums = {}
	mod_on_symbol_add_effects = []
	mod_on_item_add_effects = []
	mod_on_rent_paid_effects = []
	modded_fine_print_nums = []
	modded_apartment_floors = {}
	non_symbol_icons = ["confirm", "deny", "squiggle", "speaker", "speaker_muted", "left", "right", "down", "dpad_down", "dpad_left", "dpad_right", "dpad_up", "leftstick_click", "leftstick_down", "leftstick_left", "leftstick_right", "leftstick_up", "ps_circle", "ps_cross", "ps_l1", "ps_l2", "ps_r1", "ps_r2", "ps_select", "ps_square", "ps_start", "ps_triangle", "rightstick_click", "rightstick_down", "rightstick_left", "rightstick_right", "rightstick_up", "switch_minus", "switch_plus", "switch_zl", "switch_zr", "xbox_A", "xbox_B", "xbox_X", "xbox_Y", "switch_A", "switch_B", "switch_X", "switch_Y", "xbox_lb", "xbox_lt", "xbox_rb", "xbox_rt", "xbox_select", "xbox_start", "switch_l", "switch_r", "ps_touchpad", "invis", "hp"]
	
	if past_init:
		$"Landlord".total_fine_print = 31
		$"Landlord".init_fine_print()
	
	if save_ids:
		$"Pop-up Sprite/Pop-up".saved_mod_ids = {"symbols": {}, "items": {}, "symbol_groups": {}, "item_groups": {}, "emails": {}}

	var log_dir = Directory.new()
	if not log_dir.dir_exists("user://run_logs"):
		log_dir.make_dir("user://run_logs")
	
	var mod_dir = Directory.new()
	if not mod_dir.dir_exists("user://mods"):
		mod_dir.make_dir("user://mods")
		
	if OS.get_name() == "OSX":
		steam_mods = OS.get_executable_path().substr(0, OS.get_executable_path().find_last("/")) + "/../../../../../workshop/content/1404850/"
	else:
		steam_mods = OS.get_executable_path().substr(0, OS.get_executable_path().find_last("/")) + "/../../workshop/content/1404850/"

	var mod_files = {}
	var art_dirs = []
	var sfx_dirs = []
	
	if mod_dir.dir_exists(steam_mods) and not demo:
		mod_dir.open(steam_mods)
		mod_dir.list_dir_begin()
		while true:
			var file = mod_dir.get_next()
			if file == "":
				break
			elif not mod_dir.current_is_dir():
				continue
			elif not file.begins_with("."):
				art_dirs.append(steam_mods + file + "/art/")
				sfx_dirs.append(steam_mods + file + "/sfx/")
				var mod_dir_2 = Directory.new()
				mod_dir_2.open(steam_mods + file + "/scripts")
				mod_dir_2.list_dir_begin()
				while true:
					var m = mod_dir_2.get_next()
					if m == "":
						break
					elif not m.begins_with(".") and not malicious_mod(steam_mods + file + "/scripts/", m):
						if not mod_files.has(file):
							mod_files[file] = []
						mod_files[file].push_back(steam_mods + file + "/scripts/" + m)
		mod_dir.list_dir_end()
	
	mod_dir.open("user://mods/")
	mod_dir.list_dir_begin()
	
	while true and not demo:
		var file = mod_dir.get_next()
		if file == "":
			break
		elif not mod_dir.current_is_dir():
			continue
		elif not file.begins_with("."):
			art_dirs.append("user://mods/" + file + "/art/")
			sfx_dirs.append("user://mods/" + file + "/sfx/")
			var mod_dir_2 = Directory.new()
			mod_dir_2.open("user://mods/" + file + "/scripts")
			mod_dir_2.list_dir_begin()
			while true:
				var m = mod_dir_2.get_next()
				if m == "":
					break
				elif not m.begins_with(".") and not malicious_mod("user://mods/" + file + "/scripts/", m):
					if not mod_files.has(file):
						mod_files[file] = []
					mod_files[file].push_back("user://mods/" + file + "/scripts/" + m)
	mod_dir.list_dir_end()
	
	var tile_file = File.new()
	tile_file.open("res://JSON/Symbols - JSON.json", tile_file.READ)
	var tile_text = tile_file.get_as_text()
	var tile_db = JSON.parse(tile_text)
	tile_file.close()
	
	var item_file = File.new()
	item_file.open("res://JSON/Items - JSON.json", item_file.READ)
	var item_text = item_file.get_as_text()
	var item_db = JSON.parse(item_text)
	item_file.close()
	
	var essence_file = File.new()
	essence_file.open("res://JSON/Essences - JSON.json", essence_file.READ)
	var essence_text = essence_file.get_as_text()
	var essence_db = JSON.parse(essence_text)
	essence_file.close()
	
	var fine_print_file = File.new()
	fine_print_file.open("res://JSON/Fine Print - JSON.json", fine_print_file.READ)
	var fine_print_text = fine_print_file.get_as_text()
	var fine_print_db = JSON.parse(fine_print_text)
	fine_print_file.close()
	
	var mods = []
	mod_packs = {}
	art_replacement_nums = {}
	
	if not demo:
		for f in mod_files.keys():
			for x in mod_files[f]:
				var m = x
				mods.push_back(load(m).new())
				var id_type = mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(f)
				mods[mods.size() - 1].pack_num = f
				mods[mods.size() - 1]["mod_path"] = str(m)
				if not mod_packs.keys().has(f):
					mod_packs[f] = []
				match mods[mods.size() - 1].mod_type:
					"symbol", "existing_symbol":
						mod_names.symbols.push_back(mods[mods.size() - 1].type)
						mod_data.symbols[id_type] = {"mod_type": mods[mods.size() - 1].mod_type, "type": id_type, "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": mods[mods.size() - 1].inherit_art, "art_replacement": false, "pack_num": mods[mods.size() - 1].pack_num}
						mod_pack_nums[mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
						mod_packs[f].push_back(mod_data.symbols[id_type])
						if save_ids and past_init:
							$"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[mods[mods.size() - 1].type] = str(mods[mods.size() - 1].author_id)
					"item", "existing_item":
						mod_names.items.push_back(mods[mods.size() - 1].type)
						mod_data.items[id_type] = {"mod_type": mods[mods.size() - 1].mod_type, "type": id_type, "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": mods[mods.size() - 1].inherit_art, "art_replacement": false, "pack_num": mods[mods.size() - 1].pack_num, "cannot_be_disabled": mods[mods.size() - 1].cannot_be_disabled}
						mod_pack_nums[mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
						mod_packs[f].push_back(mod_data.items[id_type])
						if save_ids and past_init:
							$"Pop-up Sprite/Pop-up".saved_mod_ids.items[mods[mods.size() - 1].type] = str(mods[mods.size() - 1].author_id)
					"art_replacement":
						for i in range(2):
							var art_dir = Directory.new()
							if i == 0:
								if s_id == 0:
									continue
								art_dir.open(steam_mods + f + "/art/")
							else:
								art_dir.open("user://mods/" + f + "/art/")
							art_dir.list_dir_begin()
							while true:
								var file = art_dir.get_next()
								if file == "":
									break
								elif not file.begins_with(".") and file.substr(file.length() - 4, -1) == ".png":
									var type = (file.substr(0, file.length() - 4)).substr(0, file.find("_STEAM_ID_"))
									var with_id = type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f
									if tile_db.result.has(type):
										mod_names.symbols.push_back(type)
										mod_pack_nums[type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
										mod_data.symbols[type + "_" + f] = {"type": with_id, "display_name": tr(type), "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": mods[mods.size() - 1].inherit_art, "art_replacement": true, "pack_num": mods[mods.size() - 1].pack_num}
									elif item_db.result.has(type):
										mod_names.items.push_back(type)
										mod_pack_nums[type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
										mod_data.items[type + "_" + f] = {"type": with_id, "display_name": tr(type), "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": mods[mods.size() - 1].inherit_art, "art_replacement": true, "pack_num": mods[mods.size() - 1].pack_num, "cannot_be_disabled": mods[mods.size() - 1].cannot_be_disabled}
									else:
										mod_pack_nums[type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
									if not art_replacement_nums.has(type):
										art_replacement_nums[type] = ["_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f]
									else:
										art_replacement_nums[type].push_back("_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f)
									mod_packs[f].push_back({"type": type + "_" + f, "mod_type": "art_replacement", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
					"group_addition":
						mod_pack_nums["group_addition_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = str(f)
						mod_data.symbols["group_addition_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = {"type": "group_addition_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": false, "art_replacement": false, "fine_print": false, "apartment_floor": false, "pack_num": mods[mods.size() - 1].pack_num}
						mod_packs[f].push_back({"type": "group_addition_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "mod_type": "group_addition", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
						if past_init and not is_mod_disabled("group_addition_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)):
							for e in mods[mods.size() - 1].effects:
								for g in e.keys():
									for s in e[g]:
										if not group_database["symbols"].has(g):
											group_database["symbols"][g] = [s]
										else:
											group_database["symbols"][g].push_back(s)
					"email":
						var e = mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f
						mod_pack_nums[mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
						mod_packs[f].push_back({"type": mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "mod_type": "email", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
						mod_data.emails[id_type] = {"mod_type": mods[mods.size() - 1].mod_type, "type": id_type, "author_id": mods[mods.size() - 1].author_id, "inherit_art": mods[mods.size() - 1].inherit_art, "art_replacement": false, "fine_print": false, "apartment_floor": false, "pack_num": mods[mods.size() - 1].pack_num}
						if past_init:
							$"Pop-up Sprite/Pop-up".email_data.result[e] = {}
							$"Pop-up Sprite/Pop-up".email_data.result[e]["type"] = e
							if $"Pop-up Sprite/Pop-up".email_data.result[e].has("localized_text") and $"Pop-up Sprite/Pop-up".email_data.result[e].localized_text.has(TranslationServer.get_locale()):
								$"Pop-up Sprite/Pop-up".email_data.result[e].text = $"Pop-up Sprite/Pop-up".email_data.result[e].localized_text[TranslationServer.get_locale()]
							else:
								$"Pop-up Sprite/Pop-up".email_data.result[e].text = mods[mods.size() - 1].text
							if $"Pop-up Sprite/Pop-up".email_data.result[e].has("localized_header_text") and $"Pop-up Sprite/Pop-up".email_data.result[e].localized_header_text.has(TranslationServer.get_locale()):
								$"Pop-up Sprite/Pop-up".email_data.result[e].header = $"Pop-up Sprite/Pop-up".email_data.result[e].localized_header_text[TranslationServer.get_locale()]
							else:
								$"Pop-up Sprite/Pop-up".email_data.result[e].header = mods[mods.size() - 1].header_text
							if $"Pop-up Sprite/Pop-up".email_data.result[e].has("localized_replies") and $"Pop-up Sprite/Pop-up".email_data.result[e].localized_replies.has(TranslationServer.get_locale()):
								$"Pop-up Sprite/Pop-up".email_data.result[e].replies = $"Pop-up Sprite/Pop-up".email_data.result[e].localized_replies[TranslationServer.get_locale()]
							else:
								$"Pop-up Sprite/Pop-up".email_data.result[e].replies = mods[mods.size() - 1].replies
							$"Pop-up Sprite/Pop-up".email_data.result[e].reply_results = mods[mods.size() - 1].reply_results
							$"Pop-up Sprite/Pop-up".email_data.result[e].prompt = mods[mods.size() - 1].prompt
							if save_ids:
								$"Pop-up Sprite/Pop-up".saved_mod_ids.emails[mods[mods.size() - 1].type] = str(mods[mods.size() - 1].author_id)
					"fine_print":
						if past_init:
							$"Landlord".total_fine_print += 1
							mod_data.symbols["fine_print_" + str($"Landlord".total_fine_print + 6) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = {"type": "fine_print_" + str($"Landlord".total_fine_print + 6) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": false, "art_replacement": false, "fine_print": true, "apartment_floor": false, "pack_num": mods[mods.size() - 1].pack_num}
							mod_pack_nums["fine_print_" + str($"Landlord".total_fine_print + 6) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
							mod_packs[f].push_back({"type": "fine_print_" + str($"Landlord".total_fine_print + 6) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "mod_type": "fine_print", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
							if not is_mod_disabled("fine_print_" + str($"Landlord".total_fine_print + 6) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)):
								fine_print_database[str($"Landlord".total_fine_print + 6)] = {"fine_print_num": str($"Landlord".total_fine_print + 6), "difficulty": mods[mods.size() - 1].difficulty, "reliant_types": mods[mods.size() - 1].relevant_type, "reliant_groups": mods[mods.size() - 1].relevant_group, "values": mods[mods.size() - 1].values, "effects": mods[mods.size() - 1].effects, "text": mods[mods.size() - 1].text, "localized_text": mods[mods.size() - 1].localized_text, "for_items": mods[mods.size() - 1].for_items}
								modded_fine_print_nums.push_back($"Landlord".total_fine_print + 6)
					"apartment_floor":
						if past_init:
							mod_data.symbols["apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)] = {"type": "apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num), "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": false, "art_replacement": false, "fine_print": false, "apartment_floor": true, "pack_num": mods[mods.size() - 1].pack_num}
							mod_pack_nums["apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id)] = str(f)
							mod_packs[f].push_back({"type": "apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id + "_PACK_" + str(mods[mods.size() - 1].pack_num)), "mod_type": "apartment_floor", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
							if not is_mod_disabled("apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)):
								if not modded_apartment_floors.has(str(mods[mods.size() - 1].type) + "_" + mods[mods.size() - 1].pack_num):
									modded_apartment_floors[str(mods[mods.size() - 1].type) + "_" + mods[mods.size() - 1].pack_num] = []
								if modded_apartment_floors[str(mods[mods.size() - 1].type) + "_" + mods[mods.size() - 1].pack_num].size() < mods[mods.size() - 1].floor_num:
									modded_apartment_floors[str(mods[mods.size() - 1].type) + "_" + mods[mods.size() - 1].pack_num].resize(mods[mods.size() - 1].floor_num)
								modded_apartment_floors[str(mods[mods.size() - 1].type) + "_" + mods[mods.size() - 1].pack_num][mods[mods.size() - 1].floor_num - 1] = "apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)
								apartment_floor_database["apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)] = mods[mods.size() - 1]
								apartment_floor_database["apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)]["author_id"] = str(mods[mods.size() - 1].author_id)
								apartment_floor_database["apartment_floor_" + str(mods[mods.size() - 1].type) + "_" + str(mods[mods.size() - 1].floor_num) + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)]["pack_num"] = str(mods[mods.size() - 1].pack_num)
					"inherited_effects":
						mod_pack_nums["inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = str(f)
						mod_data.symbols["inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = {"type": "inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "display_name": mods[mods.size() - 1].display_name, "author_id": mods[mods.size() - 1].author_id, "localized_names": mods[mods.size() - 1].localized_names, "inherit_art": false, "art_replacement": false, "fine_print": false, "apartment_floor": false, "pack_num": mods[mods.size() - 1].pack_num}
						mod_packs[f].push_back({"type": "inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f, "mod_type": "inherited_effects", "author_id": mods[mods.size() - 1].author_id, "pack_num": mods[mods.size() - 1].pack_num})
						if past_init and not is_mod_disabled("inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + str(mods[mods.size() - 1].pack_num)):
							for e in mods[mods.size() - 1].effects:
								if not inherited_effects_database.has("inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f):
									inherited_effects_database["inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f] = [e]
								else:
									inherited_effects_database["inherited_effects_" + mods[mods.size() - 1].type + "_STEAM_ID_" + str(mods[mods.size() - 1].author_id) + "_PACK_" + f].push_back(e)
	var tmp = preload("res://Slot Icon.tscn").instance()
	var tmp_i = preload("res://Item.tscn").instance()
	for m in mods:
		var fields = base_mod_fields
		var mod_fields = {}
		for f in fields.keys():
			mod_fields[f] = m[f]
		if mod_fields["inherit_description"] == null and mod_fields["inherit_effects"]:
			mod_fields["inherit_description"] = true
		mod_fields["author_id"] = str(mod_fields["author_id"])
		mod_fields.modded = true
		var bad_mod = false
		if past_init and is_mod_disabled(append_steam_id(m.type, m.author_id) + "_PACK_" + str(m.pack_num)):
			bad_mod = true
		for e in mod_fields["effects"]:
			if not e.has("comparisons"):
				e["comparisons"] = []
			if e.has("rarity_mod") and e.rarity_mod:
				mod_fields.groups.push_back("raritymod")
			elif e.has("capsule_effect") and e.capsule_effect and not mod_fields.groups.has("capsule"):
				mod_fields.groups.push_back("capsule")
			if e.has("value_to_change"):
				if e.value_to_change == "type" and e.has("diff") and typeof(e.diff) == TYPE_STRING:
					pass
				elif not check_valid_var(e.value_to_change, m.mod_type, tmp, tmp_i, e, m.mod_path, false, past_init):
					bad_mod = true
					break
			if e.has("comparisons"):
				var comp_num = 0
				for comp in e.comparisons:
					if not comp.has("a") or not check_valid_var(comp.a, m.mod_type, tmp, tmp_i, e, m.mod_path, false, past_init):
						bad_mod = true
						break
					if typeof(comp.a) == TYPE_STRING and (comp.a == "type" and typeof(comp.b) == TYPE_STRING and mod_data.symbols.has(comp.b)):
						e.comparisons[comp_num].b = append_steam_id(e.comparisons[comp_num].b, mod_data.symbols[comp.b].author_id)
					elif typeof(comp.a) == TYPE_STRING and comp.a == "groups" and mod_fields.groups.has(comp.b):
						e.comparisons[comp_num].b = append_steam_id(e.comparisons[comp_num].b, mod_fields.author_id)
					if comp.has("value_num") and mod_fields.has("inherit_effects") and mod_fields.inherit_effects:
						e.comparisons[comp_num].value_num += tile_db.result[mod_fields.type].values.size()
					for k in comp.keys():
						if typeof(comp[k]) == TYPE_DICTIONARY and comp[k].has("counted_symbols"):
							var c_id = comp[k].counted_symbols
							if past_init and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(comp[k].counted_symbols):
								c_id = append_steam_id(comp[k].counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id]) + "_PACK_" + str(mod_pack_nums[append_steam_id(comp[k].counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id])])
							counted_symbols[c_id] = 0
							e.comparisons[comp_num][k].counted_symbols = c_id
					comp_num += 1
			if e.has("tiles_to_add"):
				var t_num = 0
				for t in e.tiles_to_add:
					if typeof(t) == TYPE_DICTIONARY:
						if t.has("type") and mod_data.symbols.has(e.tiles_to_add[t_num].type):
							e.tiles_to_add[t_num].type = append_steam_id(e.tiles_to_add[t_num].type, mod_data.symbols[e.tiles_to_add[t_num].type].author_id)
						elif t.has("groups"):
							e.tiles_to_add[t_num].groups = append_steam_id(e.tiles_to_add[t_num].groups, str(mod_fields.author_id))
					t_num += 1
			if e.has("items_to_add"):
				var t_num = 0
				for t in e.items_to_add:
					var not_disabled = true
					var with_id = append_steam_id(e.items_to_add[t_num].type, str(mod_fields.author_id))
					if mod_pack_nums.has(with_id) and past_init:
						if is_mod_disabled(with_id + "_PACK_" + mod_pack_nums[with_id]):
							not_disabled = false
					if not_disabled:
						e.items_to_add[t_num].type = append_steam_id(e.items_to_add[t_num].type, str(mod_fields.author_id))
						t_num += 1
			if e.has("diff") and typeof(e.diff) == TYPE_DICTIONARY:
				if not check_valid_var(e.diff, m.mod_type, tmp, tmp_i, e, m.mod_path, false, past_init):
					bad_mod = true
					break
				elif e.diff.has("counted_symbols"):
					var c_id = e.diff.counted_symbols
					if past_init and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(e.diff.counted_symbols):
						c_id = append_steam_id(e.diff.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id]) + "_PACK_" + str(mod_pack_nums[append_steam_id(e.diff.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id])])
					counted_symbols[c_id] = 0
					e.diff.counted_symbols = c_id
		if bad_mod:
			continue
		var old_id = mod_fields.type
		mod_fields.type = mod_fields.type + "_STEAM_ID_" + str(mod_fields.author_id) + "_PACK_" + str(m.pack_num)
		match m.mod_type:
			"symbol", "existing_symbol":
				if mod_fields.keys().hash() == fields.keys().hash() and (not past_init or (past_init and not is_mod_disabled(append_steam_id(mod_fields.type, mod_fields.author_id) + "_PACK_" + str(m.pack_num)))):
					tile_db.result[mod_fields.type] = mod_fields
					if m.mod_type == "existing_symbol":
						if mod_fields.inherit_effects:
							for k in fields.keys():
								if k != "description" and k != "localized_descriptions" and k != "values" and k != "modded" and k != "inherit_effects" and k != "inherit_art" and k != "inherit_groups" and k != "type" and k != "groups" and tile_db.result[old_id].has(k) and mod_fields[k] == fields[k]:
									mod_fields[k] = tile_db.result[old_id][k]
							mod_fields.description = increase_string_values(m.description, tile_db.result[mod_fields.type].values.size())
							for l in mod_fields.localized_descriptions:
								l = increase_string_values(l, tile_db.result[mod_fields.type].values.size())
							mod_fields.values = tile_db.result[old_id].values + mod_fields.values
					if save_ids:
						$"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[old_id] = str(mod_fields.author_id)
					if past_init and mod_fields.count_at_start > 0 and not is_mod_disabled(old_id + "_STEAM_ID_" + str(mod_fields.author_id) + "_PACK_" + str(m.pack_num)):
						for n in range(mod_fields.count_at_start):
							starting.symbols.push_back(old_id + "_STEAM_ID_" + str(mod_fields.author_id) + "_PACK_" + str(m.pack_num))
					if m.mod_type == "existing_symbol":
						if mod_fields.inherit_art:
							icon_texture_database[append_steam_id(mod_fields.type, mod_fields.author_id)] = load("res://icons/" + old_id + ".png")
						if mod_fields.inherit_groups:
							mod_fields.groups += tile_db.result[old_id].groups
						var with_id = old_id + "_STEAM_ID_" + str(mod_fields.author_id)
						if modded_existing.symbols.has(mod_fields.type):
							modded_existing.symbols[mod_fields.type].push_back(mod_fields)
						else:
							modded_existing.symbols[mod_fields.type] = [mod_fields]
							if past_init and not $"Options Sprite/Options".disabled_mods.has(with_id + "_PACK_" + str(m.pack_num)):
								existing_symbols[old_id] = with_id + "_PACK_" + str(m.pack_num)
						if modded_existing_base_types.symbols.has(old_id):
							modded_existing_base_types.symbols[old_id].push_back(with_id + "_PACK_" + str(m.pack_num))
						else:
							modded_existing_base_types.symbols[old_id] = [with_id + "_PACK_" + str(m.pack_num)]
			"item", "existing_item":
				var db = item_db
				if mod_fields.rarity == "essence":
					db = essence_db
				if mod_fields.keys().hash() == fields.keys().hash():
					db.result[mod_fields.type] = mod_fields
					if m.mod_type == "existing_item":
						if mod_fields.inherit_effects:
							for k in fields.keys():
								if k != "description" and k != "localized_descriptions" and k != "values" and k != "modded" and k != "inherit_effects" and k != "inherit_art" and k != "inherit_groups" and k != "type" and db.result[old_id].has(k) and mod_fields[k] == fields[k]:
									mod_fields[k] = db.result[old_id][k]
							mod_fields.description = increase_string_values(m.description, db.result[mod_fields.type].values.size())
							for l in mod_fields.localized_descriptions:
								l = increase_string_values(l, db.result[mod_fields.type].values.size())
							mod_fields.values = db.result[old_id].values + mod_fields.values
					if save_ids:
						$"Pop-up Sprite/Pop-up".saved_mod_ids.items[old_id] = mod_fields.author_id
					if past_init and mod_fields.count_at_start > 0 and not is_mod_disabled(old_id + "_STEAM_ID_" + str(mod_fields.author_id) + "_PACK_" + str(m.pack_num)):
						for n in range(mod_fields.count_at_start):
							starting.items.push_back(old_id + "_STEAM_ID_" + str(mod_fields.author_id) + "_PACK_" + str(m.pack_num))
					if m.mod_type == "existing_item":
						if mod_fields.inherit_art:
							icon_texture_database[mod_fields.type] = load("res://icons/" + old_id + ".png")
						if mod_fields.inherit_groups:
							mod_fields.groups += db.result[old_id].groups
						var with_id = old_id + "_STEAM_ID_" + str(mod_fields.author_id)
						if modded_existing.items.has(mod_fields.type):
							modded_existing.items[mod_fields.type].push_back(mod_fields)
						else:
							modded_existing.items[mod_fields.type] = [mod_fields]
							if past_init and not $"Options Sprite/Options".disabled_mods.has(with_id + "_PACK_" + str(m.pack_num)):
								existing_items[old_id] = with_id + "_PACK_" + mod_pack_nums[with_id]
						if modded_existing_base_types.items.has(old_id):
							modded_existing_base_types.items[old_id].push_back(with_id + "_PACK_" + str(m.pack_num))
						else:
							modded_existing_base_types.items[old_id] = [with_id + "_PACK_" + str(m.pack_num)]
	tmp.queue_free()
	tmp_i.queue_free()
	
	for s in sfx_dirs:
		var sfx_dir = Directory.new()
		sfx_dir.open(s)
		sfx_dir.list_dir_begin()
		
		while true:
			var sfx = sfx_dir.get_next()
			if sfx == "":
				break
			elif not sfx.begins_with(".") and sfx.substr(sfx.length() - 4, -1) == ".wav":
				var sfx_type = sfx.substr(0, sfx.length() - 5)
				if not sfx_database.has(sfx_type):
					sfx_database[sfx_type] = 1
				else:
					sfx_database[sfx_type] += 1
				modded_sfx_paths[sfx_type] = s
	
	if past_init:
		for s in modded_existing.symbols.keys():
			if not is_mod_disabled(s):
				if past_init and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(s):
					for i in modded_existing.symbols[s]:
						if i.author_id == $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[s]:
							tile_db.result[append_steam_id(s, i.author_id)] = i
			else:
				for a in modded_existing.symbols[s]:
					var t = a.type
					modded_existing_base_types.symbols[t.substr(0, t.find("_STEAM_ID_"))].erase(t)
					if modded_existing_base_types.symbols[t.substr(0, t.find("_STEAM_ID_"))].size() == 0:
						modded_existing_base_types.symbols.erase(t.substr(0, t.find("_STEAM_ID_")))
	
	for a in tile_db.result:
		if tile_db.result[a].has("author_id") and typeof(a) == TYPE_DICTIONARY:
			var h = append_steam_id(a.type, tile_db.result[a].author_id)
			if past_init and not is_mod_disabled(h):
				tile_db.result[h] = tile_db.result[a].duplicate(true)
	
	for a in tile_db.result:
		var t = a
		if typeof(a) == TYPE_DICTIONARY:
			t = a.type
		if not tile_db.result.has(t):
			continue
		if not tile_db.result[t].has("modded") or (tile_db.result[t].has("modded") and not tile_db.result[t].modded) and not base_types.symbols.has(t):
			base_types.symbols.push_back(t)
		if tile_db.result[a].has("author_id"):
			t = append_steam_id(a, tile_db.result[a].author_id)
		elif tile_db.result[t].has("modded") and tile_db.result[t].modded:
			t = append_steam_id(a, steam_id)
		if past_init and mod_pack_nums.has(t):
			t += "_PACK_" + mod_pack_nums[t]
		if past_init and $"Options Sprite/Options".disabled_mods.has(t):
			if existing_symbols.has(t):
				existing_symbols.erase(t)
			continue
		tile_db.result[t] = tile_db.result[a]
		if tile_db.result[t].rarity == null:
			tile_db.result[t].rarity = "none"
		if not tile_db.result[t].has("modded"):
			tile_db.result[t]["modded"] = false
		rarity_database["symbols"][tile_db.result[t].rarity].push_back(t)
		for g in tile_db.result[t].groups:
			if not tile_db.result[t].modded or (past_init and tile_db.result[t].modded and is_mod_disabled(t)):
				if not group_database["symbols"].has(g):
					group_database["symbols"][g] = []
				group_database["symbols"][g].push_back(t)
			else:
				if not mod_groups["symbols"].has(g):
					mod_groups["symbols"][g] = []
				mod_groups["symbols"][g].push_back(t)
		tile_database[t] = tile_db.result[t]
		tile_database[t]["type"] = str(t)
		if past_init and (not tile_database[t].modded or (tile_database[t].modded)) and not existing_symbols.has(t):
			existing_symbols[t] = str(t)
		var t_id = str(t)
		if not icon_texture_database.has(t_id):
			if t_id.find("_STEAM_ID_") == -1:
				icon_texture_database[t_id] = load("res://icons/%s.png" % str(t))
				if icon_texture_database[t_id] == null:
					icon_texture_database[t_id] = preload("res://icons/missing.png")
			else:
				icon_texture_database[t_id] = preload("res://icons/missing.png")
		if tile_db.result[t].has("modded") and tile_db.result[t]["modded"] and past_init and not is_mod_disabled(t):
			for e in tile_db.result[t].effects:
				if e.has("effect_type") and e.effect_type == "reverse_adjacent_symbol":
					if e.has("reverse_groups"):
						mod_reverse_effects.push_back({"groups": e.reverse_groups, "eff": e})
					elif e.has("reverse_type"):
						mod_reverse_effects.push_back({"type": e.reverse_type, "eff": e})
	if not group_database["symbols"].has("spawner1"):
		group_database["symbols"]["spawner1"] = []

	if past_init:
		for t in modded_existing.symbols:
			if not is_mod_disabled(t) and tile_database.has(t.substr(0, t.find("_STEAM_ID_"))):
				for g in tile_database[t.substr(0, t.find("_STEAM_ID_"))].groups:
					group_database.symbols[g].erase(t.substr(0, t.find("_STEAM_ID_")))
				for r in rarity_database.symbols.keys():
					rarity_database.symbols[r].erase(t.substr(0, t.find("_STEAM_ID_")))
				tile_database.erase(t.substr(0, t.find("_STEAM_ID_")))
		for s in modded_existing.items.keys():
			if not is_mod_disabled(s):
				if $"Pop-up Sprite/Pop-up".saved_mod_ids.items.has(s):
					for i in modded_existing.items[s]:
						if i.author_id == $"Pop-up Sprite/Pop-up".saved_mod_ids.items[s]:
							item_db.result[append_steam_id(s, i.author_id)] = i
			else:
				for a in modded_existing.items[s]:
					var i = a.type
					modded_existing_base_types.items[i.substr(0, i.find("_STEAM_ID_"))].erase(i)
					if modded_existing_base_types.items[i.substr(0, i.find("_STEAM_ID_"))].size() == 0:
						modded_existing_base_types.items.erase(i.substr(0, i.find("_STEAM_ID_")))

	for a in item_db.result:
		if item_db.result[a].has("author_id") and typeof(a) == TYPE_DICTIONARY and a.type.find("_STEAM_ID_") == -1:
			var h = append_steam_id(a.type, item_db.result[a].author_id)
			if past_init:
				if not is_mod_disabled(h):
					item_db.result[h] = item_db.result[a].duplicate(true)

	for a in item_db.result:
		var i = a
		if typeof(a) == TYPE_DICTIONARY:
			i = a.type
			if past_init and $"Options Sprite/Options".disabled_mods.has(i):
				continue
		if not item_db.result.has(i):
			continue
		if not item_db.result[i].has("modded") or (item_db.result[i].has("modded") and not item_db.result[i].modded) and not base_types.items.has(i):
			base_types.items.push_back(i)
		if item_db.result[i].has("author_id"):
			i = append_steam_id(i, item_db.result[i].author_id)
		if past_init and mod_pack_nums.has(i):
			i += "_PACK_" + mod_pack_nums[i]
		if past_init and $"Options Sprite/Options".disabled_mods.has(i):
			if existing_items.has(i):
				existing_items.erase(i)
			continue
		item_db.result[i] = item_db.result[a]
		if item_db.result[i].rarity == null:
			item_db.result[i].rarity = "none"
		if not item_db.result[i].has("modded"):
			item_db.result[i]["modded"] = false
		rarity_database["items"][item_db.result[i].rarity].push_back(i)
		for g in item_db.result[i].groups:
			if item_db.result[i].modded or (past_init and item_db.result[i].modded and is_mod_disabled(i)):
				if not group_database["items"].has(g):
					group_database["items"][g] = []
				group_database["items"][g].push_back(i)
			else:
				if not mod_groups["items"].has(g):
					mod_groups["items"][g] = []
				mod_groups["items"][g].push_back(i)
		item_database[i] = item_db.result[i]
		item_database[i]["type"] = str(i)
		if past_init and not existing_items.has(i):
			existing_items[i] = str(i)
		var i_id = str(i)
		if not icon_texture_database.has(i_id):
			if i_id.find("_STEAM_ID_") == -1:
				icon_texture_database[i_id] = load("res://icons/%s.png" % str(i))
				if icon_texture_database[i_id] == null:
					icon_texture_database[i_id] = preload("res://icons/item_missing.png")
			else:
				icon_texture_database[i_id] = preload("res://icons/item_missing.png")
		if item_db.result[i].has("modded") and item_db.result[i]["modded"]:
			for e in item_db.result[i].effects:
				if e.has("comparisons"):
					for comp in e.comparisons:
						if typeof(comp.a) == TYPE_STRING and comp.a == "multiple_of":
							mod_multiple_effects.push_back({"type": item_db.result[i].type, "eff": e})
							break
				if e.has("effect_type"):
					if e.effect_type == "item_added":
						mod_on_item_add_effects.push_back({"type": item_db.result[i].type, "eff": e})
					elif e.effect_type == "symbol_added":
						mod_on_symbol_add_effects.push_back({"type": item_db.result[i].type, "eff": e})
					elif e.effect_type == "rent_paid":
						mod_on_rent_paid_effects.push_back({"type": item_db.result[i].type, "eff": e})
	
	for a in essence_db.result:
		var i = a
		if typeof(a) == TYPE_DICTIONARY:
			i = a.type
			if past_init and $"Options Sprite/Options".disabled_mods.has(i + "_STEAM_ID_" + str(a.author_id) + "_PACK_" + str(a.pack_num)):
				continue
		if not essence_db.result.has(i):
			continue
		if not essence_db.result[i].has("modded") or (essence_db.result[i].has("modded") and not essence_db.result[i].modded) and not base_types.items.has(i):
			base_types.items.push_back(i)
		var with_id = i
		if essence_db.result[a].has("author_id"):
			i = append_steam_id(a, essence_db.result[a].author_id)
		if past_init and mod_pack_nums.has(i):
			i += "_PACK_" + mod_pack_nums[i]
		if past_init and $"Options Sprite/Options".disabled_mods.has(i):
			if existing_items.has(i):
				existing_items.erase(i)
			continue
		essence_db.result[i] = essence_db.result[a]
		if essence_db.result[i].rarity == null:
			essence_db.result[i].rarity = "none"
		if not essence_db.result[i].has("modded"):
			essence_db.result[i]["modded"] = false
		rarity_database["items"][essence_db.result[i].rarity].push_back(i)
		for g in essence_db.result[i].groups:
			if not essence_db.result[i].modded or (past_init and essence_db.result[i].modded and is_mod_disabled(i)):
				if not group_database["items"].has(g):
					group_database["items"][g] = []
				group_database["items"][g].push_back(i)
			else:
				if not mod_groups["items"].has(g):
					mod_groups["items"][g] = []
				mod_groups["items"][g].push_back(i)
		item_database[i] = essence_db.result[i]
		item_database[i]["type"] = str(i)
		if not item_database[i].modded or (item_database[i].modded) and not existing_items.has(i):
			existing_items[i] = str(i)
		if not icon_texture_database.has(str(i)):
			if str(i).find("_STEAM_ID_") == -1:
				icon_texture_database[str(i)] = load("res://icons/%s.png" % str(i))
				if icon_texture_database[str(i)] == null:
					icon_texture_database[str(i)] = preload("res://icons/item_missing.png")
			else:
				icon_texture_database[str(i)] = preload("res://icons/item_missing.png")
		if essence_db.result[i].has("modded") and essence_db.result[i]["modded"]:
			for e in essence_db.result[i].effects:
				if e.has("comparisons"):
					for comp in e.comparisons:
						if typeof(comp.a) == TYPE_STRING and comp.a == "multiple_of":
							mod_multiple_effects.push_back({"type": essence_db.result[i].type, "eff": e})
							break
				if e.has("effect_type"):
					if e.effect_type == "item_added":
						mod_on_item_add_effects.push_back({"type": item_db.result[i].type, "eff": e})
					elif e.effect_type == "symbol_added":
						mod_on_symbol_add_effects.push_back({"type": item_db.result[i].type, "eff": e})
					elif e.effect_type == "rent_paid":
						mod_on_rent_paid_effects.push_back({"type": item_db.result[i].type, "eff": e})

	if past_init:
		for i in modded_existing.items:
			if not is_mod_disabled(i) and item_database.has(i.substr(0, i.find("_STEAM_ID_"))):
				for g in item_database[i.substr(0, i.find("_STEAM_ID_"))].groups:
					group_database.items[g].erase(i.substr(0, i.find("_STEAM_ID_")))
				for r in rarity_database.items.keys():
					rarity_database.items[r].erase(i.substr(0, i.find("_STEAM_ID_")))
				item_database.erase(i.substr(0, i.find("_STEAM_ID_")))

	for i in fine_print_db.result:
		if not fine_print_db.result.has(i):
			continue
		fine_print_database[i] = fine_print_db.result[i]
		fine_print_database[i]["fine_print_num"] = str(i)
	
	if past_init:
		$"Reels".do_counted_symbols()
	
	for g in mod_groups.symbols.keys():
		if group_database.symbols.has(append_steam_id(g, steam_id)):
			group_database.symbols[append_steam_id(g, steam_id)] += mod_groups.symbols[g]
		else:
			group_database.symbols[append_steam_id(g, steam_id)] = mod_groups.symbols[g]
	
	for g in mod_groups.items.keys():
		if group_database.items.has(append_steam_id(g, steam_id)):
			group_database.items[append_steam_id(g, steam_id)] += mod_groups.items[g]
		else:
			group_database.items[append_steam_id(g, steam_id)] = mod_groups.items[g]
	
	base_rarities = rarity_database.duplicate(true)
	
	var sfx_dir = Directory.new()
	sfx_dir.open("res://sfx/")
	sfx_dir.list_dir_begin()
	
	while true:
		var sfx_file = sfx_dir.get_next()
		if sfx_file == "":
			break
		elif not sfx_file.begins_with(".") and sfx_file.substr(sfx_file.length() - 4, -1) == ".wav":
			var sfx_type = sfx_file.substr(0, sfx_file.length() - 5)
			
			if not sfx_database.has(sfx_type):
				sfx_database[sfx_type] = 1
			else:
				sfx_database[sfx_type] += 1
	
	for a in art_dirs:
		var art_dir = Directory.new()
		art_dir.open(a)
		art_dir.list_dir_begin()
		while true:
			var art = art_dir.get_next()
			if art == "":
				break
			elif not art.begins_with(".") and art.substr(art.length() - 4, -1) == ".png":
				var art_name = (str(art).substr(0, str(art).length() - 4)).substr(0, art.find("_STEAM_ID_"))
				var id = art.substr(art.find("_STEAM_ID_") + 10, -1)
				var img = Image.new()
				var no_pack_id
				if art.find("_STEAM_ID_") == -1:
					id = "_STEAM_ID_0"
				else:
					id = "_STEAM_ID_" + id.substr(0, id.length() - 4)
				no_pack_id = id
				if mod_pack_nums.has(art_name + id):
					id += "_PACK_" + mod_pack_nums[art_name + id]
				img.load(a + art)
				var texture = ImageTexture.new()
				texture.create_from_image(img)
				texture.set_flags(2)
				icon_texture_database[art_name + id] = texture
	var replaced_symbol_textures = []
	if is_inside_tree():
		for m in mod_data.symbols:
			if is_mod_disabled(mod_data.symbols[m].type) and mod_data.symbols[m].art_replacement:
				icon_texture_database[mod_data.symbols[m].type.substr(0, "_" + str(mod_data.symbols[m].pack_num)) + "_STEAM_ID_" + str(mod_data.symbols[m].author_id) + "_PACK_" + str(mod_data.symbols[m].pack_num)] = load("res://icons/%s.png" % str(m))
			elif mod_data.symbols[m].art_replacement:
				replaced_symbol_textures.push_back(mod_data.symbols[m].type.substr(0, mod_data.symbols[m].type.find_last("_")))
		for m in mod_data.items:
			if is_mod_disabled(mod_data.items[m].type) and mod_data.items[m].art_replacement:
				icon_texture_database[mod_data.items[m].type.substr(0, "_" + str(mod_data.items[m].pack_num)) + "_STEAM_ID_" + str(mod_data.items[m].author_id) + "_PACK_" + str(mod_data.items[m].pack_num)] = load("res://icons/%s.png" % str(m))
	
	icon_texture_database["confirm"] = preload("res://icons/confirm.png")
	icon_texture_database["deny"] = preload("res://icons/deny.png")
	icon_texture_database["squiggle"] = preload("res://icons/squiggle.png")
	icon_texture_database["speaker"] = preload("res://icons/speaker.png")
	icon_texture_database["speaker_muted"] = preload("res://icons/speaker_muted.png")
	icon_texture_database["left"] = preload("res://icons/left.png")
	icon_texture_database["right"] = preload("res://icons/right.png")
	icon_texture_database["down"] = preload("res://icons/down.png")
	icon_texture_database["reroll_token"] = preload("res://icons/reroll_token.png")
	icon_texture_database["removal_token"] = preload("res://icons/removal_token.png")
	icon_texture_database["essence_token"] = preload("res://icons/essence_token.png")
	icon_texture_database["dpad_down"] = preload("res://icons/dpad_down.png")
	icon_texture_database["dpad_left"] = preload("res://icons/dpad_left.png")
	icon_texture_database["dpad_right"] = preload("res://icons/dpad_right.png")
	icon_texture_database["dpad_up"] = preload("res://icons/dpad_up.png")
	icon_texture_database["leftstick_click"] = preload("res://icons/leftstick_click.png")
	icon_texture_database["leftstick_down"] = preload("res://icons/leftstick_down.png")
	icon_texture_database["leftstick_left"] = preload("res://icons/leftstick_left.png")
	icon_texture_database["leftstick_right"] = preload("res://icons/leftstick_right.png")
	icon_texture_database["leftstick_up"] = preload("res://icons/leftstick_up.png")
	icon_texture_database["ps_circle"] = preload("res://icons/ps_circle.png")
	icon_texture_database["ps_cross"] = preload("res://icons/ps_cross.png")
	icon_texture_database["ps_l1"] = preload("res://icons/ps_l1.png")
	icon_texture_database["ps_l2"] = preload("res://icons/ps_l2.png")
	icon_texture_database["ps_r1"] = preload("res://icons/ps_r1.png")
	icon_texture_database["ps_r2"] = preload("res://icons/ps_r2.png")
	icon_texture_database["ps_select"] = preload("res://icons/ps_select.png")
	icon_texture_database["ps_square"] = preload("res://icons/ps_square.png")
	icon_texture_database["ps_start"] = preload("res://icons/ps_start.png")
	icon_texture_database["ps_triangle"] = preload("res://icons/ps_triangle.png")
	icon_texture_database["rightstick_click"] = preload("res://icons/rightstick_click.png")
	icon_texture_database["rightstick_down"] = preload("res://icons/rightstick_down.png")
	icon_texture_database["rightstick_left"] = preload("res://icons/rightstick_left.png")
	icon_texture_database["rightstick_right"] = preload("res://icons/rightstick_right.png")
	icon_texture_database["rightstick_up"] = preload("res://icons/rightstick_up.png")
	icon_texture_database["switch_minus"] = preload("res://icons/switch_minus.png")
	icon_texture_database["switch_plus"] = preload("res://icons/switch_plus.png")
	icon_texture_database["switch_zl"] = preload("res://icons/switch_zl.png")
	icon_texture_database["switch_zr"] = preload("res://icons/switch_zr.png")
	icon_texture_database["xbox_A"] = preload("res://icons/xbox_A.png")
	icon_texture_database["xbox_B"] = preload("res://icons/xbox_B.png")
	icon_texture_database["xbox_X"] = preload("res://icons/xbox_X.png")
	icon_texture_database["xbox_Y"] = preload("res://icons/xbox_Y.png")
	icon_texture_database["switch_A"] = preload("res://icons/switch_A.png")
	icon_texture_database["switch_B"] = preload("res://icons/switch_B.png")
	icon_texture_database["switch_X"] = preload("res://icons/switch_X.png")
	icon_texture_database["switch_Y"] = preload("res://icons/switch_Y.png")
	icon_texture_database["xbox_lb"] = preload("res://icons/xbox_lb.png")
	icon_texture_database["xbox_lt"] = preload("res://icons/xbox_lt.png")
	icon_texture_database["xbox_rb"] = preload("res://icons/xbox_rb.png")
	icon_texture_database["xbox_rt"] = preload("res://icons/xbox_rt.png")
	icon_texture_database["xbox_select"] = preload("res://icons/xbox_select.png")
	icon_texture_database["xbox_start"] = preload("res://icons/xbox_start.png")
	icon_texture_database["switch_l"] = preload("res://icons/switch_l.png")
	icon_texture_database["switch_r"] = preload("res://icons/switch_r.png")
	icon_texture_database["ps_touchpad"] = preload("res://icons/ps_touchpad.png")
	icon_texture_database["invis"] = preload("res://icons/invis.png")
	icon_texture_database["hp"] = preload("res://icons/hp.png")
	for i in range(186):
		icon_texture_database["a" + str(i + 1)] = load("res://icons/a" + str(i + 1) + ".png")
		icon_texture_database["a" + str(i + 1) + "-L"] = load("res://icons/a" + str(i + 1) + "-L.png")
		non_symbol_icons.push_back("a" + str(i + 1))
		non_symbol_icons.push_back("a" + str(i + 1) + "-L")
	
	for i in range(1, 9):
		if not replaced_symbol_textures.has("bronze_arrow" + str(i)):
			icon_texture_database["bronze_arrow" + str(i)] = load("res://icons/" + "bronze_arrow" + str(i) + ".png")
		if not replaced_symbol_textures.has("silver_arrow" + str(i)):
			icon_texture_database["silver_arrow" + str(i)] = load("res://icons/" + "silver_arrow" + str(i) + ".png")
		if not replaced_symbol_textures.has("golden_arrow" + str(i)):
			icon_texture_database["golden_arrow" + str(i)] = load("res://icons/" + "golden_arrow" + str(i) + ".png")
			
	group_database["symbols"]["passed"] = ["coin"]
	group_database["symbols"]["taken"] = []
	
	if past_init:
		for i in modded_fine_print_nums:
			if not $"Landlord".possible_fine_print.has(i):
				$"Landlord".possible_fine_print.push_back(i)
		if typeof($"Pop-up Sprite/Pop-up".current_modded_floor) == TYPE_STRING and apartment_floor_database.has("apartment_floor_" + $"Pop-up Sprite/Pop-up".current_modded_floor):
			$"Pop-up Sprite/Pop-up".modded_floor_string = $"Pop-up Sprite/Pop-up".current_modded_floor
			$"Pop-up Sprite/Pop-up".current_modded_floor = apartment_floor_database["apartment_floor_" + $"Pop-up Sprite/Pop-up".current_modded_floor]
		for t in base_types.symbols:
			if is_mod_disabled(t) and tile_database.has(t):
				for g in tile_database[t].groups:
					group_database.symbols[g].erase(t)
		for i in base_types.items:
			if is_mod_disabled(i) and item_database.has(i):
				for g in item_database[i].groups:
					group_database.items[g].erase(i)

func load_mods():
	var mod_num = 0
	if not demo:
		for m in tile_database:
			if tile_database[m].modded:
				if not is_mod_disabled(m):
					mod_num += 1
				for g in range(tile_database[m].groups.size()):
					tile_database[m].groups[g] = append_steam_id(tile_database[m].groups[g], tile_database[m].author_id)
				$"Pop-up Sprite/Pop-up".mods.symbols.push_back(tile_database[m])
		for m in item_database:
			if item_database[m].modded:
				for g in range(item_database[m].groups.size()):
					if not is_mod_disabled(m):
						mod_num += 1
					item_database[m].groups[g] = append_steam_id(item_database[m].groups[g], item_database[m].author_id)
				$"Pop-up Sprite/Pop-up".mods.items.push_back(item_database[m])
	$"Pop-up Sprite/Pop-up".modded_run = (mod_num != 0)

func load_game():
	var save_game = File.new()
	if not save_game.file_exists(save_string):
		return
	
	save_game.open(save_string, File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		
		if node_data == null:
			continue
		
		var n = get_node(node_data["path"])
		
		if n != null:
			for i in node_data.keys():
				if i == "path" or i == "pos_x" or i == "pos_y":
					continue
				elif i == "essences_unlocked" or i == "highest_unlocked_floor" or i == "saved_ll_fate" or i == "landlord_fates_seen" or i == "landlord_fates_not_seen":
					$"Stats Sprite/Stats"[i] = node_data[i]
					save_stats()
				n.set(i, node_data[i])
	save_game.close()
	
	for r in $"Reels".reels:
		if r.spinning:
			$"Reels".spin()
			break
	
	match int($"Pop-up Sprite/Pop-up".times_rent_paid):
		0:
			pass
		1:
			rarity_chances = { "symbols": { "uncommon": 0.1, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
		2:
			rarity_chances = { "symbols": { "uncommon": 0.2, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.1, "rare": 0, "very_rare": 0 } }
		3:
			rarity_chances = { "symbols": { "uncommon": 0.25, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.2, "rare": 0.025, "very_rare": 0 } }
		4:
			rarity_chances = { "symbols": { "uncommon": 0.29, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.25, "rare": 0.025, "very_rare": 0 } }
		5:
			rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.3, "rare": 0.0375, "very_rare": 0.0125 } }
		_:
			rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.375, "rare": 0.05, "very_rare": 0.015 } }

func load_options():
	var save_game = File.new()
	if not save_game.file_exists("user://LBAL-Settings.save"):
		return
	
	var has_colors = false
	
	save_game.open("user://LBAL-Settings.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		
		var n = get_node(node_data["path"])
		
		if n != null:
			for i in node_data.keys():
				if i == "path" or i == "pos_x" or i == "pos_y":
					continue
				if OS.get_name() == "OSX" and i == "bordered_window":
					n.set(i, false)
				elif i == "hotkeys":
					for key in $"Options Sprite/Options".hotkeys.keys():
						if not node_data[i].has(key):
							node_data[i][key] = $"Options Sprite/Options".hotkeys[key]
					n.set(i, node_data[i])
				else:
					if i == "colors3":
						has_colors = true
					n.set(i, node_data[i])
					for k in $"Options Sprite/Options".default_colors.keys():
						if not $"Options Sprite/Options".colors3.has(k):
							$"Options Sprite/Options".colors3[k] = $"Options Sprite/Options".default_colors[k]
	save_game.close()
	if not has_colors:
		save_options()

func load_stats():
	var save_game = File.new()
	if not save_game.file_exists("user://LBAL-Stats.save"):
		if save_game.file_exists("user://LBAL-Stats.bak"):
			var dir = Directory.new()
			dir.open("user://LBAL-Stats.bak")
			dir.copy("user://LBAL-Stats.bak", "user://LBAL-Stats.save")
			load_stats()
		return
		
	save_game.open("user://LBAL-Stats.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		
		if node_data == null and save_game.file_exists("user://LBAL-Stats.bak"):
			var dir = Directory.new()
			dir.open("user://LBAL-Stats.bak")
			dir.copy("user://LBAL-Stats.bak", "user://LBAL-Stats.save")
			load_stats()
			break
		
		var n = get_node(node_data["path"])
		
		if n != null:
			for i in node_data.keys():
				if i == "path" or i == "pos_x" or i == "pos_y":
					continue
				n.set(i, node_data[i])
				if i == "achievements_unlocked":
					node_data[i].resize(186)
	save_game.close()
	
	if demo:
		$"Stats Sprite/Stats".stats_unlocked = false
	else:
		var total_games_won = $"Stats Sprite/Stats".get_converted_stat("total_games_won", "all")
		var total_executions = $"Stats Sprite/Stats".get_converted_stat("times_executed", "all")
		for a in range(1, $"Stats Sprite/Stats".total_games_won.size()):
			if $"Stats Sprite/Stats".total_games_won[a] != null and $"Stats Sprite/Stats".total_games_won[a] > 0:
				$"Stats Sprite/Stats".unlock_achievement(149 + a, true)
		if total_games_won >= 5:
			$"Stats Sprite/Stats".unlock_achievement(170, true)
		if total_games_won >= 10:
			$"Stats Sprite/Stats".unlock_achievement(171, true)
		if total_games_won >= 25:
			$"Stats Sprite/Stats".unlock_achievement(172, true)
		if total_games_won >= 50:
			$"Stats Sprite/Stats".unlock_achievement(173, true)
		if total_games_won >= 100:
			$"Stats Sprite/Stats".unlock_achievement(174, true)
		if total_games_won >= 250:
			$"Stats Sprite/Stats".unlock_achievement(175, true)
		if total_games_won >= 500:
			$"Stats Sprite/Stats".unlock_achievement(176, true)
		if total_games_won >= 777:
			$"Stats Sprite/Stats".unlock_achievement(177, true)
		if total_executions >= 1:
			$"Stats Sprite/Stats".unlock_achievement(65, true)
		if total_executions >= 2:
			$"Stats Sprite/Stats".unlock_achievement(178, true)
		if total_executions >= 3:
			$"Stats Sprite/Stats".unlock_achievement(179, true)
		if total_executions >= 4:
			$"Stats Sprite/Stats".unlock_achievement(180, true)
		if total_executions >= 5:
			$"Stats Sprite/Stats".unlock_achievement(181, true)
		if total_executions >= 10:
			$"Stats Sprite/Stats".unlock_achievement(182, true)
		if total_executions >= 25:
			$"Stats Sprite/Stats".unlock_achievement(183, true)
		if total_executions >= 50:
			$"Stats Sprite/Stats".unlock_achievement(184, true)
		if total_executions >= 77:
			$"Stats Sprite/Stats".unlock_achievement(185, true)
		if $"Stats Sprite/Stats".get_converted_stat("landlord_executions", "all") > 0:
			$"Stats Sprite/Stats".unlock_achievement(83, true)
		if $"Stats Sprite/Stats".get_converted_stat("humans_murdered_by_general_zaroff", "all") >= 1924:
			 $"Stats Sprite/Stats".unlock_achievement(59, true)
		if $"Stats Sprite/Stats".get_converted_stat("billionaires_guillotined", "all") >= 500:
			$"Stats Sprite/Stats".unlock_achievement(15, true)
		if $"Stats Sprite/Stats".get_converted_stat("rabbit_hops", "all") >= 1000:
			$"Stats Sprite/Stats".unlock_achievement(113, true)
		if $"Stats Sprite/Stats".get_converted_stat("time_spent_petting_dog", "all") >= 1:
			 $"Stats Sprite/Stats".unlock_achievement(47, true)
		if ($"Stats Sprite/Stats".get_converted_stat("rabbit_fluff_shed", "all") >= 3 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ko")) or ($"Stats Sprite/Stats".get_converted_stat("rabbit_fluff_shed", "all") >= 1.73 and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko"):
			 $"Stats Sprite/Stats".unlock_achievement(114, true)
		if ($"Stats Sprite/Stats".get_converted_stat("alcohol_consumed", "all") >= 50 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ko")) or ($"Stats Sprite/Stats".get_converted_stat("alcohol_consumed", "all") >= 189.3 and TranslationServer.get_locale() != "en" and TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "ko"):
			 $"Stats Sprite/Stats".unlock_achievement(147, true)

func get_rarity(db, type):
	for k in db.keys():
		if db[k].has(type):
			return k

func get_last_tab_or_space(string):
	var num = string.length() - 1
	while num > 0 and string[num] != " " and string[num] != "	":
		num -= 1
	return num + 1

func check_for_allowed_function(file_text, inc):
	var good = false
	for f in []:
		if file_text.substr(inc - f.length(), inc - (inc - f.length())) == f:
			good = true
			break
	return good

func malicious_mod(path, m):
	if m.substr(m.length() - 3, -1) != ".gd":
		return true
	var dir = Directory.new()
	dir.open(path)
	dir.remove(path + m.substr(0, m.length() - 2) + "txt")
	dir.copy(path + m, path + m.substr(0, m.length() - 2) + "txt")
	
	var file = File.new()
	
	file.open(path + m.substr(0, m.length() - 2) + "txt", File.READ)
	
	var quoted = false
	var uhoh = false
	var arrays = []
	var dictionaries = []
	var parenthesis = []
	var invalid_variable = false
	var key = ""
	
	var inc = 0
	var last_char = ""
	
	var file_text = file.get_as_text()
	
	var spaces_in_a_row = 0
	
	var spaces = false
	var tabs = false
	
	for s in file_text:
		if s == " " and not quoted:
			inc += 1
			spaces_in_a_row += 1
			if spaces_in_a_row >= 4:
				spaces = true
				if tabs:
					break
			continue
		elif not quoted and s == "	":
			tabs = true
			if spaces:
				break
		elif not quoted:
			spaces_in_a_row = 0
		
		if s == "\"" and last_char != "\\":
			quoted = !quoted
		elif s == "(" and not (check_for_allowed_function(file_text, inc) or file_text.substr(inc - 10, 13) == "func _init():") and not quoted:
			uhoh = true
		elif uhoh and not quoted and s == ")":
			break
		elif s == "[" and not quoted:
			arrays.push_back(inc)
		elif s == "]" and not quoted:
			arrays.pop_back()
		elif s == "{" and not quoted:
			dictionaries.push_back(inc)
		elif s == "}" and not quoted:
			dictionaries.pop_back()
		elif s == "(" and not quoted:
			parenthesis.push_back(inc)
		elif s == ")" and not quoted:
			parenthesis.pop_back()
		elif not quoted and s == "=" and last_char != "=":
			var offset = 0
			while inc - offset > 0 and file_text[inc - offset - 1] == " ":
				offset += 1
			key = file_text.substr(get_last_tab_or_space(file_text.substr(0, inc - offset)), inc - get_last_tab_or_space(file_text.substr(0, inc - offset)) - 1)
			if not base_mod_fields.keys().has(key) and key != "mod_type":
				invalid_variable = true
				break
		last_char = s
		inc += 1
	
	file.close()
	
	dir.remove(path + m.substr(0, m.length() - 2) + "txt")
	
	if uhoh:
		display_error(null, "Potentially malcious code detected in " + path + m + ", Mod was not loaded.")
	elif tabs and spaces:
		display_error(null, "Mixed tabs and spaces detected in " + path + m + ", Mod was not loaded.")
	elif quoted or arrays.size() > 0 or dictionaries.size() > 0 or parenthesis.size() > 0:
		display_error(null, "Syntax error detected in " + path + m + ", Mod was not loaded.")
	elif invalid_variable:
		display_error(null, "Invalid variable assignment (" + key + ") detected in " + path + m + ", Mod was not loaded.")
	
	return uhoh or (tabs and spaces) or quoted or arrays.size() > 0 or dictionaries.size() > 0 or invalid_variable

func get_appended_steam_id(string, type):
	if type == "symbol" and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(string) and not is_mod_disabled(append_steam_id(string, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[string])):
		return append_steam_id(string, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[string])
	elif type == "item" and $"Pop-up Sprite/Pop-up".saved_mod_ids.items.has(string) and not is_mod_disabled(append_steam_id(string, $"Pop-up Sprite/Pop-up".saved_mod_ids.items[string])):
		return append_steam_id(string, $"Pop-up Sprite/Pop-up".saved_mod_ids.items[string])
	else:
		return string

func append_steam_id(string, id):
	if string.find("_STEAM_ID_") == -1 and (mod_names.symbols.has(string) or mod_names.items.has(string) or mod_groups.symbols.keys().has(string + "_STEAM_ID_" + str(id)) or mod_groups.items.keys().has(string + "_STEAM_ID_" + str(id))):
		var d_mod_check = string + "_STEAM_ID_" + str(id)
		if mod_pack_nums.has(d_mod_check):
			d_mod_check += "_PACK_" + str(mod_pack_nums[d_mod_check])
		return string + "_STEAM_ID_" + str(id)
	return string

func increase_string_values(string, num):
	var s = string
	var cut_characters = 0
	for c in range(string.length()):
		if string[c] == "<" and c + 1 < string.length() and string[c + 1] == "v":
			var k_num = 0
			var num_str = ""
			for k in string.substr(c + 7, -1):
				if k == ">":
					var cut_character = false
					if num_str.length() != str(int(num_str) + num).length():
						cut_character = true
					s = s.insert(c + 7 + cut_characters, str(int(num_str) + num))
					if cut_character:
						cut_characters += 1
					break
				else:
					num_str += k
					s[c + 7 + cut_characters] = ""
					k_num += 1
	return s

func is_mod_disabled(m_str):
	var mod_str = m_str
	var not_in_symbol_pack = false
	var not_in_item_pack = false
	var not_in_email_pack = false
	if $"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING:
		if $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(mod_str.substr(0, mod_str.find("_STEAM_ID_"))):
			if mod_str.find("_PACK_") == -1:
				mod_str += "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[mod_str] + "_PACK_" + mod_pack_nums[mod_str + "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[mod_str]]
			if m_str.find("_PACK_") == -1 and is_mod_disabled(mod_str):
				mod_str = m_str
			for s in $"Pop-up Sprite/Pop-up".current_modded_floor.symbol_packs:
				var a = s
				if a == "self":
					a = str($"Pop-up Sprite/Pop-up".current_modded_floor.pack_num)
				if a == "base" and base_types.symbols.has(mod_str):
					not_in_symbol_pack = false
					break
				elif mod_packs.has(a) and not mod_pack_nums.has(mod_str.substr(0, mod_str.find("_PACK_"))) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_symbols.has(mod_str):
					not_in_symbol_pack = true
					break
		elif $"Pop-up Sprite/Pop-up".saved_mod_ids.items.has(mod_str):
			if mod_str.find("_PACK_") == -1:
				mod_str += "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.items[mod_str] + "_PACK_" + mod_pack_nums[mod_str + "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.items[mod_str]]
			if m_str.find("_PACK_") == -1 and is_mod_disabled(mod_str):
				mod_str = m_str
			for s in $"Pop-up Sprite/Pop-up".current_modded_floor.item_packs:
				var a = s
				if a == "self":
					a = str($"Pop-up Sprite/Pop-up".current_modded_floor.pack_num)
				if a == "base" and base_types.items.has(mod_str):
					not_in_item_pack = false
					break
				elif mod_packs.has(a) and not mod_pack_nums.has(mod_str.substr(0, mod_str.find("_PACK_"))) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_items.has(mod_str):
					not_in_item_pack = true
					break
		elif $"Pop-up Sprite/Pop-up".saved_mod_ids.emails.has(mod_str):
			if mod_str.find("_PACK_") == -1:
				mod_str += "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.emails[mod_str] + "_PACK_" + mod_pack_nums[mod_str + "_STEAM_ID_" + $"Pop-up Sprite/Pop-up".saved_mod_ids.emails[mod_str]]
			if m_str.find("_PACK_") == -1 and is_mod_disabled(mod_str):
				mod_str = m_str
			for s in $"Pop-up Sprite/Pop-up".current_modded_floor.email_packs:
				var a = s
				if a == "self":
					a = str($"Pop-up Sprite/Pop-up".current_modded_floor.pack_num)
				if a == "base" and base_types.emails.has(mod_str):
					not_in_email_pack = false
					break
				elif mod_packs.has(a) and not mod_pack_nums.has(mod_str.substr(0, mod_str.find("_PACK_"))) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_emails.has(mod_str):
					not_in_email_pack = true
					break
	if $"Options Sprite/Options".disabled_mods.has(mod_str) or ($"Pop-up Sprite/Pop-up".current_modded_floor != null and typeof($"Pop-up Sprite/Pop-up".current_modded_floor) != TYPE_STRING and ($"Pop-up Sprite/Pop-up".current_modded_floor.excluded_symbols.has(mod_str) or (not $"Pop-up Sprite/Pop-up".current_modded_floor.symbol_packs.has("base") and base_types.symbols.has(mod_str.substr(0, mod_str.find("_STEAM_ID_")))) or $"Pop-up Sprite/Pop-up".current_modded_floor.excluded_items.has(mod_str) or (not $"Pop-up Sprite/Pop-up".current_modded_floor.item_packs.has("base") and base_types.items.has(mod_str.substr(0, mod_str.find("_STEAM_ID_")))) or $"Pop-up Sprite/Pop-up".current_modded_floor.excluded_emails.has(mod_str) or (not $"Pop-up Sprite/Pop-up".current_modded_floor.email_packs.has("base") and base_types.emails.has(mod_str.substr(0, mod_str.find("_STEAM_ID_")))) or not_in_symbol_pack or not_in_item_pack or not_in_email_pack) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_symbols.has(mod_str) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_items.has(mod_str) and not $"Pop-up Sprite/Pop-up".current_modded_floor.included_emails.has(mod_str)):
		return true
	return false

func add_to_counted_symbols(dict):
	if typeof(dict) == TYPE_DICTIONARY:
		for k in dict.keys():
			if k == "starting_value":
				add_to_counted_symbols(dict[k])
			elif k == "var_math":
				for s in dict[k]:
					if typeof(s) == TYPE_DICTIONARY:
						add_to_counted_symbols(s[s.keys()[0]])
			elif k == "counted_symbols" and typeof(dict[k]) == TYPE_STRING:
				var c_id = dict[k]
				if $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(dict[k]):
					c_id = append_steam_id(dict[k], $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id]) + "_PACK_" + mod_pack_nums[append_steam_id(dict[k], $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id])]
				counted_symbols[c_id] = 0

func check_valid_var(string, type, tmp, tmp_i, e, path, just_var_math, past_init):
	if typeof(string) == TYPE_STRING and not just_var_math:
		if (((type == "symbol" or type == "existing_symbol") and not string in tmp) or ((type == "item" or type == "existing_item") and (((not e.has("effect_type") or (e.effect_type != "symbols" and e.effect_type != "counted_adjacent_symbols")) and not string in tmp_i) or ((e.has("effect_type") and (e.effect_type == "symbols" or e.effect_type == "counted_adjacent_symbols") and not e.has("target_self")) and not string in tmp)))):
			display_error(null, "Invalid variable (" + string + ") detected in " + path + ", Mod was not loaded.")
			return false
	elif typeof(string) == TYPE_DICTIONARY and (string.has("var_math") or string.has("starting_value")):
		if string.has("starting_value"):
			if typeof(string.starting_value) == TYPE_DICTIONARY:
				if string.starting_value.has("rand_num"):
					if typeof(string.starting_value.rand_num) == TYPE_DICTIONARY:
						return true
					else:
						display_error(null, "Syntax error detected in " + path + ", Mod was not loaded.")
						return false
				elif string.starting_value.has("counted_symbols"):
					if typeof(string.starting_value.counted_symbols) == TYPE_STRING:
						var c_id = string.starting_value.counted_symbols
						if past_init and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(string.starting_value.counted_symbols):
							c_id = append_steam_id(string.starting_value.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id]) + "_PACK_" + mod_pack_nums[append_steam_id(string.starting_value.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id])]
						counted_symbols[c_id] = 0
						return true
					else:
						display_error(null, "Syntax error detected in " + path + ", Mod was not loaded.")
						return false
				elif past_init:
					add_to_counted_symbols(string.starting_value)
		if string.has("var_math"):
			if typeof(string.var_math) != TYPE_ARRAY:
				display_error(null, "Syntax error detected in " + path + ", Mod was not loaded.")
				return false
			else:
				for a in string.var_math:
					if typeof(a) != TYPE_DICTIONARY or a.keys().size() == 0 or not check_valid_var(a.keys()[0], type, tmp, tmp_i, e, path, true, past_init):
						display_error(null, "Invalid variable (" + a + ") detected in " + path + ", Mod was not loaded.")
						return false
					elif typeof(a) == TYPE_DICTIONARY and a.keys().size() > 0:
						var s = a[a.keys()[0]]
						if typeof(s) == TYPE_DICTIONARY:
							if s.has("rand_num"):
								if typeof(s.rand_num) == TYPE_DICTIONARY:
									return true
								else:
									display_error(null, "Syntax error detected in " + path + ", Mod was not loaded.")
									return false
							elif s.has("counted_symbols"):
								if typeof(s.counted_symbols) == TYPE_STRING:
									var c_id = s.counted_symbols
									if past_init and $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(s.counted_symbols):
										c_id = append_steam_id(s.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id]) + "_PACK_" + str(mod_pack_nums[append_steam_id(s.counted_symbols, $"Pop-up Sprite/Pop-up".saved_mod_ids.symbols[c_id])])
									counted_symbols[c_id] = 0
								else:
									display_error(null, "Syntax error detected in " + path + ", Mod was not loaded.")
									return false
							elif past_init:
								add_to_counted_symbols(s)
	return true

func display_error(error_type, error):
	var prefix
	match error_type:
		"endless", "are_you_sure":
			prefix = ""
		"achievement_unlocked":
			prefix = "<color_09FF00>"
			if $"Options Sprite/Options".CJK_lang:
				prefix += tr("achievement_unlocked")
			else:
				prefix += tr("achievement_unlocked") + " "
			prefix += "<end>"
		_:
			prefix = "<color_00FFE5>><end><color_DD0000>Error:<end> "
	queued_errors.push_back(prefix + "<color_FFFFFF>" + error + "<end>")
	write_error(prefix + error)

func exit():
	get_tree().quit()

func delete_save():
	var dir = Directory.new()
	dir.remove(save_string)
	save_game()
