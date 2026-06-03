extends "res://Outline Label.tscn::10"

var coins = 1
var queued_increase = 0

func _ready():
	can_display_decimals = false
	diff_cjk_space = true
	var save_game = File.new()
	if not save_game.file_exists("user://LBAL-Settings.save"):
		$"/root/Main".save_options()
	$"/root/Main".load_options()
	
	alignment_tags.dont = true
	align_text()
	need_to_left = false

func align_text():
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		get_child(0).custom_max_width = 10000
		change_font_size(0.09375, false)
		icon_z_index = 4
		remove_texts()
	else:
		texts[8].icon_z_index = 4
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		pass
	elif $"/root/Main/Options Sprite/Options".ui_scaling.text == 1.75:
		custom_icon_offset = Vector2(-3, -4)
	change_set_size(base_scale)
	force_update = true
	.update()
	if int($"/root/Main/Options Sprite/Options".display_font) == 1:
		if TranslationServer.get_locale() == "th":
			rect_position = Vector2(6, $"/root/Main/Options Sprite/Options".resolution_y - (get_child(0).get_font("font").get_height() + 1) * current_scale + 16)
		else:
			rect_position = Vector2(6, $"/root/Main/Options Sprite/Options".resolution_y - (get_child(0).get_font("font").get_height() + 1) * current_scale)
	elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
		rect_position = Vector2(12, $"/root/Main/Options Sprite/Options".resolution_y - (get_child(0).get_font("font").get_height() + 1) * current_scale + 10)
	else:
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			rect_position = Vector2(12, $"/root/Main/Options Sprite/Options".resolution_y - (get_font("font").get_height() + 1) * current_scale - 4)
		else:
			rect_position = Vector2(12, $"/root/Main/Options Sprite/Options".resolution_y - (get_font("font").get_height() + 1) * current_scale * 4 - 4)

func update():
	if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
		if $"/root/Main/Pop-up Sprite/Pop-up".endless_mode or $"/root/Main/Options Sprite/Options".spin_speed == 0 or $"/root/Main/Options Sprite/Options".animation_speed == 0 or $"/root/Main/Options Sprite/Options".counting_speed == 0:
			coins += queued_increase
			queued_increase = 0
			if $"/root/Main/Items".item_types.has("guillotine_essence") and coins >= $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("guillotine_essence")].values[0] and not $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("guillotine_essence")].disabled:
				$"/root/Main".guillotine_essence_anim = 600
		else:
			var speed = $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset
			if queued_increase > 0:
				if queued_increase > speed:
					coins += speed
					queued_increase -= speed
				else:
					coins += queued_increase
					queued_increase = 0
			elif queued_increase < 0:
				if abs(queued_increase) > speed:
					coins -= speed
					queued_increase += speed
				else:
					coins += queued_increase
					queued_increase = 0
		
		if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
			raw_string = "<color_FBF236>" + parse_num_str(str(coins)) + "<end><icon_coin>"
		else:
			raw_string = "<icon_coin><color_FBF236>" + parse_num_str(str(coins)) + "<end>"
	if get_children().size() > 0:
		.update()

func save():
	var save_dict = {
		"path" : get_path(),
		"coins": coins,
		"queued_increase": queued_increase
	}
	return save_dict
