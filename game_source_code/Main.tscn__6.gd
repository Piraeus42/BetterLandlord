extends Node2D

var buttons = []
var back_button
var achievements_button
var merch_button
var logo_button
var discord_button
var twitter_button
var patch_time = 1704477600
var colon = "<color_C4C4C4>:<end>"
var patch_text
var title_loading = false
var floor_buttons = []
var init_set = false
var temp_floor = 1
var floor_mods = [{"string": "mod_1", "values": [7, 25], "pos": 1}, {"string": "mod_1", "values": [8, 25], "pos": 2}, {"string": "mod_2", "values": [1], "pos": 6}, {"string": "mod_4", "values": [1], "pos": 9}, {"string": "mod_1", "values": [10, 25], "pos": 4}, {"string": "mod_4", "values": [1], "pos": 10}, {"string": "mod_1", "values": [11, 25], "pos": 5}, {"string": "mod_3", "values": [1], "pos": 7}, {"string": "mod_6", "values": [25, 12], "pos": 12}, {"string": "mod_7", "values": [250], "pos": 15}, {"string": "mod_4", "values": [3], "pos": 11}, {"string": "mod_7", "values": [750], "pos": 16}, {"string": "mod_6", "values": [20, 12], "pos": 13}, {"string": "mod_9", "values": [], "pos": 19}, {"string": "mod_5", "values": [1], "pos": 8}, {"string": "mod_8", "values": [2], "pos": 17}, {"string": "mod_1", "values": [9, 25], "pos": 3}, {"string": "mod_6", "values": [15, 12], "pos": 14}, {"string": "mod_8", "values": [3], "pos": 18}]
var mod_button
var promo_button
var promo_button2
var page_button
var page_button2
var rightmost_stat_button_x = 0
var modded_floor_page = 0
var temp_modded_floor

func _ready():
	patch_text = $"Background/Patch Text"
	var sc = $"/root/Main/Options Sprite/Options".ui_scaling.buttons * 2
	
	logo_button = preload("res://TT Button.tscn").instance()
	logo_button.texture = preload("res://tt logo big.png")
	logo_button.rect_position = Vector2(936, 488)
	logo_button.target = self
	logo_button.call = "website"
	logo_button.toggle = false
	logo_button.hotkey = true
	logo_button.title_button = true
	logo_button.alignment_tags.right = true
	logo_button.alignment_tags.bottom = true
	
	twitter_button = preload("res://TT Button.tscn").instance()
	twitter_button.texture = preload("res://newsletter-logo.png")
	twitter_button.rect_position = Vector2(936, 488 - 44 * sc)
	twitter_button.target = self
	twitter_button.call = "twitter"
	twitter_button.toggle = false
	twitter_button.hotkey = true
	twitter_button.title_button = true
	twitter_button.alignment_tags.right = true
	twitter_button.alignment_tags.bottom = true
	
	discord_button = preload("res://TT Button.tscn").instance()
	discord_button.texture = preload("res://discord-logo.png")
	discord_button.rect_position = Vector2(936, 488 - 88 * sc)
	discord_button.target = self
	discord_button.call = "discord"
	discord_button.toggle = false
	discord_button.hotkey = true
	discord_button.title_button = true
	discord_button.alignment_tags.right = true
	discord_button.alignment_tags.bottom = true
	
	merch_button = preload("res://TT Button.tscn").instance()
	merch_button.texture = preload("res://merch-logo.png")
	merch_button.rect_position = Vector2(936, 488 - 132 * sc)
	merch_button.target = self
	merch_button.call = "merch"
	merch_button.toggle = false
	merch_button.hotkey = true
	merch_button.title_button = true
	merch_button.alignment_tags.right = true
	merch_button.alignment_tags.bottom = true
	
	page_button = preload("res://TT Button.tscn").instance()
	page_button.button_text = "<icon_left>"
	page_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
	page_button.color_type = "button_color_continue"
	page_button.target = self
	page_button.call = "scroll_mods_left"
	page_button.toggle = false
	page_button.scale_mod = -1
	page_button.title_button = true
	
	page_button2 = preload("res://TT Button.tscn").instance()
	page_button2.button_text = "<icon_right>"
	page_button2.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
	page_button2.color_type = "button_color_continue"
	page_button2.target = self
	page_button2.call = "scroll_mods_right"
	page_button2.toggle = false
	page_button2.scale_mod = -1
	page_button2.title_button = true
	
	add_child(merch_button)
	add_child(discord_button)
	add_child(twitter_button)
	add_child(logo_button)
	add_child(page_button)
	add_child(page_button2)
	
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		page_button.text_node.change_set_size(page_button.text_node.base_scale)
		page_button2.text_node.change_set_size(page_button2.text_node.base_scale)
		
	page_button.text_node.icon_z_index = 9
	page_button2.text_node.icon_z_index = 9
	page_button.text_node.force_update = true
	page_button.text_node.update()
	page_button2.text_node.force_update = true
	page_button2.text_node.update()
	page_button.correct_size()
	page_button2.correct_size()
	
	if int($"/root/Main/Options Sprite/Options".display_font) == 1:
		patch_text.rect_position.y = $"/root/Main/Options Sprite/Options".resolution_y - (patch_text.get_child(0).get_font("font").get_height() + 1) * patch_text.current_scale * 2
	elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
		patch_text.rect_position.y = $"/root/Main/Options Sprite/Options".resolution_y - (patch_text.get_child(0).get_font("font").get_height() - 7) * patch_text.current_scale * 2
	
	$"Background/Title Text".alignment_tags.centered = true
	$"Background/Title Text 2".alignment_tags.centered = true

func update():
	if visible and not Input.is_mouse_button_pressed(BUTTON_LEFT):
		title_loading = false
	
	if not $"/root/Main".demo:
		var time_left = patch_time - OS.get_unix_time()
		patch_text.raw_string = "<color_6F32A1>v1." + str($"/root/Main".content_patch_num) + "." + str($"/root/Main".hotfix_num) + "<end>"
		if time_left <= 0:
			pass
		else:
			var days = floor(time_left / 86400)
			var hours = int(floor(time_left / 3600)) % 24
			var minutes = int(floor(time_left / 60)) % 60
			var seconds = time_left % 60
			
			patch_text.raw_string += "\n<color_C71585>" + tr("patch_timer") + "<end>"

			if days < 10:
				patch_text.raw_string += "0" + str(days) + colon
			else:
				patch_text.raw_string += str(days) + colon

			if hours < 10:
				patch_text.raw_string += "0" + str(hours) + colon
			else:
				patch_text.raw_string += str(hours) + colon

			if minutes < 10:
				patch_text.raw_string += "0" + str(minutes) + colon
			else:
				patch_text.raw_string += str(minutes) + colon

			if seconds < 10:
				patch_text.raw_string += "0" + str(seconds)
			else:
				patch_text.raw_string += str(seconds)
		patch_text.change_set_size(patch_text.base_scale)
		patch_text.update()
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			patch_text.rect_position.y = $"/root/Main/Options Sprite/Options".resolution_y - (patch_text.get_child(0).get_font("font").get_height() + 1) * patch_text.current_scale * 2
			if time_left <= 0:
				patch_text.rect_position.y += (patch_text.get_child(0).get_font("font").get_height() + 1) * patch_text.current_scale
		else:
			patch_text.rect_position.y = $"/root/Main/Options Sprite/Options".resolution_y - (patch_text.get_font("font").get_height() + 1) * patch_text.current_scale * 8 - 4
			if time_left <= 0:
				patch_text.rect_position.y += (patch_text.get_font("font").get_height() + 1) * patch_text.current_scale * 4

