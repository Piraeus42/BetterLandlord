extends Control

var background
var border
var active = false
var hovering = false
var selectable = false
var off_screen = false
var tooltip_card = false
var item = false
var held = false
var delay = 0
var r_x_mod = 0
var extra_height = 0
var cant_go_dirs = []
var selector_alignment = "card"

var data = {}

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
	if event is InputEventKey and ($"/root/Main/Options Sprite/Options".input_type == 0 and event.is_pressed() or ($"/root/Main/Options Sprite/Options".input_type == 1 and not event.is_pressed())) and not event.is_echo() and OS.is_window_focused():
		$"/root/Main".last_pressed_key_code = event.scancode
	elif event is InputEventMouseButton and ($"/root/Main/Options Sprite/Options".input_type == 0 and event.is_pressed() or ($"/root/Main/Options Sprite/Options".input_type == 1 and not event.is_pressed())) and not event.is_echo() and OS.is_window_focused() and event.button_index != BUTTON_LEFT:
		$"/root/Main".last_pressed_key_code = event.button_index
	if active and hovering and event is InputEventMouseButton and ((event.is_pressed() and $"/root/Main/Options Sprite/Options".input_type == 1) or ($"/root/Main/Options Sprite/Options".input_type == 0 and (event.is_pressed() or Steam.isSteamRunningOnSteamDeck()))) and event.button_index == BUTTON_LEFT and not event.is_echo() and not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible and not $"/root/Main".lmb_down:
		if $"/root/Main/Options Sprite/Options".input_type == 0:
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(data.type)
		else:
			held = true
		$"/root/Main".lmb_down = true
		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
	elif held and active and hovering and event is InputEventMouseButton and not event.is_pressed() and event.button_index == BUTTON_LEFT and not event.is_echo() and not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
		if $"/root/Main/Options Sprite/Options".input_type == 1 and held:
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			else:
				$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(data.type)
			held = false
		$"/root/Main".lmb_down = false
		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
	elif event is InputEventMouseButton and not event.is_pressed() and event.button_index == BUTTON_LEFT:
		$"/root/Main".lmb_down = false
		held = false
	if $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and event is InputEventKey and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
		if event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["inspect"][0]:
			if not $"/root/Main/Selector Sprite/Selector".visible:
				$"/root/Main/Selector Sprite/Selector".visible = true
			else:
				pass
		elif event.scancode == $"/root/Main/Options Sprite/Options".hotkeys["confirm_select"][0]:
			if not $"/root/Main/Selector Sprite/Selector".visible:
				$"/root/Main/Selector Sprite/Selector".visible = true

func _ready():
	set_icon_size()
		
	if item:
		background.color = $"/root/Main/Options Sprite/Options".colors3["item_background"]
	else:
		background.color = $"/root/Main/Options Sprite/Options".colors3["symbol_background"]
	
	set_card_size()
	
	background.get_node("Title").force_update = true
	background.get_node("Title").update()
	set_icon_size()
	set_card_size()

