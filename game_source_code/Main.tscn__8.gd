extends "res://Outline Label.tscn::10"

var errors = []

func _ready():
	if int($"/root/Main/Options Sprite/Options".display_font) > 0:
		change_set_size(0.5)
		base_scale = 0.5
	if TranslationServer.get_locale() == "ar":
		rect_position = Vector2(-8, 8)
		need_to_left = true
	else:
		rect_position = Vector2(8, 8)

func add_error(error_string):
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		get_child(0).custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - 8
	else:
		texts[8].custom_max_width = $"/root/Main/Options Sprite/Options".resolution_x - 8
	errors.push_front({"error": error_string, "display_time": 360 + errors.size() * 30})
	raw_string = ""
	var first_err = true
	for e in errors:
		if first_err:
			first_err = false
			raw_string = e.error
		else:
			raw_string += "\n" + e.error
	force_update = true
	.update()
	if raw_string == "":
		get_parent().get_child(0).rect_size.y = 0
	elif $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		get_parent().get_child(0).rect_size.y = (get_child(0).get_font("font").get_height() + 1) * current_scale * get_child(0).get_line_count() + 16 * current_scale + 8
	else:
		get_parent().get_child(0).rect_size.y = (get_font("font").get_height() + 3) * 4 * get_line_count() * current_scale + 8
	get_parent().get_child(0).rect_size.x = $"/root/Main/Options Sprite/Options".resolution_x

func display():
	var error_tbe
	for e in errors:
		e.display_time -= 1
		if e.display_time <= 0:
			error_tbe = e
	if error_tbe != null:
		raw_string = ""
		errors.remove(errors.size() - 1)
		var first_err = true
		for e in errors:
			if first_err:
				first_err = false
				raw_string = e.error
			else:
				raw_string += "\n" + e.error
		$"/root/Main".tts(raw_string, [], self)
		force_update = true
		.update()
		if raw_string == "":
			get_parent().get_child(0).rect_size.y = 0
		elif $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			get_parent().get_child(0).rect_size.y = (get_child(0).get_font("font").get_height() + 1) * current_scale * get_child(0).get_line_count() + 16 * current_scale + 8
		else:
			get_parent().get_child(0).rect_size.y = (get_font("font").get_height() + 3) * 4 * get_line_count() * current_scale + 8
		get_parent().get_child(0).rect_size.x = $"/root/Main/Options Sprite/Options".resolution_x
