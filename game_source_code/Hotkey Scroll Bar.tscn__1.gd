extends ColorRect

var can_drag = false
var dragging = false
var top = 1
var bottom = 328.0
var base_bottom = 328.0
var border
var aligned = false
var saved_resolution = Vector2(1024, 576)
var alignment_tags = {"bottom": false, "right": true, "centered": false, "v_centered": false}
var need_to_update = false

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
	update_positions(event)

func update():
	if need_to_update and visible:
		update_positions(null)
		need_to_update = false
	if ((($"/root/Main/Options Sprite/Options".option_buttons.has($"/root/Main".selected_node) or $"/root/Main/Options Sprite/Options".option_sliders.has($"/root/Main".selected_node)) and $"/root/Main".selected_node.get_parent() == get_parent()) or $"/root/Main/Options Sprite/Options".hyperlinks.has($"/root/Main".selected_node)) and $"/root/Main/Selector Sprite/Selector".visible:
		var size_y
		if $"/root/Main".selected_node.selector_alignment == "hyperlink":
			size_y = $"/root/Main".selected_node.background.rect_size.y * $"/root/Main".selected_node.get_parent().rect_scale.y
		else:
			size_y = $"/root/Main".selected_node.rect_size.y
		while $"/root/Main".selected_node.rect_global_position.y + size_y >= $"/root/Main/Options Sprite/Options".resolution_y:
			rect_position.y += 5 * $"/root/Main/Options Sprite/Options".resolution_y / 576
			update_positions(null)
			if rect_position.y >= bottom:
				break
		while $"/root/Main".selected_node.rect_global_position.y < get_parent().rect_global_position.y:
			rect_position.y -= 5 * $"/root/Main/Options Sprite/Options".resolution_y / 576
			update_positions(null)
			if rect_position.y <= top:
				break
	if $"/root/Main".down_keys["scroll_down"] == 1 or $"/root/Main".down_keys["scroll_down"] >= 25:
		$"/root/Main".selected_node = null
		rect_position.y += 15 * $"/root/Main/Options Sprite/Options".resolution_y / 576
		update_positions(null)
	elif $"/root/Main".down_keys["scroll_up"] == 1 or $"/root/Main".down_keys["scroll_up"] >= 25:
		$"/root/Main".selected_node = null
		rect_position.y -= 15 * $"/root/Main/Options Sprite/Options".resolution_y / 576
		update_positions(null)
	if (($"/root/Main/Options Sprite/Options".option_buttons.size() > 0 and $"/root/Main/Options Sprite/Options".option_buttons.has($"/root/Main".selected_node) or $"/root/Main/Options Sprite/Options".option_sliders.has($"/root/Main".selected_node) and $"/root/Main".selected_node != $"/root/Main/Options Sprite/Options".option_buttons[0]) or ($"/root/Main/Options Sprite/Options".menu == "credits" and $"/root/Main/Options Sprite/Options".option_texts.size() > 1 and ((not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0 and not $"/root/Main/Options Sprite/Options".option_texts[1].texts[8].color_texts.has($"/root/Main".selected_node)) or (($"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0) and not $"/root/Main/Options Sprite/Options".option_texts[1].get_child(0).color_texts.has($"/root/Main".selected_node))) and not $"/root/Main/Options Sprite/Options".menu_buttons.has($"/root/Main".selected_node) and $"/root/Main".selected_node != $"/root/Main/Options Sprite/Options".back_button and $"/root/Main".selected_node != $"/root/Main/Options Sprite/Options".reset_button and $"/root/Main".selected_node != $"/root/Main/Options Sprite/Options".exit_button)) and $"/root/Main/Selector Sprite/Selector".visible:
		if $"/root/Main/Options Sprite/Options".back_button != null:
			$"/root/Main/Options Sprite/Options".back_button.selectable = false
		for b in $"/root/Main/Options Sprite/Options".menu_buttons:
			b.selectable = false
			b.options_button = false
		if $"/root/Main/Options Sprite/Options".option_buttons.size() > 0 and $"/root/Main/Options Sprite/Options".option_buttons[0] == $"/root/Main".selected_node and $"/root/Main/Options Sprite/Options".menu != "credits":
			if $"/root/Main/Options Sprite/Options".menu_buttons.size() > 0:
				$"/root/Main/Options Sprite/Options".menu_buttons[$"/root/Main/Options Sprite/Options".menu_buttons.size() - 1].add_to_group("Selector Override Up")
		else:
			if $"/root/Main/Options Sprite/Options".menu_buttons.size() > 0:
				$"/root/Main/Options Sprite/Options".menu_buttons[$"/root/Main/Options Sprite/Options".menu_buttons.size() - 1].remove_from_group("Selector Override Up")
	else:
		if $"/root/Main/Options Sprite/Options".back_button != null:
			$"/root/Main/Options Sprite/Options".back_button.selectable = true
		for b in $"/root/Main/Options Sprite/Options".menu_buttons:
			b.selectable = true
			b.options_button = true

func update_positions(event):
	if $"/root/Main/Options Sprite/Options".visible and $"/root/Main/Options Sprite/Options".can_update_scrollables:
		var can_move = true
		var can_move_down = true
		var can_move_up = true
		if can_move:
			var global_mod = 8.0
			if (can_drag and ((get_global_mouse_position().x < border.rect_global_position.x or get_global_mouse_position().x > border.rect_global_position.x + border.rect_size.x / (8.0 / rect_scale.x / global_mod) or get_global_mouse_position().y < border.rect_global_position.y or get_global_mouse_position().y > border.rect_global_position.y + border.rect_size.y / (8.0 / rect_scale.x / global_mod))) or (not OS.is_window_focused() and not Steam.isSteamRunningOnSteamDeck())):
				can_drag = false
			elif not can_drag and (OS.is_window_focused() or Steam.isSteamRunningOnSteamDeck()) and not (get_global_mouse_position().x < border.rect_global_position.x or get_global_mouse_position().x > border.rect_global_position.x + border.rect_size.x / (8.0 / rect_scale.x / global_mod) or get_global_mouse_position().y < border.rect_global_position.y or get_global_mouse_position().y > border.rect_global_position.y + border.rect_size.y / (8.0 / rect_scale.x / global_mod)):
				can_drag = true
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if can_drag:
				if not dragging and (event.pressed or Steam.isSteamRunningOnSteamDeck()):
					dragging = true
			if dragging and not event.pressed:
				dragging = false
		if event is InputEventMouseMotion and dragging and (get_global_mouse_position().y >= border.rect_global_position.y or get_global_mouse_position().y <= border.rect_global_position.y + border.rect_size.y * 64):
			rect_position.y = round((get_global_mouse_position().y) - (border.rect_size.y - 8) / 2.0) - get_parent().rect_position.y
			if rect_position.y < top:
				rect_position.y = top
			elif rect_position.y > bottom:
				rect_position.y = bottom
		elif event is InputEventPanGesture and visible:
			rect_position.y += event.delta.y * 32.0
		elif ((event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP) and can_move_up) and event.is_pressed() and visible:
			if $"/root/Main/Options Sprite/Options".menu == "input":
				rect_position.y -= bottom / ($"/root/Main/Options Sprite/Options".option_buttons.size() - 12.0) * 3.0
			else:
				var scroll_num = 30
				if $"/root/Main/Options Sprite/Options".menu == "mods" and get_parent().get_children().size() / 2 >= 10:
					scroll_num /= ceil(get_parent().get_children().size() / 2.0 / 16.0)
				rect_position.y -= scroll_num
		elif ((event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN) and can_move_down) and event.is_pressed() and visible:
			if $"/root/Main/Options Sprite/Options".menu == "input":
				rect_position.y += bottom / ($"/root/Main/Options Sprite/Options".option_buttons.size() - 12.0) * 3.0
			else:
				var scroll_num = 30
				if $"/root/Main/Options Sprite/Options".menu == "mods" and get_parent().get_children().size() / 2 >= 10:
					scroll_num /= ceil(get_parent().get_children().size() / 2.0 / 16.0)
				rect_position.y += scroll_num
		if rect_position.y < top:
			rect_position.y = top
		elif rect_position.y > bottom:
			rect_position.y = bottom
		if $"/root/Main/Options Sprite/Options".menu != "colors" and visible:
			$"/root/Main/Options Sprite/Options".saved_scroll_bar_pos_y = rect_position.y
		var increment = 0
		var y_offset = get_parent().rect_size.y
		var y_pos = ($"/root/Main/Options Sprite/Options".lowest_y_position + $"/root/Main/Options Sprite/Options".lowest_y_size) - get_parent().rect_size.y * (bottom / base_bottom)
		var mod = 1
		if $"/root/Main/Options Sprite/Options".lowest_y_position + $"/root/Main/Options Sprite/Options".lowest_y_size < get_parent().rect_size.y and not event is InputEventMouseButton and event is String and event == "check":
			mod = 0
			visible = false
		elif event is String and event == "check":
			visible = true
		if $"/root/Main/Options Sprite/Options".menu == "input":
			for i in get_parent().get_children():
				if i != self and not i is Line2D:
					var font_offset = 40 * $"/root/Main/Options Sprite/Options".ui_scaling.text
					if TranslationServer.get_locale() == "th":
						font_offset += 26 * $"/root/Main/Options Sprite/Options".ui_scaling.text
					i.rect_position.y = font_offset * floor(increment / 3) - (((floor(get_parent().get_children().size() / 3) * font_offset) - y_offset) * (((rect_position.y - top) / (bottom - top)) * mod))
					increment += 1
		else:
			var inc = 0
			var new_lines = 0
			var new_line_height
			for c in get_parent().get_children():
				new_line_height = 0
				if c != self and inc < $"/root/Main/Options Sprite/Options".base_y_positions.size():
					if c is Line2D:
						c.position.y = floor($"/root/Main/Options Sprite/Options".base_y_positions[inc] - (y_pos * ((rect_position.y - top) / (bottom - top))) * mod)
					else:
						if ($"/root/Main/Options Sprite/Options".menu == "credits" or $"/root/Main/Options Sprite/Options".menu == "achievements" or $"/root/Main/Options Sprite/Options".menu == "input") and inc > 0 and get_parent().get_child(inc) is Label:
							if get_parent().get_child(inc) is Label and c is Label and get_parent().get_child(1) is Label:
								c.update()
								get_parent().get_child(inc).update()
								if get_parent().get_child(inc).get_child(0).get_font("font").get_path() != "res://PICO-8.tres":
									if get_parent().get_child(1).get_font("font").get_path() == "res://PICO-8.tres" and get_parent().get_child(1).texts.size() > 7:
										new_line_height = (get_parent().get_child(1).texts[8].get_font("font").get_height() + 3) * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.text
									else:
										new_line_height = get_parent().get_child(1).get_child(0).get_font("font").get_height() / 2 * $"/root/Main/Options Sprite/Options".ui_scaling.text
									if $"/root/Main/Options Sprite/Options".menu == "achievements":
										new_lines += 1
									new_lines += get_parent().get_child(inc).get_child(0).text.count("\n")
								else:
									if $"/root/Main/Options Sprite/Options".menu == "achievements":
										new_lines += 1
									new_line_height = (get_parent().get_child(inc).texts[8].get_font("font").get_height() + 3) * 4 * $"/root/Main/Options Sprite/Options".ui_scaling.text
									new_lines += get_parent().get_child(inc).texts[8].text.count("\n")
						if $"/root/Main/Options Sprite/Options".menu == "legal":
							if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) == 1:
								c.rect_position.y = -floor(((c.get_child(0).get_font("font").get_height() + 2) * c.current_scale * (c.get_child(0).text.count("\n") + 1) * ((rect_position.y - top) / (bottom - top))) * mod)
							elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
								c.rect_position.y = -floor(((c.get_child(0).get_font("font").get_height() + 3) * c.current_scale * (c.get_child(0).text.count("\n") - 1) * ((rect_position.y - top) / (bottom - top))) * mod)
							else:
								c.rect_position.y = -floor((13 * 4 * c.current_scale * (c.text.count("\n") - 1) * ((rect_position.y - top) / (bottom - top))) * mod)
						else:
							if $"/root/Main/Options Sprite/Options".menu == "credits" and c is TextureButton:
								c.rect_position.y = floor($"/root/Main/Options Sprite/Options".lowest_y_position + new_lines * new_line_height - (y_pos * ((rect_position.y - top) / (bottom - top))) * mod)
							else:
								c.rect_position.y = floor($"/root/Main/Options Sprite/Options".base_y_positions[inc] + new_lines * new_line_height - (y_pos * ((rect_position.y - top) / (bottom - top))) * mod)
					inc += 1
			if $"/root/Main/Options Sprite/Options".menu == "audio":
				var num = -6
				for b in $"/root/Main/Options Sprite/Options".option_buttons:
					if num >= 0:
						if (num - 1) % 3 == 0:
							b.rect_position.y = $"/root/Main/Options Sprite/Options".option_buttons[num + 5].rect_position.y
						elif (num - 2) % 3 == 0:
							b.rect_position.y = $"/root/Main/Options Sprite/Options".option_buttons[num + 4].rect_position.y
					num += 1
				if event is String and event == "check":
					$"/root/Main".update_alignments()
				num = 0
				for s in $"/root/Main/Options Sprite/Options".slider_texts:
					s.rect_position = Vector2($"/root/Main/Options Sprite/Options".option_buttons[num].rect_position.x - $"/root/Main/Options Sprite/Options".option_buttons[num].rect_size.x * 2, $"/root/Main/Options Sprite/Options".option_buttons[num].rect_position.y)
					num += 1

func _ready():
	rect_position = Vector2(992, top)
	
	border = $"Border"
	border.rect_position = Vector2(-8, -8)
	border.rect_size = Vector2(rect_size.x + 16, rect_size.y + 16)
	
	color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar"])
	get_child(0).color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar_border"])