func update_promo_button_positions():
	promo_button.alignment_tags.dont = true
	promo_button.correct_size()
	promo_button2.alignment_tags.dont = true
	promo_button2.correct_size()
	if $"/root/Main".tt_data != null:
		promo_button.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x / 2 - promo_button.rect_size.x / 2, $"/root/Main/Options Sprite/Options".resolution_y - promo_button.rect_size.y * 2 - 16)
		if TranslationServer.get_locale() == "ar":
			promo_button.rect_position.y += 40
		promo_button.base_x = promo_button.rect_position.x
		promo_button2.visible = false
	else:
		promo_button.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x / 2 - (promo_button.rect_size.x + promo_button2.rect_size.x) / 2 + promo_button2.rect_size.x + 16, $"/root/Main/Options Sprite/Options".resolution_y - promo_button.rect_size.y * 2 - 16)
		promo_button2.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x / 2 - (promo_button.rect_size.x + promo_button2.rect_size.x) / 2, $"/root/Main/Options Sprite/Options".resolution_y - promo_button.rect_size.y * 2 - 16)
		promo_button.base_x = promo_button.rect_position.x
		promo_button2.base_x = promo_button2.rect_position.x

func draw():
	title_loading = true
	$"/root/Main/Pop-up Sprite/Pop-up".floor_selected = false
	remove()
	var title_text = $"Background/Title Text"
	var title_text2 = $"Background/Title Text 2"
	match TranslationServer.get_locale():
		"en", "it", "es", "tr", "pt_PT", "th", "bg", "ar":
			title_text.raw_string = "Luck be a"
			title_text2.raw_string = "Landlord"
		"pt_BR":
			title_text.raw_string = "Sorte seja"
			title_text2.raw_string = "o Proprietário"
		"ru":
			title_text.raw_string =  "Удачи,"
			title_text2.raw_string = "арендодатель"
		"fr":
			title_text.raw_string = "La Chance"
			title_text2.raw_string = "du Locataire"
		"es_ES":
			title_text.raw_string = "La Suerte es"
			title_text2.raw_string = "un Casero"
		"ko":
			title_text.raw_string = "집주인이"
			title_text2.raw_string = "너무해"
		"vi":
			title_text.raw_string = "Đánh Cược"
			title_text2.raw_string = "với Chủ Nhà"
		_:
			title_text.raw_string = tr("Title translation")
	
	var new_game_button = preload("res://TT Button.tscn").instance()
	var continue_button = preload("res://TT Button.tscn").instance()
	var stats_button = preload("res://TT Button.tscn").instance()
	var exit_button = preload("res://TT Button.tscn").instance()
	var options_button = preload("res://TT Button.tscn").instance()
	promo_button = preload("res://TT Button.tscn").instance()
	promo_button2 = preload("res://TT Button.tscn").instance()
	mod_button = preload("res://TT Button.tscn").instance()
	
	new_game_button.button_text = tr("start")
	new_game_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_start"])
	new_game_button.color_type = "button_color_start"
	new_game_button.target = $"/root/Main"
	new_game_button.call = "new_game"
	new_game_button.toggle = false
	
	buttons.push_back(new_game_button)
	
	continue_button.button_text = tr("continue")
	continue_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
	continue_button.color_type = "button_color_continue"
	continue_button.target = $"/root/Main"
	continue_button.call = "continue_game"
	continue_button.toggle = false
	
	buttons.push_back(continue_button)
	
	options_button.button_text = tr("options")
	options_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_options"])
	options_button.color_type = "button_color_options"
	options_button.target = $"/root/Main/Options Sprite/Options"
	options_button.call = "open"
	options_button.toggle = false
	options_button.args = [options_button]
	options_button.shortcuts = ["options"]
	
	buttons.push_back(options_button)
	
	stats_button.button_text = tr("stats")
	stats_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_stats"])
	stats_button.color_type = "button_color_stats"
	stats_button.target = self
	stats_button.call = "stats_menu"
	stats_button.toggle = false
	
	if not $"/root/Main".demo and $"/root/Main/Stats Sprite/Stats".stats_unlocked:
		buttons.push_back(stats_button)
	
	exit_button.button_text = tr("exit")
	exit_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_exit"])
	exit_button.color_type = "button_color_exit"
	exit_button.target = $"/root/Main"
	exit_button.call = "exit"
	exit_button.toggle = false
	
	page_button.visible = false
	page_button2.visible = false
	
	if $"/root/Main".tt_data != null:
		promo_button.button_text = tr($"/root/Main".tt_data.text)
		promo_button.call = "tt_data"
	elif OS.get_unix_time() > 1689958800 and not $"/root/Main".demo:
		promo_button2.button_text = tr("ios_ad")
		promo_button2.call = "ios"
		promo_button.button_text = tr("android_ad")
		promo_button.call = "android"
	elif OS.get_unix_time() < 1610128800:
		promo_button.button_text = tr("wishlist_button")
		promo_button.call = "steam"
	elif OS.get_unix_time() < 1678726800 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "pt_BR" or TranslationServer.get_locale() == "es" or TranslationServer.get_locale() == "ko" or TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ru" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "es_ES" or TranslationServer.get_locale() == "ja" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "pt_PT" or TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "fr" or TranslationServer.get_locale() == "zh_TW"):
		promo_button.button_text = tr("plushie_ad")
		promo_button.call = "pizza"
		if $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 1:
			promo_button.tall_button = true
	else:
		promo_button.button_text = tr("steam_button")
		promo_button.call = "steam"
	promo_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_promo"])
	promo_button.color_type = "button_color_promo"
	promo_button.target = self
	promo_button.toggle = false
	promo_button.rect_size_mod = 0.25
	
	promo_button2.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_promo"])
	promo_button2.color_type = "button_color_promo"
	promo_button2.target = self
	promo_button2.toggle = false
	promo_button2.rect_size_mod = 0.25
	
	mod_button.button_text = tr("mods")
	mod_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_mods"])
	mod_button.color_type = "button_color_mods"
	mod_button.target = $"/root/Main/Options Sprite/Options"
	mod_button.call = "open_mods"
	mod_button.toggle = false
	mod_button.args = [mod_button]
	mod_button.rect_size_mod = 0.25
	mod_button.title_button = true
	
	if not $"/root/Main".demo:
		buttons.push_back(mod_button)
	buttons.push_back(exit_button)

	if $"/root/Main".demo or (OS.get_unix_time() < 1678726800 and (TranslationServer.get_locale() == "en" or TranslationServer.get_locale() == "pt_BR" or TranslationServer.get_locale() == "es" or TranslationServer.get_locale() == "ko" or TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "ru" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "es_ES" or TranslationServer.get_locale() == "ja" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "pt_PT" or TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "fr" or TranslationServer.get_locale() == "zh_TW")):
		buttons.push_back(promo_button)
	elif OS.get_unix_time() > 1689958800:
		buttons.push_back(promo_button)
		buttons.push_back(promo_button2)
	
	for b in range(buttons.size()):
		if $"/root/Main/Options Sprite/Options".resolution_y < 720:
			buttons[b].scale_mod = -1
		buttons[b].title_button = true
		add_child(buttons[b])
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			buttons[b].text_node.get_child(0).custom_max_width = 10000
		else:
			buttons[b].text_node.texts[8].custom_max_width = 10000
		buttons[b].selector_alignment = "centered"
	
	update_button_positions()
	
	for b in floor_buttons:
		remove_child(b)
		b.queue_free()
		
	floor_buttons.clear()
	
	update_promo_button_positions()
	$"/root/Main".update_alignments()

	while promo_button.rect_global_position.x + promo_button.rect_size.x > logo_button.rect_global_position.x - 8:
		promo_button.scale_mod -= 1
		promo_button2.scale_mod -= 1
		promo_button.change_size()
		promo_button2.change_size()
		update_promo_button_positions()
		if promo_button.current_scale <= 0.5:
			break

	patch_text.visible = true
	$"Background/Title Text".visible = true
	$"Background/Title Text 2".visible = true
	$"Background/Info Text".visible = false
	$"Background/Mod Text".visible = false
	$"Background/Mod Text".e_spaced = true
	logo_button.visible = true
	merch_button.visible = true
	discord_button.visible = true
	twitter_button.visible = true
	
	for b in $"/root/Main/Menus".buttons_menu.get_children():
		b.visible = false
	
	visible = true
	
	draw_title_text()
	
	$"/root/Main/Execution Sprite".visible = false
	$"/root/Main".change_current_menu_path("/root/Main/Title")

