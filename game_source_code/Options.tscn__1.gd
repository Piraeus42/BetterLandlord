extends ColorRect

var menu = "graphics"

var menu_buttons = []
var disabled_mods = []
var option_types = []
var option_buttons = []
var dropdown_buttons = []
var option_texts = []
var option_sliders = []
var hyperlinks = []
var slider_texts = []
var slider_lines = []
var base_y_positions = []
var lowest_y_position = 0
var lowest_y_size = 0
var lowest_global_pos_y = 0
var back_button
var reset_button
var exit_button
var header_text
var y_offset = 58
var dropdown = false
var can_update_scrollables = false
var saved_scroll_bar_pos_y = 1
var spacing_offset = 10
var button_offset = 0
var top_offset = 0
var hotkey_offset = 0
var reset_pos = 0

var source_button
var last_menu = ""

var x_resolutions = [1024, 1280, 1280, 1360, 1366, 1440, 1600, 1680, 1920, 1920, 2560, 2560, 2560, 3440, 3840]
var y_resolutions = [576, 720, 800, 768, 768, 900, 900, 1050, 1080, 1200, 1080, 1440, 1600, 1440, 2160]
var framerates = [30, 60, 120, 144, 240, tr("uncapped")]
var languages = ["English", "Français", "Italiano", "Deutsch", "Español-España", "Español-Latinoamérica", "Português-Brasil", "Português-Europeu", "Русский", "български", "polski", "Dansk", "Türkçe", "简体中文", "繁體中文", "日本語", "한국어", "Tiếng Việt", "ภาษาไทย", "العربية"]
var language_codes = ["en", "fr", "it", "de", "es_ES", "es", "pt_BR", "pt_PT", "ru", "bg", "pl", "da_DK", "tr", "zh", "zh_TW", "ja", "ko", "vi", "th", "ar"]
var credits = {"g/g": tr("gameplay") + "/" + tr("graphics") + ":", "website": "<color_1887CC>Dan DiIorio - TrampolineTales<end>", "new": tr("music") + " (" + tr("new") + "):", "vin": "<color_1887CC>Vincent Colavita<end>", "old": tr("music") + " (" + tr("old") + "):", "zapsplat": "<color_1887CC>www.ZapSplat.com<end>", "lang": tr("language") + ":", "fr": "Français:", "nelson": "<color_1887CC>Nelson Sant'ana - OmeletteDuGrosMage<end>", "it": "Italiano:", "localizedirect3": tr("refused_translator_names"), "de": "Deutsch:", "marenthyu": "<color_1887CC>Peter Fredebold - Marenthyu<end>", "es_ES": "Español-España:", "PCubiles": "<color_1887CC>Pablo Cubiles - PCubiles<end>", "es": "Español-Latinoamérica:", "mixur": "<color_1887CC>Miguel Urdaneta - Mixur<end>", "pt_BR": "Português-Brasil:", "lordkitty": "Emerson Bossi", "pt_PT": "Português-Europeu:", "Migo": "<color_1887CC>Miriam Gonçalves<end>", "ru": "Русский:", "localizedirect1": tr("refused_translator_names"), "bg": "български:", "kalin": "<color_1887CC>Kalin Kirilov<end>", "pl": "polski:", "jan": "<color_1887CC>Abyssal_Novelist<end>", "da_DK": "Dansk:", "quap": "<color_1887CC>Casper Hansen - Quapper<end>", "tr": "Türkçe:", "taylan": "<color_1887CC>Taylan Özgür Keleş<end> / <color_1887CC>Merdan Avcı<end>", "zh": "简体中文:", "zh_team": "爱丽丝拉斐尔 - IrisRaphael / <color_1887CC>晓夫九 - Xiaofu9<end> / <color_1887CC>ShariaVanilla<end>", "zh_TW": "繁體中文:", "jpao": "<color_1887CC>Judy Pao<end>", "ja": "日本語:", "toyoch": "<color_1887CC>Toyofumi Morita - Toyoch<end>", "ko": "한국어:", "kate": "<color_1887CC>Kate Letourneau<end>", "vi": "Tiếng Việt:", "bob": "Trinh Quoc Phu - Bob Trinh", "th": "ภาษาไทย:", "plearn": "<color_1887CC>Noppon Varapaiboon - PlearnGaming<end>", "ar": "العربية:", "ar_team": "Eman Abdo / <color_1887CC>Montassar Ghanmi - Eternal Dream Arabization<end> / <color_1887CC>Mohammed Seif Eddine Chaib - loclait<end>", "br": "", "special_thanks_header": tr("special_thanks"), "special_thanks": "Laragh Walsh, Lune Aspen, Mom, Dad, Grandma, The Discord Community, The Content Creators, The Godot Engine Contributers, Mega Crit, Seaven Studio, MJ Lewis, Peter Lyngholm Madsen, WillOBot, pank0, Tomas 'Lirin' Tworek, Rami Ismail, Chris Zukowski, Mike Rose, Chris King, ...and You!\n", "dedication": tr("dedication"), "br2": ""}
var CJK_credits = {"g/g": tr("gameplay") + "／" + tr("graphics") + ":", "website": "<color_1887CC>Dan DiIorio - TrampolineTales<end>", "new": tr("music") + "（" + tr("new") + "）" + "：", "vin": "<color_1887CC>Vincent Colavita<end>", "old": tr("music") + "（" + tr("old") + "）：", "zapsplat": "<color_1887CC>www.ZapSplat.com<end>", "lang": tr("language") + "：", "fr": "Français：", "nelson": "<color_1887CC>Nelson Sant'ana - OmeletteDuGrosMage<end>", "it": "Italiano：", "localizedirect3": tr("refused_translator_names"), "de": "Deutsch：", "marenthyu": "<color_1887CC>Peter Fredebold - Marenthyu<end>", "es_ES": "Español-España：", "PCubiles": "<color_1887CC>Pablo Cubiles - PCubiles<end>", "es": "Español-Latinoamérica：", "mixur": "<color_1887CC>Miguel Urdaneta - Mixur<end>", "pt_BR": "Português-Brasil：", "lordkitty": "Emerson Bossi", "pt_PT": "Português-Europeu：", "Migo": "<color_1887CC>Miriam Gonçalves<end>", "ru": "Русский：", "localizedirect1": tr("refused_translator_names"), "bg": "български：", "kalin": "<color_1887CC>Kalin Kirilov<end>", "pl": "polski：", "jan": "<color_1887CC>Abyssal_Novelist<end>", "da_DK": "Dansk：", "quap": "<color_1887CC>Casper Hansen - Quapper<end>", "tr": "Türkçe：", "taylan": "<color_1887CC>Taylan Özgür Keleş<end> ／ <color_1887CC>Merdan Avcı<end>", "zh": "简体中文：", "zh_team": "爱丽丝拉斐尔 - IrisRaphael ／ <color_1887CC>晓夫九 - Xiaofu9<end> ／ <color_1887CC>ShariaVanilla<end>", "zh_TW": "繁體中文：", "jpao": "<color_1887CC>Judy Pao<end>", "ja": "日本語：", "toyoch": "<color_1887CC>Toyofumi Morita - Toyoch<end>", "ko": "한국어：", "kate": "<color_1887CC>Kate Letourneau<end>", "vi": "Tiếng Việt:", "bob": "Trinh Quoc Phu - Bob Trinh", "th": "ภาษาไทย:", "plearn": "<color_1887CC>Noppon Varapaiboon - PlearnGaming<end>", "ar": "العربية:", "ar_team": "Eman Abdo ／ <color_1887CC>Montassar Ghanmi - Eternal Dream Arabization<end> ／ <color_1887CC>Mohammed Seif Eddine Chaib - loclait<end>", "br": "", "special_thanks_header": tr("special_thanks"), "special_thanks": "Laragh Walsh, Lune Aspen, Mom, Dad, Grandma, The Discord Community, The Content Creators, The Godot Engine Contributers, Mega Crit, Seaven Studio, MJ Lewis, Peter Lyngholm Madsen, WillOBot, pank0, Tomas 'Lirin' Tworek, Rami Ismail, Chris Zukowski, Mike Rose, Chris King, ...and You!\n", "dedication": tr("dedication"), "br2": ""}
var assignable_hotkeys = ["confirm_select", "deny_cancel", "SPIN", "up", "down", "left", "right", "options", "inventory", "add_symbol_1", "add_symbol_2", "add_symbol_3", "skip", "use_reroll", "use_removal", "fast_forward", "enable_disable_item", "lock_tooltip", "inspect", "scroll_up", "scroll_down"]
var fonts = ["SinsGold", "NotoSans", "OpenDyslexic"]
var input_types = ["on_press", "on_release"]
var soundtrack_types = ["old", "new", "both"]
var default_colors = {"background": "FF8300", "reels": "FFFFFF", "symbol_bonus_text": "FBF236", "symbol_multiplier_text": "FBF236", "symbol_reminder_down_text": "E14A68", "symbol_reminder_up_text": "FBF236", "item_reminder_up_text": "FBF236", "item_reminder_down_text": "E14A68", "item_count_text": "61D3E3", "item_destroy_text": "7234BF", "inventory_background": "000000", "inventory_text": "FFFFFF", "button_border": "000000", "button_color_start": "C71585", "button_color_continue": "06799F", "button_color_options": "C4C4C4", "button_color_stats": "2A570F", "button_color_mods": "800080", "button_color_exit": "6A1111", "button_color_promo": "1A1A1A", "button_color_misc": "F28050", "button_color_inventory": "046BF9", "button_color_header": "C4DA0C", "button_color_removal": "222222", "button_color_page": "228C8C", "button_color_start_text": "FFFFFF", "button_color_continue_text": "FFFFFF", "button_color_options_text": "FFFFFF", "button_color_stats_text": "FFFFFF", "button_color_mods_text": "FFFFFF", "button_color_exit_text": "FFFFFF", "button_color_promo_text": "FFFFFF", "button_color_misc_text": "FFFFFF", "button_color_inventory_text": "FFFFFF", "button_color_header_text": "FFFFFF", "text_color_misc": "FFFFFF", "text_color_keyword": "E14A68", "text_color_common": "797979", "text_color_uncommon": "38769A", "text_color_rare": "F8F87B", "text_color_very_rare": "4A1369", "text_color_essence": "FF005D", "options_background": "000000", "symbol_background": "640F39", "item_background": "094643", "email_background": "122950", "email_border": "000000", "scroll_bar": "FFFFFF", "scroll_bar_border": "000000", "reel_border": "000000"}
var colors3 = default_colors.duplicate(true)
var ui_scaling = {"text": 1.0, "reels_ui": 1.0, "items_ui": 1.0, "buttons": 1.0, "tooltips": 1.0, "emails": 1.0, "inventory": 1.0, "symbol_item_selections": 1.0}
var current_color
var changing_languages = false
var temp_color

var language = null
var CJK_lang = false
var RTL_lang = false
var resolution_x = 1024
var resolution_y = 576
var saved_resolution_x = 1024
var saved_resolution_y = 576
var vsync = false
var bordered_window = false
var fullscreen = false
var just_changed_osx_fullscreen = false
var changing_osx_fullscreen = false
var max_fps = 60
var spin_speed = 1
var spin_speed_offset = 0
var animation_speed = 1
var animation_speed_offset = 0
var counting_speed = 1
var counting_speed_offset = 0
var menu_speed = 1
var menu_speed_offset = 0
var input_type = 0
var display_font = 0
var text_border = true
var first_menu = false
var digit_separators = true
var scientific_notation = true
var init_scaling_set = false
var old_endless_mode = false
var max_scaling = 0

var master_volume = { "goal_volume": 0, "value": 100, "muted": false, }
var music = { "goal_volume": 0, "value": 80, "muted": false, }
var sfx = { "goal_volume": 0, "value": 80, "muted": false, }
var tracks = { "Old BGM #1": [0, 0], "Old BGM #2": [0, 0], "Old BGM #3": [0, 0], "Old BGM #4": [0, 0], "Old BGM #5": [0, 0], "Old BGM #6": [0, 0], "Old BGM #7": [0, 0], "Old BGM #8": [0, 0], "Banana Beats": [1, 1], "Big Man Zaroff": [1, 1], "Capsule Machine": [1, 1], "Hex of Funkiness": [1, 1], "Instant Ramen": [1, 1], "Rainbow Peppers": [1, 1], "Spin to Win!": [1, 1], "The Mouse Song": [1, 1], "Bird Whistle": [0, 1], "Essence Party": [0, 1], "Guillotine Dance": [0, 1], "Roll of the Dice": [0, 1]}
var track_names = ["Banana Beats", "Big Man Zaroff", "Capsule Machine", "Hex of Funkiness", "Instant Ramen", "Rainbow Peppers", "Spin to Win!", "The Mouse Song", "Bird Whistle", "Essence Party", "Guillotine Dance", "Roll of the Dice", "Old BGM #1", "Old BGM #2", "Old BGM #3", "Old BGM #4", "Old BGM #5", "Old BGM #6", "Old BGM #7", "Old BGM #8"]
var mute_while_in_background = false

var screen_reader = false

var echo = false
var deck_setting = false

var hotkey_being_assigned
var hotkey_button_being_assigned
var le
var done_assigning = true
var done_assigning_timer = 2

var hotkeys = {}
var mod_dropdown_buttons = 0
var displayed_mods = []
var saved_modpack_keys = {}
var starter_button
var last_selector_button_pos

var are_you_sure_timer = 0

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed() and not done_assigning:
		le.grab_focus()
	elif ((event is InputEventKey and event.scancode == hotkeys["confirm_select"][0]) or (event is InputEventMouseButton and event.button_index == hotkeys["confirm_select"][0])) and ((event.is_pressed() and input_type == 0) or (not event.is_pressed() and input_type == 1)) and done_assigning:
		return
	
	var keys_up = false
	
	if hotkey_being_assigned != null and done_assigning_timer == 2:
		if event is InputEventKey and ((event.is_pressed() and input_type == 0) or (not event.is_pressed() and input_type == 1)) and option_buttons.find(hotkey_button_being_assigned) % 2 == 0:
			hotkeys[hotkey_being_assigned][0] = event.scancode
			var hba = hotkey_being_assigned
			hotkey_being_assigned = null
			le.grab_focus()
			Input.parse_input_event(event)
			if le.text.length() > 0 and le.text[0] != " ":
				hotkey_button_being_assigned.saved_raw_string = le.text[0]
				hotkey_button_being_assigned.text_node.raw_string = le.text[0]
				hotkeys[hba][2] = le.text[0]
			else:
				hotkey_button_being_assigned.saved_raw_string = OS.get_scancode_string(event.scancode)
				hotkey_button_being_assigned.text_node.raw_string = OS.get_scancode_string(event.scancode)
				hotkeys[hba][2] = OS.get_scancode_string(event.scancode)
			hotkey_button_being_assigned.update_size()
			hotkey_button_being_assigned.do_call()
			hotkey_button_being_assigned.visual_reset()
			hotkey_button_being_assigned = null
			le.release_focus()
			le.clear()
			$"/root/Main".save_options()
		elif event is InputEventMouseButton and event.is_pressed() and event.button_index != BUTTON_LEFT and option_buttons.find(hotkey_button_being_assigned) % 2 == 0:
			hotkeys[hotkey_being_assigned][0] = event.button_index
			var mini_str = event.as_text().substr(event.as_text().find("button_index="), -1)
			mini_str = "MOUSE" + mini_str.substr(19, mini_str.find(",") - 19)
			hotkey_button_being_assigned.saved_raw_string = mini_str
			hotkey_button_being_assigned.text_node.raw_string = mini_str
			hotkeys[hotkey_being_assigned][2] = mini_str
			hotkey_button_being_assigned.update_size()
			hotkey_button_being_assigned.do_call()
			hotkey_button_being_assigned.visual_reset()
			hotkey_button_being_assigned = null
			hotkey_being_assigned = null
			$"/root/Main".save_options()
		elif event is InputEventJoypadButton and event.is_pressed() and option_buttons.find(hotkey_button_being_assigned) % 2 == 1:
			hotkeys[hotkey_being_assigned][1] = event.button_index
			var hba = hotkey_being_assigned
			hotkey_being_assigned = null
			le.grab_focus()
			Input.parse_input_event(event)
			hotkey_button_being_assigned.saved_raw_string = "<button_" + str(event.button_index) + ">"
			hotkey_button_being_assigned.text_node.raw_string = "<button_" + str(event.button_index) + ">"
			hotkeys[hba][3] = "<button_" + str(event.button_index) + ">"
			hotkey_button_being_assigned.update_size()
			hotkey_button_being_assigned.do_call()
			hotkey_button_being_assigned.visual_reset()
			hotkey_button_being_assigned = null
			le.release_focus()
			le.clear()
			$"/root/Main".save_options()
	
	if ((event is InputEventKey and event.scancode == hotkeys["options"][0]) or (event is InputEventMouseButton and event.button_index == hotkeys["options"][0])) and ((event.is_pressed() and input_type == 0) or (not event.is_pressed() and input_type == 1)):
		return
	if ((event is InputEventKey and event.scancode == hotkeys["options"][0]) or (event is InputEventMouseButton and event.button_index == hotkeys["options"][0]) or (event is InputEventJoypadButton and event.button_index == hotkeys["options"][1])) and not ((event.is_pressed() and input_type == 0) or (not event.is_pressed() and input_type == 1)):
		echo = false
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT) or (event is InputEventKey and event.scancode == hotkeys["confirm_select"][0]) or (event is InputEventJoypadButton and event.button_index == hotkeys["confirm_select"][1]):
		echo = false

