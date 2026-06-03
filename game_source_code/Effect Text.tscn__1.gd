extends "res://Outline Label.tscn::10"

var animating = false
var effect_timer = 0
var clump
var lines = []
var line_parents = []
var line_targets = []
var line_color
var start_pos = Vector2(0.0, 0.0)
var goal_pos = Vector2(8.0, 472.0)
var coin_value = 0
var reroll_value = 0
var removal_value = 0
var essence_value = 0
var to_be_added = true
var instant_fanfare
var hidden = false

func _ready():
	effect_text = true
	can_display_decimals = false
	if texts.size() == 0:
		change_font_size(0.0625, false)
	if not $"/root/Main/Options Sprite/Options".CJK_lang:
		scale_mod = 1
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		base_scale = 0.5
	dont_scale = true
	diff_cjk_space = true
	remove_from_group("Pause Update")

func set_goal_pos(num):
	var font_mod
	if $"/root/Main/Options Sprite/Options".CJK_lang or TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "th":
		font_mod = 1.0
	elif TranslationServer.get_locale() == "ar":
		if int($"/root/Main/Options Sprite/Options".display_font) == 0:
			font_mod = 4.0
		else:
			font_mod = 1.0
	else:
		font_mod = 4.0
	match num:
		0:
			goal_pos = Vector2(1.0, int($"/root/Main/Coins".rect_position.y - (get_font("font").get_height() + 2) * current_scale * font_mod))
		1:
			goal_pos = Vector2(1.0, int($"/root/Main/Coins".rect_position.y - (get_font("font").get_height() + 2) * current_scale * 1.5 * font_mod))
		2:
			goal_pos = Vector2(1.0, int($"/root/Main/Coins".rect_position.y - (get_font("font").get_height() + 2) * current_scale * 2 * font_mod))

func update():
	if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible and animating and effect_timer > 0 and (to_be_added or effect_timer >= 155):
		if $"/root/Main/Options Sprite/Options".counting_speed == 0:
			if not instant_fanfare:
				visible = false
			$"/root/Main/Sums/Coin Sum".add_value(coin_value)
			$"/root/Main/Sums/Extra Sum".add_value(reroll_value, removal_value, essence_value)
			$"/root/Main/Sums/HP Sum".add_value(coin_value)
			coin_value = 0
			reroll_value = 0
			removal_value = 0
			essence_value = 0
			
			effect_timer = 0
			animating = false
			$"/root/Main/Reels".finalize_clumps()
		elif $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset < 1:
			if $"/root/Main/Options Sprite/Options".counting_speed == 0.75:
				if $"/root/Main".frame_timer % 3 != 0:
					execute_effect()
					effect_timer -= 1
					.update()
			elif $"/root/Main/Options Sprite/Options".counting_speed == 0.5:
				if $"/root/Main".frame_timer % 2 != 0:
					execute_effect()
					effect_timer -= 1
					.update()
		else:
			for n in range($"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset):
				execute_effect()
				effect_timer -= 1
			.update()

func execute_effect():
	if effect_timer <= 108:
		pass
	elif effect_timer <= 109:
		effect_timer = 0
		animating = false
		$"/root/Main/Reels".finalize_clumps()
	elif effect_timer <= 112:
		pass
	elif effect_timer <= 113:
		if not instant_fanfare:
			visible = false
		$"/root/Main/Sums/Coin Sum".add_value(coin_value)
		$"/root/Main/Sums/Extra Sum".add_value(reroll_value, removal_value, essence_value)
		$"/root/Main/Sums/HP Sum".add_value(coin_value)
		coin_value = 0
		reroll_value = 0
		removal_value = 0
		essence_value = 0
	elif effect_timer <= 125:
		if not instant_fanfare:
			var offset_timer = (abs(effect_timer - 125) / 12)
			rect_position.x = floor(goal_pos.x + ((start_pos.x - goal_pos.x) * (1 - offset_timer)))
			rect_position.y = floor(goal_pos.y + ((start_pos.y - goal_pos.y) * (1 - offset_timer)))
		else:
			effect_timer = 113.0
	elif effect_timer <= 155:
		pass
	elif effect_timer <= 158:
		if not instant_fanfare:
			rect_position.y += 8
	elif effect_timer <= 159:
		if not instant_fanfare:
			rect_position.y -= 24
	elif effect_timer == 160:
		if not hidden:
			if TranslationServer.get_locale() == "ar":
				.update()
			visible = true
		effect_timer = 160.0

func add_lines():
	for i in range(line_targets.size()):
		var s = preload("res://Slot Line.tscn").instance()
		lines.push_back(s)
		$"/root/Main/Reels".add_child(s)

func update_lines():
	var font = get_font("font")
	var y_offset
	for i in range(line_targets.size()):
		y_offset = 0
		if rect_position.y != line_targets[i].rect_position.y and rect_position.x != line_targets[i].rect_position.x:
			y_offset = 0.75 * (rect_position.y - line_targets[i].rect_position.y) / (abs(rect_position.y - line_targets[i].rect_position.y))
		else:
			lines[i].line.width = 4
		lines[i].line.set_point_position(0, Vector2(rect_position.x + (font.get_string_size(text).x * rect_scale.x) / 2, rect_position.y - font.extra_spacing_top + y_offset))
		lines[i].line.set_point_position(1, Vector2(line_targets[i].rect_position.x + (font.get_string_size(text).x * rect_scale.x) / 2, line_targets[i].rect_position.y - font.extra_spacing_top - y_offset))