func scroll_mods_left():
	modded_floor_page -= 1
	reset_floor_menu()
	page_button.visual_unpress()
	floor_menu()

func scroll_mods_right():
	modded_floor_page += 1
	reset_floor_menu()
	page_button2.visual_unpress()
	floor_menu()

func reset_floor_menu():
	for b in floor_buttons:
		if is_instance_valid(b):
			remove_child(b)
			b.queue_free()
	floor_buttons.clear()

func draw_title_text():
	var title_text = $"Background/Title Text"
	var title_text2 = $"Background/Title Text 2"
	if visible:
		var t_mod = 0
		while true:
			var fh = 0
			var txt = ""
			var txt2 = ""
			if not $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "vi":
				title_text.forced_font = preload("res://Title_Font.tres")
				title_text.add_font_override("font", preload("res://Title_Font.tres"))
				title_text2.forced_font = preload("res://Title_Font.tres")
				title_text2.add_font_override("font", preload("res://Title_Font.tres"))
				title_text.add_texts()
				title_text2.add_texts()
				title_text.change_set_size(title_text.base_scale)
				title_text2.change_set_size(title_text2.base_scale)
				var i = 0
				for t in title_text.texts:
					t.add_font_override("font", preload("res://Title_Font.tres"))
					if i != 9:
						t.rect_position.x = -8 + (i % 3) * 8
						t.rect_position.y = -8 + floor(i / 3) * 8
					i += 1
					if i == 4:
						i += 1
				i = 0
				for t in title_text2.texts:
					t.add_font_override("font", preload("res://Title_Font.tres"))
					if i != 9:
						t.rect_position.x = -8 + (i % 3) * 8
						t.rect_position.y = -8 + floor(i / 3) * 8
					i += 1
					if i == 4:
						i += 1
				title_text.text_mod = 8 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25) + 1 + t_mod
				title_text2.text_mod = 8 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25) + 1 + t_mod
				title_text.change_set_size(title_text.base_scale)
				title_text2.change_set_size(title_text2.base_scale)
				title_text.force_update = true
				title_text2.force_update = true
				title_text.update()
				title_text2.update()
				title_text.rect_position = Vector2(512 - (title_text.get_font("font").get_string_size(title_text.text).x) * title_text.current_scale / 2, 10 * title_text2.current_scale)
				title_text2.rect_position = Vector2(512 - (title_text2.get_font("font").get_string_size(title_text2.text).x) * title_text2.current_scale / 2, 98 * title_text2.current_scale)
				fh = title_text.texts[8].get_font("font").get_height()
				txt = title_text.texts[8].text
				txt2 = title_text2.texts[8].text
			elif TranslationServer.get_locale() == "ko" or TranslationServer.get_locale() == "vi":
				title_text.text_mod = 8 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.125) + t_mod
				title_text2.text_mod = 8 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.125) + t_mod
				title_text.change_set_size(title_text.base_scale)
				title_text2.change_set_size(title_text2.base_scale)
				title_text.force_update = true
				title_text2.force_update = true
				title_text.update()
				title_text2.update()
				title_text.rect_position = Vector2(512 - (title_text.get_font("font").get_string_size(title_text.get_child(0).text).x) * title_text.current_scale / 2, 10 * title_text.current_scale)
				title_text2.rect_position = Vector2(512 - (title_text2.get_font("font").get_string_size(title_text2.get_child(0).text).x) * title_text2.current_scale / 2, 98 * title_text2.current_scale)
				fh = title_text.get_child(0).get_font("font").get_height()
				txt = title_text.get_child(0).text
				txt2 = title_text2.get_child(0).text
			else:
				title_text.text_mod = 14 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.125) + t_mod
				title_text.change_set_size(title_text.base_scale + t_mod)
				title_text.force_update = true
				title_text.update()
				title_text.rect_position = Vector2(512 - (title_text.get_font("font").get_string_size(title_text.get_child(0).text).x) * title_text.current_scale / 2, 10 * title_text.current_scale)
				fh = title_text.get_child(0).get_font("font").get_height()
				txt = title_text.get_child(0).text
			if title_text.rect_position.y + fh * title_text.current_scale + 16 >= buttons[0].rect_position.y or (title_text2.raw_string != "" and title_text2.rect_position.y + fh * title_text2.current_scale + 16 >= buttons[0].rect_position.y) or title_text.get_font("font").get_string_size(title_text.get_child(0).text).x * title_text.current_scale + 64 >= $"/root/Main/Options Sprite/Options".resolution_x or title_text.get_font("font").get_string_size(title_text.text).x * title_text.current_scale + 64 >= $"/root/Main/Options Sprite/Options".resolution_x or (title_text2.raw_string != "" and (title_text2.get_font("font").get_string_size(title_text2.get_child(0).text).x * title_text2.current_scale + 64 >= $"/root/Main/Options Sprite/Options".resolution_x or title_text2.get_font("font").get_string_size(title_text2.text).x * title_text2.current_scale + 64 >= $"/root/Main/Options Sprite/Options".resolution_x)):
				t_mod -= 1
			else:
				break
	title_text.saved_resolution = Vector2(1024, 576)
	title_text2.saved_resolution = Vector2(1024, 576)
	title_text.aligned = false
	title_text2.aligned = false
	$"/root/Main".update_alignments()

