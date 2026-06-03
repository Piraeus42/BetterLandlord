extends ColorRect

var can_drag = false
var dragging = false
var top = 112
var bottom = 512
var base_bottom = 512
var border
var aligned = false
var saved_resolution = Vector2(1024, 576)
var alignment_tags = {"bottom": false, "right": true, "centered": false, "v_centered": false}
var last_pos_y = -1000
var first_email_input = false

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _input(event):
	update_positions(event)

func update():
	if visible:
		if $"/root/Main".down_keys["up"] == 1 or $"/root/Main".down_keys["down"] == 1 or $"/root/Main".down_keys["left"] == 1 or $"/root/Main".down_keys["right"] == 1:
			first_email_input = true
		if $"/root/Main".selected_node != null and is_instance_valid($"/root/Main".selected_node) and str($"/root/Main".selected_node.get_path()).find("/Pop-up Sprite/Pop-up/Container/") != -1 and $"/root/Main".selected_node.selector_alignment != "card" and $"/root/Main".selected_node.selector_alignment != "card" and $"/root/Main/Selector Sprite/Selector".visible and $"/root/Main/Pop-up Sprite/Pop-up".offset_y == $"/root/Main/Pop-up Sprite/Pop-up".offset_top and $"/root/Main/Pop-up Sprite/Pop-up".visible and first_email_input:
			var size_y = $"/root/Main".selected_node.rect_size.y
			while $"/root/Main".selected_node.rect_global_position.y + size_y >= $"/root/Main/Pop-up Sprite/Pop-up/Container".rect_global_position.y + $"/root/Main/Pop-up Sprite/Pop-up/Container".rect_size.y - 24:
				rect_position.y += 5 * $"/root/Main/Options Sprite/Options".resolution_y / 576
				update_positions(null)
				if rect_position.y >= bottom:
					break
			while $"/root/Main".selected_node.rect_global_position.y < $"/root/Main/Pop-up Sprite/Pop-up/Container".rect_global_position.y:
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

func update_positions(event):
	if not $"/root/Main/Options Sprite/Options".visible:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if can_drag:
				if not dragging and event.pressed:
					dragging = true
			if dragging and not event.pressed:
				dragging = false
		if event is InputEventMouseMotion and dragging and (get_global_mouse_position().y >= border.rect_global_position.y or get_global_mouse_position().y <= border.rect_global_position.y + border.rect_size.y * get_parent().offset_top):
			rect_position.y = round(get_global_mouse_position().y - get_parent().offset_top - (border.rect_size.y - 1) / 2.0)
			if rect_position.y < top:
				rect_position.y = top
			elif rect_position.y > bottom:
				rect_position.y = bottom
		elif event is InputEventPanGesture and visible and get_parent().rect_position.y <= get_parent().offset_top:
			rect_position.y += event.delta.y * 32.0
		elif event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP and event.is_pressed() and visible and get_parent().rect_position.y <= get_parent().offset_top:
			if get_parent().cards.size() > 0:
				rect_position.y -= 120
			elif get_parent().emails[0].type != "win":
				var scroll_num = 40
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					if get_parent().label_text.get_child(0).text.count("\n") > 0:
						scroll_num /= ceil(get_parent().label_text.get_child(0).text.count("\n") / 16.0)
				else:
					if get_parent().label_text.text.count("\n") > 0:
						scroll_num /= ceil(get_parent().label_text.text.count("\n") / 16.0)
				rect_position.y -= scroll_num
			else:
				rect_position.y -= 40
		elif event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN and event.is_pressed() and visible and get_parent().rect_position.y <= get_parent().offset_top:
			if get_parent().cards.size() > 0:
				rect_position.y += 120
			elif get_parent().emails[0].type != "win":
				var scroll_num = 40
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					if get_parent().label_text.get_child(0).text.count("\n") > 0:
						scroll_num /= ceil(get_parent().label_text.get_child(0).text.count("\n") / 16.0)
				else:
					if get_parent().label_text.text.count("\n") > 0:
						scroll_num /= ceil(get_parent().label_text.text.count("\n") / 16.0)
				rect_position.y += scroll_num
			else:
				rect_position.y += 40
		if rect_position.y < top:
			rect_position.y = top
		elif rect_position.y > bottom:
			rect_position.y = bottom
		if event == null:
			$"/root/Main/Pop-up Sprite/Pop-up".update()

func _ready():
	rect_position = Vector2(get_parent().get_child(0).rect_size.x - 16, top)
	
	border = $"Border"
	border.rect_position = Vector2(-8, -8)
	border.rect_size = Vector2(rect_size.x + 16, rect_size.y + 16)
	
	border.connect("mouse_entered", self, "enter")
	border.connect("mouse_exited", self, "exit")
	
	color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar"])
	get_child(0).color = Color($"/root/Main/Options Sprite/Options".colors3["scroll_bar_border"])

func enter():
	can_drag = true

func exit():
	can_drag = false
