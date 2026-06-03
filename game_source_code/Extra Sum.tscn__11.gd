extends "res://Outline Label.tscn::10"

var reroll_value = 0
var removal_value = 0
var essence_value = 0
var adding = false
var delay = 25
var offset_num = 0
var start_pos = 0

func _ready():
	diff_cjk_space = true
	can_display_decimals = false
	if texts.size() > 0:
		texts[8].icon_z_index = 4
	else:
		icon_z_index = 4
		change_font_size(0.09375, false)
		offset_num = 8
		remove_texts()
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		get_child(0).custom_max_width = 10000
	need_to_left = false

func add_value(reroll_num, removal_num, essence_num):
	raw_string = ""
	reroll_value += round(reroll_num)
	removal_value += round(removal_num)
	essence_value += round(essence_num)
	if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
		if reroll_value != 0:
			raw_string += "<color_49AA10>" + parse_num_str(str(reroll_value)) + "<end><icon_reroll_token> "
		if removal_value != 0:
			raw_string += "<color_6B6B6B>" + parse_num_str(str(removal_value)) + "<end><icon_removal_token> "
		if essence_value != 0:
			raw_string += "<color_FF005D>" + parse_num_str(str(essence_value)) + "<end><icon_essence_token> "
	else:
		if reroll_value != 0:
			raw_string += "<icon_reroll_token><color_49AA10>" + parse_num_str(str(reroll_value)) + "<end> "
		if removal_value != 0:
			raw_string += "<icon_removal_token><color_6B6B6B>" + parse_num_str(str(removal_value)) + "<end> "
		if essence_value != 0:
			raw_string += "<icon_essence_token><color_FF005D>" + parse_num_str(str(essence_value)) + "<end> "
	visible = true
	var font_mod
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		font_mod = 1.0
	else:
		font_mod = 4.0
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		start_pos = int($"/root/Main/Sums/Coin Sum".rect_position.y - (get_child(0).get_font("font").get_height() + 2) * current_scale * font_mod)
		$"/root/Main/Sums/HP Sum".start_pos = int(rect_position.y - (get_child(0).get_font("font").get_height() + 2) * current_scale * font_mod)
	else:
		start_pos = int($"/root/Main/Sums/Coin Sum".rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod)
		$"/root/Main/Sums/HP Sum".start_pos = int(rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod)
	rect_position.y = start_pos

func update():
	if $"/root/Main/Options Sprite/Options".counting_speed == 0:
		if reroll_value != 0 or removal_value != 0 or essence_value != 0:
			if $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens > $"/root/Main/Pop-up Sprite/Pop-up".removal_cost - 1:
				$"/root/Main/Menus".buttons_menu.removal_button.text_node.values = [$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens]
				$"/root/Main/Menus".buttons_menu.removal_button.update_size()
				$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
				$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
				$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
				$"/root/Main/Menus".buttons_menu.removal_button.visible = true
			else:
				$"/root/Main/Menus".buttons_menu.removal_button.visible = false
			delay = 25
			visible = false
			raw_string = ""
			reroll_value = 0
			removal_value = 0
			essence_value = 0
			adding = false
			.update()
			if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1:
				$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
			else:
				$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8
	elif $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset < 1:
		if ($"/root/Main/Options Sprite/Options".counting_speed == 0.75 and $"/root/Main".frame_timer % 3 != 0) or ($"/root/Main/Options Sprite/Options".counting_speed == 0.5 and $"/root/Main".frame_timer % 2 != 0):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.y -= 8
					delay -= 1
				elif adding and rect_position.y < $"/root/Main/Coins".rect_position.y:
					rect_position.y += 16
				elif not adding and rect_position.y < start_pos:
					rect_position.y += 8
				if adding:
					if rect_position.y >= $"/root/Main/Coins".rect_position.y:
						delay = 25
						visible = false
						raw_string = ""
						if $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens > $"/root/Main/Pop-up Sprite/Pop-up".removal_cost - 1:
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.values = [$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens]
							$"/root/Main/Menus".buttons_menu.removal_button.update_size()
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
							$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
							$"/root/Main/Menus".buttons_menu.removal_button.visible = true
						else:
							$"/root/Main/Menus".buttons_menu.removal_button.visible = false
						reroll_value = 0
						removal_value = 0
						essence_value = 0
						adding = false
				if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1:
					$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
				else:
					$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8
	else:
		for i in range($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.y -= 8
					delay -= 1
				elif adding and rect_position.y < $"/root/Main/Coins".rect_position.y:
					rect_position.y += 16
				elif not adding and rect_position.y < start_pos:
					rect_position.y += 8
				if adding:
					if rect_position.y >= $"/root/Main/Coins".rect_position.y:
						delay = 25
						visible = false
						raw_string = ""
						if $"/root/Main/Pop-up Sprite/Pop-up".removal_tokens > $"/root/Main/Pop-up Sprite/Pop-up".removal_cost - 1:
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.values = [$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens]
							$"/root/Main/Menus".buttons_menu.removal_button.update_size()
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
							$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
							$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
							$"/root/Main/Menus".buttons_menu.removal_button.visible = true
						else:
							$"/root/Main/Menus".buttons_menu.removal_button.visible = false
						reroll_value = 0
						removal_value = 0
						essence_value = 0
						adding = false
		if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1:
			$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
		else:
			$"/root/Main/Menus".buttons_menu.removal_button.rect_position.x = $"/root/Main/Menus".buttons_menu.deck_button.rect_position.x - $"/root/Main/Menus".buttons_menu.removal_button.rect_size.x - 8
	.update()

func save():
	var save_dict = {
		"path" : get_path(),
		"pos_x": rect_position.x,
		"pos_y": rect_position.y,
		"delay": delay,
		"reroll_value": reroll_value,
		"removal_value": removal_value,
		"essence_value": essence_value,
		"adding": adding
	}
	return save_dict