func set_mod_text_scale():
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Background/Mod Text".icon_z_index = 9
		$"Background/Mod Text".custom_icon_offset.y = 0
		if $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1:
			pass
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text == 1.25 and int($"/root/Main/Options Sprite/Options".display_font) != 2:
			$"Background/Mod Text".scale_mod = -1
			$"Background/Mod Text".custom_icon_offset.y = 5
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1.5:
			$"Background/Mod Text".scale_mod = -1
			$"Background/Mod Text".custom_icon_offset.y = 2
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text == 1.75:
			$"Background/Mod Text".scale_mod = 0
			$"Background/Mod Text".custom_icon_offset.y = 2
		elif $"/root/Main/Options Sprite/Options".ui_scaling.text == 2:
			$"Background/Mod Text".scale_mod = 0
			$"Background/Mod Text".custom_icon_offset.y = 4
		else:
			$"Background/Mod Text".scale_mod = 0
		if TranslationServer.get_locale() == "ar":
			$"Background/Mod Text".get_child(0).custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - rightmost_stat_button_x
		else:
			$"Background/Mod Text".get_child(0).custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - $"Background/Mod Text".rect_position.x - 16
	else:
		$"Background/Mod Text".texts[8].icon_z_index = 9
		if TranslationServer.get_locale() == "ar":
			$"Background/Mod Text".texts[8].custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - rightmost_stat_button_x
		else:
			$"Background/Mod Text".texts[8].custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - $"Background/Mod Text".rect_position.x - 16
		$"Background/Mod Text".scale_mod = 1
		if int($"/root/Main/Options Sprite/Options".display_font) != 0:
			$"Background/Mod Text".rect_position.y += 2
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Background/Mod Text".rect_position.y = $"Background/Info Text".rect_position.y + $"Background/Info Text".get_child(0).get_font("font").get_height() * $"Background/Info Text".current_scale * $"Background/Info Text".get_child(0).get_line_count() + 8
	else:
		$"Background/Mod Text".rect_position.y = $"Background/Info Text".rect_position.y + $"Background/Info Text".get_font("font").get_height() * $"Background/Info Text".current_scale * 4.0 * $"Background/Info Text".get_line_count() + 8

func update_button_positions():
	var button_offset = 4
	var b_mod = 0
	for b in range(buttons.size()):
		if buttons[b] == promo_button or buttons[b] == promo_button2:
			continue
		buttons[b].text_node.icon_z_index = 9
		if $"/root/Main".demo or not $"/root/Main/Stats Sprite/Stats".stats_unlocked:
			if b == 3:
				b_mod -= 1
			else:
				buttons[b].text_node.force_update = true
				buttons[b].text_node.update()
			buttons[b].rect_position = Vector2(round($"/root/Main/Options Sprite/Options".resolution_x / 2 - buttons[b].rect_size.x / 2), $"/root/Main/Options Sprite/Options".resolution_y / 2 - buttons[b].rect_size.y * buttons.size() / 2 + (buttons[b].rect_size.y + 16) * b + 32)
		else:
			buttons[b].text_node.force_update = true
			buttons[b].text_node.update()
			buttons[b].correct_size()
			buttons[b].rect_position = Vector2(round($"/root/Main/Options Sprite/Options".resolution_x / 2 - buttons[b].rect_size.x / 2), $"/root/Main/Options Sprite/Options".resolution_y / 2 - buttons[b].rect_size.y * buttons.size() / 2 + (buttons[b].rect_size.y + 16) * b + 32)
		if $"/root/Main".demo:
			buttons[b].rect_position.y += 24
		buttons[b].title_button = true
		buttons[b].base_x = buttons[b].rect_position.x
		buttons[b].correct_size()

func website():
	if not title_loading and OS.is_window_focused():
		OS.shell_open("https://TrampolineTales.com")

func discord():
	if not title_loading and OS.is_window_focused():
		OS.shell_open("https://TrampolineTales.com/discord")

func steam():
	if not title_loading and OS.is_window_focused():
		OS.shell_open("https://store.steampowered.com/app/1404850/")

func merch():
	if not title_loading and OS.is_window_focused():
		OS.shell_open("https://TrampolineTales.com/shop")

func ios():
	if OS.is_window_focused():
		OS.shell_open("https://apps.apple.com/us/app/luck-be-a-landlord/id6450724928")

func android():
	if OS.is_window_focused():
		OS.shell_open("https://play.google.com/store/apps/details?id=com.trampolinetales.lbal")

func pizza():
	if OS.is_window_focused():
		OS.shell_open("https://www.makeship.com/products/pizza-the-cat-plush")

func twitter():
	if OS.is_window_focused():
		OS.shell_open("https://blog.TrampolineTales.com/")

func tt_data():
	if OS.is_window_focused():
		OS.shell_open($"/root/Main".tt_data.url)