func _ready():
	get_spacing()
	set_max_scaling()
	if $"/root/Main".demo:
		credits.erase("dedication")
		CJK_credits.erase("dedication")
		credits.erase("br")
		CJK_credits.erase("br")
		credits.erase("br2")
		CJK_credits.erase("br2")
	
	color = Color("F5" + colors3["options_background"])
	
	le = $"LineEdit"
	le.rect_scale = Vector2(0.1, 0.1)
	header_text = $"Header"
	header_text.raw_string = tr("options")
	if CJK_lang or RTL_lang or int(display_font) > 0:
		header_text.icon_z_index = 10
	else:
		header_text.texts[8].icon_z_index = 10
	header_text.update()
	if TranslationServer.get_locale() == "th":
		header_text.rect_position = Vector2(16, 16)
	else:
		header_text.rect_position = Vector2(16, 8)
	$"Input Header 1".rect_position = Vector2(16, 152)
	$"Input Header 1".raw_string = "<text_color_keyword>" + tr("command") + "<end>"
	$"Input Header 2".raw_string = "<text_color_keyword>" + tr("keyboard") + "<end>"
	$"Input Header 3".raw_string = "<text_color_keyword>" + tr("controller") + "<end>"
	$"Input Header 2".alignment_tags.dont = true
	$"Input Header 3".alignment_tags.dont = true
	if not hotkeys.has("left"):
		hotkeys["left"] = [KEY_LEFT, -1, "Left", ""]
	if not hotkeys.has("right"):
		hotkeys["right"] = [KEY_RIGHT, -1, "Right", ""]

func get_spacing():
	var test_button = preload("res://TT Button.tscn").instance()
	if menu == "input":
		test_button.hotkey = true
	add_child(test_button)
	test_button.correct_size()
	var y1
	if test_button.hotkey:
		y1 = test_button.get_child(0).rect_size.y
	else:
		y1 = test_button.rect_size.y
	remove_child(test_button)
	var test_text = preload("res://Outline Label.tscn").instance()
	test_text.raw_string = "TEST"
	add_child(test_text)
	test_text.force_update = true
	test_text.update()
	var y2
	if CJK_lang or int(display_font) > 0:
		y2 = test_text.get_font("font").get_height() * test_text.current_scale
	else:
		y2 = test_text.get_font("font").get_height() * test_text.current_scale * 4
	button_offset = y1 + 16 * ui_scaling.buttons
	if y1 > y2:
		spacing_offset = y1 + 16 * ui_scaling.buttons
		if test_button.hotkey:
			lowest_y_size = test_button.get_child(0).rect_size.y
		else:
			lowest_y_size = test_button.rect_size.y
	else:
		spacing_offset = y2 + 16 * ui_scaling.buttons
		if CJK_lang or int(display_font) > 0:
			lowest_y_size = test_text.get_child(0).get_font("font").get_height() * test_text.current_scale
		else:
			lowest_y_size = test_text.get_font("font").get_height() * test_text.current_scale * 4
	remove_child(test_text)

func open_mods(s_b):
	open(s_b)

func open(s_b):
	if not echo:
		if last_menu == "":
			last_menu = $"/root/Main".current_menu_path
		can_update_scrollables = false
		echo = true
		visible = true
		if int(display_font) > 0 and $"/root/Main/Pop-up Sprite/Pop-up".options_button != null and TranslationServer.get_locale() != "th":
			$"/root/Main/Pop-up Sprite/Pop-up".options_button.text_node.rect_position = Vector2(8, 0)
			$"/root/Main/Pop-up Sprite/Pop-up".options_button.text_node.get_child(0).rect_position = Vector2(0, 0)
		if not first_menu:
			if $"/root/Main/Reels".displayed_icons[0][0] != null and is_instance_valid($"/root/Main/Reels".displayed_icons[0][0]):
				for x in range($"/root/Main/Reels".reel_width):
					for y in range($"/root/Main/Reels".reel_height):
						$"/root/Main/Reels".displayed_icons[y][x].selectable = false
						if not $"/root/Main/Reels".checking_effects:
							$"/root/Main/Reels".displayed_icons[y][x].sfx_player.volume_db = -80
			for c in $"/root/Main/Pop-up Sprite/Pop-up".cards:
				c.unhover()
				c.hovering = false
				c.selectable = false
			for i in $"/root/Main/Items".items:
				i.unhover()
				i.hovering = false
				i.selectable = false
			if back_button != null:
				close()
			elif s_b != null and s_b.button_text == tr("mods"):
				$"/root/Main".load_data(not $"/root/Main".sandbox_mode, $"/root/Main".sandbox_mode, true)
				if CJK_lang or int(display_font) > 0:
					top_offset = 152 + (-1 + ui_scaling.text) * 26
				else:
					top_offset = 132 + (-1 + ui_scaling.text) * 26
				change_menu("mods", null, false)
			elif s_b != null and s_b.button_text == tr("achievements_no_colon"):
				if CJK_lang or int(display_font) > 0:
					top_offset = 72 + (-1 + ui_scaling.text) * 26
				else:
					top_offset = 72 + (-1 + ui_scaling.text) * 26
				change_menu("achievements", null, false)
			else:
				change_menu("graphics", null, false)
				remove_buttons()
				add_buttons()
				
			source_button = s_b
			if source_button != null:
				source_button.shortcuts = []
		else:
			$"Input Header 1".visible = false
			$"Input Header 2".visible = false
			$"Input Header 3".visible = false
			add_dropdown("language")
		$"/root/Main".change_current_menu_path("/root/Main/Options Sprite/Options/" + menu)

func close():
	if not echo:
		last_selector_button_pos = null
		echo = true
		remove_buttons()
		if back_button != null:
			back_button.queue_free()
			back_button = null
		if exit_button != null:
			exit_button.queue_free()
			exit_button = null
		if reset_button != null:
			reset_button.queue_free()
			reset_button = null
		hotkey_being_assigned = null
		hotkey_button_being_assigned = null
		done_assigning = true
		if not dropdown:
			$"Hotkeys".visible = false
			$"Scrollables".visible = false
			$"Color Text".visible = false
			if source_button != null and is_instance_valid(source_button):
				source_button.down = false
				source_button.visual_reset()
				source_button.shortcuts = ["options"]
				source_button = null
			visible = false
			if menu == "mods":
				$"/root/Main".load_data(not $"/root/Main".sandbox_mode, $"/root/Main".sandbox_mode, true)
				$"/root/Main".reload()
			menu = "graphics"
			$"Scrollables/Scroll Bar".rect_position.y = $"Scrollables/Scroll Bar".top
			saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".top
			if $"/root/Main/Reels".displayed_icons[0][0] != null and is_instance_valid($"/root/Main/Reels".displayed_icons[0][0]) and not $"/root/Main/Reels".checking_effects:
				for x in range($"/root/Main/Reels".reel_width):
					for y in range($"/root/Main/Reels".reel_height):
							$"/root/Main/Reels".displayed_icons[y][x].sfx_player.volume_db = sfx.goal_volume
			if last_menu != "":
				$"/root/Main".change_current_menu_path(last_menu)
				last_menu = ""
			$"/root/Main".endless_toggle_counter = 0
		else:
			if menu == "input":
				$"Hotkeys".visible = true
			elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "gameplay" or menu == "legal":
				$"Scrollables".visible = true
			elif current_color != null:
				$"Color Text".visible = true
			dropdown = false
			if current_color != null:
				update_setting("color", temp_color)
				change_menu("graphics", null, false)
				can_update_scrollables = true
				$"Scrollables/Scroll Bar".rect_position.y = saved_scroll_bar_pos_y
				for node in $"/root/Main".get_tree().get_nodes_in_group("UI - Button"):
					node.add_lines()
				for node in $"/root/Main".get_tree().get_nodes_in_group("UI - Text"):
					if not node.get_parent() is TextureButton:
						node.force_update = true
				for node in $"/root/Main".get_tree().get_nodes_in_group("Reel Border"):
					node.get_child(0).color = Color(colors3["reel_border"])
				for node in $"/root/Main".get_tree().get_nodes_in_group("Scroll Bar"):
					node.color = Color(colors3["scroll_bar"])
					node.get_child(0).color = Color(colors3["scroll_bar_border"])
				for node in $"/root/Main".get_tree().get_nodes_in_group("Bar"):
					node.color = Color(colors3["scroll_bar"])
					node.get_child(0).color = Color(colors3["scroll_bar_border"])
				color = Color("F5" + colors3["options_background"])
				reset_email()
			else:
				add_buttons()
			$"/root/Main".change_current_menu_path("/root/Main/Options Sprite/Options/" + menu)
		if int(display_font) > 0 and $"/root/Main/Pop-up Sprite/Pop-up".options_button != null and TranslationServer.get_locale() != "th":
			$"/root/Main/Pop-up Sprite/Pop-up".options_button.text_node.rect_position = Vector2(8, 0)
			$"/root/Main/Pop-up Sprite/Pop-up".options_button.text_node.get_child(0).rect_position = Vector2(0, 0)

func set_max_scaling():
	if resolution_y >= 2160:
		max_scaling = 7
	elif resolution_y >= 1600:
		max_scaling = 6
	elif resolution_y >= 1440:
		max_scaling = 5
	elif resolution_y >= 1080:
		max_scaling = 4
	elif resolution_y >= 1050:
		max_scaling = 3
	elif resolution_y >= 900:
		max_scaling = 2
	elif resolution_y >= 720:
		max_scaling = 1
	else:
		max_scaling = 0

func auto_set_scaling():
	if resolution_y >= 2160:
		ui_scaling.text = 2.5
		ui_scaling.reels_ui = 3.5
		ui_scaling.items_ui = 2.5
		ui_scaling.buttons = 2.5
		ui_scaling.tooltips = 2.5
		ui_scaling.emails = 2.5
		ui_scaling.inventory = 2.5
		ui_scaling.symbol_item_selections = 2.5
	elif resolution_y >= 1600:
		ui_scaling.text = 2
		ui_scaling.reels_ui = 2.5
		ui_scaling.items_ui = 1.75
		ui_scaling.buttons = 2.5
		ui_scaling.tooltips = 2
		ui_scaling.emails = 2.25
		ui_scaling.inventory = 1.75
		ui_scaling.symbol_item_selections = 2
	elif resolution_y >= 1440:
		ui_scaling.text = 1.75
		ui_scaling.reels_ui = 2.25
		ui_scaling.items_ui = 1.75
		ui_scaling.buttons = 2.5
		ui_scaling.tooltips = 2
		ui_scaling.emails = 2.25
		ui_scaling.inventory = 1.75
		ui_scaling.symbol_item_selections = 2
	elif resolution_y >= 1080:
		ui_scaling.text = 1.5
		ui_scaling.reels_ui = 2
		ui_scaling.items_ui = 1.25
		ui_scaling.buttons = 1.5
		ui_scaling.tooltips = 1.75
		ui_scaling.emails = 1.75
		ui_scaling.inventory = 1.75
		ui_scaling.symbol_item_selections = 1.75
	elif resolution_y >= 1050:
		ui_scaling.text = 1.5
		ui_scaling.reels_ui = 1.75
		ui_scaling.items_ui = 1.25
		ui_scaling.buttons = 1.5
		ui_scaling.tooltips = 1.5
		ui_scaling.emails = 1.5
		ui_scaling.inventory = 1.5
		ui_scaling.symbol_item_selections = 1.5
	elif resolution_y >= 900:
		ui_scaling.text = 1.25
		ui_scaling.reels_ui = 1.5
		ui_scaling.items_ui = 1.25
		ui_scaling.buttons = 1.25
		ui_scaling.tooltips = 1.25
		ui_scaling.emails = 1.25
		ui_scaling.inventory = 1.25
		ui_scaling.symbol_item_selections = 1.25
	elif resolution_y >= 800:
		ui_scaling.text = 1
		ui_scaling.reels_ui = 1.25
		ui_scaling.items_ui = 1
		ui_scaling.buttons = 1.25
		ui_scaling.tooltips = 1
		ui_scaling.emails = 1.25
		ui_scaling.inventory = 1.25
		ui_scaling.symbol_item_selections = 1
	elif resolution_y >= 720:
		ui_scaling.text = 1
		ui_scaling.reels_ui = 1.25
		ui_scaling.items_ui = 1
		ui_scaling.buttons = 1
		ui_scaling.tooltips = 1
		ui_scaling.emails = 1.25
		ui_scaling.inventory = 1
		ui_scaling.symbol_item_selections = 1
	else:
		ui_scaling.text = 1
		ui_scaling.reels_ui = 1
		ui_scaling.items_ui = 1
		ui_scaling.buttons = 1
		ui_scaling.tooltips = 1
		ui_scaling.emails = 1
		ui_scaling.inventory = 1
		ui_scaling.symbol_item_selections = 1
	update_setting("ui_scaling", null)

func add_dropdown(s):
	if menu == "input":
		saved_scroll_bar_pos_y = $"Hotkeys/Scroll Bar".rect_position.y
	else:
		saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	dropdown = true
	remove_buttons()
	$"Scrollables".visible = false
	if not first_menu:
		add_system_buttons()
		header_text.raw_string += "\n\n" + tr(s)
	else:
		header_text.raw_string = ""
	match s:
		"resolution":
			for i in range(x_resolutions.size()):
				add_dropdown_button("resolution", i * (button_offset - 1), i)
		"max_fps":
			for i in range(framerates.size()):
				add_dropdown_button("max_fps", 160 + i * button_offset, i)
		"language":
			if button_offset * 10.5 >= resolution_y:
				for i in range(languages.size()):
					add_dropdown_button("language", 16 + i * (button_offset * 0.75 - 1), i)
			else:
				for i in range(languages.size()):
					add_dropdown_button("language", 16 + i * (button_offset - 1), i)
		"text", "items_ui", "buttons", "tooltips", "emails", "inventory", "symbol_item_selections":
			for i in range(3 + max_scaling):
				add_dropdown_button(s, 160 + i * button_offset, i)
		"reels_ui":
			if resolution_y >= 2160:
				for i in range(13):
					add_dropdown_button(s, 160 + i * button_offset, i)
			else:
				for i in range(3 + max_scaling):
					add_dropdown_button(s, 160 + i * button_offset, i)
		"spin_speed":
			for i in range(7):
				add_dropdown_button("spin_speed", 160 + i * button_offset, i)
		"animation_speed":
			for i in range(7):
				add_dropdown_button("animation_speed", 160 + i * button_offset, i)
		"counting_speed":
			for i in range(7):
				add_dropdown_button("counting_speed", 160 + i * button_offset, i)
		"menu_speed":
			for i in range(7):
				add_dropdown_button("menu_speed", 160 + i * button_offset, i)
		"input_type":
			for i in range(input_types.size()):
				add_dropdown_button("input_type", 160 + i * button_offset, i)
		"font":
			if TranslationServer.get_locale() == "ru" or TranslationServer.get_locale() == "bg":
				for i in range(fonts.size() - 1):
					add_dropdown_button("font", 160 + i * button_offset, i)
			else:
				for i in range(fonts.size()):
					add_dropdown_button("font", 160 + i * button_offset, i)
	$"/root/Main".change_current_menu_path("dropdown")

