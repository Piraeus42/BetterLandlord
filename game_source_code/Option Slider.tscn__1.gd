extends ColorRect

var can_drag = false
var dragging = false
var top
var bottom
var left = 64
var right = 864
var border
var data
var true_pos = Vector2(0, 0)
var color_slider = false
var prev_rect_pos_x = 0
var active = true
var selectable = true
var off_screen = false
var cant_go_dirs = ["left", "right"]
var selector_alignment = "slider"

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _input(event):
	update_positions(event)

func update():
	if ($"/root/Main".down_keys["left"] == 1 or $"/root/Main".down_keys["left"] >= 25) and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self:
		if not color_slider:
			rect_position.x -= ($"/root/Main/Options Sprite/Options".resolution_x - 224) / 100
		else:
			rect_position.x -= ($"/root/Main/Options Sprite/Options".resolution_x - 224) / 255
		update_positions(null)
	elif ($"/root/Main".down_keys["right"] == 1 or $"/root/Main".down_keys["right"] >= 25) and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self:
		if not color_slider:
			rect_position.x += ($"/root/Main/Options Sprite/Options".resolution_x - 224) / 100
		else:
			rect_position.x += ($"/root/Main/Options Sprite/Options".resolution_x - 224) / 255
		update_positions(null)

func update_positions(event):
	if $"/root/Main/Options Sprite/Options".visible:
		var global_mod = 1.0
		if (can_drag and (not OS.is_window_focused() or (get_global_mouse_position().x < border.rect_global_position.x or get_global_mouse_position().x > border.rect_global_position.x + border.rect_size.x / (1.0 / rect_scale.x / global_mod) or get_global_mouse_position().y < border.rect_global_position.y or get_global_mouse_position().y > border.rect_global_position.y + border.rect_size.y / (1.0 / rect_scale.x / global_mod))) or not OS.is_window_focused()):
			can_drag = false
		elif not can_drag and OS.is_window_focused() and not (get_global_mouse_position().x < border.rect_global_position.x or get_global_mouse_position().x > border.rect_global_position.x + border.rect_size.x / (1.0 / rect_scale.x / global_mod) or get_global_mouse_position().y < border.rect_global_position.y or get_global_mouse_position().y > border.rect_global_position.y + border.rect_size.y / (1.0 / rect_scale.x / global_mod)):
			can_drag = true
		
		if can_drag:
			tts()
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if can_drag:
				if not dragging and event.pressed:
					dragging = true
			if dragging and not event.pressed:
				dragging = false
		if event is InputEventMouseMotion and dragging and (get_global_mouse_position().x >= border.rect_global_position.x or get_global_mouse_position().x <= border.rect_global_position.x + border.rect_size.x * 64):
			if not color_slider:
				rect_position.x = round((get_global_mouse_position().x) - (border.rect_size.x - 8) / 2.0)
				rect_position.x -= int(rect_position.x) % 8
			else:
				rect_position.x = round(get_global_mouse_position().x - (border.rect_size.x - 8) / 2.0)
				rect_position.x -= int(rect_position.x) % 2
			if rect_position.x < left:
				rect_position.x = left
			elif rect_position.x > right:
				rect_position.x = right
		if rect_position.x <= left:
			rect_position.x = left
		elif rect_position.x >= right:
			rect_position.x = right
		if not color_slider:
			var prev_value = data.value_obj.value
			data.value_obj.value = round((rect_position.x - left) / (8.0 + (right - 864) / 100.0))
			data.value_text.raw_string = str(data.value_obj.value)
			if prev_value != data.value_obj.value:
				$"/root/Main/Options Sprite/Options".update_setting(data.setting_type, data.value_obj.value)
		elif prev_rect_pos_x != stepify(rect_position.x, 0.001) and $"/root/Main/Options Sprite/Options".current_color != null:
			var c = Color(data.value_obj)
			if $"/root/Main/Options Sprite/Options".temp_color != null:
				c = $"/root/Main/Options Sprite/Options".temp_color
			c[data.setting_type] = round(round((rect_position.x * 2.55) - round(left * 2.55)) / (8.0 + (right - 864) / 100)) / 255.0
			data.value_text.raw_string = str(round(((rect_position.x - left) / (8.0 + (right - 864) / 100)) * 2.55))
			$"/root/Main/Options Sprite/Options".temp_color = c
			$"/root/Main/Options Sprite/Options/Color Text".raw_string = "<color_" + c.to_html(false).to_upper() + ">#" + c.to_html(false).to_upper() + "<end>"
			$"/root/Main/Options Sprite/Options/Color Text".force_update = true
			$"/root/Main/Options Sprite/Options/Color Text".update()
			prev_rect_pos_x = stepify(rect_position.x, 0.001)

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	var t_label = preload("res://Outline Label.tscn").instance()
	t_label.visible = false
	get_parent().add_child(t_label)
	var button_num = $"/root/Main/Options Sprite/Options".option_sliders.find(self)
	t_label.raw_string = $"/root/Main/Options Sprite/Options".option_texts[button_num].raw_string
	t_label.values = $"/root/Main/Options Sprite/Options".option_texts[button_num].values
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		t_label.get_child(0).custom_max_width = 10000000
	else:
		t_label.custom_max_width = 10000000
	t_label.tts = true
	t_label.update()
	var option
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		option = t_label.get_child(0).text + "\n"
	else:
		option = t_label.text + "\n"
	get_parent().remove_child(t_label)
	t_label.queue_free()
	if not color_slider:
		$"/root/Main".tts(option + str(round((rect_position.x - left) / (8.0 + (right - 864) / 100.0))), [], self)
	else:
		$"/root/Main".tts(option + str(round(((rect_position.x - left) / (8.0 + (right - 864) / 100)) * 2.55)), [], self)

func _ready():
	rect_size = Vector2(48, 16)
	right = $"/root/Main/Options Sprite/Options".resolution_x - 160.0
	
	border = $"Border"
	border.rect_position = Vector2(-8, -8)
	border.rect_size = Vector2(rect_size.x + 16, rect_size.y + 16)

	color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar"])
	get_child(0).color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar_border"])

func slider():
	pass