func floor_menu():
	rightmost_stat_button_x = 0
	$"Background/Info Text".visible = true
	$"Background/Info Text".raw_string = tr("select_your_floor")
	$"Background/Info Text".rect_position = Vector2(8, 16)
	if int($"/root/Main/Options Sprite/Options".display_font) != 0:
		$"Background/Info Text".rect_position.y += 2
	
	$"Background/Mod Text".visible = true
	$"Background/Mod Text".values = [1, 5]
	if $"/root/Main/Options Sprite/Options".resolution_y < 720:
		$"Background/Mod Text".text_mod = 0
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			$"Background/Mod Text".scale_mod = -1
	else:
		$"Background/Mod Text".text_mod = 1
	$"Background/Mod Text".alignment_tags.dont = true
	$"Background/Mod Text".rect_position.x = 32 + 216 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
	set_mod_text_scale()
	
	if $"/root/Main".current_menu_path != "floor_menu":
		for b in range(buttons.size()):
			if b != 0 and b != 2:
				remove_child(buttons[b])
				buttons[b].queue_free()
		if mod_button != null:
			if get_children().has(mod_button):
				remove_child(mod_button)
			mod_button.queue_free()
			mod_button = null
	
	var highest_floor = $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor
	if modded_floor_page > 0:
		highest_floor = 0
		for p in $"/root/Main".modded_apartment_floors[$"/root/Main".modded_apartment_floors.keys()[modded_floor_page - 1]]:
			if $"/root/Main/Stats Sprite/Stats".unlocked_modded_floors.has(p) or not $"/root/Main".apartment_floor_database[p].locked:
				highest_floor += 1
			else:
				break
	for b in range(1, highest_floor + 1):
		var n = preload("res://TT Button.tscn").instance()
		floor_buttons.push_back(n)
		if b < 10:
			n.button_text = "0" + str(b)
		else:
			n.button_text = str(b)
		n.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
		n.color_type = "button_color_continue"
		n.target = self
		n.call = "set_floor"
		n.toggle = true
		n.title_button = true
		var p = b - 1
		n.rect_position = Vector2(8 + (p % 3) * 72 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons, $"/root/Main/Options Sprite/Options".resolution_y / 2 - 64 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons * floor((b - 1) / 3) + 96 + 72 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons)
		if b >= 19:
			n.rect_position.x += 36 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
		n.args = [b]
		n.alignment_tags.dont = true
		add_child(n)
		if rightmost_stat_button_x < n.rect_position.x + n.rect_size.x:
			rightmost_stat_button_x = n.rect_position.x + n.rect_size.x
	if $"/root/Main".current_menu_path != "floor_menu":
		buttons.remove(1)
		buttons.remove(2)
		buttons.remove(2)
		buttons[0].down = false
		buttons[0].visual_reset()
		buttons[0].update_size()
		buttons[0].rect_position = Vector2(round($"/root/Main/Options Sprite/Options".resolution_x / 2 - buttons[0].rect_size.x / 2), $"/root/Main/Options Sprite/Options".resolution_y - 16 - buttons[0].rect_size.y)
		buttons[0].alignment_tags.dont = true
		buttons[0].aligned = false
		buttons[0].saved_resolution = Vector2(1024, 576)
		buttons[0].reset_position()
		if $"/root/Main/Stats Sprite/Stats".stats_unlocked:
			buttons[0].rect_position.y += 1
		buttons[1].down = false
		buttons[1].visual_reset()
		buttons[1].update_size()
		buttons[1].rect_position = Vector2(8, $"/root/Main/Options Sprite/Options".resolution_y - 8 - buttons[1].rect_size.y)
		buttons[1].base_x = 1
		buttons[1].alignment_tags.dont = true
		buttons[1].aligned = false
		buttons[1].saved_resolution = Vector2(1024, 576)
		buttons[1].reset_position()

		back_button = preload("res://TT Button.tscn").instance()
		
		back_button.button_text = tr("back")
		back_button.shortcuts = ["deny_cancel"]
		back_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_options"])
		back_button.color_type = "button_color_options"
		back_button.target = self
		back_button.call = "draw"
		back_button.toggle = false
		back_button.alignment_tags.dont = true
	
		if $"/root/Main/Options Sprite/Options".resolution_y < 720:
			back_button.scale_mod = -1
	
		add_child(back_button)
	
		back_button.text_node.update()
		back_button.button_text = back_button.text_node.text
		back_button.update_size()
		back_button.button_text = back_button.text_node.raw_string
		back_button.base_x = back_button.rect_position.x
		back_button.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x - 8 - back_button.rect_size.x, $"/root/Main/Options Sprite/Options".resolution_y - 8 - back_button.rect_size.y)
		back_button.base_x = back_button.rect_position.x
		back_button.title_button = true
		
		back_button.reset_position()
		
		buttons.push_back(back_button)
	
		merch_button.visible = false
		discord_button.visible = false
		twitter_button.visible = false
		logo_button.visible = false
		patch_text.visible = false
		$"Background/Title Text".visible = false
		$"Background/Title Text 2".visible = false
	init_set = true
	floor_buttons[highest_floor - 1].was_down_while_active = true
	floor_buttons[highest_floor - 1].press()
	if $"/root/Main/Options Sprite/Options".input_type == 1:
		floor_buttons[highest_floor - 1].down = true
		floor_buttons[highest_floor - 1].unpress()
	init_set = false
	$"Background/Mod Text".force_update = true
	$"Background/Mod Text".update()
	$"Background/Info Text".update()
	if $"Background/Info Text".text.count("\n") > 0:
		$"Background/Mod Text".rect_position.y += 30
	$"/root/Main".change_current_menu_path("floor_menu")
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		for i in $"Background/Mod Text".get_child(0).icons:
			i.update_hitbox()
	else:
		for i in $"Background/Mod Text".texts[8].icons:
			i.update_hitbox()
	
	page_button.rect_position = Vector2(buttons[1].rect_position.x + buttons[1].rect_size.x + 8, buttons[1].rect_position.y)
	page_button2.rect_position = Vector2(page_button.rect_position.x + page_button.rect_size.x + 8, buttons[1].rect_position.y)
	page_button.base_x = page_button.rect_position.x
	page_button2.base_x = page_button2.rect_position.x
	if modded_floor_page > 0:
		page_button.visible = true
	else:
		page_button.visible = false
	if $"/root/Main".modded_apartment_floors.size() > 0 and modded_floor_page < $"/root/Main".modded_apartment_floors.keys().size():
		page_button2.visible = true
	else:
		page_button2.visible = false
	if TranslationServer.get_locale() == "ar" and $"/root/Main/Options Sprite/Options".resolution_y >= 1050:
		for b in buttons:
			b.rect_position.y -= 24

