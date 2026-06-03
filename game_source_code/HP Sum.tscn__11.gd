extends "res://Outline Label.tscn::10"

var hp_value = 0
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
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		remove_texts()
	visible = false
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		get_child(0).custom_max_width = 10000
	need_to_left = false

func add_value(hp):
	if not $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight:
		adding = false
		visible = false
		return
	hp_value += hp
	raw_string = "<icon_hp><color_CC0000>" + parse_num_str(str(hp_value)) + "<end>"
	if hp_value > 0:
		visible = true
	var font_mod
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		font_mod = 1.0
	else:
		font_mod = 4.0
	if $"/root/Main/Sums/Extra Sum".reroll_value == 0 and $"/root/Main/Sums/Extra Sum".removal_value == 0 and $"/root/Main/Sums/Extra Sum".essence_value == 0:
		if int($"/root/Main/Options Sprite/Options".display_font) > 0:
			start_pos = int($"/root/Main/Sums/Coin Sum".rect_position.y - (get_child(0).get_font("font").get_height() + 2) * current_scale * font_mod)
		else:
			start_pos = int($"/root/Main/Sums/Coin Sum".rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod)
	else:
		if int($"/root/Main/Options Sprite/Options".display_font) > 0:
			start_pos = int($"/root/Main/Sums/Extra Sum".rect_position.y - (get_child(0).get_font("font").get_height() + 2) * current_scale * font_mod)
		else:
			start_pos = int($"/root/Main/Sums/Extra Sum".rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod)
	if int($"/root/Main/Options Sprite/Options".display_font) == 1:
		rect_position.x = 6
	else:
		rect_position.x = 12
	rect_position.y = start_pos

func update():
	if $"/root/Main/Options Sprite/Options".visible or $"/root/Main/Title".visible:
		return
	if not $"/root/Main/Pop-up Sprite/Pop-up".doing_boss_fight:
		adding = false
		visible = false
		return
	if $"/root/Main/Options Sprite/Options".counting_speed == 0:
		if hp_value != 0:
			delay = 25
			visible = false
			raw_string = ""
			$"/root/Main/Landlord".take_damage(round(hp_value))
			hp_value = 0
			adding = false
			.update()
	elif $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset < 1:
		if ($"/root/Main/Options Sprite/Options".counting_speed == 0.75 and $"/root/Main".frame_timer % 3 != 0) or ($"/root/Main/Options Sprite/Options".counting_speed == 0.5 and $"/root/Main".frame_timer % 2 != 0):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.x -= 8
					rect_position.y += 8
					delay -= 1
				elif adding and rect_position.y > $"/root/Main/Landlord/Temp".rect_position.y:
					rect_position.x += ($"/root/Main/Landlord/Temp".rect_position.x - 12) / 15.0
					rect_position.y += ($"/root/Main/Landlord/Temp".rect_position.y - start_pos) / 15.0
				elif not adding and rect_position.y < start_pos:
					rect_position.x += ($"/root/Main/Landlord/Temp".rect_position.x - 12) / 30.0
					rect_position.y += ($"/root/Main/Landlord/Temp".rect_position.y - start_pos) / 30.0
				if adding:
					if rect_position.y <= $"/root/Main/Landlord/Temp".rect_position.y:
						delay = 25
						visible = false
						raw_string = ""
						$"/root/Main/Landlord".take_damage(round(hp_value))
						hp_value = 0
						adding = false
	else:
		for i in range($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.x -= 8
					rect_position.y += 8
					delay -= 1
				elif adding and rect_position.y > $"/root/Main/Landlord/Temp".rect_position.y:
					rect_position.x += ($"/root/Main/Landlord/Temp".rect_position.x - 12) / 15.0
					rect_position.y += ($"/root/Main/Landlord/Temp".rect_position.y - start_pos) / 15.0
				elif not adding and rect_position.y < start_pos:
					rect_position.x += ($"/root/Main/Landlord/Temp".rect_position.x - 12) / 30.0
					rect_position.y += ($"/root/Main/Landlord/Temp".rect_position.y - start_pos) / 30.0
				if adding:
					if rect_position.y <= $"/root/Main/Landlord/Temp".rect_position.y:
						delay = 25
						visible = false
						raw_string = ""
						$"/root/Main/Landlord".take_damage(round(hp_value))
						hp_value = 0
						adding = false
	.update()

func save():
	var save_dict = {
		"path" : get_path(),
		"pos_x": rect_position.x,
		"pos_y": rect_position.y,
		"delay": delay,
		"hp_value": hp_value,
		"adding": adding
	}
	return save_dict