func set_icon_size():
	var icon = $"Icon"
	
	background = $"Background"
	border = $"Border"
	
	icon.type = data.type
	icon.set_texture($"/root/Main".get_replacement_texture(data.type))
	
	background.rect_size.x = 300 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
	
	if $"/root/Main".tile_database.has(data.type):
		if int($"/root/Main/Options Sprite/Options".display_font) == 1:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 94 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 16)
		elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 100 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 16)
		else:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 90 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 8)
		icon.scale = Vector2(8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
	else:
		if int($"/root/Main/Options Sprite/Options".display_font) == 1:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 94 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 16)
		elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 100 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 16)
		else:
			icon.position = Vector2(background.rect_size.x / 2 - icon.texture.get_size().x * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 90 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - icon.texture.get_size().y * 2 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1) * 8)
		icon.scale = Vector2(4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
		
	icon.position.y -= 2

func set_card_size():
	var title = $"Background/Title"
	var rarity = $"Background/Rarity"
	var value = $"Background/Value"
	var description = $"Background/Description"
	var separator = $"Separator"
	var font_offset
	var font_size_value = 3
	var cjk_mod
	var cjk = $"/root/Main/Options Sprite/Options".CJK_lang

	background = $"Background"

	title.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
	rarity.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
	value.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
	description.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
	separator.width = 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections

	title.dont_scale = true
	rarity.dont_scale = true
	value.dont_scale = true
	description.dont_scale = true
	
	if TranslationServer.get_locale() == "ar":
		description.need_to_left = true

	if cjk:
		description.diff_cjk_space = false
		cjk_mod = 1
		title.scale_mod = -1
		rarity.scale_mod = -1
		value.scale_mod = -1
		description.scale_mod = -1
		title.text_mod -= 1
		rarity.text_mod -= 1
		value.text_mod -= 1
		description.text_mod -= 1
		title.tooltip_desc = true
		value.tooltip_desc = true
		description.tooltip_desc = true
		title.change_set_size(title.base_scale)
		rarity.change_set_size(rarity.base_scale)
		value.change_set_size(value.base_scale)
		description.change_set_size(description.base_scale)
		title.custom_icon_offset = Vector2(0, 4)
		rarity.custom_icon_offset = Vector2(0, 4)
		value.custom_icon_offset = Vector2(0, 4)
		description.custom_icon_offset = Vector2(0, 4)
	else:
		if int($"/root/Main/Options Sprite/Options".display_font) == 0:
			title.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
			title.change_set_size(0.75)
			title.base_scale = 0.75
			rarity.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
			rarity.change_set_size(0.75)
			rarity.base_scale = 0.75
			value.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
			value.change_set_size(0.75)
			value.base_scale = 0.75
			description.tooltip_desc = true
			description.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25)
			description.change_set_size(0.75)
			description.base_scale = 0.75
			cjk_mod = 4
		else:
			title.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25) - 1
			title.text_mod -= 1
			title.change_set_size(0.5)
			title.base_scale = 0.5
			rarity.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25) - 1
			rarity.text_mod -= 1
			rarity.change_set_size(0.5)
			rarity.base_scale = 0.5
			value.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25) - 1
			value.text_mod -= 1
			value.change_set_size(0.5)
			value.base_scale = 0.5
			description.tooltip_desc = true
			description.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections) / 0.25) - 1
			description.text_mod -= 1
			description.change_set_size(0.5)
			description.base_scale = 0.5
			cjk_mod = 1
		title.v_spaced = true
		rarity.v_spaced = true
		value.v_spaced = true
		description.v_spaced = true
	
	if data.has("type"):
		if data.modded:
			if data.localized_names.has(TranslationServer.get_locale()):
				title.raw_string = data.localized_names[TranslationServer.get_locale()]
			else:
				title.raw_string = data.display_name
		elif data.rarity == "essence":
			title.raw_string = tr(data.type.substr(0, data.type.length() - 8))
			if title.raw_string == data.type.substr(0, data.type.length() - 8):
				title.raw_string = ""
		else:
			title.raw_string = tr(data.type)
			if title.raw_string == data.type:
				title.raw_string = ""
		title.size_update = true
		title.raw_string = tr(data.type)
		if data.modded:
			if data.localized_names.has(TranslationServer.get_locale()):
				title.raw_string = data.localized_names[TranslationServer.get_locale()]
			else:
				title.raw_string = data.display_name
		elif data.rarity == "essence":
			title.raw_string = tr(data.type.substr(0, data.type.length() - 8))
			if title.raw_string == data.type.substr(0, data.type.length() - 8):
				title.raw_string = ""
		else:
			title.raw_string = tr(data.type)
			if title.raw_string == data.type:
				title.raw_string = ""
		
		title.force_update = true
		title.update()
		
		if cjk or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in title.get_child(0).icons:
				i.active = false
		else:
			for i in title.texts[8].icons:
				i.active = false
		
		if cjk:
			title.rect_position.x = background.rect_size.x / 2 - (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(0, title.get_child(0).text.find("\n"))).x) * cjk_mod / 2 * title.current_scale
			font_offset = title.get_font("font").get_height() * title.current_scale
			var saved_w = (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(0, title.get_child(0).text.find("\n"))).x - title.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
			var saved_pos = title.get_child(0).text.find("\n")
			for i in range(title.get_child(0).text.count("\n")):
				var w = (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(saved_pos + 1, title.get_child(0).text.substr(saved_pos + 1, -1).find("\n"))).x - title.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
				if w > saved_w:
					title.rect_position.x = background.rect_size.x / 2 - w
					w = saved_w
				saved_pos = title.get_child(0).text.substr(saved_pos, -1).find("\n")
			font_offset = (title.get_child(0).get_font("font").get_height() + 4) * title.current_scale
		else:
			if int($"/root/Main/Options Sprite/Options".display_font) == 1:
				title.rect_position = Vector2(background.rect_size.x / 2 - (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(0, title.get_child(0).text.find("\n"))).x - title.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale, 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
			elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
				title.rect_position = Vector2(background.rect_size.x / 2 - (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(0, title.get_child(0).text.find("\n"))).x - 16) * cjk_mod / 2 * title.current_scale, 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
			else:
				title.rect_position = Vector2(background.rect_size.x / 2 - (title.get_font("font").get_string_size(title.text.substr(0, title.text.find("\n"))).x - title.get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale, 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
			var saved_w
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				saved_w = (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(0, title.get_child(0).text.find("\n"))).x - title.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
			else:
				saved_w = (title.get_font("font").get_string_size(title.text.substr(0, title.text.find("\n"))).x - title.get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				var saved_pos = title.get_child(0).text.find("\n")
				for i in range(title.get_child(0).text.count("\n")):
					var w
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						w = (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(saved_pos + 1, title.get_child(0).text.substr(saved_pos + 1, -1).find("\n"))).x - 16) * cjk_mod / 2 * title.current_scale
					else:
						w = (title.get_child(0).get_font("font").get_string_size(title.get_child(0).text.substr(saved_pos + 1, title.get_child(0).text.substr(saved_pos + 1, -1).find("\n"))).x - title.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
					if w > saved_w:
						title.rect_position.x = background.rect_size.x / 2 - w
						w = saved_w
					saved_pos = title.get_child(0).text.substr(saved_pos, -1).find("\n")
			else:
				var saved_pos = title.text.find("\n")
				for i in range(title.text.count("\n")):
					var w = (title.get_font("font").get_string_size(title.text.substr(saved_pos, title.text.substr(saved_pos + 1, -1).find("\n"))).x - title.get_font("font").extra_spacing_space) * cjk_mod / 2 * title.current_scale
					if w > saved_w:
						title.rect_position.x = background.rect_size.x / 2 - w
						w = saved_w
					saved_pos = title.text.substr(saved_pos, -1).find("\n")
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				font_offset = (title.get_child(0).get_font("font").get_height() + 4) * title.current_scale
			else:
				font_offset = (title.get_font("font").get_height() + 34) * title.current_scale
		
		if cjk or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			$"Icon".position.y += (font_offset + 8) * title.get_child(0).text.count("\n")
		else:
			$"Icon".position.y += (font_offset + 8) * title.text.count("\n")

		match data.rarity:
			"common":
				rarity.raw_string = "<text_color_common>"+ tr("common") + "<end>"
			"uncommon":
				rarity.raw_string = "<text_color_uncommon>"+ tr("uncommon") + "<end>"
			"rare":
				rarity.raw_string = "<text_color_rare>"+ tr("rare") + "<end>"
			"very_rare":
				rarity.raw_string = "<text_color_very_rare>"+ tr("very_rare") + "<end>"
			"essence":
				rarity.raw_string = "<text_color_essence>"+ tr("essence") + "<end>"
				
		if data.type == "hover_coin":
			rarity.raw_string = "<text_color_common>"+ tr("common") + "<end>"
		rarity.change_font_size(font_size_value, true)
		if cjk:
			rarity.rect_position = Vector2(background.rect_size.x / 2 - rarity.get_font("font").get_string_size(rarity.get_child(0).text).x * rarity.current_scale / 2, title.rect_position.y + font_offset + (156 - (title.get_font("font").get_height()) * 0.5) * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + (font_offset + 8) * title.get_child(0).text.count("\n"))
		else:
			if int($"/root/Main/Options Sprite/Options".display_font) == 1:
				rarity.rect_position = Vector2(background.rect_size.x / 2 - (rarity.get_child(0).get_font("font").get_string_size(rarity.get_child(0).text).x - rarity.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * rarity.current_scale, title.rect_position.y + font_offset + 112 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + (font_offset + 8) * title.get_child(0).text.count("\n"))
			elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
				rarity.rect_position = Vector2(background.rect_size.x / 2 - (rarity.get_child(0).get_font("font").get_string_size(rarity.get_child(0).text).x - 24) * cjk_mod / 2 * rarity.current_scale, title.rect_position.y + font_offset + 112 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + (font_offset + 8) * title.get_child(0).text.count("\n"))
			else:
				rarity.rect_position = Vector2(background.rect_size.x / 2 - (rarity.get_font("font").get_string_size(rarity.text).x - rarity.get_font("font").extra_spacing_space) * cjk_mod / 2 * rarity.current_scale, title.rect_position.y + font_offset + 100 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections + (font_offset + 8) * title.text.count("\n"))
		
		if data.has("value") and not $"/root/Main".item_database.has(data.type):
			value.raw_string = tr("value")
			value.values = [data.value]
			
			value.force_update = true
			value.update()
			
			if cjk:
				value.rect_position.x = background.rect_size.x / 2 - value.get_font("font").get_string_size(value.get_child(0).text).x * cjk_mod / 2 * value.current_scale
			elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
				value.rect_position.x = background.rect_size.x / 2 - (value.get_child(0).get_font("font").get_string_size(value.get_child(0).text).x - value.get_child(0).get_font("font").extra_spacing_space) * cjk_mod / 2 * value.current_scale
			elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
				value.rect_position.x = background.rect_size.x / 2 - (value.get_child(0).get_font("font").get_string_size(value.get_child(0).text).x - 24) * cjk_mod / 2 * value.current_scale
			else:
				value.rect_position.x = background.rect_size.x / 2 - (value.get_font("font").get_string_size(value.text).x - value.get_font("font").extra_spacing_space) * cjk_mod / 2 * value.current_scale
			
			if rarity.raw_string != "":
				value.rect_position.y = rarity.rect_position.y + font_offset
				if cjk:
					description.rect_position.y = value.rect_position.y + font_offset * 1.5 - 6 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					description.rect_position.y = value.rect_position.y + font_offset * 1.5 + 6 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
				else:
					description.rect_position.y = value.rect_position.y + font_offset * 2 - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
			else:
				value.rect_position.y = title.rect_position.y + font_offset + 8 + (font_offset + 8) * title.text.count("\n")
				if cjk:
					description.rect_position.y = value.rect_position.y + font_offset * 2 - 32 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
				else:
					description.rect_position.y = value.rect_position.y + font_offset * 2 - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
			if title.raw_string == "":
				if cjk:
					value.rect_position.y -= 68 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
				else:
					value.rect_position.y -= 44 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		elif rarity.raw_string != "":
			if cjk:
				description.rect_position.y = rarity.rect_position.y + font_offset * 2 - 24 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
			else:
				description.rect_position.y = rarity.rect_position.y + font_offset * 2 - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		else:
			if cjk:
				description.rect_position.y = title.rect_position.y + font_offset * 2 - 32 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
			else:
				description.rect_position.y = title.rect_position.y + font_offset * 2 - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		if data.type != "essence_token" and data.type != "reroll_token" and data.type != "removal_token":
			if data.modded:
				if data.localized_descriptions.has(TranslationServer.get_locale()):
					description.raw_string = data.localized_descriptions[TranslationServer.get_locale()]
				else:
					description.raw_string = data.description
				if data.inherit_description and data.inherit_effects:
					var mod_desc = description.raw_string
					var inherited_type = data.type.substr(0, data.type.find("_STEAM_ID_"))
					if tr(inherited_type + "_desc") != inherited_type + "_desc":
						description.raw_string = tr(inherited_type + "_desc")
					else:
						description.raw_string = ""
					if mod_desc != "":
						if description.raw_string == "":
							description.raw_string += mod_desc
						else:
							description.raw_string += "\n" + mod_desc
			else:
				description.raw_string = tr(data.type + "_desc")
		else:
			description.raw_string = tr(data.type + "_reminder")
			if cjk:
				description.rect_position.y -= 80
			else:
				description.rect_position.y -= 72
		if description.raw_string == data.type + "_desc" or description.raw_string == data.type + "_reminder":
			description.raw_string = ""
		else:
			description.values = data.values
		if int($"/root/Main/Options Sprite/Options".display_font) == 2:
			description.rect_position.x = 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		else:
			description.rect_position.x = 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		
		description.force_update = true
		if int($"/root/Main/Options Sprite/Options".display_font) > 0:
			description.base_scale = 0.5
		description.change_set_size(description.base_scale)
		description.update()

		if description.raw_string != "":
			separator.clear_points()
			if int($"/root/Main/Options Sprite/Options".display_font) == 0:
				separator.add_point(Vector2(16, description.rect_position.y - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections))
				separator.add_point(Vector2(background.rect_size.x - 16, description.rect_position.y - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections))
			else:
				separator.add_point(Vector2(16, description.rect_position.y - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections))
				separator.add_point(Vector2(background.rect_size.x - 16, description.rect_position.y - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections))
		else:
			if cjk:
				background.rect_size.y = value.rect_position.y + (value.get_font("font").get_height() * value.current_scale) * value.get_child(0).get_line_count() + 8
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				background.rect_size.y = value.rect_position.y + (value.get_child(0).get_font("font").get_height() * value.current_scale) * (value.get_child(0).text.count("\n") + 1.25)
			else:
				background.rect_size.y = value.rect_position.y + ((value.get_font("font").get_height() * value.current_scale * 4.0) + value.current_scale * 4.0 * (3 + 1.0 / 9.0)) * value.get_line_count()
		if cjk:
			if description.raw_string != "":
				background.rect_size.y = description.rect_position.y + ((description.get_font("font").get_height() * description.current_scale) * description.get_child(0).get_line_count() + 8)
			elif rarity.raw_string != "":
				background.rect_size.y = 296 * ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 0.25)
			if title.raw_string == "":
				value.rect_position.y += 8 * ($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 0.25)
		elif description.raw_string != "":
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				background.rect_size.y = description.rect_position.y + ((description.get_child(0).get_font("font").get_height() * description.current_scale)) * (description.get_child(0).text.count("\n") + 1.25)
			else:
				background.rect_size.y = description.rect_position.y + ((description.get_font("font").get_height() * description.current_scale * 4.0) + description.current_scale * 4.0 * (3 + 1.0 / 9.0)) * description.get_line_count()
		if data.type == "missing" or data.type == "item_missing":
			if cjk:
				background.rect_size.y += value.rect_position.y + (value.get_font("font").get_height() * value.current_scale) * value.get_child(0).get_line_count() + 8
			else:
				background.rect_size.y += $"Icon".texture.get_size().y * $"Icon".scale.y
		elif rarity.raw_string == "" and description.raw_string == "":
			if cjk:
				background.rect_size.y -= 104 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
			else:
				background.rect_size.y -= 68 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		if TranslationServer.get_locale() == "th":
			background.rect_size.y -= 16 / $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections
		background.rect_size.y += extra_height
		if $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections > 1:
			border.rect_position = Vector2(background.rect_position.x - 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, background.rect_position.y - 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
			border.rect_size = Vector2(background.rect_size.x + 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, background.rect_size.y + 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
		else:
			border.rect_position = Vector2(background.rect_position.x - 4, background.rect_position.y - 4)
			border.rect_size = Vector2(background.rect_size.x + 8, background.rect_size.y + 8)
		if $"/root/Main".item_database.has(data.type):
			background.color = $"/root/Main/Options Sprite/Options".colors3["item_background"]
	else:
		description.raw_string = data.text
		description.change_font_size(font_size_value, true)
		description.rect_position = Vector2(8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
		if int($"/root/Main/Options Sprite/Options".display_font) > 0:
			font_offset = (description.get_child(0).get_font("font").get_height() - description.get_child(0).get_font("font").extra_spacing_top) * description.rect_scale.y
		else:
			font_offset = (description.get_font("font").get_height() - description.get_font("font").extra_spacing_top) * description.rect_scale.y
		if cjk:
			background.rect_size.y = description.rect_position.y + (font_offset - 16) * description.get_child(0).get_line_count()
		else:
			background.rect_size.y = 16 + description.rect_position.y + font_offset * description.get_line_count() * 2
		background.rect_size.y += extra_height
		if $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections > 1:
			border.rect_position = Vector2(background.rect_position.x - 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, background.rect_position.y - 4 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
			border.rect_size = Vector2(background.rect_size.x + 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections, background.rect_size.y + 8 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections)
		else:
			border.rect_position = Vector2(background.rect_position.x - 4, background.rect_position.y - 4)
			border.rect_size = Vector2(background.rect_size.x + 8, background.rect_size.y + 8)

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	if visible and active:
		var t_label = preload("res://Outline Label.tscn").instance()
		t_label.visible = false
		add_child(t_label)
		t_label.raw_string = $"Background/Title".raw_string + "\n" + $"Background/Rarity".raw_string + "\n" + $"Background/Value".raw_string
		if data.has("value"):
			t_label.values = [data.value]
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
		if data.has("values"):
			$"/root/Main".tts(start + "\n" + $"Background/Description".raw_string, data.values, self)
		else:
			$"/root/Main".tts(start + "\n" + $"Background/Description".raw_string, [], self)

func update():
	if is_instance_valid($"/root/Main") and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and $"/root/Main/Selector Sprite/Selector".visible:
		tts()
		if $"/root/Main".down_keys["inspect"] == 1:
			$"/root/Main".down_keys["inspect"] += 1
			if $"Background/Description" != null:
				if not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0 and $"Background/Description".forced_font == null:
					for i in $"Background/Description".texts[8].icons:
						if i.type != "coin":
							$"/root/Main".selected_node = i
							break
					return
				else:
					for i in $"Background/Description".get_child(0).icons:
						if i.type != "coin":
							$"/root/Main".selected_node = i
							break
					return
		elif $"/root/Main".down_keys["deny_cancel"] == 1 or $"/root/Main".down_keys["deny_cancel"] >= 25:
			$"/root/Main".down_keys["deny_cancel"] += 1
			$"/root/Main".selected_node = self
		elif $"/root/Main".down_keys["confirm_select"] == 1:
			$"/root/Main".down_keys["confirm_select"] += 1
			$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(data.type)
			return
	selectable = active and not $"/root/Main/Options Sprite/Options".visible
	rect_size = background.rect_size
	if delay <= 0 and $"/root/Main".hide_selector:
		var popup_rect = $"/root/Main/Pop-up Sprite/Pop-up/Container"
		if active and (hovering and not $"/root/Main/Options Sprite/Options".visible and (not OS.is_window_focused() or ($"/root/Main".mouse_position.x < border.rect_global_position.x or $"/root/Main".mouse_position.x > border.rect_global_position.x + border.rect_size.x or $"/root/Main".mouse_position.y < border.rect_global_position.y or $"/root/Main".mouse_position.y > border.rect_global_position.y + border.rect_size.y) or ($"/root/Main".mouse_position.x < popup_rect.rect_global_position.x or $"/root/Main".mouse_position.x > popup_rect.rect_global_position.x + popup_rect.rect_size.x or $"/root/Main".mouse_position.y < popup_rect.rect_global_position.y or $"/root/Main".mouse_position.y > popup_rect.rect_global_position.y + popup_rect.rect_size.y)) or not OS.is_window_focused() or not $"/root/Main/Pop-up Sprite/Pop-up".hovering_in_main):
			unhover()
			hovering = false
		elif active and not hovering and OS.is_window_focused() and not ($"/root/Main".mouse_position.x < border.rect_global_position.x or $"/root/Main".mouse_position.x > border.rect_global_position.x + border.rect_size.x or $"/root/Main".mouse_position.y < border.rect_global_position.y or $"/root/Main".mouse_position.y > border.rect_global_position.y + border.rect_size.y) and $"/root/Main/Pop-up Sprite/Pop-up".hovering_in_main and not ($"/root/Main".mouse_position.x < popup_rect.rect_global_position.x or $"/root/Main".mouse_position.x > popup_rect.rect_global_position.x + popup_rect.rect_size.x or $"/root/Main".mouse_position.y < popup_rect.rect_global_position.y or $"/root/Main".mouse_position.y > popup_rect.rect_global_position.y + popup_rect.rect_size.y):
			hover()
		if active and $"/root/Main".press_timer > 0 and (((not ($"/root/Main".mouse_position.x < border.rect_global_position.x or $"/root/Main".mouse_position.x > border.rect_global_position.x + border.rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < border.rect_global_position.y or $"/root/Main".mouse_position.y > border.rect_global_position.y + border.rect_size.y * rect_scale.y)))):
			$"/root/Main/Pop-up Sprite/Pop-up".resolve_event(data.type)
	if not OS.is_window_focused():
		delay = 3
		hovering = false
	elif delay != 0:
		delay -= 1
	if $"/root/Main/Selector Sprite/Selector".visible or $"/root/Main/Pop-up Sprite/Pop-up".offset_y != $"/root/Main/Pop-up Sprite/Pop-up".offset_top:
		if item:
			background.color = $"/root/Main/Options Sprite/Options".colors3["item_background"]
		else:
			background.color = $"/root/Main/Options Sprite/Options".colors3["symbol_background"]

func hover():
	hovering = true
	tts()
	if item:
		background.color = $"/root/Main/Options Sprite/Options".colors3["item_background"]
		background.color.v += 0.2
	else:
		background.color = $"/root/Main/Options Sprite/Options".colors3["symbol_background"]
		background.color.v += 0.2

func unhover():
	hovering = false
	if item:
		background.color = $"/root/Main/Options Sprite/Options".colors3["item_background"]
	else:
		background.color = $"/root/Main/Options Sprite/Options".colors3["symbol_background"]

func update_hitboxes():
	var desc = $"Background/Description"
	if desc.texts.size() > 0:
		for i in desc.texts[8].icons:
			i.update_hitbox()
			i.source = self
	else:
		for i in desc.icons:
			i.update_hitbox()
			i.source = self