func stats_menu():
	rightmost_stat_button_x = 0
	$"Background/Info Text".visible = true
	$"Background/Info Text".raw_string = tr("select_your_floor")
	$"Background/Info Text".rect_position = Vector2(8, 16)
	if int($"/root/Main/Options Sprite/Options".display_font) != 0:
		$"Background/Info Text".rect_position.y += 2
	
	$"Background/Mod Text".visible = true
	$"Background/Mod Text".values = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
	$"Background/Mod Text".text_mod = 1
	set_mod_text_scale()
	
	for b in range(buttons.size()):
		if b != 2:
			remove_child(buttons[b])
			buttons[b].queue_free()
	if mod_button != null:
		remove_child(mod_button)
		mod_button.queue_free()
		mod_button = null
		
	for b in range(1, $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor + 2):
		var n = preload("res://TT Button.tscn").instance()
		floor_buttons.push_back(n)
		if b < 10:
			n.button_text = "0" + str(b)
		else:
			n.button_text = str(b)
		n.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
		n.color_type = "button_color_continue"
		n.target = self
		n.call = "show_stats"
		n.toggle = true
		n.title_button = true
		var p = b - 1
		if b == $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor + 1:
			n.button_text = tr("all")
			n.args = ["all"]
		else:
			n.args = [b]
		n.rect_position = Vector2(8 + (p % 3) * 72 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons, $"/root/Main/Options Sprite/Options".resolution_y / 2 - 64 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons * floor((b - 1) / 3) + 96 + 72 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons)
		n.alignment_tags.dont = true
		add_child(n)
		if rightmost_stat_button_x < n.rect_position.x + n.rect_size.x:
			rightmost_stat_button_x = n.rect_position.x + n.rect_size.x
	buttons.remove(0)
	buttons.remove(0)
	buttons.remove(1)
	buttons.remove(1)
	buttons[0].down = false
	buttons[0].visual_reset()
	buttons[0].update_size()
	buttons[0].rect_position = Vector2(8, $"/root/Main/Options Sprite/Options".resolution_y - 8 - buttons[0].rect_size.y)
	buttons[0].base_x = 8
	buttons[0].alignment_tags.dont = true
	buttons[0].aligned = false
	buttons[0].saved_resolution = Vector2(1024, 576)
	buttons[0].reset_position()
	
	back_button = preload("res://TT Button.tscn").instance()
	
	back_button.button_text = tr("back")
	back_button.shortcuts = ["deny_cancel"]
	back_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_options"])
	back_button.color_type = "button_color_options"
	back_button.target = self
	back_button.call = "draw"
	back_button.toggle = false
	back_button.alignment_tags.dont = true
	
	if $"/root/Main/Options Sprite/Options".resolution_y < 720:
		back_button.scale_mod = -1
	
	add_child(back_button)
	
	back_button.text_node.update()
	back_button.button_text = back_button.text_node.text
	back_button.update_size()
	back_button.button_text = back_button.text_node.raw_string
	back_button.base_x = back_button.rect_position.x
	back_button.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x - 8 - back_button.rect_size.x, $"/root/Main/Options Sprite/Options".resolution_y - 8 - back_button.rect_size.y)
	back_button.base_x = back_button.rect_position.x
	back_button.title_button = true
	
	back_button.reset_position()
	
	buttons.push_back(back_button)
	
	achievements_button = preload("res://TT Button.tscn").instance()
	
	achievements_button.button_text = tr("achievements_no_colon")
	achievements_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_stats"])
	achievements_button.color_type = "button_color_stats"
	achievements_button.target = $"/root/Main/Options Sprite/Options"
	achievements_button.call = "open_mods"
	achievements_button.toggle = false
	achievements_button.args = [achievements_button]
	achievements_button.rect_size_mod = 0.25
	achievements_button.title_button = true
	
	if $"/root/Main/Options Sprite/Options".resolution_y < 720:
		achievements_button.scale_mod = -1
	
	add_child(achievements_button)
	
	achievements_button.text_node.update()
	achievements_button.button_text = achievements_button.text_node.text
	achievements_button.update_size()
	achievements_button.button_text = achievements_button.text_node.raw_string
	achievements_button.base_x = achievements_button.rect_position.x
	achievements_button.rect_position = Vector2($"/root/Main/Options Sprite/Options".resolution_x / 2 - achievements_button.rect_size.x / 2, $"/root/Main/Options Sprite/Options".resolution_y - 8 - achievements_button.rect_size.y)
	achievements_button.base_x = achievements_button.rect_position.x
	achievements_button.title_button = true
	
	achievements_button.reset_position()
	
	buttons.push_back(achievements_button)
	
	merch_button.visible = false
	discord_button.visible = false
	twitter_button.visible = false
	logo_button.visible = false
	patch_text.visible = false
	$"Background/Title Text".visible = false
	$"Background/Title Text 2".visible = false
	init_set = true
	floor_buttons[$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor].was_down_while_active = true
	floor_buttons[$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor].press()
	set_mod_text_scale()
	if $"/root/Main/Options Sprite/Options".input_type == 1:
		floor_buttons[$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor].down = true
		floor_buttons[$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor].unpress()
	init_set = false
	$"Background/Mod Text".force_update = true
	$"Background/Mod Text".update()
	$"Background/Mod Text".rect_position.y += 0
	$"/root/Main".change_current_menu_path("stats_menu")
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		for i in $"Background/Mod Text".get_child(0).icons:
			i.update_hitbox()
	else:
		for i in $"Background/Mod Text".texts[8].icons:
			i.update_hitbox()
	if TranslationServer.get_locale() == "ar" and $"/root/Main/Options Sprite/Options".resolution_y >= 1050:
		for b in buttons:
			b.rect_position.y -= 24