func add_dropdown_button(s, y_pos, choice):
	var button = preload("res://TT Button.tscn").instance()

	dropdown_buttons.push_back(button)
	
	button.rect_position.y = y_pos
	button.color = Color(colors3["button_color_options"])
	button.color_type = "button_color_options"
	button.target = self
	button.toggle = false
	button.options_button = true
	button.scrollable_button = true
	if s == "language" and button_offset * 10.5 >= resolution_y:
		button.scale_mod = -1
	
	match s:
		"resolution":
			button.call = "update_setting"
			button.args = ["resolution", choice]
			button.button_text = str(x_resolutions[choice]) + " x " + str(y_resolutions[choice])
		"max_fps":
			button.call = "update_setting"
			button.args = ["max_fps", choice]
			button.button_text = str(framerates[choice])
		"language":
			button.call = "update_setting"
			button.args = ["language", choice]
			button.button_text = languages[choice]
			button.dont_reset = true
		"spin_speed", "animation_speed", "counting_speed", "menu_speed":
			button.call = "update_setting"
			if choice == 0:
				button.button_text = "0.5x"
				button.args = [s, 0.5]
			elif choice == 1:
				button.button_text = "0.75x"
				button.args = [s, 0.75]
			elif choice % 7 != 6:
				button.button_text = str(choice - 1) + "x"
				button.args = [s, choice - 1]
			else:
				button.button_text = tr("instant")
				button.args = [s, 0]
		"input_type":
			button.call = "update_setting"
			button.args = ["input_type", choice]
			button.button_text = tr(input_types[choice])
		"font":
			button.call = "update_setting"
			button.args = ["font", choice]
			button.button_text = fonts[choice]
		"text", "reels_ui", "items_ui", "buttons", "tooltips", "emails", "inventory", "symbol_item_selections":
			button.call = "update_setting"
			match choice:
				0:
					button.button_text = "50%"
					button.args = [s, 0.5]
				1:
					button.button_text = "75%"
					button.args = [s, 0.75]
				2:
					button.button_text = "100%"
					button.args = [s, 1.0]
				3:
					button.button_text = "125%"
					button.args = [s, 1.25]
				4:
					button.button_text = "150%"
					button.args = [s, 1.5]
				5:
					button.button_text = "175%"
					button.args = [s, 1.75]
				6:
					button.button_text = "200%"
					button.args = [s, 2]
				7:
					button.button_text = "225%"
					button.args = [s, 2.25]
				8:
					button.button_text = "250%"
					button.args = [s, 2.5]
				9:
					button.button_text = "275%"
					button.args = [s, 2.75]
				10:
					button.button_text = "300%"
					button.args = [s, 3]
				11:
					button.button_text = "325%"
					button.args = [s, 3.25]
				12:
					button.button_text = "350%"
					button.args = [s, 3.5]
					
	if s == "font" and choice != display_font and choice == 0:
		button.get_node("Text").forced_pico = true
	
	add_child(button)
	
	if s == "font" and choice != display_font:
		match choice:
			0:
				button.text_node.change_set_size(1.0)
			1:
				button.text_node.forced_font = preload("res://NotoSans_Resize.tres")
			2:
				button.text_node.forced_font = preload("res://OpenDyslexic_Resize.tres")
		if choice != 0:
			for t in button.text_node.texts:
				button.text_node.remove_child(t)
				t.queue_free()
			button.text_node.texts.clear()
			button.text_node.add_child(preload("res://Pico Label.tscn").instance())
			button.text_node.add_child(Control.new())
			
			button.text_node.change_set_size(0.5)
			button.text_node.base_scale = 0.5
	
	var f_button = false
	
	if s == "language":
		if TranslationServer.get_locale() == "th" and choice < languages.size() - 7:
			button.text_node.forced_font = preload("res://NotoSans_Resize.tres")
		if choice == languages.size() - 7 and TranslationServer.get_locale() != "zh":
			button.text_node.forced_font = preload("res://NotoSansSC_Resize.tres")
			f_button = true
		elif choice == languages.size() - 6 and TranslationServer.get_locale() != "zh_TW":
			button.text_node.forced_font = preload("res://NotoSansTC_Resize.tres")
			f_button = true
		elif choice == languages.size() - 5 and TranslationServer.get_locale() != "ja":
			button.text_node.forced_font = preload("res://NotoSansJP_Resize.tres")
			f_button = true
		elif choice == languages.size() - 4 and TranslationServer.get_locale() != "ko":
			button.text_node.forced_font = preload("res://NotoSansKR_Resize.tres")
			f_button = true
		elif choice == languages.size() - 3 and TranslationServer.get_locale() != "vi":
			button.text_node.forced_font = preload("res://NotoSans_Resize.tres")
			f_button = true
		elif choice == languages.size() - 2 and TranslationServer.get_locale() != "th":
			button.text_node.forced_font = preload("res://NotoSansTH_Resize.tres")
			f_button = true
		elif choice == languages.size() - 1 and TranslationServer.get_locale() != "ar":
			button.text_node.rtl = true
			if int(display_font) == 1 or CJK_lang:
				button.text_node.forced_font = preload("res://NotoSansAR_Resize.tres")
				f_button = true
			elif int(display_font) == 2:
				button.text_node.forced_font = preload("res://OpenDyslexic_Resize.tres")
				f_button = true
			else:
				button.text_node.align = Label.ALIGN_RIGHT
		elif choice == languages.size() - 11 and TranslationServer.get_locale() != "bg" and display_font == 2:
			button.text_node.forced_font = preload("res://NotoSans_Resize.tres")
		elif choice == languages.size() - 12 and TranslationServer.get_locale() != "ru" and display_font == 2:
			button.text_node.forced_font = preload("res://NotoSans_Resize.tres")
			
	if f_button:
		for t in button.text_node.get_children():
			button.text_node.remove_child(t)
			t.queue_free()
		button.text_node.texts.clear()
		button.text_node.add_child(preload("res://Pico Label.tscn").instance())
		button.text_node.add_child(Control.new())
		button.text_node.change_set_size(0.5)
		button.text_node.base_scale = 0.5
		button.change_size()
	elif TranslationServer.get_locale() == "th":
		button.centered_text_button = true
		button.text_node.rect_position.y = 10
		
	button.text_node.force_update = true
	button.text_node.update()
	button.button_text = button.text_node.text
	button.button_text = button.text_node.raw_string
	button.update_size()
	button.correct_size()
	if s == "language":
		if button_offset * 10.5 >= resolution_y:
			if choice >= languages.size() - 10:
				button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
				button.rect_position.y -= button_offset * 0.75 * (languages.size() - 10)
			else:
				button.rect_position.x = resolution_x / 2 - 140 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
				button.rect_position.y -= button_offset * 0.75 / 2 - 16
			button.rect_position.y += resolution_y / 2 - button_offset * 0.75 * 5
		else:
			if choice >= languages.size() - 10:
				button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
				button.rect_position.y -= button_offset * (languages.size() - 10) + 8
			else:
				button.rect_position.x = resolution_x / 2 - 140 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
				button.rect_position.y -= button_offset / 2 - 16
			button.rect_position.y += resolution_y / 2 - button_offset * 5
	elif s == "resolution":
		if choice >= x_resolutions.size() - 7:
			button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
			button.rect_position.y -= button_offset * (x_resolutions.size() - 7) - 8
		else:
			button.rect_position.x = resolution_x / 2 - 140 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
		button.rect_position.y += resolution_y / 2 - button_offset * 3.5 - 8
	elif s == "reels_ui":
		if choice >= 7:
			button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
			button.rect_position.y -= button_offset * 7 - 8
		elif max_scaling < 3:
			button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
		else:
			button.rect_position.x = resolution_x / 2 - 140 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
		button.rect_position.y += resolution_y / 2 - button_offset * 4.5 - 8
	elif ui_scaling.keys().has(s):
		if choice >= 5:
			button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
			button.rect_position.y -= button_offset * 5 - 8
		elif max_scaling < 3:
			button.rect_position.x = resolution_x / 2 + 200 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
		else:
			button.rect_position.x = resolution_x / 2 - 140 * ui_scaling.buttons - button.rect_size.x / 2 * button.rect_scale.x
		button.rect_position.y += resolution_y / 2 - button_offset * 4.5 - 8
	else:
		button.rect_position.x = 880 - button.rect_size.x
		button.alignment_tags.right = true
		if max_scaling == 0 and (s == "spin_speed" or s == "animation_speed" or s == "counting_speed" or s == "menu_speed"):
			button.rect_position.y -= button_offset
	button.base_x = button.rect_position.x
	if CJK_lang or button.text_node.forced_font != null or int(display_font) > 0:
		button.text_node.get_child(0).custom_max_width = 10000
	else:
		button.text_node.texts[8].custom_max_width = 10000
	button.text_node.force_update = true
	button.text_node.update()
	button.correct_size()
	
	if TranslationServer.get_locale() == "th":
		button.centered_text_button = true
		button.text_node.rect_position.y = 0

func get_credit(s):
	if CJK_lang and TranslationServer.get_locale() != "ko":
		for n in CJK_credits.keys():
			if CJK_credits[n] == s:
				return n
	else:
		for n in credits.keys():
			if credits[n] == s:
				return n

func add_option_text(s):
	var t = preload("res://Outline Label.tscn").instance()
	t.raw_string = s
	if t.raw_string == tr("symbols"):
		t.values = [0, 0, $"/root/Main".mod_data.symbols.size()]
	elif t.raw_string == tr("items"):
		t.values = [0, 0, 0, $"/root/Main".mod_data.items.size()]
	if CJK_lang or int(display_font) > 0:
		t.icon_z_index = 10
	else:
		t.texts[8].icon_z_index = 10
	if TranslationServer.get_locale() == "ar" and (t.raw_string == credits["special_thanks"] or t.raw_string == credits["zh_team"] or t.raw_string == credits["ar_team"] or t.raw_string == credits["taylan"] or t.raw_string == tr("legal_stuff")):
		t.rtl = false
		t.align = Label.ALIGN_LEFT
		t.force_update = true
	option_texts.push_back(t)
	if menu == "input":
		t.get_child(0).icon_z_index = 9
		$"Hotkeys".add_child(t)
	elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "mods" or menu == "gameplay" or menu == "legal":
		if CJK_lang or int(display_font) > 0:
			t.get_child(0).custom_max_width = $"Scrollables".rect_size.x - 80
		else:
			t.texts[8].custom_max_width = $"Scrollables".rect_size.x - 80
		if menu == "credits":
			match get_credit(s):
				"website":
					t.hyperlinks.push_back("https://TrampolineTales.com")
				"vin":
					t.hyperlinks.push_back("https://www.vincentcolavitamusic.com/")
				"zapsplat":
					t.hyperlinks.push_back("https://www.zapsplat.com/")
				"localizedirect1", "localizedirect2", "localizedirect3", "localizedirect4":
					t.hyperlinks.push_back("https://www.localizedirect.com/")
				"jan":
					t.hyperlinks.push_back("https://abyssalnovelist.carrd.co/")
				"Migo":
					t.hyperlinks.push_back("https://twitter.com/MiTranslation")
				"quap":
					t.hyperlinks.push_back("https://twitter.com/QuapperWasTaken")
				"taylan":
					t.hyperlinks.push_back("https://www.linkedin.com/in/taylan-%C3%B6zg%C3%BCr-kele%C5%9F-b15b9423b/")
					t.hyperlinks.push_back("https://www.linkedin.com/in/merdan-avc%C4%B1-618988260/")
				"zh_team":
					t.hyperlinks.push_back("https://space.bilibili.com/12173473?spm_id_from=333.337.0.0")
					t.hyperlinks.push_back("https://b23.tv/BBxGyU5")
				"ar_team":
					t.hyperlinks.push_back("https://translate.games/")
					t.hyperlinks.push_back("https://loclait.com/")
				"toyoch":
					t.hyperlinks.push_back("https://twitter.com/toyoch")
				"nelson":
					t.hyperlinks.push_back("mailto:santananelsontraduction@gmail.com")
				"jpao":
					t.hyperlinks.push_back("mailto:judypao29@yahoo.com")
				"marenthyu":
					t.hyperlinks.push_back("https://twitter.com/marenthyu")
				"mixur":
					t.hyperlinks.push_back("https://www.artstation.com/mixur")
				"PCubiles":
					t.hyperlinks.push_back("https://www.reddit.com/user/PCubiles")
				"kate":
					t.hyperlinks.push_back("https://twitter.com/katelovelymomo")
				"plearn":
					t.hyperlinks.push_back("https://www.youtube.com/plearngaming")
				"kalin":
					t.hyperlinks.push_back("https://www.proz.com/profile/3792850")
				"ar":
					t.rtl = true
				"dedication":
					if CJK_lang or int(display_font) > 0:
						if ui_scaling.text == 1.25 or int(display_font) > 0:
							t.scale_mod = -2
						else:
							t.scale_mod = -1
					elif ui_scaling.text > 1.5:
						t.scale_mod = -1
					elif ui_scaling.text != 1:
						t.scale_mod = 1
		elif menu == "achievements":
			if CJK_lang:
				t.scale_mod = -1
			elif TranslationServer.get_locale() == "ar":
				t.need_to_left = true
		$"Scrollables".add_child(t)
		t.get_child(0).icon_z_index = 9
	else:
		add_child(t)
	if CJK_lang or int(display_font) > 0:
		t.get_child(0).custom_max_width = resolution_x - 152
	else:
		t.texts[8].custom_max_width = resolution_x - 152
	t.force_update = true
	t.set_icon_size()
	t.update()

func godot():
	change_menu("legal", null, false)

func toggle_mod_display(s):
	if displayed_mods.has(s):
		displayed_mods.erase(s)
	else:
		displayed_mods.push_back(s)
	saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	base_y_positions.clear()
	update_setting("mod", null)
	lowest_y_position = $"Scrollables".get_child($"Scrollables".get_children().size() - 1).rect_position.y
	remove_system_buttons()
	add_system_buttons()
	can_update_scrollables = true
	$"Scrollables/Scroll Bar".rect_position.y = saved_scroll_bar_pos_y

