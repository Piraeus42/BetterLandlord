extends "res://Outline Label.tscn::10"

var value = 0
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
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		get_child(0).custom_max_width = 10000
	need_to_left = false

func set_start_pos():
	var font_mod
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		font_mod = 1.0
	else:
		font_mod = 4.0
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		start_pos = int($"/root/Main/Coins".rect_position.y - (get_child(0).get_font("font").get_height() + 2) * current_scale * font_mod)
	else:
		start_pos = int($"/root/Main/Coins".rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod)

func add_value(num):
	value += round(num)
	if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
		raw_string = "<color_FBF236>" + parse_num_str(str(value)) + "<end><icon_coin>"
	else:
		raw_string = "<icon_coin><color_FBF236>" + parse_num_str(str(value)) + "<end>"
	visible = true
	set_start_pos()
	rect_position.y = start_pos

func update():
	if $"/root/Main/Options Sprite/Options".counting_speed == 0:
		if value != 0:
			if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] == 0 and ($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != $"/root/Main/Pop-up Sprite/Pop-up".times_to_pay_rent or $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid >= 12) and $"/root/Main/Options Sprite/Options".music.goal_volume > -80 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != 11:
				if int($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid + 1) % 4 == 0 and $"/root/Main/Pop-up Sprite/Pop-up".can_try_to_pay_rent() and $"/root/Main/Pop-up Sprite/Pop-up".can_cycle_music:
					$"/root/Main/Music Player".fully_fade_out()
					$"/root/Main/Music Player".play_rand_music()
					$"/root/Main/Music Player".fade_in()
					$"/root/Main/Pop-up Sprite/Pop-up".can_cycle_music = false
			delay = 25
			visible = false
			raw_string = ""
			$"/root/Main/Coins".queued_increase += value
			value = 0
			adding = false
			$"/root/Main/".save_game()
			.update()
	elif $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset < 1:
		if ($"/root/Main/Options Sprite/Options".counting_speed == 0.75 and $"/root/Main".frame_timer % 3 != 0) or ($"/root/Main/Options Sprite/Options".counting_speed == 0.5 and $"/root/Main".frame_timer % 2 != 0):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.y -= 8
					delay -= 1
				elif adding and rect_position.y < start_pos + 32 * current_scale:
					rect_position.y += 16
				elif not adding and rect_position.y < start_pos:
					rect_position.y += 8
				elif adding:
					if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] == 0 and ($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != $"/root/Main/Pop-up Sprite/Pop-up".times_to_pay_rent or $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid >= 12) and $"/root/Main/Options Sprite/Options".music.goal_volume > -80 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != 11:
						if int($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid + 1) % 4 == 0 and $"/root/Main/Pop-up Sprite/Pop-up".can_try_to_pay_rent() and $"/root/Main/Pop-up Sprite/Pop-up".can_cycle_music:
							$"/root/Main/Music Player".fully_fade_out()
							$"/root/Main/Music Player".play_rand_music()
							$"/root/Main/Music Player".fade_in()
					$"/root/Main/Reels".effects_playing = false
					delay = 25
					visible = false
					raw_string = ""
					$"/root/Main/Coins".queued_increase += value
					value = 0
					adding = false
					$"/root/Main/".save_game()
	else:
		for i in range($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset):
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				if adding and delay > 10:
					delay -= 1
				elif adding and delay > 0:
					rect_position.y -= 8
					delay -= 1
				elif adding and rect_position.y < start_pos + 32 * current_scale:
					rect_position.y += 16
				elif not adding and rect_position.y < start_pos:
					rect_position.y += 8
				elif adding:
					if $"/root/Main/Pop-up Sprite/Pop-up".rent_values[1] == 0 and ($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != $"/root/Main/Pop-up Sprite/Pop-up".times_to_pay_rent or $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid >= 12) and $"/root/Main/Options Sprite/Options".music.goal_volume > -80 and $"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid != 11:
						if int($"/root/Main/Pop-up Sprite/Pop-up".times_rent_paid + 1) % 4 == 0 and $"/root/Main/Pop-up Sprite/Pop-up".can_try_to_pay_rent() and $"/root/Main/Pop-up Sprite/Pop-up".can_cycle_music:
							$"/root/Main/Music Player".fully_fade_out()
							$"/root/Main/Music Player".play_rand_music()
							$"/root/Main/Music Player".fade_in()
					$"/root/Main/Reels".effects_playing = false
					delay = 25
					visible = false
					raw_string = ""
					$"/root/Main/Coins".queued_increase += value
					value = 0
					adding = false
					$"/root/Main/".save_game()
	.update()

func save():
	var save_dict = {
		"path" : get_path(),
		"pos_x": rect_position.x,
		"pos_y": rect_position.y,
		"delay": delay,
		"value": value,
		"adding": adding
	}
	return save_dict