func show_stats(fl):
	$"Background/Mod Text".need_to_left = false
	$"Background/Info Text".need_to_left = false
	set_mod_text_scale()
	$"Background/Mod Text".text_mod = 1
	$"Background/Mod Text".raw_string = ""
	$"Background/Mod Text".force_update = true
	$"Background/Mod Text".update()
	$"Background/Mod Text".values = []
	$"Background/Mod Text".alignment_tags.dont = true
	var stats = $"/root/Main/Stats Sprite/Stats"
	$"Background/Mod Text".values = [stats.get_converted_stat("total_games_played", fl), stats.get_converted_stat("total_games_won", fl), stats.get_converted_stat("current_winstreaks", fl), stats.get_converted_stat("highest_winstreaks", fl), stats.get_converted_stat("billionaires_guillotined", fl), round(stepify(stats.get_converted_stat("time_spent_petting_dog", fl), 0.1)), stepify(stats.get_converted_stat("rabbit_fluff_shed", fl), 0.01), stats.get_converted_stat("humans_murdered_by_general_zaroff", fl), round(stats.get_converted_stat("alcohol_consumed", fl)), stats.get_converted_stat("times_executed", fl), round(stats.get_converted_stat("rabbit_hops", fl)), round(stats.get_converted_stat("landlord_executions", fl)), stats.highest_unlocked_floor, $"/root/Main/Pop-up Sprite/Pop-up".max_floor]
	if typeof(fl) == TYPE_STRING and fl == "all":
		for b in range(floor_buttons.size()):
			if b != $"/root/Main/Pop-up Sprite/Pop-up".max_floor:
				floor_buttons[b].active = true
				floor_buttons[b].visual_reset()
				floor_buttons[b].down = false
			else:
				floor_buttons[b].active = false
	else:
		for b in range(floor_buttons.size()):
			if b != fl - 1:
				floor_buttons[b].active = true
				floor_buttons[b].visual_reset()
				floor_buttons[b].down = false
			else:
				floor_buttons[b].active = false
	$"Background/Mod Text".raw_string += tr("games_played") + "\n"
	$"Background/Mod Text".raw_string += tr("games_won") + "\n"
	if $"Background/Mod Text".values[11] != 0:
		$"Background/Mod Text".raw_string += tr("landlord_executions") + "\n"
	if TranslationServer.get_locale() == "ar":
		$"Background/Mod Text".rect_position.x = rightmost_stat_button_x - 32
	else:
		$"Background/Mod Text".rect_position.x = rightmost_stat_button_x + 32
	if typeof(fl) == TYPE_STRING and fl == "all":
		$"Background/Mod Text".raw_string += tr("floors_unlocked") + "\n"
		if TranslationServer.get_locale() == "ar":
			$"Background/Mod Text".raw_string += tr("achievements") + " <text_color_keyword>186<end>/<text_color_keyword>" + str($"/root/Main/Stats Sprite/Stats".achievements_unlocked.count(true)) + "<end>" + "\n"
		else:
			$"Background/Mod Text".raw_string += tr("achievements") + " <text_color_keyword>" + str($"/root/Main/Stats Sprite/Stats".achievements_unlocked.count(true)) + "<end>/<text_color_keyword>186<end>" + "\n"
	else:
		$"Background/Mod Text".raw_string += tr("current_winstreak") + "\n"
		$"Background/Mod Text".raw_string += tr("highest_winstreak") + "\n"
	if $"Background/Mod Text".values[4] != 0:
		$"Background/Mod Text".raw_string += tr("billionaires_guillotined") + "\n"
	if $"Background/Mod Text".values[5] != 0:
		$"Background/Mod Text".raw_string += tr("time_spent_petting_dog") + "\n"
	if $"Background/Mod Text".values[10] != 0:
		$"Background/Mod Text".raw_string += tr("rabbit_hops") + "\n"
	if $"Background/Mod Text".values[6] != 0:
		$"Background/Mod Text".raw_string += tr("rabbit_fluff_shed") + "\n"
	if $"Background/Mod Text".values[7] != 0:
		$"Background/Mod Text".raw_string += tr("humans_murdered_by_general_zaroff") + "\n"
	if $"Background/Mod Text".values[8] != 0:
		$"Background/Mod Text".raw_string += tr("alcohol_consumed") + "\n"
	if $"Background/Mod Text".values[9] != 0:
		$"Background/Mod Text".raw_string += tr("times_executed") + "\n"
	$"Background/Mod Text".force_update = true
	$"Background/Mod Text".update()
	set_mod_text_scale()
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		while $"Background/Mod Text".rect_global_position.y + $"Background/Mod Text".get_child(0).get_font("font").get_height() * $"Background/Mod Text".current_scale * $"Background/Mod Text".get_child(0).get_line_count() >= back_button.rect_global_position.y:
			$"Background/Mod Text".text_mod -= 1
			$"Background/Mod Text".force_update = true
			$"Background/Mod Text".change_set_size($"Background/Mod Text".base_scale)
			$"Background/Mod Text".update()
	else:
		$"Background/Mod Text".update()
		while $"Background/Mod Text".rect_global_position.y + ($"Background/Mod Text".get_font("font").get_height() + 3) * $"Background/Mod Text".current_scale * 4.0 * $"Background/Mod Text".get_line_count() >= back_button.rect_global_position.y:
			$"Background/Mod Text".text_mod -= 1
			$"Background/Mod Text".force_update = true
			$"Background/Mod Text".change_set_size($"Background/Mod Text".base_scale)
			$"Background/Mod Text".update()
	if TranslationServer.get_locale() == "ar":
		$"Background/Mod Text".need_to_left = true
		$"Background/Info Text".need_to_left = true
		$"Background/Mod Text".force_update = true
		$"Background/Mod Text".update()
		$"Background/Info Text".force_update = true
		$"Background/Info Text".update()
	tts()