func add_button(s):
	var button = preload("res://TT Button.tscn").instance()
	var button2
	var button3
	
	option_buttons.push_back(button)
	
	button.alignment_tags.right = true
	button.color = Color(colors3["button_color_options"])
	button.color_type = "button_color_options"
	button.target = self
	button.toggle = false
	button.options_button = true
	button.scrollable_button = true
	button.selector_alignment = "right"
	if menu != "mods" and menu != "achievements":
		button.cant_go_dirs = ["left", "right"]
	
	if (menu == "audio" and track_names.has(s)) or (menu == "mods" and $"/root/Main".mod_packs.keys().has(s)):
		button2 = preload("res://TT Button.tscn").instance()
		
		button2.color = Color(colors3["button_color_options"])
		button2.color_type = "button_color_options"
		button2.toggle = false
		button2.options_button = true
		button2.scrollable_button = true
		
		if menu == "audio":
			button3 = preload("res://TT Button.tscn").instance()
			button2.alignment_tags.right = true
		
			if tracks[s][0] == 1:
				button2.button_text = "<icon_confirm>"
			else:
				button2.button_text = "<icon_deny>"
		
			button.call = "toggle_endless_track"
			button.args = [track_names[floor((option_buttons.size() - 6) / 3)]]
			
			button2.target = self
			button2.call = "toggle_normal_track"
			button2.args = [track_names[floor((option_buttons.size() - 6) / 3)]]
			
			if tracks[s][1] == 1:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			
			button3.button_text = "<icon_speaker>"
			button3.target = $"/root/Main/Music Player"
			button3.call = "play_set_music"
			button3.args = [track_names[floor((option_buttons.size() - 6) / 3)]]
			
			button3.alignment_tags.right = true
			button3.color = Color(colors3["button_color_options"])
			button3.color_type = "button_color_options"
			button3.toggle = false
			button3.options_button = true
			button3.scrollable_button = true
			
			option_buttons.push_back(button2)
			option_buttons.push_back(button3)
		elif menu == "mods":
			if displayed_mods.has(s):
				button2.button_text = "<icon_down>"
			else:
				button2.button_text = "<icon_right>"
			button2.target = self
			button2.call = "toggle_mod_display"
			button2.args = [s]
			option_buttons.push_back(button2)
			mod_dropdown_buttons += 1
	match s:
		"godot_engine":
			button.call = "godot"
			button.button_text = tr("legal")
			button.toggle = false
			button.hotkey = false
			button.rect_position.y = option_texts[option_texts.size() - 1].rect_position.y + 152 + top_offset
		"resolution":
			button.button_text = str(resolution_x) + " x " + str(resolution_y)
			button.call = "add_dropdown"
			button.args = [s]
		"max_fps":
			if max_fps == 0:
				button.button_text = tr("uncapped")
			else:
				button.button_text = str(max_fps)
			button.call = "add_dropdown"
			button.args = [s]
		"vsync":
			if vsync:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["vsync"]
		"borderless":
			if bordered_window:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["bordered_window"]
		"fullscreen":
			if fullscreen:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["fullscreen"]
		"language":
			match TranslationServer.get_locale():
				"en":
					button.button_text = "English"
				"fr":
					button.button_text = "Français"
				"it":
					button.button_text = "Italiano"
				"de":
					button.button_text = "Deutsch"
				"es_ES":
					button.button_text = "Español-España"
				"es":
					button.button_text = "Español-Latinoamérica"
				"pt_BR":
					button.button_text = "Português-Brasil"
				"pt_PT":
					button.button_text = "Português-Europeu"
				"ru":
					button.button_text = "Русский"
				"bg":
					button.button_text = "български"
				"pl":
					button.button_text = "polski"
				"tr":
					button.button_text = "Türkçe"
				"da_DK":
					button.button_text = "Dansk"
				"zh":
					button.button_text = "简体中文"
				"zh_TW":
					button.button_text = "繁體中文"
				"ja":
					button.button_text = "日本語"
				"ko":
					button.button_text = "한국어"
				"vi":
					button.button_text = "Tiếng Việt"
				"th":
					button.button_text = "ภาษาไทย"
				"ar":
					button.button_text = "اَلْعَرَبِيَّةُ"
			button.call = "add_dropdown"
			button.args = [s]
		"mute_while_in_background":
			if mute_while_in_background:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["mute_while_in_background"]
		"spin_speed":
			if spin_speed != 0:
				button.button_text = str(spin_speed) + "x"
			else:
				button.button_text = tr("instant")
			button.call = "add_dropdown"
			button.args = [s]
		"animation_speed":
			if animation_speed != 0:
				button.button_text = str(animation_speed) + "x"
			else:
				button.button_text = tr("instant")
			button.call = "add_dropdown"
			button.args = [s]
		"counting_speed":
			if counting_speed != 0:
				button.button_text = str(counting_speed) + "x"
			else:
				button.button_text = tr("instant")
			button.call = "add_dropdown"
			button.args = [s]
		"menu_speed":
			if menu_speed != 0:
				button.button_text = str(menu_speed) + "x"
			else:
				button.button_text = tr("instant")
			button.call = "add_dropdown"
			button.args = [s]
		"input_type":
			button.button_text = tr(input_types[input_type])
			button.call = "add_dropdown"
			button.args = [s]
		"font":
			button.button_text = fonts[display_font]
			button.call = "add_dropdown"
			button.args = [s]
		"text_border":
			if text_border:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["text_border"]
		"digit_separators":
			if digit_separators:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["digit_separators"]
		"scientific_notation":
			if scientific_notation:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["scientific_notation"]
		"screen_reader":
			if screen_reader:
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "toggle_change"
			button.args = ["screen_reader"]
		"background", "inventory_background", "inventory_text", "item_count_text", "item_destroy_text", "item_reminder_down_text", "item_reminder_up_text", "reels", "symbol_bonus_text", "symbol_multiplier_text", "symbol_reminder_down_text", "symbol_reminder_up_text", "button_border", "button_color_start", "button_color_continue", "button_color_options", "button_color_stats", "button_color_mods", "button_color_exit", "button_color_promo", "button_color_misc", "button_color_inventory", "button_color_header", "button_color_removal", "button_color_page", "button_color_start_text", "button_color_continue_text", "button_color_options_text", "button_color_stats_text", "button_color_mods_text", "button_color_exit_text", "button_color_promo_text", "button_color_misc_text", "button_color_inventory_text", "button_color_header_text", "text_color_misc", "text_color_keyword", "text_color_common", "text_color_uncommon", "text_color_rare", "text_color_very_rare", "text_color_essence", "options_background", "symbol_background", "item_background", "email_background", "email_border", "scroll_bar", "scroll_bar_border", "reel_border":
			button.button_text = "<color_" + colors3[s] + ">#" + colors3[s] + "<end>"
			button.call = "change_menu"
			button.args = ["colors", s, false]
		"text", "reels_ui", "items_ui", "buttons", "tooltips", "emails", "inventory", "symbol_item_selections":
			button.button_text = str(floor(ui_scaling[s] * 100)) + "%"
			button.call = "add_dropdown"
			button.args = [s]
	if menu == "audio" and s != "mute_while_in_background" and s != "soundtrack" and s != tr("normal") + " " + tr("endless") and not track_names.has(s):
		if self[s].muted:
			button.button_text = "<icon_speaker_muted>"
		else:
			button.button_text = "<icon_speaker>"
		button.call = "toggle_change"
		button.args = [s]
	
	if menu == "mods":
		if button2 == null:
			var mod = s.substr(6, s.find(">") - 6)
			if not disabled_mods.has(mod):
				button.button_text = "<icon_confirm>"
			else:
				button.button_text = "<icon_deny>"
			button.call = "disable_mod"
			button.args = [mod]
		else:
			var inc = 0
			var non_counted_mods = 0
			for m in $"/root/Main".mod_packs[s]:
				if m.mod_type == "art_replacement":
					if disabled_mods.has(m.type.substr(0, m.type.find("_" + str(m.pack_num))) + "_STEAM_ID_" + str(m.author_id) + "_PACK_" + str(m.pack_num)):
						inc += 1
				elif m.mod_type == "email" or m.mod_type == "group_addition" or m.mod_type == "inherited_effects":
					non_counted_mods += 1
				elif disabled_mods.has(m.type):
					inc += 1
			if inc == 0:
				button.button_text = "<icon_confirm>"
			elif inc == $"/root/Main".mod_packs[s].size() - non_counted_mods:
				button.button_text = "<icon_deny>"
			else:
				button.button_text = "<icon_squiggle>"
			button.call = "disable_mod_pack"
			button.args = [s]
	
	if menu == "input":
		var hotkey_num = option_buttons.size() - 1
		button.button_text = hotkeys[assignable_hotkeys[floor(hotkey_num / 2)]][hotkey_num % 2 + 2]
		button.toggle = true
		button.hotkey = true
		button.cant_go_dirs.clear()
		button.call = "assign_hotkey"
		button.args = [button]
		button.alignment_tags.dont = true
		$"Hotkeys".add_child(button)
		button.text_node.text_mod = -floor((1 - ui_scaling.text) / 0.25) - 1
		if int(display_font) > 0:
			button.text_node.text_mod = 0
			button.text_node.base_scale = 0.5
			button.text_node.change_set_size(0.5)
		elif ui_scaling.text != 1:
			button.text_node.change_set_size(button.text_node.base_scale)
		if not CJK_lang and int(display_font) == 0:
			$"Input Header 1".rect_position = Vector2(16, top_offset)
			$"Input Header 2".rect_position = Vector2(resolution_x - 300 * ui_scaling.text - $"Input Header 2".get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".rect_scale.x * 4.0 * ui_scaling.text, top_offset)
			$"Input Header 3".rect_position = Vector2($"Input Header 2".rect_position.x + $"Input Header 2".get_child(0).get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".current_scale * 4.0 + 60 * ui_scaling.text, top_offset)
			if hotkey_num % 2 == 0:
				button.rect_position = Vector2($"Input Header 2".rect_position.x + $"Input Header 2".get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".current_scale * 2 - 152, 0)
			else:
				button.rect_position = Vector2($"Input Header 3".rect_position.x + $"Input Header 3".get_font("font").get_string_size(tr("controller")).x * $"Input Header 3".current_scale * 2 - 152, 0)
			button.background.rect_size = Vector2(312, 36 * ui_scaling.text)
		else:
			$"Input Header 1".rect_position = Vector2(16, top_offset)
			if TranslationServer.get_locale() == "vi":
				$"Input Header 2".rect_position = Vector2(resolution_x - 460 * ui_scaling.text - $"Input Header 2".get_child(0).get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".rect_scale.x / 2 * ui_scaling.text, top_offset)
			else:
				$"Input Header 2".rect_position = Vector2(resolution_x - 400 * ui_scaling.text - $"Input Header 2".get_child(0).get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".rect_scale.x / 2 * ui_scaling.text, top_offset)
			$"Input Header 3".rect_position = Vector2($"Input Header 2".rect_position.x + $"Input Header 2".get_child(0).get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".current_scale + 60, top_offset)
			if display_font > 0 and TranslationServer.get_locale() != "vi" and TranslationServer.get_locale() != "th" and TranslationServer.get_locale() != "ar":
				if hotkey_num % 2 == 0:
					button.rect_position = Vector2($"Input Header 2".rect_position.x + $"Input Header 2".get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".current_scale * 4 - 112, 0)
				else:
					button.rect_position = Vector2($"Input Header 3".rect_position.x + $"Input Header 3".get_font("font").get_string_size(tr("controller")).x * $"Input Header 3".current_scale * 4 - 112, 0)
			else:
				if hotkey_num % 2 == 0:
					button.rect_position = Vector2($"Input Header 2".rect_position.x + $"Input Header 2".get_font("font").get_string_size(tr("keyboard")).x * $"Input Header 2".current_scale / 2 - 112, 0)
				else:
					button.rect_position = Vector2($"Input Header 3".rect_position.x + $"Input Header 3".get_font("font").get_string_size(tr("controller")).x * $"Input Header 3".current_scale / 2 - 112, 0)
			button.background.rect_size = Vector2(224, 36 * ui_scaling.text)
		button.base_x = button.rect_position.x
	elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "mods" or menu == "gameplay" or menu == "legal":
		$"Scrollables".add_child(button)
		if button2 != null:
			$"Scrollables".add_child(button2)
		if button3 != null:
			$"Scrollables".add_child(button3)
	else:
		add_child(button)
	
	if TranslationServer.get_locale() == "ru" and button.text_node.raw_string == tr("uncapped"):
		button.scale_mod = -1
	elif TranslationServer.get_locale() == "ar" and s == "language":
		button.button_text = "العربية"
		button.text_node.raw_string = "العربية"
		button.text_node.rtl = true
		button.text_node.align = Label.ALIGN_RIGHT
	
	if CJK_lang or int(display_font) > 0:
		button.text_node.icon_z_index = 10
		button.text_node.get_child(0).custom_max_width = 10000
		if button2 != null:
			button2.text_node.icon_z_index = 10
			button2.text_node.get_child(0).custom_max_width = 10000
		if button3 != null:
			button3.text_node.icon_z_index = 10
			button3.text_node.get_child(0).custom_max_width = 10000
	else:
		button.text_node.texts[8].icon_z_index = 10
		button.text_node.texts[8].custom_max_width = 10000
		if button2 != null:
			button2.text_node.texts[8].icon_z_index = 10
			button2.text_node.texts[8].custom_max_width = 10000
		if button3 != null:
			button3.text_node.texts[8].icon_z_index = 10
			button3.text_node.texts[8].custom_max_width = 10000
	button.text_node.force_update = true
	button.text_node.update()
	button.button_text = button.text_node.text
	button.update_size()
	button.correct_size()
	if button2 != null:
		button2.text_node.force_update = true
		button2.text_node.update()
		button2.button_text = button2.text_node.text
		button2.selector_alignment = "right"
		button2.cant_go_dirs = ["left"]
		button2.update_size()
		button2.correct_size()
	if button3 != null:
		button3.text_node.force_update = true
		button3.text_node.update()
		button3.button_text = button3.text_node.text
		button3.selector_alignment = "right"
		button3.cant_go_dirs = ["right"]
		button3.update_size()
		button3.correct_size()
	if menu == "audio":
		if option_buttons.size() == 6:
			button.rect_position.y = 176 + (option_sliders.size() + 3) * y_offset + (option_sliders.size() + 3) + (option_buttons.size() - 5) * spacing_offset
			button.cant_go_dirs.clear()
		elif option_buttons.size() > 6:
			button.rect_position.y = 508 + floor(option_buttons.size() / 3) * spacing_offset
			button2.rect_position.y = 508 + floor(option_buttons.size() / 3) * spacing_offset
			button3.rect_position.y = 508 + floor(option_buttons.size() / 3) * spacing_offset
			button.cant_go_dirs.clear()
		else:
			button.rect_position.y = 94 + y_offset + (option_sliders.size() + option_buttons.size() - 1) * y_offset
			button.selector_alignment = "slider"
	elif button.call != "godot":
		if menu == "mods":
			if $"/root/Main".mod_packs.keys().has(s):
				button2.rect_position = Vector2(32, 112 + (option_buttons.size() - mod_dropdown_buttons) * spacing_offset)
			button.rect_position.y = 112 + (option_buttons.size() - mod_dropdown_buttons) * spacing_offset
		else:
			button.rect_position.y = 112 + (option_buttons.size() + option_sliders.size()) * spacing_offset
	button.button_text = button.text_node.raw_string
	if button2 != null:
		button2.button_text = button2.text_node.raw_string
	if button3 != null:
		button3.button_text = button3.text_node.raw_string
	if menu == "input":
		pass
	elif TranslationServer.get_locale() != "ru" and not ((TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "es_ES" or TranslationServer.get_locale() == "es" or TranslationServer.get_locale() == "pl") and menu == "gameplay"):
		if menu == "audio" and option_buttons.size() > 6:
			button.rect_position.x = 880 - button.rect_size.x * 2 * (((option_buttons.size() - 5) % 3) + 1)
			button2.rect_position.x = 880 - button2.rect_size.x * 2 * (((option_buttons.size() - 4) % 3) + 1)
			button3.rect_position.x = 880 - button3.rect_size.x * 2 * (((option_buttons.size() - 3) % 3) + 1)
		else:
			button.rect_position.x = 880 - button.rect_size.x
	else:
		if menu == "audio" and option_buttons.size() > 6:
			button.rect_position.x = 960 - button.rect_size.x * 2 * (((option_buttons.size() - 5) % 3) + 1)
			button2.rect_position.x = 960 - button2.rect_size.x * 2 * (((option_buttons.size() - 4) % 3) + 1)
			button3.rect_position.x = 960 - button3.rect_size.x * 2 * (((option_buttons.size() - 3) % 3) + 1)
		else:
			button.rect_position.x = 960 - button.rect_size.x
	if s == "godot_engine":
		button.rect_position.x = resolution_x / 2 - button.rect_size.x / 2
		button.alignment_tags["dont"] = true
		button.selector_alignment = "godot"
	button.base_x = button.rect_position.x
	if button2 != null:
		button2.base_x = button2.rect_position.x
	if button3 != null:
		button3.base_x = button3.rect_position.x
	
	if CJK_lang or RTL_lang or int(display_font) > 0:
		for i in button.text_node.icons:
			i.update_hitbox()
		if button2 != null:
			for i in button2.text_node.icons:
				i.update_hitbox()
		if button3 != null:
			for i in button3.text_node.icons:
				i.update_hitbox()
	else:
		for i in button.text_node.texts[8].icons:
			i.update_hitbox()
		if button2 != null:
			for i in button2.text_node.texts[8].icons:
				i.update_hitbox()
		if button3 != null:
			for i in button3.text_node.texts[8].icons:
				i.update_hitbox()

func toggle_normal_track(s):
	if tracks[s][0] == 0:
		tracks[s][0] = 1
	elif tracks[s][0] == 1:
		tracks[s][0] = 0
	update_setting(s, null)

func toggle_endless_track(s):
	if tracks[s][1] == 0:
		tracks[s][1] = 1
	elif tracks[s][1] == 1:
		tracks[s][1] = 0
	update_setting(s, null)

func toggle_change(s):
	if menu == "audio" and s != "mute_while_in_background":
		self[s].muted = !self[s].muted
	else:
		self[s] = !self[s]
	update_setting(s, null)
	if menu == "audio":
		$"Scrollables/Scroll Bar".update_positions("check")
	
func disable_mod(mod):
	if not disabled_mods.has(mod):
		disabled_mods.push_back(mod)
	else:
		while disabled_mods.has(mod):
			disabled_mods.erase(mod)
	saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	update_setting("mod", null)
	can_update_scrollables = true
	$"Scrollables/Scroll Bar".rect_position.y = saved_scroll_bar_pos_y

func disable_mod_pack(mod):
	var inc = 0
	var d_mods = []
	for m in $"/root/Main".mod_packs[mod]:
		if m.mod_type == "art_replacement":
			if disabled_mods.has(m.type.substr(0, m.type.find("_" + str(m.pack_num))) + "_STEAM_ID_" + str(m.author_id) + "_PACK_" + str(m.pack_num)):
				inc += 1
			d_mods.push_back(m.type.substr(0, m.type.find("_" + str(m.pack_num))) + "_STEAM_ID_" + str(m.author_id) + "_PACK_" + str(m.pack_num))
		else:
			if disabled_mods.has(m.type):
				inc += 1
			d_mods.push_back(m.type)
	if inc > 0:
		for d in d_mods:
			while disabled_mods.has(d):
				disabled_mods.erase(d)
	else:
		for d in d_mods:
			if not disabled_mods.has(d):
				disabled_mods.push_back(d)
	saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	update_setting("mod", null)
	can_update_scrollables = true
	$"Scrollables/Scroll Bar".rect_position.y = saved_scroll_bar_pos_y

func add_menu_buttons():
	add_menu_button("graphics")
	add_menu_button("audio")
	add_menu_button("gameplay")
	add_menu_button("input")
	add_menu_button("credits")
	var total_width = 0
	for m in range(menu_buttons.size()):
		total_width += (menu_buttons[m].rect_size.x + 16 + floor(m / 16)) * menu_buttons[m].rect_scale.x
	var last_pos = 0
	for m in range(menu_buttons.size()):
		menu_buttons[m].rect_position = Vector2(512 - total_width / 2 + last_pos, reset_pos + 16)
		menu_buttons[m].base_x = menu_buttons[m].rect_position.x
		last_pos = menu_buttons[m].rect_position.x + menu_buttons[m].rect_size.x - menu_buttons[0].rect_position.x + 16
	top_offset = menu_buttons[0].rect_position.y + menu_buttons[0].rect_size.y + 16

func tts():
	if not screen_reader:
		return
	var t_label = preload("res://Outline Label.tscn").instance()
	t_label.visible = false
	t_label.raw_string = ""
	add_child(t_label)
	for s in $"Scrollables".get_children():
		if s is Label:
			t_label.raw_string += tr(s.raw_string) + "\n"
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		t_label.get_child(0).custom_max_width = 10000000
	else:
		t_label.custom_max_width = 10000000
	t_label.tts = true
	t_label.update()
	$"/root/Main".tts(t_label.raw_string, [], self)
	remove_child(t_label)
	t_label.queue_free()

func change_menu(p_menu, color, menu_button_pushed):
	are_you_sure_timer = 0
	lowest_y_position = 0
	lowest_y_size = 0
	lowest_global_pos_y = 0
	if p_menu == "credits":
		$"/root/Main".endless_toggle_counter += 1
	else:
		$"/root/Main".endless_toggle_counter = 0
	base_y_positions.clear()
	if CJK_lang or int(display_font) > 0:
		$"Color Text".rect_position.y = header_text.rect_position.y + header_text.get_font("font").get_height() * 3 * header_text.current_scale
	else:
		$"Color Text".rect_position.y = header_text.rect_position.y + header_text.get_font("font").get_height() * 3 * header_text.current_scale * 4
	
	$"Hotkeys".visible = false
	$"Scrollables".visible = false
	
	if p_menu == "colors":
		saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	elif p_menu == "credits":
		$"/root/Main/Stats Sprite/Stats".unlock_achievement(38, true)
	
	$"Hotkeys/Scroll Bar".rect_position.y = $"Hotkeys/Scroll Bar".top
	if p_menu == menu and not menu_button_pushed:
		$"Scrollables/Scroll Bar".rect_position.y = saved_scroll_bar_pos_y
	else:
		$"Scrollables/Scroll Bar".rect_position.y = $"Scrollables/Scroll Bar".top
	if p_menu == "colors":
		current_color = color
		menu = current_color
		dropdown = true
		match current_color:
			"item_count_text":
				header_text.raw_string += "\n\n" + (tr("item_text"))
				header_text.values = [1]
			"item_destroy_text":
				header_text.raw_string += "\n\n" + (tr("item_text"))
				header_text.values = [2]
			"item_reminder_down_text":
				header_text.raw_string += "\n\n" + (tr("item_text"))
				header_text.values = [3]
			"item_reminder_up_text":
				header_text.raw_string += "\n\n" + (tr("item_text"))
				header_text.values = [4]
			"symbol_bonus_text":
				header_text.raw_string += "\n\n" + (tr("symbol_text"))
				header_text.values = [1]
			"symbol_multiplier_text":
				header_text.raw_string += "\n\n" + (tr("symbol_text"))
				header_text.values = [2]
			"symbol_reminder_down_text":
				header_text.raw_string += "\n\n" + (tr("symbol_text"))
				header_text.values = [3]
			"symbol_reminder_up_text":
				header_text.raw_string += "\n\n" + (tr("symbol_text"))
				header_text.values = [4]
			"button_color_start":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [1]
			"button_color_continue":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [2]
			"button_color_options":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [3]
			"button_color_stats":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [4]
			"button_color_mods":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [5]
			"button_color_exit":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [6]
			"button_color_promo":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [7]
			"button_color_misc":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [8]
			"button_color_inventory":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [9]
			"button_color_header":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [10]
			"button_color_removal":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [11]
			"button_color_page":
				header_text.raw_string += "\n\n" + (tr("button_color"))
				header_text.values = [12]
			"button_color_start_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [1]
			"button_color_continue_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [2]
			"button_color_options_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [3]
			"button_color_stats_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [4]
			"button_color_mods_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [5]
			"button_color_exit_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [6]
			"button_color_promo_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [7]
			"button_color_misc_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [8]
			"button_color_inventory_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [9]
			"button_color_header_text":
				header_text.raw_string += "\n\n" + (tr("button_text"))
				header_text.values = [10]
			"text_color_misc":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [1]
			"text_color_keyword":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [2]
			"text_color_common":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [3]
			"text_color_uncommon":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [4]
			"text_color_rare":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [5]
			"text_color_very_rare":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [6]
			"text_color_essence":
				header_text.raw_string += "\n\n" + (tr("text_color"))
				header_text.values = [7]
			_:
				header_text.raw_string += "\n\n" + tr(current_color)
		$"Color Text".visible = true
		var color_str = "#" + Color(colors3[current_color]).to_html(false).to_upper()
		$"Color Text".raw_string = "<color_" + Color(colors3[current_color]).to_html(false).to_upper() + ">" + color_str + "<end>"
		if CJK_lang:
			$"Color Text".rect_position.x = resolution_x / 2 - $"Color Text".get_font("font").get_string_size(color_str).x * $"Color Text".current_scale / 2.0
		elif int(display_font) > 0:
			$"Color Text".rect_position.x = resolution_x / 2 - $"Color Text".get_child(0).get_font("font").get_string_size(color_str).x * $"Color Text".current_scale / 2.0
		else:
			$"Color Text".rect_position.x = resolution_x / 2 - $"Color Text".get_font("font").get_string_size(color_str).x * $"Color Text".current_scale * 2.0
		$"Color Text".alignment_tags.centered = true
	else:
		menu = p_menu
		current_color = null
		$"Color Text".visible = false
	get_spacing()
	
	if menu == "input":
		$"Hotkeys".visible = true
		can_update_scrollables = true
	elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "mods" or menu == "gameplay" or menu == "legal":
		$"Scrollables".visible = true
		can_update_scrollables = true
	elif current_color != null:
		$"Color Text".visible = true
	
	remove_buttons()
	add_buttons()
	
	if menu == "input":
		$"Hotkeys/Scroll Bar".update_positions("init")
		lowest_y_position = $"Hotkeys".get_child($"Hotkeys".get_children().size() - 1).rect_position.y
		$"Hotkeys/Scroll Bar".update_positions("check")
	elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "mods" or menu == "gameplay":
		$"Scrollables/Scroll Bar".update_positions("init")
		var lyp = 0
		for s in $"Scrollables".get_children():
			if s is Label:
				s.update()
				if CJK_lang or int(display_font) > 0 or (s.get_child(0) is Label and s.get_child(0).get_font("font").get_path() != "res://PICO-8.tres"):
					if lyp < s.rect_position.y + s.get_font("font").get_height() / 2 * ui_scaling.text * s.get_child(0).text.count("\n"):
						lyp = s.rect_position.y + s.get_font("font").get_height() / 2 * ui_scaling.text * s.get_child(0).text.count("\n")
				else:
					if lyp < s.rect_position.y + s.get_font("font").get_height() * 4 * ui_scaling.text * s.texts[8].text.count("\n"):
						lyp = s.rect_position.y + s.get_font("font").get_height() * 4 * ui_scaling.text * s.texts[8].text.count("\n")
			elif s is TextureButton and lyp < s.rect_position.y:
				lyp = s.rect_position.y
		lowest_y_position = lyp
		$"Scrollables/Scroll Bar".update_positions("check")
	if $"Color Text".visible:
		$"/root/Main".change_current_menu_path("colors")
	elif init_scaling_set:
		$"/root/Main".change_current_menu_path("/root/Main/Options Sprite/Options/" + menu)
	else:
		init_scaling_set = true
	
	if menu == "credits" or menu == "achievements":
		tts()

func add_system_buttons():
	back_button = preload("res://TT Button.tscn").instance()
	
	back_button.button_text = tr("back")
	back_button.scale_mod = -1
	back_button.color = Color(colors3["button_color_options"])
	back_button.color_type = "button_color_options"
	back_button.target = self
	if menu == "legal":
		back_button.call = "change_menu"
		back_button.args = ["credits", null, false]
	else:
		back_button.call = "close"
	back_button.toggle = false
	back_button.shortcuts = ["options"]
	back_button.options_button = true
	back_button.alignment_tags.right = true
	
	add_child(back_button)
	
	if CJK_lang or int(display_font) > 0:
		back_button.text_node.get_child(0).custom_max_width = 100000
	else:
		back_button.text_node.texts[8].custom_max_width = 100000
	back_button.text_node.force_update = true
	back_button.text_node.update()
	back_button.button_text = back_button.text_node.text
	back_button.update_size()
	back_button.correct_size()
	
	back_button.rect_position = Vector2(1008 - back_button.rect_size.x * back_button.rect_scale.x, 8)
	back_button.base_x = back_button.rect_position.x
	
	if menu != "credits" and menu != "mods" and menu != "achievements" and menu != "legal" and (not dropdown or current_color != null):
		reset_button = preload("res://TT Button.tscn").instance()
		
		reset_button.button_text = tr("reset_to_default")
		reset_button.scale_mod = -1
		reset_button.color = Color(colors3["button_color_options"])
		reset_button.color_type = "button_color_options"
		reset_button.target = self
		reset_button.call = "reset_to_default"
		reset_button.args = [menu, true]
		reset_button.toggle = false
		reset_button.options_button = true
		reset_button.alignment_tags.centered = true
		
		add_child(reset_button)
		
		reset_button.text_node.force_update = true
		reset_button.text_node.update()
		reset_button.button_text = reset_button.text_node.text
		reset_button.update_size()
		reset_button.correct_size()
		
		reset_button.rect_position = Vector2(512 - reset_button.rect_size.x * reset_button.rect_scale.x / 2, spacing_offset + 6)
		reset_pos = reset_button.rect_position.y + reset_button.rect_size.y
		reset_button.base_x = reset_button.rect_position.x
	
	if not $"/root/Main/Title".visible and not dropdown:
		exit_button = preload("res://TT Button.tscn").instance()
		
		exit_button.button_text = tr("main_menu")
		exit_button.scale_mod = -1
		exit_button.color = Color(colors3["button_color_options"])
		exit_button.color_type = "button_color_options"
		exit_button.target = $"/root/Main"
		exit_button.call = "title"
		exit_button.toggle = false
		exit_button.options_button = true
		exit_button.alignment_tags.centered = true
		
		add_child(exit_button)
		
		exit_button.text_node.force_update = true
		exit_button.text_node.update()
		exit_button.button_text = exit_button.text_node.text
		exit_button.update_size()
		exit_button.correct_size()
		
		exit_button.rect_position = Vector2(512 - exit_button.rect_scale.x * exit_button.rect_size.x / 2, 12)
		exit_button.base_x = exit_button.rect_position.x
	var scroll_bar
	if menu == "input":
		scroll_bar = $"Hotkeys/Scroll Bar"
		scroll_bar.rect_position.y = scroll_bar.top
		var increment = 0
		for i in $"Hotkeys".get_children():
			if i != scroll_bar:
				i.rect_position.y = 40 * $"/root/Main/Options Sprite/Options".ui_scaling.text * floor(increment / 3)
				add_to_base_y_positions(i)
				increment += 1
		if lowest_y_position < scroll_bar.bottom - $"Hotkeys".rect_position.y:
			increment = 0
			for i in $"Hotkeys".get_children():
				if i != scroll_bar:
					var font_offset = 40 * $"/root/Main/Options Sprite/Options".ui_scaling.text
					i.rect_position.y = font_offset * floor(increment / 3)
					increment += 1
			scroll_bar.visible = false
		else:
			scroll_bar.visible = true
	elif (lowest_y_position >= $"Scrollables/Scroll Bar".bottom or menu == "legal") and menu != "input":
		scroll_bar = $"Scrollables/Scroll Bar"
		scroll_bar.visible = true
		if saved_scroll_bar_pos_y == scroll_bar.top:
			scroll_bar.rect_position.y = scroll_bar.top
	else:
		scroll_bar = $"Scrollables/Scroll Bar"
		scroll_bar.visible = false
		if saved_scroll_bar_pos_y == scroll_bar.top:
			scroll_bar.rect_position.y = scroll_bar.top
	scroll_bar.need_to_update = true

func add_menu_button(type):
	var b = preload("res://TT Button.tscn").instance()
	b.button_text = tr(type)
	b.call = "change_menu"
	b.args = [type, null, true]
	menu_buttons.push_back(b)
	
	b.color = Color(colors3["button_color_header"])
	b.color_type = "button_color_header"
	b.target = self
	b.toggle = false
	b.options_button = true
		
	if type == "credits" and TranslationServer.get_locale() == "ru" and (resolution_x < 1280 or (resolution_x == 1280 and ui_scaling.buttons == 1.25)):
		b.scale_mod = -1
	
	add_child(b)
	
	b.selector_alignment = "centered"
	if type == "graphics":
		starter_button = b
		b.cant_go_dirs = ["left"]
		b.selector_alignment = "slider"
	elif type == "credits":
		b.cant_go_dirs = ["right"]
	
	if CJK_lang or RTL_lang or int(display_font) > 0:
		b.text_node.icon_z_index = 10
	else:
		b.text_node.texts[8].icon_z_index = 10
	b.text_node.force_update = true
	b.text_node.update()
	b.button_text = b.text_node.text
	b.update_size()
	b.correct_size()
	b.button_text = b.text_node.raw_string
	b.alignment_tags.centered = true
	
	if CJK_lang or RTL_lang or int(display_font) > 0:
		for i in b.text_node.icons:
			i.update_hitbox()
	else:
		for i in b.text_node.texts[8].icons:
			i.update_hitbox()
			
	if menu == "input":
		$"Input Header 1".visible = true
		$"Input Header 2".visible = true
		$"Input Header 3".visible = true
	else:
		$"Input Header 1".visible = false
		$"Input Header 2".visible = false
		$"Input Header 3".visible = false

func update_mod_str(handle, result, results_returned, total_matching, cached):
	for i in results_returned:
		var res = Steam.getQueryUGCResult(handle, i)
		var inc = 0
		for o in option_texts:
			if o.raw_string == str(res.file_id):
				o.raw_string = res.title
				saved_modpack_keys[str(res.file_id)] = res.title
				o.force_update = true
				break
			inc += 1

func add_buttons():
	var fm = false
	mod_dropdown_buttons = 0
	match menu:
		"graphics":
			if OS.get_name() == "OSX":
				option_types = ["language", "font", "resolution", "max_fps", "vsync", "fullscreen", "ui_scaling", "text", "reels_ui", "items_ui", "buttons", "tooltips", "emails", "inventory", "symbol_item_selections", "colors", "background", "reels", "inventory_background", "inventory_text", "item_count_text", "item_destroy_text", "item_reminder_down_text", "item_reminder_up_text", "symbol_bonus_text", "symbol_multiplier_text", "symbol_reminder_down_text", "symbol_reminder_up_text", "button_border", "button_color_start", "button_color_continue", "button_color_options", "button_color_stats", "button_color_mods", "button_color_exit", "button_color_promo", "button_color_misc", "button_color_inventory", "button_color_header", "button_color_removal", "button_color_page", "button_color_start_text", "button_color_continue_text", "button_color_options_text", "button_color_stats_text", "button_color_mods_text", "button_color_exit_text", "button_color_promo_text", "button_color_misc_text", "button_color_inventory_text", "button_color_header_text", "text_color_misc", "text_color_keyword", "text_color_common", "text_color_uncommon", "text_color_rare", "text_color_very_rare", "text_color_essence", "options_background", "symbol_background", "item_background", "email_background", "email_border", "scroll_bar", "scroll_bar_border", "reel_border"]
			else:
				option_types = ["language", "font", "resolution", "max_fps", "vsync", "fullscreen", "borderless", "ui_scaling", "text", "reels_ui", "items_ui", "buttons", "tooltips", "emails", "inventory", "symbol_item_selections", "colors", "background", "reels", "inventory_background", "inventory_text", "item_count_text", "item_destroy_text", "item_reminder_down_text", "item_reminder_up_text", "symbol_bonus_text", "symbol_multiplier_text", "symbol_reminder_down_text", "symbol_reminder_up_text", "button_border", "button_color_start", "button_color_continue", "button_color_options", "button_color_stats", "button_color_mods", "button_color_exit", "button_color_promo", "button_color_misc", "button_color_inventory", "button_color_header", "button_color_removal", "button_color_page", "button_color_start_text", "button_color_continue_text", "button_color_options_text", "button_color_stats_text", "button_color_mods_text", "button_color_exit_text", "button_color_promo_text", "button_color_misc_text", "button_color_inventory_text", "button_color_header_text", "text_color_misc", "text_color_keyword", "text_color_common", "text_color_uncommon", "text_color_rare", "text_color_very_rare", "text_color_essence", "options_background", "symbol_background", "item_background", "email_background", "email_border", "scroll_bar", "scroll_bar_border", "reel_border"]
			if CJK_lang or TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "th":
				option_types.erase("font")
		"audio":
			option_types = ["master_volume", "music", "sfx", "mute_while_in_background", "soundtrack", tr("normal") + " " + tr("endless")]
			for k in track_names:
				option_types.push_back(k)
		"gameplay":
			option_types = ["spin_speed", "animation_speed", "counting_speed", "menu_speed", "input_type", "screen_reader", "digit_separators", "scientific_notation"]
		"input":
			option_types = assignable_hotkeys
			option_types.erase("scroll_up")
			option_types.erase("scroll_down")
		"credits":
			option_types = []
			if CJK_lang and TranslationServer.get_locale() != "ko":
				for c in CJK_credits.keys():
					option_types.push_back(CJK_credits[c])
			else:
				for c in credits.keys():
					option_types.push_back(credits[c])
		"achievements":
			var unlocked_chievos = []
			option_types = []
			if $"/root/Main/Stats Sprite/Stats".achievements_unlocked.find(null) != -1:
				if TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "ja":
					option_types = ["<text_color_common>" + tr("locked") + "：<end>"]
				elif TranslationServer.get_locale() == "fr":
					option_types = ["<text_color_common>" + tr("locked") + " :<end>"]
				else:
					option_types = ["<text_color_common>" + tr("locked") + ":<end>"]
			for i in range($"/root/Main/Stats Sprite/Stats".achievements_unlocked.size()):
				if $"/root/Main/Stats Sprite/Stats".achievements_unlocked[i] == true:
					unlocked_chievos.push_back("<icon_a" + str(i + 1) + "> " + tr("achievement_" + str(i)))
				elif $"/root/Main/Stats Sprite/Stats".achievements_unlocked[i] == null:
					option_types.push_back("<icon_a" + str(i + 1) + "-L> <text_color_common>" + tr("achievement_" + str(i)) + "<end>")
			if $"/root/Main/Stats Sprite/Stats".achievements_unlocked.find(true) != -1:
				if TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "ja":
					option_types.push_back("<text_color_misc>" + tr("unlocked") + "：<end>")
				elif TranslationServer.get_locale() == "fr":
					option_types.push_back("<text_color_misc>" + tr("unlocked") + " :<end>")
				else:
					option_types.push_back("<text_color_misc>" + tr("unlocked") + ":<end>")
				for i in unlocked_chievos:
					option_types.push_back(i)
		"legal":
			option_types = [tr("legal_stuff")]
		"background", "inventory_background", "inventory_text", "item_count_text", "item_destroy_text", "item_reminder_down_text", "item_reminder_up_text", "reels", "symbol_bonus_text", "symbol_multiplier_text", "symbol_reminder_down_text", "symbol_reminder_up_text", "button_border", "button_color_start", "button_color_continue", "button_color_options", "button_color_stats", "button_color_mods", "button_color_exit", "button_color_promo", "button_color_misc", "button_color_inventory", "button_color_header", "button_color_removal", "button_color_page", "button_color_start_text", "button_color_continue_text", "button_color_options_text", "button_color_stats_text", "button_color_mods_text", "button_color_exit_text", "button_color_promo_text", "button_color_misc_text", "button_color_inventory_text", "button_color_header_text", "text_color_misc", "text_color_keyword", "text_color_common", "text_color_uncommon", "text_color_rare", "text_color_very_rare", "text_color_essence", "options_background", "symbol_background", "item_background", "email_background", "email_border", "scroll_bar", "scroll_bar_border", "reel_border":
			option_types = ["R", "G", "B"]
		"mods":
			option_types = []
			var ugcs = []
			Steam.connect("ugc_query_completed", self, "update_mod_str")
			for k in $"/root/Main".mod_packs.keys():
				option_types.push_back(k)
				if not saved_modpack_keys.has(k) and int(k) > 0:
					ugcs.push_back(int(k))
				if displayed_mods.has(k):
					for t in $"/root/Main".mod_packs[k]:
						var m
						if $"/root/Main".mod_data.symbols.has(t.type):
							m = $"/root/Main".mod_data.symbols[t.type]
							if $"/root/Main".icon_texture_database.has(m.type) or m.art_replacement or m.fine_print or m.apartment_floor:
								option_types.push_back("<icon_" + m.type + "> ")
							else:
								if not m.art_replacement and not m.fine_print and not m.apartment_floor:
									continue
								option_types.push_back("<icon_missing> ")
							if m.localized_names.keys().has(TranslationServer.get_locale()):
								option_types[option_types.size() - 1] += m.localized_names[TranslationServer.get_locale()]
							else:
								option_types[option_types.size() - 1] += m.display_name
						elif $"/root/Main".mod_data.items.has(t.type):
							m = $"/root/Main".mod_data.items[t.type]
							if $"/root/Main".icon_texture_database.has(m.type) or m.art_replacement:
								option_types.push_back("<icon_" + m.type + "> ")
							else:
								option_types.push_back("<icon_item_missing> ")
							if m.localized_names.keys().has(TranslationServer.get_locale()):
								option_types[option_types.size() - 1] += m.localized_names[TranslationServer.get_locale()]
							else:
								option_types[option_types.size() - 1] += m.display_name
			if ugcs.size() > 0:
				var n = Steam.createQueryUGCDetailsRequest(ugcs)
				Steam.setReturnMetadata(n, false)
				Steam.sendQueryUGCRequest(n)
				Steam.releaseQueryUGCRequest(n)
	add_system_buttons()
	if current_color == null and menu != "mods" and menu != "achievements":
		$"Input Header 1".raw_string = "<text_color_keyword>" + tr("command") + "<end>"
		$"Input Header 1".rect_position = Vector2(16, top_offset)
		$"Input Header 2".rect_position.y = top_offset
		$"Input Header 3".rect_position.y = top_offset
		if CJK_lang or int(display_font) > 0:
			hotkey_offset = top_offset + $"Input Header 1".get_child(0).get_font("font").get_height() * $"Input Header 1".current_scale + 4
		else:
			hotkey_offset = top_offset + $"Input Header 1".get_font("font").get_height() * 4 * $"Input Header 1".current_scale + 4
		add_menu_buttons()
	elif menu == "mods":
		$"Input Header 1".rect_position = Vector2(16, 88)
		$"Input Header 1".raw_string = "<color_800080>" + tr("mod_header") + "<end>"
		$"Input Header 1".visible = true
		$"Input Header 2".visible = false
		$"Input Header 3".visible = false
	elif menu == "achievements":
		$"Input Header 1".visible = false
		$"Input Header 2".visible = false
		$"Input Header 3".visible = false
	for b in range(option_types.size()):
		match option_types[b]:
			"item_count_text":
				add_option_text(tr("item_text"))
				option_texts[b].values = [1]
			"item_destroy_text":
				add_option_text(tr("item_text"))
				option_texts[b].values = [2]
			"item_reminder_down_text":
				add_option_text(tr("item_text"))
				option_texts[b].values = [3]
			"item_reminder_up_text":
				add_option_text(tr("item_text"))
				option_texts[b].values = [4]
			"symbol_bonus_text":
				add_option_text(tr("symbol_text"))
				option_texts[b].values = [1]
			"symbol_multiplier_text":
				add_option_text(tr("symbol_text"))
				option_texts[b].values = [2]
			"symbol_reminder_down_text":
				add_option_text(tr("symbol_text"))
				option_texts[b].values = [3]
			"symbol_reminder_up_text":
				add_option_text(tr("symbol_text"))
				option_texts[b].values = [4]
			"button_color_start":
				add_option_text(tr("button_color"))
				option_texts[b].values = [1]
			"button_color_continue":
				add_option_text(tr("button_color"))
				option_texts[b].values = [2]
			"button_color_options":
				add_option_text(tr("button_color"))
				option_texts[b].values = [3]
			"button_color_stats":
				add_option_text(tr("button_color"))
				option_texts[b].values = [4]
			"button_color_mods":
				add_option_text(tr("button_color"))
				option_texts[b].values = [5]
			"button_color_exit":
				add_option_text(tr("button_color"))
				option_texts[b].values = [6]
			"button_color_promo":
				add_option_text(tr("button_color"))
				option_texts[b].values = [7]
			"button_color_misc":
				add_option_text(tr("button_color"))
				option_texts[b].values = [8]
			"button_color_inventory":
				add_option_text(tr("button_color"))
				option_texts[b].values = [9]
			"button_color_header":
				add_option_text(tr("button_color"))
				option_texts[b].values = [10]
			"button_color_removal":
				add_option_text(tr("button_color"))
				option_texts[b].values = [11]
			"button_color_page":
				add_option_text(tr("button_color"))
				option_texts[b].values = [12]
			"button_color_start_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [1]
			"button_color_continue_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [2]
			"button_color_options_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [3]
			"button_color_stats_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [4]
			"button_color_mods_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [5]
			"button_color_exit_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [6]
			"button_color_promo_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [7]
			"button_color_misc_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [8]
			"button_color_inventory_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [9]
			"button_color_header_text":
				add_option_text(tr("button_text"))
				option_texts[b].values = [10]
			"text_color_misc":
				add_option_text(tr("text_color"))
				option_texts[b].values = [1]
			"text_color_keyword":
				add_option_text(tr("text_color"))
				option_texts[b].values = [2]
			"text_color_common":
				add_option_text(tr("text_color"))
				option_texts[b].values = [3]
			"text_color_uncommon":
				add_option_text(tr("text_color"))
				option_texts[b].values = [4]
			"text_color_rare":
				add_option_text(tr("text_color"))
				option_texts[b].values = [5]
			"text_color_very_rare":
				add_option_text(tr("text_color"))
				option_texts[b].values = [6]
			"text_color_essence":
				add_option_text(tr("text_color"))
				option_texts[b].values = [7]
			_:
				if track_names.has(option_types[b]):
					add_option_text(option_types[b])
				else:
					if menu == "mods" and saved_modpack_keys.keys().has(option_types[b]):
						add_option_text(saved_modpack_keys[option_types[b]])
					else:
						add_option_text(tr(option_types[b]))
				if menu == "legal":
					option_texts[0].force_update = true
					option_texts[0].update()
		if menu == "credits" or menu == "input" or menu == "legal" or menu == "achievements":
			if menu == "input":
				option_texts[b].text_mod = -1
				if CJK_lang or int(display_font) > 0:
					option_texts[b].rect_position = Vector2(16, 120 + (option_sliders.size() + b) * 40 * ui_scaling.text)
				else:
					option_texts[b].rect_position = Vector2(16, 16 + (option_sliders.size() + b) * 40 * ui_scaling.text)
			elif menu != "mods" and menu != "achievements":
				option_texts[b].rect_position = Vector2(16, 118 + spacing_offset + (option_sliders.size() + b) * spacing_offset)
			else:
				option_texts[b].rect_position = Vector2(16, 118 + (option_sliders.size() + b))
			if menu == "credits" and ((credits["zh_TW"].replace("฿", "") == option_types[b] and not CJK_lang) or (CJK_credits["zh_TW"].replace("฿", "") == option_types[b] and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansTC_Resize.tres")
			elif menu == "credits" and (((credits["ru"] == option_types[b] and not CJK_lang) or (CJK_credits["ru"] == option_types[b] and CJK_lang)) or ((credits["bg"] == option_types[b] and not CJK_lang) or (CJK_credits["bg"] == option_types[b] and CJK_lang))) and int(display_font) == 2:
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSans_Resize.tres")
			elif menu == "credits" and (((credits["zh"].replace("฿", "") == option_types[b] or credits["zh_team"].replace("฿", "") == option_types[b]) and not CJK_lang) or ((CJK_credits["zh"].replace("฿", "") == option_types[b] or CJK_credits["zh_team"].replace("฿", "") == option_types[b]) and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansSC_Resize.tres")
			elif menu == "credits" and ((credits["ko"].replace("฿", "") == option_types[b] and not CJK_lang) or (CJK_credits["ko"].replace("฿", "") == option_types[b] and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansKR_Resize.tres")
			elif menu == "credits" and ((credits["ja"].replace("฿", "") == option_types[b] and not CJK_lang) or (CJK_credits["ja"].replace("฿", "") == option_types[b] and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansJP_Resize.tres")
			elif menu == "credits" and ((credits["th"].replace("฿", "") == option_types[b] and not CJK_lang) or (CJK_credits["th"].replace("฿", "") == option_types[b] and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansTH_Resize.tres")
			elif menu == "credits" and ((credits["ar"].replace("฿", "") == option_types[b] and not CJK_lang) or (CJK_credits["ar"].replace("฿", "") == option_types[b] and CJK_lang)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSansAR_Resize.tres")
			elif menu == "credits" and ((credits["vi"].replace("฿", "") == option_types[b] and not CJK_lang) or (TranslationServer.get_locale() == "th" and option_types[b] != credits["g/g"] and option_types[b] != credits["old"] and option_types[b] != credits["new"] and option_types[b] != credits["vin"] and option_types[b] != credits["zapsplat"] and option_types[b] != credits["lang"] and option_types[b] != credits["special_thanks"] and option_types[b] != credits["special_thanks_header"] and option_types[b] != credits["dedication"] and option_types[b].find(tr("refused_translator_names")) == -1)):
				option_texts[b].base_scale = 0.5
				option_texts[b].change_set_size(0.5)
				option_texts[b].forced_font = preload("res://NotoSans_Resize.tres")
		elif menu == "gameplay" and TranslationServer.get_locale() == "de":
			option_texts[b].rect_position = Vector2(16, 118 + spacing_offset + (option_sliders.size() + b) * spacing_offset)
		elif menu == "audio":
			if track_names.has(option_texts[b].raw_string):
				option_texts[b].rect_position = Vector2(144, 508 + (b - option_sliders.size()) * spacing_offset)
			elif (option_texts[b].raw_string == tr("soundtrack") and b > 3) or option_texts[b].raw_string == tr("normal") + " " + tr("endless"):
				option_texts[b].rect_position.y = 508 + (b - option_sliders.size()) * spacing_offset
			else:
				option_texts[b].rect_position = Vector2(144, 94 + y_offset + (option_sliders.size() + b) * y_offset)
		elif default_colors.keys().has(menu):
			option_texts[b].rect_position = Vector2(144, b * 2 * (y_offset + 8) + top_offset)
		else:
			option_texts[b].rect_position = Vector2(144, 118 + spacing_offset + (option_sliders.size() + b) * spacing_offset)
		if option_texts[b].raw_string == tr("mute_while_in_background"):
			option_texts[b].rect_position.y = 508 + (b - option_sliders.size()) * spacing_offset
		elif option_texts[b].raw_string == tr("colors") or option_texts[b].raw_string == tr("ui_scaling") or (option_texts[b].raw_string == tr("soundtrack") and b > 3):
			if CJK_lang:
				option_texts[b].rect_position.x = 512 - option_texts[b].get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].rect_scale.x / 4.0 * ui_scaling.text
			elif int(display_font) > 0:
				option_texts[b].rect_position.x = 512 - option_texts[b].get_child(0).get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].rect_scale.x / 4.0 * ui_scaling.text
			else:
				option_texts[b].rect_position.x = 512 - option_texts[b].get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].rect_scale.x * 2.0 * ui_scaling.text
			option_texts[b].alignment_tags.centered = true
		elif option_texts[b].raw_string == tr("normal") + " " + tr("endless"):
			if CJK_lang:
				option_texts[b].rect_position.x = 668 - option_texts[b].get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].current_scale / 4.0 * resolution_x / 1024
			elif int(display_font) > 0:
				option_texts[b].rect_position.x = 668 - option_texts[b].get_child(0).get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].current_scale / 4.0 * resolution_x / 1024
			else:
				option_texts[b].rect_position.x = 668 - option_texts[b].get_font("font").get_string_size(option_texts[b].raw_string).x * option_texts[b].current_scale * resolution_x / 1024
			option_texts[b].alignment_tags.right = true
		add_to_base_y_positions(option_texts[b])
		if menu != "credits" and menu != "input" and menu != "legal" and menu != "achievements":
			add_button(option_types[b])
			add_to_base_y_positions(option_buttons[option_buttons.size() - 1])
			if menu == "audio" and option_buttons.size() > 6:
				add_to_base_y_positions(option_buttons[option_buttons.size() - 2])
				add_to_base_y_positions(option_buttons[option_buttons.size() - 3])
			elif menu == "mods" and option_buttons.size() > 1 and option_buttons[option_buttons.size() - 1].call == "toggle_mod_display" and option_buttons[option_buttons.size() - 2].call == "disable_mod_pack":
				add_to_base_y_positions(option_buttons[option_buttons.size() - 2])
			match option_types[b]:
				"master_volume", "music", "sfx":
					var l = Line2D.new()
					slider_lines.push_back(l)
					l.default_color = Color("#FFFFFF")
					l.width = 8
					l.add_point(Vector2(resolution_x - 128, 152 + (slider_texts.size() + b + 1) * y_offset + 40))
					l.add_point(Vector2(96, 152 + (slider_texts.size() + b + 1) * y_offset + 40))
					$"Scrollables".add_child(l)
					add_to_base_y_positions(l)
					add_option_slider(option_types[b])
					option_sliders[option_sliders.size() - 1].rect_position = Vector2(option_sliders[option_sliders.size() - 1].left + self[option_types[b]].value * (8.0 + (resolution_x - 1024) / 100.0), (option_sliders.size() + b + 8) * y_offset - 280)
					option_sliders[option_sliders.size() - 1].top = option_texts[b].rect_position.y * 64
					option_sliders[option_sliders.size() - 1].bottom = (option_sliders[option_sliders.size() - 1].rect_position.y + option_sliders[option_sliders.size() - 1].rect_size.y + 8) * 8
					add_to_base_y_positions(option_sliders[option_sliders.size() - 1])
					var t = preload("res://Outline Label.tscn").instance()
					t.raw_string = str(self[option_types[b]].value)
					if CJK_lang or int(display_font) > 0:
						t.icon_z_index = 10
					else:
						t.texts[8].icon_z_index = 10
					t.alignment_tags.dont = true
					slider_texts.push_back(t)
					option_sliders[option_sliders.size() - 1].data = { "value_obj": self[option_types[b]], "value_text": t, "setting_type": option_types[b] }
					$"Scrollables".add_child(t)
					add_to_base_y_positions(t)
				"R", "G", "B":
					var l = Line2D.new()
					slider_lines.push_back(l)
					l.default_color = Color("#FFFFFF")
					l.width = 8
					l.add_point(Vector2(resolution_x - 128, b * 2 * (y_offset + 8) + 80 + top_offset))
					l.add_point(Vector2(96, b * 2 * (y_offset + 8) + 80 + top_offset))
					add_child(l)
					add_to_base_y_positions(l)
					add_option_slider(option_types[b])
					option_sliders[option_sliders.size() - 1].rect_position = Vector2(option_sliders[option_sliders.size() - 1].left + Color(colors3[current_color])[option_types[b].to_lower()] * (resolution_x - option_sliders[option_sliders.size() - 1].left - 160), 272 + b * 2 * (y_offset + 8) + top_offset - 200)
					option_sliders[option_sliders.size() - 1].top = option_texts[b].rect_position.y * 64
					option_sliders[option_sliders.size() - 1].bottom = (option_sliders[option_sliders.size() - 1].rect_position.y + option_sliders[option_sliders.size() - 1].rect_size.y + 1) * 8
					option_sliders[option_sliders.size() - 1].color_slider = true
					option_buttons[option_buttons.size() - 1].visible = false
					add_to_base_y_positions(option_sliders[option_sliders.size() - 1])
					var t = preload("res://Outline Label.tscn").instance()
					t.raw_string = str(round(Color(colors3[current_color])[option_types[b].to_lower()] * 255))
					if CJK_lang or int(display_font) > 0:
						t.icon_z_index = 10
					else:
						t.texts[8].icon_z_index = 10
					if CJK_lang or int(display_font) > 0:
						t.rect_position = Vector2(728, 176 + b * 2 * (y_offset + 8) + top_offset - 200)
					else:
						t.rect_position = Vector2(728, 176 + b * 2 * (y_offset + 8) + top_offset - 200)
					t.alignment_tags.right = true
					slider_texts.push_back(t)
					option_sliders[option_sliders.size() - 1].data = { "value_obj": colors3[current_color], "value_text": t, "setting_type": option_types[b].to_lower() }
					add_child(t)
					add_to_base_y_positions(t)
			if option_types[b] == "colors" or option_types[b] == "ui_scaling" or option_types[b] == tr("symbols") or option_types[b] == tr("items") or option_types[b] == "soundtrack" or option_types[b] == tr("normal") + " " + tr("endless"):
				option_buttons[option_buttons.size() - 1].visible = false
		elif menu == "input":
			add_button(option_types[b])
			add_button(option_types[b])
	remove_system_buttons()
	add_system_buttons()
	if menu == "credits":
		add_button("godot_engine")
		add_to_base_y_positions(option_buttons[0])
	if last_selector_button_pos != null and option_buttons.size() - 1 > last_selector_button_pos:
		$"/root/Main".selected_node = option_buttons[last_selector_button_pos]
		last_selector_button_pos = null
	else:
		last_selector_button_pos = null

func add_option_slider(setting):
	var slider = preload("res://Option Slider.tscn").instance()
	option_sliders.push_back(slider)
	if menu == "audio":
		$"Scrollables".add_child(slider)
	else:
		add_child(slider)

func remove_system_buttons():
	if exit_button != null:
		exit_button.queue_free()
		exit_button = null
		
	if back_button != null:
		back_button.queue_free()
		back_button = null
	
	if reset_button != null:
		reset_button.queue_free()
		reset_button = null

func remove_buttons():
	var n = 0
	for b in option_buttons:
		if $"/root/Main".selected_node == b:
			last_selector_button_pos = n
		if $"Hotkeys".get_children().has(b):
			$"Hotkeys".remove_child(b)
		if $"Scrollables".get_children().has(b):
			$"Scrollables".remove_child(b)
		b.queue_free()
		n += 1
	for b in dropdown_buttons:
		b.queue_free()
	for o in option_texts:
		if $"Hotkeys".get_children().has(o):
			$"Hotkeys".remove_child(o)
		if $"Scrollables".get_children().has(o):
			$"Scrollables".remove_child(o)
		o.queue_free()
	for s in option_sliders:
		s.queue_free()
	for t in slider_texts:
		t.queue_free()
	for l in slider_lines:
		l.queue_free()
	for m in menu_buttons:
		m.queue_free()
	
	remove_system_buttons()
	
	option_buttons.clear()
	dropdown_buttons.clear()
	option_texts.clear()
	option_sliders.clear()
	hyperlinks.clear()
	slider_texts.clear()
	slider_lines.clear()
	menu_buttons.clear()
	if menu == "mods":
		header_text.raw_string = tr("mods")
	elif menu == "achievements":
		header_text.raw_string = tr("achievements_no_colon")
	elif current_color == null:
		header_text.raw_string = tr("options")
	reset_scrollables()

func reset_scrollables():
	$"Hotkeys".rect_size.y = resolution_y - hotkey_offset
	$"Hotkeys".rect_position.y = hotkey_offset
	$"Hotkeys/Scroll Bar".bottom = $"Hotkeys".rect_size.y - 56
	$"Hotkeys/Scroll Bar".base_bottom = $"Hotkeys".rect_size.y - 56
	
	$"Scrollables".rect_size.y = resolution_y - top_offset
	$"Scrollables".rect_position.y = top_offset
	$"Scrollables/Scroll Bar".bottom = $"Scrollables".rect_size.y - 56
	$"Scrollables/Scroll Bar".base_bottom = $"Scrollables".rect_size.y - 56

func reset_text():
	if not CJK_lang:
		$"/root/Main/Coins".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/Coin Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/Extra Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/HP Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Landlord/Temp".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		if ui_scaling.text == 0.5:
			$"/root/Main/Sums/Coin Sum".scale_mod += 2
			$"/root/Main/Sums/Extra Sum".scale_mod += 2
			$"/root/Main/Sums/HP Sum".scale_mod += 2
			$"/root/Main/Coins".scale_mod += 2
			$"/root/Main/Landlord/Temp".scale_mod += 2
		elif ui_scaling.text == 0.75:
			$"/root/Main/Sums/Coin Sum".scale_mod += 1
			$"/root/Main/Sums/Extra Sum".scale_mod += 1
			$"/root/Main/Sums/HP Sum".scale_mod += 1
			$"/root/Main/Coins".scale_mod += 1
			$"/root/Main/Landlord/Temp".scale_mod += 1
		elif ui_scaling.text == 2.5:
			$"/root/Main/Sums/Coin Sum".scale_mod -= 1
			$"/root/Main/Sums/Extra Sum".scale_mod -= 1
			$"/root/Main/Sums/HP Sum".scale_mod -= 1
			$"/root/Main/Coins".scale_mod -= 1
			$"/root/Main/Landlord/Temp".scale_mod -= 1
		else:
			$"/root/Main/Sums/Coin Sum".text_mod = 0
			$"/root/Main/Sums/Extra Sum".text_mod = 0
			$"/root/Main/Sums/HP Sum".text_mod = 0
			$"/root/Main/Coins".text_mod = 0
			$"/root/Main/Landlord/Temp".text_mod = 0
		if ui_scaling.text == 1.75:
			$"/root/Main/Coins".custom_icon_offset = Vector2(-3, -4)
			$"/root/Main/Sums/Coin Sum".custom_icon_offset = Vector2(-3, -4)
			$"/root/Main/Sums/Extra Sum".custom_icon_offset = Vector2(-3, -4)
			$"/root/Main/Sums/HP Sum".custom_icon_offset = Vector2(-3, -4)
			$"/root/Main/Landlord/Temp".custom_icon_offset = Vector2(-3, -4)
		else:
			$"/root/Main/Coins".custom_icon_offset = Vector2(0, 0)
			$"/root/Main/Sums/Coin Sum".custom_icon_offset = Vector2(0, 0)
			$"/root/Main/Sums/Extra Sum".custom_icon_offset = Vector2(0, 0)
			$"/root/Main/Sums/HP Sum".custom_icon_offset = Vector2(0, 0)
			$"/root/Main/Landlord/Temp".custom_icon_offset = Vector2(0, 0)
		$"/root/Main/Title/Background/Mod Text".rect_position.y = 64 * ui_scaling.text
	else:
		$"/root/Main/Coins".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/Coin Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/Extra Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Sums/HP Sum".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		$"/root/Main/Landlord/Temp".scale_mod = 1 + -floor((1 - ui_scaling.text) / 0.25)
		if ui_scaling.text > 1:
			$"/root/Main/Coins".scale_mod -= -floor((1 - ui_scaling.text) / 0.25)
			$"/root/Main/Sums/Coin Sum".scale_mod -= -floor((1 - ui_scaling.text) / 0.25)
			$"/root/Main/Sums/Extra Sum".scale_mod -= -floor((1 - ui_scaling.text) / 0.25)
			$"/root/Main/Sums/HP Sum".scale_mod -= -floor((1 - ui_scaling.text) / 0.25)
			$"/root/Main/Landlord/Temp".scale_mod -= -floor((1 - ui_scaling.text) / 0.25)
		if ui_scaling.text >= 2.25:
			$"/root/Main/Landlord/Temp".custom_icon_offset.x = -26
		elif ui_scaling.text >= 2:
			$"/root/Main/Landlord/Temp".custom_icon_offset.x = -22
		elif ui_scaling.text >= 1.5:
			$"/root/Main/Landlord/Temp".custom_icon_offset.x = -18
		else:
			$"/root/Main/Landlord/Temp".custom_icon_offset.x = -12
	$"/root/Main/Error Sprite/Background".rect_size.x = resolution_x
	$"/root/Main/Title/Background/Mod Text".rect_position.y = 64 * ui_scaling.text
	$"/root/Main/Coins".change_set_size($"/root/Main/Coins".base_scale)
	$"/root/Main/Coins".force_update = true
	$"/root/Main/Coins".update()
	$"/root/Main/Title".set_mod_text_scale()
	$"/root/Main/Title/Background/Mod Text".change_set_size($"/root/Main/Title/Background/Mod Text".base_scale)
	$"/root/Main/Title/Background/Mod Text".get_child(0).custom_max_width = resolution_x - $"/root/Main/Title/Background/Mod Text".rect_position.x
	$"/root/Main/Title/Background/Mod Text".force_update = true
	$"/root/Main/Title/Background/Mod Text".update()
	$"/root/Main/Coins".change_set_size($"/root/Main/Coins".base_scale)
	$"/root/Main/Sums/Coin Sum".change_set_size($"/root/Main/Sums/Coin Sum".base_scale)
	$"/root/Main/Sums/Extra Sum".change_set_size($"/root/Main/Sums/Extra Sum".base_scale)
	$"/root/Main/Sums/HP Sum".change_set_size($"/root/Main/Sums/HP Sum".base_scale)
	$"/root/Main/Landlord/Temp".change_set_size($"/root/Main/Landlord/Temp".base_scale)
	if CJK_lang or int(display_font) > 0 or TranslationServer.get_locale() == "th":
		$"/root/Main/Title".patch_text.rect_position.y = resolution_y - ($"/root/Main/Title".patch_text.get_child(0).get_font("font").get_height() + 1) * $"/root/Main/Title".patch_text.current_scale * 2
	else:
		$"/root/Main/Title".patch_text.rect_position.y = resolution_y - ($"/root/Main/Title".patch_text.get_font("font").get_height() + 1) * $"/root/Main/Title".patch_text.current_scale * 8 - 4
	if $"/root/Main/Reels".displayed_icons.size() > 0 and $"/root/Main/Reels".displayed_icons[0][0] != null and is_instance_valid($"/root/Main/Reels".displayed_icons[0][0]):
		for x in range($"/root/Main/Reels".reel_width):
			for y in range($"/root/Main/Reels".reel_height):
				$"/root/Main/Reels".displayed_icons[y][x].get_child(1).force_update = true
				$"/root/Main/Reels".displayed_icons[y][x].get_child(2).force_update = true
				$"/root/Main/Reels".displayed_icons[y][x].get_child(3).force_update = true
				$"/root/Main/Reels".displayed_icons[y][x].update_value_text()
	if $"/root/Main/Title".visible and not deck_setting:
		$"/root/Main/Title".draw()
		$"/root/Main".change_current_menu_path("/root/Main/Title")
		last_menu = "/root/Main/Title"
	$"/root/Main/Coins".align_text()

func reset_email():
	var bs = $"/root/Main/Pop-up Sprite/Pop-up/Container".get_child(1).base_scale
	var tm = -floor((1 - ui_scaling.emails) / 0.25)
	if $"/root/Main/Pop-up Sprite/Pop-up".inv_open:
		$"/root/Main/Pop-up Sprite/Pop-up".undraw_deck()
	$"/root/Main/Pop-up Sprite/Pop-up".scroll_bar.visible = false
	$"/root/Main/Pop-up Sprite/Pop-up".visible = false
	$"/root/Main/Pop-up Sprite/Pop-up".label_text.force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).text_mod = tm
	if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
		$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).rect_position.x = 12 * ui_scaling.emails
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).text_mod = tm
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).text_mod = tm
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(2).text_mod = tm
	$"/root/Main/Pop-up Sprite/Pop-up/Container".get_child(1).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(2).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Container".get_child(1).change_set_size(bs)
	$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).change_set_size(bs)
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).change_set_size(bs)
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).change_set_size(bs)
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(2).change_set_size(bs)
	
	if not CJK_lang:
		if ui_scaling.emails == 1.25:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 2
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 2
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 2
		elif ui_scaling.emails == 1.5:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 3
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 3
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 3
		elif ui_scaling.emails == 1.75:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 4
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 4
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 4
		elif ui_scaling.emails == 2:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 5
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 5
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 5
		elif ui_scaling.emails == 2.25:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 6
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 6
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 6
		elif ui_scaling.emails == 2.5:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 7
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 7
			$"/root/Main/Pop-up Sprite/Pop-up/Sender Container".get_child(0).scale_mod = 7
		else:
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).scale_mod = 1
			$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).scale_mod = 1
	
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(0).update()
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).force_update = true
	$"/root/Main/Pop-up Sprite/Pop-up/Rent Container".get_child(1).update()
	
	if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and not $"/root/Main/Pop-up Sprite/Pop-up".emails[0].prompt:
		for c in $"/root/Main/Pop-up Sprite/Pop-up".cards:
			c.background.rect_size.x = 300 * ui_scaling.symbol_item_selections
			c.get_node("Background").get_node("Title").force_update = true
			c.get_node("Background").get_node("Title").update()
			c.get_node("Background").get_node("Value").force_update = true
			c.get_node("Background").get_node("Value").update()
			c.get_node("Background").get_node("Rarity").force_update = true
			c.get_node("Background").get_node("Rarity").update()
			c.get_node("Background").get_node("Description").force_update = true
			c.get_node("Background").get_node("Description").update()
			c.get_node("Separator").clear_points()
			c.set_icon_size()
			c.set_card_size()
		
		$"/root/Main/Pop-up Sprite/Pop-up".display()
		$"/root/Main/Pop-up Sprite/Pop-up".update_card_positions()

func reset_buttons():
	$"/root/Main/Title".twitter_button.rect_position.y = $"/root/Main/Title".logo_button.rect_position.y - 88 * ui_scaling.buttons
	$"/root/Main/Title".discord_button.rect_position.y = $"/root/Main/Title".logo_button.rect_position.y - 176 * ui_scaling.buttons
	$"/root/Main/Title".merch_button.rect_position.y = $"/root/Main/Title".logo_button.rect_position.y - 264 * ui_scaling.buttons
	if $"/root/Main".tt_data != null:
		if $"/root/Main/Title".promo_button != null and is_instance_valid($"/root/Main/Title".promo_button):
			$"/root/Main/Title".promo_button.rect_position = Vector2(resolution_x / 2 - $"/root/Main/Title".promo_button.rect_size.x / 2, resolution_y - $"/root/Main/Title".promo_button.rect_size.y * 2 - 16)
			$"/root/Main/Title".promo_button.base_x = $"/root/Main/Title".promo_button.rect_position.x
			if TranslationServer.get_locale() == "ar":
				$"/root/Main/Title".promo_button.rect_position.y += 40
	else:
		if $"/root/Main/Title".promo_button != null and is_instance_valid($"/root/Main/Title".promo_button):
			$"/root/Main/Title".promo_button.rect_position = Vector2(resolution_x / 2 - ($"/root/Main/Title".promo_button.rect_size.x + $"/root/Main/Title".promo_button2.rect_size.x) / 2 + $"/root/Main/Title".promo_button2.rect_size.x + 16, resolution_y - $"/root/Main/Title".promo_button.rect_size.y * 2 - 16)
			$"/root/Main/Title".promo_button.base_x = $"/root/Main/Title".promo_button.rect_position.x
		if $"/root/Main/Title".promo_button2 != null and is_instance_valid($"/root/Main/Title".promo_button2):
			$"/root/Main/Title".promo_button2.rect_position = Vector2(resolution_x / 2 - ($"/root/Main/Title".promo_button.rect_size.x + $"/root/Main/Title".promo_button2.rect_size.x) / 2, resolution_y - $"/root/Main/Title".promo_button.rect_size.y * 2 - 16)
			$"/root/Main/Title".promo_button2.base_x = $"/root/Main/Title".promo_button2.rect_position.x
	if $"/root/Main/Title".back_button != null:
		$"/root/Main/Title".back_button.rect_position = Vector2(resolution_x - 8 - $"/root/Main/Title".back_button.rect_size.x, resolution_y - 8 - $"/root/Main/Title".back_button.rect_size.y)
	if $"/root/Main/Title".back_button == null or ($"/root/Main/Title".back_button != null and not $"/root/Main/Title".back_button.visible):
		$"/root/Main/Title".update_button_positions()
	else:
		var p = -1
		for n in $"/root/Main/Title".floor_buttons:
			p += 1
			n.rect_position = Vector2(8 + (p % 3) * 80 * ui_scaling.buttons, resolution_y / 2 - 72 * ui_scaling.buttons * floor(p / 3) + 32 + 72 * ui_scaling.buttons)
		$"/root/Main/Title/Background/Mod Text".rect_position.x = 32 + 216 * ui_scaling.buttons
		if not CJK_lang:
			$"/root/Main/Title/Background/Mod Text".texts[8].custom_max_width = resolution_x - $"/root/Main/Title/Background/Mod Text".rect_position.x

	$"/root/Main/Menus".buttons_menu.deck_button.correct_size()
	$"/root/Main/Menus".buttons_menu.deck_button.rect_position = Vector2(resolution_x - 8 - $"/root/Main/Menus".buttons_menu.deck_button.rect_size.x, resolution_y - $"/root/Main/Menus".buttons_menu.deck_button.rect_size.y - 6)
	$"/root/Main/Menus".buttons_menu.deck_button.base_x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x
	$"/root/Main/Menus".buttons_menu.options_button.correct_size()
	if ui_scaling.buttons > 1:
		$"/root/Main/Menus".buttons_menu.options_button.rect_position = Vector2(resolution_x - 8 - $"/root/Main/Menus".buttons_menu.options_button.rect_size.x, $"/root/Main/Menus".buttons_menu.deck_button.rect_position.y - $"/root/Main/Menus".buttons_menu.options_button.rect_size.y - 8 * ui_scaling.buttons)
	else:
		$"/root/Main/Menus".buttons_menu.options_button.rect_position = Vector2(resolution_x - 8 - $"/root/Main/Menus".buttons_menu.options_button.rect_size.x, $"/root/Main/Menus".buttons_menu.deck_button.rect_position.y - $"/root/Main/Menus".buttons_menu.options_button.rect_size.y - 8)
	$"/root/Main/Menus".buttons_menu.options_button.base_x = $"/root/Main/Menus".buttons_menu.options_button.rect_position.x
	$"/root/Main/Items".update_positions()
	if ui_scaling.buttons > 1:
		$"/root/Main/Menus".buttons_menu.removal_button.rect_position = Vector2($"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8 * ui_scaling.buttons, $"/root/Main/Menus".buttons_menu.deck_button.rect_position.y)
	else:
		$"/root/Main/Menus".buttons_menu.removal_button.rect_position = Vector2($"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 16, $"/root/Main/Menus".buttons_menu.deck_button.rect_position.y)
	$"/root/Main/Menus".buttons_menu.removal_button.base_x = $"/root/Main/Menus".buttons_menu.removal_button.rect_position.x

	$"/root/Main/Menus".buttons_menu.right_button.correct_size()
	$"/root/Main/Menus".buttons_menu.right_button.rect_position = Vector2($"/root/Main/Menus".buttons_menu.options_button.rect_position.x - $"/root/Main/Menus".buttons_menu.right_button.rect_size.x - 8, $"/root/Main/Menus".buttons_menu.options_button.rect_position.y)
	$"/root/Main/Menus".buttons_menu.right_button.base_x = $"/root/Main/Menus".buttons_menu.right_button.rect_position.x

	$"/root/Main/Menus".buttons_menu.left_button.correct_size()
	$"/root/Main/Menus".buttons_menu.left_button.rect_position = Vector2($"/root/Main/Menus".buttons_menu.right_button.rect_position.x - $"/root/Main/Menus".buttons_menu.left_button.rect_size.x - 8, $"/root/Main/Menus".buttons_menu.right_button.rect_position.y)
	$"/root/Main/Menus".buttons_menu.left_button.base_x = $"/root/Main/Menus".buttons_menu.left_button.rect_position.x

	$"/root/Main/Menus".buttons_menu.spin_button.correct_size()
	$"/root/Main/Menus".buttons_menu.spin_button.rect_position = Vector2(resolution_x / 2 - $"/root/Main/Menus".buttons_menu.spin_button.rect_size.x / 2, resolution_y - $"/root/Main/Menus".buttons_menu.spin_button.rect_size.y - 6 * ui_scaling.buttons)
	$"/root/Main/Menus".buttons_menu.spin_button.base_x = $"/root/Main/Menus".buttons_menu.spin_button.rect_position.x

	$"/root/Main/Title".draw_title_text()

func update_setting(setting, choice):
	var need_timer = false
	var old_sb = source_button
	if menu == "input":
		saved_scroll_bar_pos_y = $"Hotkeys/Scroll Bar".rect_position.y
	else:
		saved_scroll_bar_pos_y = $"Scrollables/Scroll Bar".rect_position.y
	if menu == "graphics" or menu == "gameplay" or choice == null:
		remove_buttons()
	match setting:
		"resolution":
			if choice != null:
				resolution_x = x_resolutions[choice]
				resolution_y = y_resolutions[choice]
				saved_resolution_x = resolution_x
				saved_resolution_y = resolution_y
			need_timer = true
			for node in get_tree().get_nodes_in_group("Aligned"):
				node.aligned = false
			for node in get_tree().get_nodes_in_group("Background X"):
				node.rect_size.x = resolution_x
			for node in get_tree().get_nodes_in_group("Background Y"):
				node.rect_size.y = resolution_y
			for node in get_tree().get_nodes_in_group("Background Y Scaling"):
				node.rect_size.y = resolution_y - (576 - node.saved_y) - top_offset
				node.rect_position.y = top_offset
			for node in get_tree().get_nodes_in_group("Scroll Bar"):
				if not node.alignment_tags.has("dont"):
					node.bottom = node.base_bottom + resolution_y - 576
			$"/root/Main/Pop-up Sprite/Pop-up".rect_position.x = resolution_x / 2 - $"/root/Main/Pop-up Sprite/Pop-up".rect_size.x / 2
			$"/root/Main/Reels".coin_goal_y_offset = resolution_y - 576
			source_button = null
		"max_fps":
			if str(framerates[choice]) == tr("uncapped"):
				max_fps = 0
			else:
				max_fps = framerates[choice]
			Engine.target_fps = max_fps
		"vsync":
			OS.vsync_enabled = vsync
		"language":
			language = language_codes[choice]
			if language_codes[choice] == "zh" or language_codes[choice] == "zh_TW" or language_codes[choice] == "zh_HK" or language_codes[choice] == "ja" or language_codes[choice] == "ko":
				RTL_lang = false
				CJK_lang = true
				display_font = 0
			elif (language_codes[choice] == "ru" or language_codes[choice] == "bg") and display_font == 2:
				RTL_lang = false
				CJK_lang = false
				display_font = 0
			elif language_codes[choice] == "vi" or language_codes[choice] == "th":
				RTL_lang = false
				CJK_lang = false
				display_font = 1
			else:
				RTL_lang = false
				CJK_lang = false
				display_font = 0
			changing_languages = true
			$"/root/Main".save_options()
			if first_menu:
				first_menu = false
			$"/root/Main".reload()
		"fullscreen":
			if OS.get_name() == "OSX":
				just_changed_osx_fullscreen = true
				changing_osx_fullscreen = true
				if not fullscreen:
					$"/root/Main".osx_setting_timer_offset = 44
			if fullscreen:
				resolution_x = OS.get_screen_size(OS.current_screen).x
				resolution_y = OS.get_screen_size(OS.current_screen).y
			else:
				resolution_x = saved_resolution_x
				resolution_y = saved_resolution_y
			update_setting("resolution", null)
			remove_buttons()
			need_timer = true
		"bordered_window":
			need_timer = true
		"spin_speed", "animation_speed", "counting_speed", "menu_speed":
			self[setting] = choice
		"input_type":
			self[setting] = choice
			$"/root/Main".last_pressed_key_code = -1
			$"/root/Main".down_scancodes.clear()
		"font":
			display_font = choice
			$"/root/Main".save_options()
			if first_menu:
				first_menu = false
			$"/root/Main".reload()
		"color":
			colors3[current_color] = choice.to_html(false).to_upper()
		"text":
			ui_scaling[setting] = choice
			for node in get_tree().get_nodes_in_group("UI - Text"):
				if not node.get_parent() is TextureButton and not node.dont_scale:
					node.force_update = true
					node.scale_mod = -floor((1 - choice) / 0.25)
					node.change_set_size(node.base_scale)
			source_button = null
			reset_text()
			reset_email()
			reset_buttons()
			get_spacing()
		"tooltips":
			ui_scaling[setting] = choice
		"inventory":
			ui_scaling[setting] = choice
			if $"/root/Main/Pop-up Sprite/Pop-up".inv_open:
				$"/root/Main/Pop-up Sprite/Pop-up".undraw_deck()
				$"/root/Main/Pop-up Sprite/Pop-up".draw_deck()
		"symbol_item_selections":
			ui_scaling[setting] = choice
			for c in $"/root/Main/Pop-up Sprite/Pop-up".cards:
				c.background.rect_size.x = 300 * ui_scaling.symbol_item_selections
				c.get_node("Separator").clear_points()
				c.set_icon_size()
				c.set_card_size()
			source_button = null
			reset_email()
		"emails":
			ui_scaling[setting] = choice
			source_button = null
			reset_email()
		"items_ui":
			ui_scaling[setting] = choice
			for i in $"/root/Main/Items".items:
				i.scale = Vector2(round(choice / 0.25), round(choice / 0.25))
			$"/root/Main/Items".update_positions()
		"buttons":
			ui_scaling[setting] = choice
			for node in get_tree().get_nodes_in_group("UI - Button"):
				node.change_size()
			reset_buttons()
			reset_email()
			get_spacing()
		"reels_ui":
			ui_scaling[setting] = choice
			$"/root/Main/Reels".draw_reels()
			for node in get_tree().get_nodes_in_group("UI - Reels"):
				node.update_scale()
			for e in $"/root/Main/Reels".texts:
				e.aligned = false
			reset_text()
			$"/root/Main/Items".update_positions()
		"ui_scaling":
			for node in get_tree().get_nodes_in_group("UI - Text"):
				if not node.get_parent() is TextureButton and not node.dont_scale:
					node.force_update = true
					node.scale_mod = -floor((1 - ui_scaling.text) / 0.25)
					node.change_set_size(node.base_scale)
			source_button = null
			reset_text()
			for c in $"/root/Main/Pop-up Sprite/Pop-up".cards:
				c.background.rect_size.x = 300 * ui_scaling.symbol_item_selections
				c.get_node("Separator").clear_points()
				c.set_icon_size()
				c.set_card_size()
			for i in $"/root/Main/Items".items:
				i.scale = Vector2(round(ui_scaling.items_ui / 0.25), round(ui_scaling.items_ui / 0.25))
			for node in get_tree().get_nodes_in_group("UI - Button"):
				node.change_size()
			reset_buttons()
			reset_email()
			get_spacing()
			reset_scrollables()
			$"/root/Main/Reels".draw_reels()
			for node in get_tree().get_nodes_in_group("UI - Reels"):
				node.update_scale()
			for e in $"/root/Main/Reels".texts:
				e.aligned = false
			$"/root/Main/Items".update_positions()
	if menu == "audio" and setting != "mute_while_in_background" and not track_names.has(setting):
		if choice != null:
			self[setting].value = choice
			
		update_goal_volume(setting)
		
		if setting == "master_volume":
			update_goal_volume("music")
			update_goal_volume("sfx")
			if music.goal_volume <= -80 or master_volume.goal_volume <= -80:
				$"/root/Main/Music Player".current_music_node.stop()
			else:
				$"/root/Main/Music Player".current_music_node.volume_db = music.goal_volume
				if not $"/root/Main/Music Player".current_music_node.playing:
					if $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight and $"/root/Main/Landlord/Temp".visible:
						randomize()
						if rand_range(0, 1) < 0.5:
							$"/root/Main/Music Player".play_set_music("Landlocked")
						else:
							$"/root/Main/Music Player".play_set_music("Mad for Money")
					else:
						$"/root/Main/Music Player".play_rand_music()
						$"/root/Main/Music Player".current_music_node.volume_db += 20
			
		if setting == "music":
			$"/root/Main/Music Player".current_music_node.volume_db = music.goal_volume
			if music.goal_volume <= -80:
				$"/root/Main/Music Player".current_music_node.stop()
			elif not $"/root/Main/Music Player".current_music_node.playing:
				if $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight and $"/root/Main/Landlord/Temp".visible:
					randomize()
					if rand_range(0, 1) < 0.5:
						$"/root/Main/Music Player".play_set_music("Landlocked")
					else:
						$"/root/Main/Music Player".play_set_music("Mad for Money")
				else:
					$"/root/Main/Music Player".play_rand_music()
					$"/root/Main/Music Player".current_music_node.volume_db += 20
	
	if current_color == null:
		dropdown = false
	
	if (menu == "graphics" or menu == "gameplay" or choice == null) and not deck_setting:
		if menu == "input":
			$"Hotkeys".visible = true
		elif menu == "audio" or menu == "credits" or menu == "achievements" or menu == "graphics" or menu == "gameplay" or menu == "legal":
			$"Scrollables".visible = true
		elif current_color != null:
			$"Color Text".visible = true
		if $"/root/Main".reload_scene_timer == 0:
			add_buttons()
	if setting == "resolution":
		set_max_scaling()
		auto_set_scaling()
		reset_text()
		reset_email()
		reset_buttons()
		reset_scrollables()
		$"/root/Main/Reels".draw_reels()
		$"/root/Main".update_alignments()
		$"/root/Main/Items".update_positions()
		
	$"/root/Main".save_options()
	
	if (setting == "buttons" or setting == "text" or setting == "ui_scaling") and not deck_setting:
		change_menu("graphics", null, false)
	
	if need_timer:
		$"/root/Main".updated_setting_timer = 0
	source_button = old_sb

func update_goal_volume(setting):
	if self[setting].muted or self[setting].value == 0 or master_volume.muted or master_volume.value == 0:
		self[setting].goal_volume = -80
	else:
		self[setting].goal_volume = (-20 + 20 * master_volume.value / 100) + (-20 + 20 * self[setting].value / 100)

func reset_to_default(type, update_and_save):
	if are_you_sure_timer == 0 and reset_button != null:
		are_you_sure_timer = 480
		$"/root/Main".display_error("are_you_sure", tr("are_you_sure_setting_reset"))
		reset_button.down = false
		reset_button.visual_reset()
		return
	var old_sb = source_button
	match type:
		"graphics":
			if Steam.isSteamRunningOnSteamDeck():
				resolution_x = 1280
				resolution_y = 800
			else:
				resolution_x = 1024
				resolution_y = 576
			saved_resolution_x = resolution_x
			saved_resolution_y = resolution_y
			vsync = false
			bordered_window = false
			fullscreen = false
			max_fps = 60
			colors3 = default_colors.duplicate(true)
			ui_scaling = {"text": 1.0, "reels_ui": 1.0, "items_ui": 1.0, "buttons": 1.0, "tooltips": 1.0, "emails": 1.0, "inventory": 1.0, "symbol_item_selections": 1.0}
			$"/root/Main/Pop-up Sprite/Pop-up".rect_position.x = resolution_x / 2 - $"/root/Main/Pop-up Sprite/Pop-up".rect_size.x / 2
			$"/root/Main/Reels".coin_goal_y_offset = resolution_y - 576
			source_button = null
			for node in get_tree().get_nodes_in_group("UI - Text"):
				if not node.get_parent() is TextureButton and not node.dont_scale:
					node.force_update = true
					node.scale_mod = 0
					node.change_set_size(node.base_scale)
			for node in get_tree().get_nodes_in_group("UI - Button"):
				node.change_size()
			if not $"/root/Main".need_config:
				reset_text()
				reset_email()
				reset_buttons()
				reset_scrollables()
				$"/root/Main/Reels".draw_reels()
				$"/root/Main".update_alignments()
				$"/root/Main/Items".update_positions()
				change_menu("graphics", null, false)
		"audio":
			master_volume = { "goal_volume": 0, "value": 100, "muted": false, }
			music = { "goal_volume": 0, "value": 80, "muted": false, }
			sfx = { "goal_volume": 0, "value": 80, "muted": false, }
			mute_while_in_background = false
			tracks = { "Old BGM #1": [0, 0], "Old BGM #2": [0, 0], "Old BGM #3": [0, 0], "Old BGM #4": [0, 0], "Old BGM #5": [0, 0], "Old BGM #6": [0, 0], "Old BGM #7": [0, 0], "Old BGM #8": [0, 0], "Banana Beats": [1, 1], "Big Man Zaroff": [1, 1], "Capsule Machine": [1, 1], "Hex of Funkiness": [1, 1], "Instant Ramen": [1, 1], "Rainbow Peppers": [1, 1], "Spin to Win!": [1, 1], "The Mouse Song": [1, 1], "Bird Whistle": [0, 1], "Essence Party": [0, 1], "Guillotine Dance": [0, 1], "Roll of the Dice": [0, 1]}
			$"/root/Main/Music Player".current_music_node.stop()
			$"/root/Main/Music Player".current_music_node.volume_db = music.goal_volume
			$"/root/Main/Music Player".play_rand_music()
			$"/root/Main/Music Player".current_music_node.volume_db += 20
		"gameplay":
			spin_speed = 1
			animation_speed = 1
			counting_speed = 1
			menu_speed = 1
			input_type = 0
			digit_separators = true
			scientific_notation = true
			screen_reader = false
		"input":
			for h in assignable_hotkeys:
				match h:
					"confirm_select":
						hotkeys[h] = [KEY_ENTER, JOY_BUTTON_0, "Enter", "<button_0>"]
					"deny_cancel":
						hotkeys[h] = [KEY_BACKSPACE, JOY_BUTTON_1, "BackSpace", "<button_1>"]
					"SPIN":
						hotkeys[h] = [KEY_SPACE, JOY_BUTTON_3, "Space", "<button_3>"]
					"up":
						hotkeys[h] = [KEY_UP, JOY_BUTTON_12, "Up", "<button_12>"]
					"down":
						hotkeys[h] = [KEY_DOWN, JOY_BUTTON_13, "Down", "<button_13>"]
					"left":
						hotkeys[h] = [KEY_LEFT, JOY_BUTTON_14, "Left", "<button_14>"]
					"right":
						hotkeys[h] = [KEY_RIGHT, JOY_BUTTON_15, "Right", "<button_15>"]
					"options":
						hotkeys[h] = [KEY_ESCAPE, JOY_BUTTON_11, "Escape", "<button_11>"]
					"inventory":
						hotkeys[h] = [KEY_I, JOY_BUTTON_10, "i", "<button_10>"]
					"add_symbol_1":
						hotkeys[h] = [KEY_1, -1, "1", ""]
					"add_symbol_2":
						hotkeys[h] = [KEY_2, -1, "2", ""]
					"add_symbol_3":
						hotkeys[h] = [KEY_3, -1, "3", ""]
					"skip":
						hotkeys[h] = [KEY_S, JOY_BUTTON_6, "s", "<button_6>"]
					"use_reroll":
						hotkeys[h] = [KEY_R, JOY_BUTTON_5, "r", "<button_5>"]
					"use_removal":
						hotkeys[h] = [KEY_X, JOY_BUTTON_4, "x", "<button_4>"]
					"fast_forward":
						hotkeys[h] = [KEY_F, JOY_BUTTON_7, "f", "<button_7>"]
					"enable_disable_item":
						hotkeys[h] = [BUTTON_RIGHT, JOY_BUTTON_9, "MOUSE_RIGHT", "<button_9>"]
					"lock_tooltip":
						hotkeys[h] = [KEY_L, -1, "l", ""]
					"inspect":
						hotkeys[h] = [null, JOY_BUTTON_2, "", "<button_2>"]
					"scroll_up":
						hotkeys[h] = [null, -1, "", ""]
					"scroll_down":
						hotkeys[h] = [null, -1, "", ""]
					_:
						hotkeys[h] = [-1, -1, "", ""]
	if current_color != null:
		colors3[current_color] = default_colors[current_color]
		update_setting("color", Color(colors3[current_color]))
	if update_and_save:
		$"/root/Main".save_options()
		remove_buttons()
		add_buttons()
		match type:
			"graphics":
				update_setting("vsync", false)
				update_setting("fullscreen", false)
				update_setting("max_fps", 1)
				update_setting("bordered_window", false)
				update_setting("resolution", 0)
				$"/root/Main".updated_setting_timer = -10
			"audio":
				update_setting("master_volume", 80)
				update_setting("music", 80)
				update_setting("sfx", 80)
	source_button = old_sb

func add_to_base_y_positions(c):
	if $"Scrollables".visible or $"Hotkeys".visible:
		if c is Line2D:
			if menu == "audio":
				c.position.y += slider_lines.size() * 60 * (resolution_y / 576 - 1)
			c.position.y -= 152
			base_y_positions.push_back(c.position.y)
		else:
			if menu == "audio":
				c.rect_position.y += slider_lines.size() * 60 * (resolution_y / 576 - 1)
			if menu == "achievements":
				c.rect_position.y -= 102
				if CJK_lang or int(display_font) > 0:
					lowest_y_size = c.get_child(0).get_font("font").get_height() * c.current_scale * (c.get_child(0).text.count("\n") + 1)
			else:
				c.rect_position.y -= 152
			base_y_positions.push_back(c.rect_position.y)

func assign_hotkey(btn):
	if done_assigning or hotkey_button_being_assigned != btn:
		var h = assignable_hotkeys[floor(option_buttons.find(btn) / 2)]
		var offset = option_buttons.find(btn) % 2
		if (offset == 1 and $"/root/Main".controllers <= 0) or (offset == 0 and Steam.isSteamRunningOnSteamDeck()):
			btn.down = false
			btn.visual_reset()
			return
		for b in option_buttons:
			if b != btn:
				b.down = false
				b.visual_reset()
			else:
				hotkeys[h][0 + offset] = -1
				hotkeys[h][2 + offset] = ""
				var old_button = option_buttons[assignable_hotkeys.find(h) * 2 + offset]
				old_button.button_text = ""
				old_button.text_node.raw_string = ""
				old_button.update_size()
				$"/root/Main".save_options()
		hotkey_being_assigned = h
		hotkey_button_being_assigned = btn
		le.grab_focus()
		done_assigning = false
	else:
		done_assigning_timer = 0

func save():
	var save_dict = {
		"path" : get_path(),
		"pos_x": rect_position.x,
		"pos_y": rect_position.y,
		"language": language,
		"CJK_lang": CJK_lang,
		"RTL_lang": RTL_lang,
		"resolution_x": resolution_x,
		"resolution_y": resolution_y,
		"saved_resolution_x": resolution_x,
		"saved_resolution_y": resolution_y,
		"vsync": vsync,
		"bordered_window": bordered_window,
		"fullscreen": fullscreen,
		"max_fps": max_fps,
		"master_volume": master_volume,
		"music": music,
		"sfx": sfx,
		"mute_while_in_background": mute_while_in_background,
		"spin_speed": spin_speed,
		"animation_speed": animation_speed,
		"counting_speed": counting_speed,
		"menu_speed": menu_speed,
		"input_type": input_type,
		"display_font": display_font,
		"text_border": text_border,
		"hotkeys": hotkeys,
		"colors3": colors3,
		"ui_scaling": ui_scaling,
		"tracks": tracks,
		"screen_reader": screen_reader,
		"digit_separators": digit_separators,
		"scientific_notation": scientific_notation,
		"disabled_mods": disabled_mods,
		"init_scaling_set": init_scaling_set,
		"old_endless_mode": old_endless_mode
	}
	return save_dict