func set_floor(fl):
	$"Background/Mod Text".need_to_left = false
	$"Background/Info Text".need_to_left = false
	set_mod_text_scale()
	$"Background/Mod Text".text_mod = 1
	$"Background/Mod Text".raw_string = ""
	$"Background/Mod Text".force_update = true
	$"Background/Mod Text".update()
	$"Background/Mod Text".values = []
	for b in range(floor_buttons.size()):
		if b != fl - 1:
			floor_buttons[b].active = true
			floor_buttons[b].visual_reset()
			floor_buttons[b].down = false
		else:
			floor_buttons[b].active = false
	temp_floor = fl
	temp_modded_floor = ""
	if TranslationServer.get_locale() == "ar":
		$"Background/Mod Text".rect_position.x = rightmost_stat_button_x - 32
	else:
		$"Background/Mod Text".rect_position.x = rightmost_stat_button_x + 32
	if modded_floor_page > 0:
		temp_floor = 1
		$"/root/Main/Pop-up Sprite/Pop-up".modded_floor_string = $"/root/Main".modded_apartment_floors[$"/root/Main".modded_apartment_floors.keys()[modded_floor_page - 1]][fl - 1]
		temp_modded_floor = $"/root/Main".apartment_floor_database[$"/root/Main".modded_apartment_floors[$"/root/Main".modded_apartment_floors.keys()[modded_floor_page - 1]][fl - 1]]
		if temp_modded_floor.localized_text.has(TranslationServer.get_locale()):
			$"Background/Mod Text".raw_string = temp_modded_floor.localized_text[TranslationServer.get_locale()]
		else:
			$"Background/Mod Text".raw_string = temp_modded_floor.text
	elif fl == 1:
		$"Background/Mod Text".raw_string = tr("no_mods")
	else:
		var very_end = ""
		var extra_values = []
		var mod_1s = 0
		var mod_4s = 0
		var mod_6s = 0
		var mod_7s = 0
		var mod_8s = 0
		var mod_4_value_pos = -1
		var mod_6_value_pos = -1
		var mod_7_value_pos = -1
		var mod_8_value_pos = -1
		var positioned_mods = []
		positioned_mods.resize($"/root/Main/Pop-up Sprite/Pop-up".max_floor)
		for f in range(fl - 1):
			positioned_mods[floor_mods[f].pos - 1] = floor_mods[f]
		var f_tbe = []
		for f in range(positioned_mods.size()):
			if positioned_mods[f] == null:
				f_tbe.push_back(f)
		for f in range(f_tbe.size()):
			positioned_mods.remove(f_tbe[f] - f)
		for f in range(fl - 1):
			if positioned_mods[f].string == "mod_1":
				var rs = tr(positioned_mods[f].string)
				var start
				var end
				var offset = 0
				while true:
					var can_break = true
					for s in range(offset, rs.length()):
						if rs[s] == "_" and rs[s - 5] == "v" and rs[s - 6] == "<":
							start = s
						if start != null and rs[s] == ">":
							end = s
						if start != null and end != null:
							rs = rs.substr(0, start) + "_" + str(int(rs.substr(start, end - start)) + mod_1s * 2) + rs.substr(start + (end - start), -1)
							offset += end
							start = null
							end = null
							can_break = false
							break
					if can_break:
						mod_1s += 1
						break
				$"Background/Mod Text".raw_string += rs + "\n"
				$"Background/Mod Text".values += positioned_mods[f].values
		for f in range(fl - 1):
			if positioned_mods[f].string != "mod_1":
				var rs = tr(positioned_mods[f].string)
				var start
				var end
				var offset = 0
				while true:
					var can_break = true
					for s in range(offset, rs.length()):
						if rs[s] == "_" and rs[s - 5] == "v" and rs[s - 6] == "<":
							start = s
						if start != null and rs[s] == ">":
							end = s
						if start != null and end != null:
							rs = rs.substr(0, start) + "_" + str(int(rs.substr(start, end - start)) + mod_1s * 2 + extra_values.size()) + rs.substr(start + (end - start), -1)
							offset += end
							start = null
							end = null
							can_break = false
							break
					if can_break:
						break
				if positioned_mods[f].string == "mod_4" and mod_4s >= 1:
					extra_values[mod_4_value_pos] += 1
				elif positioned_mods[f].string == "mod_4":
					mod_4s += 1
					mod_4_value_pos = extra_values.size()
					extra_values += positioned_mods[f].values
					very_end += rs + "\n"
				elif positioned_mods[f].string == "mod_6" and mod_6s >= 1:
					extra_values[mod_6_value_pos] -= 5
				elif positioned_mods[f].string == "mod_6":
					mod_6s += 1
					mod_6_value_pos = extra_values.size()
					extra_values += positioned_mods[f].values
					very_end += rs + "\n"
				elif positioned_mods[f].string == "mod_7" and mod_7s >= 1:
					extra_values[mod_7_value_pos] += 500
				elif positioned_mods[f].string == "mod_7":
					mod_7s += 1
					mod_7_value_pos = extra_values.size()
					extra_values += positioned_mods[f].values
					very_end += rs + "\n"
				elif positioned_mods[f].string == "mod_8" and mod_8s >= 1:
					extra_values[mod_8_value_pos] += 1
				elif positioned_mods[f].string == "mod_8":
					mod_8s += 1
					mod_8_value_pos = extra_values.size()
					extra_values += positioned_mods[f].values
					very_end += rs + "\n"
				else:
					very_end += rs + "\n"
					extra_values += positioned_mods[f].values
		set_mod_text_scale()
		$"Background/Mod Text".raw_string += very_end.substr(0, very_end.length() - 1)
		$"Background/Mod Text".force_update = true
		$"Background/Mod Text".values += extra_values
		$"Background/Mod Text".e_spaced = true
		$"Background/Mod Text".update()
	set_mod_text_scale()
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		$"Background/Mod Text".update()
		while $"Background/Mod Text".rect_global_position.y + $"Background/Mod Text".get_child(0).get_font("font").get_height() * $"Background/Mod Text".current_scale * $"Background/Mod Text".get_child(0).get_line_count() >= buttons[0].rect_global_position.y:
			$"Background/Mod Text".text_mod -= 1
			$"Background/Mod Text".force_update = true
			$"Background/Mod Text".change_set_size($"Background/Mod Text".base_scale)
			$"Background/Mod Text".update()
	else:
		$"Background/Mod Text".update()
		while $"Background/Mod Text".rect_global_position.y + ($"Background/Mod Text".get_font("font").get_height() + 3) * $"Background/Mod Text".current_scale * 4.0 * $"Background/Mod Text".get_line_count() >= buttons[0].rect_global_position.y:
			$"Background/Mod Text".text_mod -= 1
			$"Background/Mod Text".force_update = true
			$"Background/Mod Text".change_set_size($"Background/Mod Text".base_scale)
			$"Background/Mod Text".update()
	if TranslationServer.get_locale() == "ar":
		$"Background/Mod Text".need_to_left = true
		$"Background/Info Text".need_to_left = true
		$"Background/Mod Text".force_update = true
		$"Background/Mod Text".update()
		$"Background/Info Text".force_update = true
		$"Background/Info Text".update()
	tts()

func tts():
	$"/root/Main".tts($"Background/Info Text".raw_string + "\n" + $"Background/Mod Text".raw_string, $"Background/Mod Text".values, self)

func remove():
	visible = false
	for b in buttons:
		if is_instance_valid(b):
			remove_child(b)
			b.queue_free()
	for b in floor_buttons:
		if is_instance_valid(b):
			remove_child(b)
			b.queue_free()
	floor_buttons.clear()
	buttons.clear()
	if back_button != null and is_instance_valid(back_button):
		if get_children().has(back_button):
			remove_child(back_button)
		back_button.queue_free()
		back_button = null
	if mod_button != null and is_instance_valid(mod_button):
		if get_children().has(mod_button):
			remove_child(mod_button)
		mod_button.queue_free()
		mod_button = null
	if merch_button != null:
		merch_button.visible = false
	if discord_button != null:
		discord_button.visible = false
	if twitter_button != null:
		twitter_button.visible = false
	if logo_button != null:
		logo_button.visible = false
	$"Background/Mod Text".raw_string = ""
	$"/root/Main/Menus".buttons_menu.spin_button.visible = true
	$"/root/Main/Menus".buttons_menu.options_button.visible = true
	$"/root/Main/Menus".buttons_menu.deck_button.visible = true
	if $"/root/Main/Menus".buttons_menu.right_button != null:
		$"/root/Main/Items".update_page_buttons()
	if $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens > 0:
		$"/root/Main/Menus".buttons_menu.removal_button.update_size()
		$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
		$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
		$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
		$"/root/Main/Menus".buttons_menu.removal_button.visible = true
