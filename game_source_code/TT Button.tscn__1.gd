extends Control

var color = Color(0, 0, 0, 0)
var target
var call
var button_text = ""

var shortcuts = []
var args = []
var doing_call = false

var base_x
var hover_color
var toggle = false
var active = true
var down = false
var hovering = false
var title_button = false
var options_button = false
var email_button = false
var tall_button = false
var scrollable_button = false
var delayed = false

var text_node
var background
var top
var bottom
var left
var right
var rect_size_mod
var forced_size = -1
var hotkey = false
var held = false
var saved_raw_string
var true_pos = Vector2(0, 0)
var texture
var sprite
var moved_once = false
var was_down_while_active = false
var delay = 0
var alignment_tags = {"bottom": false, "right": false, "centered": false, "v_centered": false}
var aligned = false
var saved_resolution = Vector2(1024, 576)
var saved_rect_size
var current_scale = 1.0
var saved_scale = 1.0
var base_scale = 1.0
var scale_mod = 0
var dont_reset = false
var text_offset = Vector2(0, 0)
var border_thickness = 4
var can_be_offscreen = false
var dont_scale = false
var scale_with_thickness = true
var centered_text_button = false
var main
var options
var tooltip_card = false
var selectable = false
var off_screen = false
var selector_alignment = "left"
var cant_go_dirs = []

var color_type = "button_color_misc"

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
	if not get_global_rect().intersects(Rect2(0, 0, options.resolution_x, options.resolution_y)) and not can_be_offscreen:
		if event is InputEventMouseMotion and not main.lmb_down and not Steam.isSteamRunningOnSteamDeck() and not $"/root/Main/Selector Sprite/Selector".visible:
			get_tree().set_input_as_handled()
		return
	for t in $"/root/Main/Tooltips".get_children():
		if t.controller_tooltip:
			return
	var hotkey_input = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if event is InputEventKey and (options.input_type == 0 and event.is_pressed() or (options.input_type == 1 and not event.is_pressed())) and not event.is_echo() and OS.is_window_focused():
		main.last_pressed_key_code = event.scancode
	elif event is InputEventMouseButton and (options.input_type == 0 and event.is_pressed() or (options.input_type == 1 and not event.is_pressed())) and not event.is_echo() and OS.is_window_focused() and event.button_index != BUTTON_LEFT:
		main.last_pressed_key_code = event.button_index
	elif event is InputEventJoypadButton and (options.input_type == 0 and event.is_pressed() or (options.input_type == 1 and not event.is_pressed())) and not event.is_echo() and OS.is_window_focused():
		main.last_pressed_key_code = event.button_index
	if options.input_type == 1 and hotkey_input:
		for s in shortcuts:
			var scancode = options.hotkeys[s][0]
			var button_index = options.hotkeys[s][1]
			if event is InputEventKey and not event.is_echo() and OS.is_window_focused() and scancode == event.scancode and event.is_pressed():
				main.down_scancodes.erase(event.scancode)
			elif event is InputEventMouseButton and not event.is_echo() and OS.is_window_focused() and scancode == event.button_index and event.is_pressed():
				main.down_scancodes.erase(event.button_index)
			elif event is InputEventJoypadButton and not event.is_echo() and OS.is_window_focused() and button_index == event.button_index and event.is_pressed():
				main.down_scancodes.erase(event.button_index)
	if visible and active and options.done_assigning:
		if hotkey_input:
			for s in shortcuts:
				var scancode = options.hotkeys[s][0]
				var button_index = options.hotkeys[s][1]
				if event is InputEventKey and not down and event.scancode == scancode and (main.last_pressed_key_code == event.scancode or options.input_type == 1) and event.is_pressed() and can_be_pressed() and not event.is_echo() and OS.is_window_focused() and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.scancode) and $"/root/Main".down_keys[s] == 0:
					$"/root/Main".down_keys[s] = 2
					was_down_while_active = true
					press()
					break
				elif event is InputEventMouseButton and not down and event.button_index == scancode and (main.last_pressed_key_code == event.button_index or options.input_type == 1) and event.is_pressed() and can_be_pressed() and not event.is_echo() and OS.is_window_focused() and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.button_index) and $"/root/Main".down_keys[s] == 0:
					$"/root/Main".down_keys[s] = 2
					was_down_while_active = true
					press()
					break
				elif event is InputEventJoypadButton and not down and event.button_index == button_index and (main.last_pressed_key_code == event.button_index or options.input_type == 1) and event.is_pressed() and can_be_pressed() and not event.is_echo() and OS.is_window_focused() and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.button_index) and $"/root/Main".down_keys[s] == 0:
					$"/root/Main".down_keys[s] = 2
					was_down_while_active = true
					main.down_scancodes.erase(button_index)
					press()
					break
			for s in shortcuts:
				var scancode = options.hotkeys[s][0]
				var button_index = options.hotkeys[s][1]
				if event is InputEventKey and event.scancode == scancode and main.last_pressed_key_code == event.scancode and not event.is_pressed() and can_be_pressed() and not toggle and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.scancode):
					for b in shortcuts:
						if Input.is_key_pressed(scancode):
							return
					if options.input_type == 1 and was_down_while_active:
						down = true
					unpress()
					break
				elif event is InputEventMouseButton and event.button_index == scancode and main.last_pressed_key_code == event.button_index and not event.is_pressed() and can_be_pressed() and not toggle and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.button_index):
					for b in shortcuts:
						if Input.is_mouse_button_pressed(scancode):
							return
					if options.input_type == 1 and was_down_while_active:
						down = true
					unpress()
					break
				elif event is InputEventJoypadButton and event.button_index == button_index and main.last_pressed_key_code == event.button_index and not event.is_pressed() and can_be_pressed() and not toggle and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and not main.down_scancodes.has(event.button_index):
					if options.input_type == 1 and was_down_while_active:
						down = true
					unpress()
					break
		if hovering and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and ((event.is_pressed() and options.input_type == 1) or options.input_type == 0) and (not main.lmb_down or options.just_changed_osx_fullscreen) and options.done_assigning:
			was_down_while_active = true
			main.lmb_down = true
			if Steam.isSteamRunningOnSteamDeck():
				$"/root/Main".press_timer = 3
			elif texture == null or event.is_pressed():
				press()
		elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_pressed() and options.done_assigning:
			if options.input_type == 1:
				if hovering:
					down = true
					unpress()
				elif held:
					held = false
					was_down_while_active = false
					visual_reset()
		if hotkey_input:
			if options.input_type == 0:
				for s in shortcuts:
					var scancode = options.hotkeys[s][0]
					var button_index = options.hotkeys[s][1]
					if event is InputEventKey and not event.is_echo() and OS.is_window_focused() and scancode == event.scancode:
						if event.is_pressed():
							if not main.down_scancodes.has(event.scancode):
								main.down_scancodes.push_back(event.scancode)
						else:
							main.down_scancodes.erase(event.scancode)
					elif event is InputEventMouseButton and not event.is_echo() and OS.is_window_focused() and scancode == event.button_index:
						if event.is_pressed():
							if not main.down_scancodes.has(event.button_index):
								main.down_scancodes.push_back(event.button_index)
						else:
							main.down_scancodes.erase(event.button_index)
					elif event is InputEventJoypadButton and not event.is_echo() and OS.is_window_focused() and button_index == event.button_index:
						if event.is_pressed():
							if not main.down_scancodes.has(event.button_index):
								main.down_scancodes.push_back(event.button_index)
						else:
							main.down_scancodes.erase(event.button_index)
			elif options.input_type == 1 and was_down_while_active:
				for s in shortcuts:
					var scancode = options.hotkeys[s][0]
					var button_index = options.hotkeys[s][1]
					if event is InputEventKey and scancode == event.scancode and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
						if not main.down_scancodes.has(event.scancode):
							main.down_scancodes.push_back(event.scancode)
					elif event is InputEventMouseButton and not event.is_echo() and OS.is_window_focused() and scancode == event.button_index and not event.is_pressed():
						if not main.down_scancodes.has(event.button_index):
							main.down_scancodes.push_back(event.button_index)
					elif event is InputEventJoypadButton and not event.is_echo() and OS.is_window_focused() and button_index == event.button_index and not event.is_pressed():
						if not main.down_scancodes.has(event.button_index):
							main.down_scancodes.push_back(event.button_index)

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	if visible and active and can_be_pressed():
		if options_button and $"/root/Main/Options Sprite/Options".menu != "mods" and not $"/root/Main/Options Sprite/Options".menu_buttons.has(self) and self != $"/root/Main/Options Sprite/Options".back_button and self != $"/root/Main/Options Sprite/Options".exit_button and self != $"/root/Main/Options Sprite/Options".reset_button:
			var t_label = preload("res://Outline Label.tscn").instance()
			t_label.visible = false
			get_parent().add_child(t_label)
			var button_num = $"/root/Main/Options Sprite/Options".option_buttons.find(self)
			if $"/root/Main/Options Sprite/Options".menu == "audio" and button_num > 6:
				button_num = 6 + floor((button_num - 6) / 3)
			elif $"/root/Main/Options Sprite/Options".menu == "input":
				button_num = floor(button_num / 2)
			if $"/root/Main/Options Sprite/Options".dropdown:
				t_label.raw_string = $"/root/Main/Options Sprite/Options/Header".raw_string
				t_label.values = $"/root/Main/Options Sprite/Options/Header".values
			else:
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
				option = t_label.get_child(0).text
			else:
				option = t_label.text
			get_parent().remove_child(t_label)
			t_label.queue_free()
			$"/root/Main".tts(option + "\n" + $"Text".raw_string, $"Text".values, self)
		elif texture != null:
			match texture.get_path():
				"res://discord-logo.png":
					$"/root/Main".tts(tr("discord_button"), [], self)
				"res://newsletter-logo.png":
					$"/root/Main".tts(tr("newsletter_button"), [], self)
				"res://tt logo big.png":
					$"/root/Main".tts("TrampolineTales.com", [], self)
				"res://merch-logo.png":
					$"/root/Main".tts(tr("merch_ad"), [], self)
		else:
			$"/root/Main".tts($"Text".raw_string, $"Text".values, self)

func _ready():
	text_node = $"Text"
	background = $"Background"
	top = $"Top"
	bottom = $"Bottom"
	left = $"Left"
	right = $"Right"
	sprite = $"Sprite"
	main = $"/root/Main"
	options = $"/root/Main/Options Sprite/Options"
	text_node.raw_string = button_text
	saved_raw_string = text_node.raw_string
		
	if hotkey:
		color = Color(0, 0, 0, 0)
		hover_color = Color(0, 0, 0, 0.5)
		background.rect_size.y = 36 * options.ui_scaling.text
	else:
		hover_color = color
	if options_button and (options.CJK_lang or text_node.forced_font != null):
		text_node.get_child(0).icon_z_index = 9
			
	background.color = color
	hover_color.v += 0.2
	
	if texture != null:
		sprite.set_texture(texture)
	
	if options.CJK_lang and text_node.get_child(0) != null:
		text_node.change_icon_size_override(3, Vector2(-4, -2))
	
	if text_node.forced_pico:
		text_node.add_texts()
	change_size()
	
	if not toggle:
		connect("button_up", self, "visual_unpress")
	
	if base_x == null:
		base_x = rect_position.x
		
	if options.CJK_lang or options.display_font > 0 or text_node.forced_font != null:
		text_node.get_child(0).custom_max_width = 100000
	else:
		text_node.texts[8].custom_max_width = 100000
	text_node.force_update = true
	text_node.update()

func update():
	if not is_inside_tree():
		return
	if options.input_type == 1 and moved_once and rect_position.x != base_x and can_be_pressed() and $"/root/Main".down_keys["confirm_select"] == 0 and $"/root/Main".selected_node != null and $"/root/Main".selected_node != self and not toggle:
		visual_reset()
	if is_inside_tree() and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and (not down or hotkey) and $"/root/Main/Selector Sprite/Selector".visible:
		tts()
		if options.input_type == 1 and can_be_pressed() and (options.hotkey_being_assigned == null or hotkey) and options.done_assigning and was_down_while_active and $"/root/Main".down_keys["confirm_select"] == 0 and rect_position.x != base_x:
			down = true
			unpress()
			return
		if $"/root/Main".down_keys["confirm_select"] == 1:
			$"/root/Main".down_keys["confirm_select"] += 1
			was_down_while_active = true
			press()
			return
	if delay <= 0:
		if active and (hovering and (not OS.is_window_focused() or (texture == null and ($"/root/Main".mouse_position.x < background.rect_global_position.x - 2 or $"/root/Main".mouse_position.x > background.rect_global_position.x + 2 + background.rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < background.rect_global_position.y - 2 or $"/root/Main".mouse_position.y > background.rect_global_position.y + 2 + background.rect_size.y * rect_scale.y)) or unhovering_texture()) or not OS.is_window_focused()) and visible and options.done_assigning:
			unhover()
			hovering = false
		elif active and not hovering and OS.is_window_focused() and (texture == null and (not ($"/root/Main".mouse_position.x < background.rect_global_position.x - 2 or $"/root/Main".mouse_position.x > background.rect_global_position.x + 2 + background.rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < background.rect_global_position.y - 2 or $"/root/Main".mouse_position.y > background.rect_global_position.y + 2 + background.rect_size.y * rect_scale.y)) or hovering_texture()) and visible:
			hover()
		if $"/root/Main".press_timer > 0 and ((texture == null and (not ($"/root/Main".mouse_position.x < background.rect_global_position.x - 2 or $"/root/Main".mouse_position.x > background.rect_global_position.x + 2 + background.rect_size.x * rect_scale.x or $"/root/Main".mouse_position.y < background.rect_global_position.y - 2 or $"/root/Main".mouse_position.y > background.rect_global_position.y + 2 + background.rect_size.y * rect_scale.y))) or hovering_texture()):
			was_down_while_active = true
			press()
	if not OS.is_window_focused():
		delay = 3
		hovering = false
	elif delay != 0:
		delay -= 1
	if can_be_pressed():
		selectable = true
	else:
		selectable = false

func hovering_texture():
	if texture != null and not ($"/root/Main".mouse_position.x < sprite.global_position.x or $"/root/Main".mouse_position.x > sprite.global_position.x + sprite.texture.get_size().x * rect_scale.x or $"/root/Main".mouse_position.y < sprite.global_position.y or $"/root/Main".mouse_position.y > sprite.global_position.y + sprite.texture.get_size().y * rect_scale.y) and visible:
		return true
	else:
		return false

func unhovering_texture():
	if texture != null and ($"/root/Main".mouse_position.x < sprite.global_position.x or $"/root/Main".mouse_position.x > sprite.global_position.x + sprite.texture.get_size().x * rect_scale.x or $"/root/Main".mouse_position.y < sprite.global_position.y or $"/root/Main".mouse_position.y > sprite.global_position.y + sprite.texture.get_size().y * rect_scale.y) and visible:
		return true
	else:
		return false

func can_be_pressed():
	return (((title_button and $"/root/Main/Title".visible and not options.visible) or (options_button and options.visible) or (email_button and $"/root/Main/Pop-up Sprite/Pop-up".visible and not options.visible and not $"/root/Main/Title".visible) or (not $"/root/Main/Pop-up Sprite/Pop-up".visible and not options.visible and not $"/root/Main/Title".visible)) and (OS.is_window_focused() or Steam.isSteamRunningOnSteamDeck()) and visible and options.done_assigning)

func hover():
	if can_be_pressed() and not hovering and not main.lmb_down and (not scrollable_button or (scrollable_button and rect_position.y > -background.rect_size.y)) and not $"/root/Main/Selector Sprite/Selector".visible:
		if not delayed:
			tts()
			if hotkey:
				background.color = Color(255, 255, 255, 0.2)
			else:
				background.color = color
				background.color.v += 0.2
		hovering = true

func unhover():
	if hovering:
		if active and not down:
			background.color = color
		hovering = false

func press():
	if can_be_pressed() and ((was_down_while_active and options.input_type == 1) or options.input_type == 0):
		if delayed:
			delayed = false
			background.color = color
			return
		if Steam.isSteamRunningOnSteamDeck():
			$"/root/Main".press_timer = 0
		if active and toggle and down:
			unpress()
			do_call()
		elif active and not down:
			if saved_raw_string != tr("removal_pay") and saved_raw_string != tr("reroll_pay") and not hotkey:
				var str2 = saved_raw_string
				while str2.find("<color_FBF236>") != -1:
					var start = str2.find("<color_FBF236>")
					var end
					for c in range(str2.length()):
						if str2[start + c] == "<" and str2[start + c + 1] == "e":
							end = start + c
							break
					str2 = str2.substr(0, start) + str2.substr(start + 14, end - 14 - str2.substr(0, start).length()) + str2.substr(end + 5, -1)
				text_node.raw_string = "<color_FBF236>" + str2 + "<end>"
				update_size()
				text_node.force_update = true
				text_node.update()
				correct_size()
			if not hotkey and not moved_once and base_x != null:
				rect_position.x = base_x + 8
				moved_once = true
			else:
				background.color.v += 0.2
			options.just_changed_osx_fullscreen = false
			if options.input_type == 0:
				if texture == null:
					down = true
				do_call()
				if is_inside_tree():
					for t in $"/root/Main/Tooltips".get_children():
						t.queue_free()
			else:
				held = true

func visual_unpress():
	if options.input_type == 0:
		unpress()

func visual_reset():
	if texture == null and not dont_reset:
		background.color = color
		text_node.raw_string = saved_raw_string
		if base_x != null:
			rect_position.x = base_x
		text_node.force_update = true
		text_node.update()
		button_text = text_node.text
		update_size()
		correct_size()
		button_text = saved_raw_string
		moved_once = false

func unpress():
	if can_be_pressed() and down and ((was_down_while_active and options.input_type == 1) or options.input_type == 0):
		down = false
		if (options.input_type == 0 or not toggle):
			visual_reset()
		hovering = false
		if options.input_type == 1:
			held = false
			if texture == null:
				down = true
			do_call()
			if str(get_path()).length() > 0:
				for t in $"/root/Main/Tooltips".get_children():
					t.queue_free()
			down = false

func change_size():
	if dont_scale:
		current_scale = 1.0 + scale_mod * 0.25
	else:
		current_scale = options.ui_scaling.buttons + scale_mod * 0.25
	if sprite.texture != null:
		if saved_rect_size == null:
			saved_rect_size = Vector2(sprite.texture.get_size().x * 2, sprite.texture.get_size().y * 2)
		else:
			saved_rect_size = Vector2(sprite.texture.get_size().x * rect_scale.x, sprite.texture.get_size().y * rect_scale.y)
		if title_button:
			current_scale *= 2
		rect_scale = Vector2(current_scale, current_scale)
		rect_size = Vector2(sprite.texture.get_size().x * current_scale, sprite.texture.get_size().y * current_scale)
	elif not hotkey:
		text_node.force_size_change = true
		saved_rect_size = Vector2(rect_size.x, rect_size.y)
		if options.CJK_lang or text_node.forced_font != null or int(options.display_font) > 0:
			if current_scale < 0.5:
				current_scale = 0.5
			if not dont_scale:
				text_node.change_set_size(options.ui_scaling.buttons / 2.0 + scale_mod * 0.125)
			else:
				text_node.change_set_size(0.5 + scale_mod * 0.125)
		else:
			if current_scale < 0.5:
				current_scale = 0.5
			text_node.change_set_size(current_scale)
		if current_scale > 1:
			border_thickness = current_scale * 4
		else:
			border_thickness = 4
		text_node.size_update = true
		text_node.update()
	update_size()
	correct_size()
	if (saved_rect_size != rect_size or saved_scale != current_scale) and saved_rect_size != null:
		if alignment_tags.v_centered:
			rect_position.y += saved_rect_size.y / 2.0 - rect_size.y / 2.0
		elif alignment_tags.bottom:
			rect_position.y += saved_rect_size.y - rect_size.y
		if alignment_tags.centered:
			rect_position.x += saved_rect_size.x / 2.0 - rect_size.x / 2.0
		elif alignment_tags.right:
			rect_position.x += saved_rect_size.x - rect_size.x
		if down:
			base_x = rect_position.x - 8
		else:
			base_x = rect_position.x
		saved_scale = current_scale
		correct_size()
	if sprite.texture == null or not hotkey:
		rect_size = background.rect_size

func do_call():
	OS.set_clipboard("")
	if not options.visible and not $"/root/Main/Title".visible and ($"/root/Main/Landlord".anim_time > 0 or $"/root/Main/Sums/HP Sum".adding):
		return
	doing_call = true
	match args.size():
		0:
			target.call(call)
		1:
			target.call(call, args[0])
		2:
			target.call(call, args[0], args[1])
		3:
			target.call(call, args[0], args[1], args[2])
	doing_call = false

func update_size():
	if text_node == null or sprite.texture != null:
		return
	var extra_mod = 1
	if current_scale > 1:
		extra_mod = current_scale
	if not hotkey:
		if (options.CJK_lang or text_node.forced_font != null or int(options.display_font) > 0) and not text_node.forced_pico:
			if text_node.forced_font == null:
				text_node.rect_position = Vector2(12 * border_thickness / 4, 0)
			elif not options.CJK_lang:
				text_node.rect_position = Vector2(4, -4 * current_scale)
			background.rect_size = Vector2(text_node.get_child(0).get_font("font").get_string_size(text_node.get_child(0).text).x / 2 * (2 * text_node.get_child(0).rect_scale.x) + 15 * extra_mod, 48 * current_scale)
		else:
			if text_node.get_font("font").get_path() == "res://PICO-8.tres":
				text_node.rect_position = Vector2(14 * border_thickness / 4, 8 * current_scale)
			elif text_node.get_font("font").get_path() == "res://NotoSans_Resize.tres" or text_node.get_child(0).get_font("font").get_path() == "res://OpenDyslexic_Resize.tres":
				text_node.rect_position = Vector2(2, -1 * current_scale)
			background.rect_size = Vector2(text_node.get_font("font").get_string_size(button_text).x / 2 * (2 * text_node.texts[8].rect_scale.x) + 15 * extra_mod, 48 * current_scale)
			if forced_size != -1:
				background.rect_size.x = forced_size
	elif options.CJK_lang:
		text_node.rect_position.x = -text_node.get_font("font").get_string_size(text_node.get_child(0).text).x * text_node.current_scale / 2.0
	else:
		text_node.rect_position.x = -text_node.get_font("font").get_string_size(text_node.text).x * text_node.current_scale * 2.0
	if scale_with_thickness and text_node.forced_font == null:
		if border_thickness >= 4:
			text_node.rect_position.x -= border_thickness
		elif border_thickness < 4:
			text_node.rect_position.x += border_thickness
	if tall_button:
		if int(options.display_font) > 0:
			background.rect_size.y += 16
		else:
			background.rect_size.y += 8
	elif text_node.forced_font != null and not options.CJK_lang and int(options.display_font) == 0:
		text_node.rect_position.x += 4
		text_node.rect_position.y += 4
	rect_size.x = background.rect_size.x + 2
	rect_size.y = background.rect_size.y + 2
	if hotkey and sprite.texture != null:
		rect_size = sprite.texture.get_size()
	
	top.clear_points()
	bottom.clear_points()
	left.clear_points()
	right.clear_points()
	
	top.width = border_thickness
	bottom.width = border_thickness
	left.width = border_thickness
	right.width = border_thickness
	
	if not hotkey:
		top.default_color = Color(options.colors3["button_border"])
		top.add_point(Vector2(-2, 0))
		top.add_point(Vector2(rect_size.x + 2, 0))
		
		bottom.default_color = Color(options.colors3["button_border"])
		bottom.add_point(Vector2(-2, rect_size.y))
		bottom.add_point(Vector2(rect_size.x + 2, rect_size.y))
		
		left.default_color = Color(options.colors3["button_border"])
		left.add_point(Vector2(0, 0))
		left.add_point(Vector2(0, rect_size.y))
		
		right.default_color = Color(options.colors3["button_border"])
		right.add_point(Vector2(rect_size.x, 0))
		right.add_point(Vector2(rect_size.x, rect_size.y))

func correct_size():
	if text_node == null or sprite.texture != null:
		return
	var extra_mod = 1
	if current_scale > 1:
		extra_mod = current_scale
	if not hotkey:
		if (options.CJK_lang or text_node.forced_font != null or options.display_font > 0) and not text_node.forced_pico:
			if text_node.forced_font == null:
				text_node.set_icon_size()
				if text_node.get_child(0).get_font("font").get_path() == "res://NotoSansTH_Resize.tres":
					if current_scale < 1.25:
						text_node.get_child(0).rect_position = Vector2(0, 1.5 * border_thickness + 4)
					elif current_scale <= 1.5:
						text_node.get_child(0).rect_position = Vector2(0, 1.5 * border_thickness + 4)
					else:
						text_node.get_child(0).rect_position = Vector2(0, 1.5 * border_thickness + 4)
				if (text_node.get_child(0).get_font("font").get_path() == "res://NotoSans_Resize.tres" or text_node.get_child(0).get_font("font").get_path() == "res://NotoSansAR_Resize.tres" or text_node.get_child(0).get_font("font").get_path() == "res://OpenDyslexic_Resize.tres"):
					if current_scale < 1.25:
						text_node.rect_position = Vector2(16 * border_thickness / 4, 1.5 * border_thickness)
					elif current_scale <= 1.5:
						text_node.rect_position = Vector2(15 * border_thickness / 4, 1.5 * border_thickness)
					else:
						text_node.rect_position = Vector2(14 * border_thickness / 4, 1.5 * border_thickness)
				else:
					text_node.rect_position = Vector2(12 * border_thickness / 4, 0)
			elif not options.CJK_lang:
				if (text_node.forced_font.get_path() == "res://NotoSans_Resize.tres" or text_node.get_child(0).get_font("font").get_path() == "res://OpenDyslexic_Resize.tres") and text_node.raw_string != options.languages[15] and text_node.raw_string != options.languages[16]:
					text_node.rect_position = Vector2(4 * border_thickness / 2 + 4 * current_scale, 8 * current_scale)
				else:
					text_node.rect_position = Vector2(4 * border_thickness / 2, 2 * current_scale)
			background.rect_size = Vector2(text_node.get_child(0).get_font("font").get_string_size(text_node.get_child(0).text).x / 2 * (2 * text_node.get_child(0).rect_scale.x) + 15 * extra_mod, 48 * current_scale)
			if text_node.get_child(0).text.length() > 0 and text_node.get_child(0).text[text_node.get_child(0).text.length() - 1] == text_node.get_child(0).cjk_space:
				if TranslationServer.get_locale() == "vi":
					background.rect_size.x -= -10 + 14 / current_scale
				elif int(options.display_font) > 0:
					if options.ui_scaling.buttons < 1:
						background.rect_size.x -= 16 * current_scale
					elif options.ui_scaling.buttons > 1:
						background.rect_size.x -= current_scale
				else:
					background.rect_size.x += -38 + (current_scale + scale_mod * 0.25) * 40
			if text_node.get_child(0).text.length() > 0 and text_node.get_child(0).text[text_node.get_child(0).text.length() - 1] == " ":
				if TranslationServer.get_locale() == "ar" and int(options.display_font) == 1:
					pass
				else:
					background.rect_size.x -= 12 * current_scale
		else:
			if text_node.get_font("font").get_path() == "res://PICO-8.tres":
				text_node.rect_position = Vector2(14 * border_thickness / 4, 8 * current_scale)
			elif text_node.get_font("font").get_path() == "res://NotoSans_Resize.tres" or text_node.get_child(0).get_font("font").get_path() == "res://OpenDyslexic_Resize.tres":
				text_node.rect_position = Vector2(2, -1 * current_scale)
			background.rect_size = Vector2(text_node.get_font("font").get_string_size(text_node.text).x / 2 * (2 * text_node.texts[8].rect_scale.x) + 15 * extra_mod, 48 * current_scale)
			if forced_size != -1:
				background.rect_size.x = forced_size
			if text_node.text.length() > 0 and text_node.text[text_node.text.length() - 1] == " ":
				background.rect_size.x -= 12 * current_scale
	else:
		if options.CJK_lang or int(options.display_font) > 0:
			text_node.rect_position.x = background.rect_position.x + background.rect_size.x / 2 - text_node.get_child(0).get_font("font").get_string_size((text_node.get_child(0).text)).x / 2 * text_node.current_scale
		else:
			text_node.rect_position.x = background.rect_position.x + background.rect_size.x / 2 - text_node.get_font("font").get_string_size((text_node.text)).x / 2 * text_node.current_scale * 4
	if scale_with_thickness and text_node.forced_font == null:
		if border_thickness >= 4:
			text_node.rect_position.x -= border_thickness
		elif border_thickness < 4:
			text_node.rect_position.x += border_thickness
	if tall_button:
		if int(options.display_font) > 0:
			background.rect_size.y += 16
		else:
			background.rect_size.y += 8
	if TranslationServer.get_locale() == "ar" and int(options.display_font) == 0:
		if call != "set_floor" and call != "show_stats" and call != "spin":
			background.rect_size.y += current_scale * 10
		elif call == "spin":
			text_node.rect_position.y -= 20
	rect_size.x = background.rect_size.x + 2
	rect_size.y = background.rect_size.y + 2
	if hotkey and sprite.texture != null:
		rect_size = sprite.texture.get_size()
	
	add_lines()
	if centered_text_button:
		if int(options.display_font) == 1 and TranslationServer.get_locale() != "th":
			text_node.rect_position.x = rect_size.x / 2 - (text_node.get_child(0).get_font("font").get_string_size(text_node.get_child(0).text).x - 10) / 2 * text_node.current_scale
		elif int(options.display_font) == 2 and TranslationServer.get_locale() != "th":
			text_node.rect_position.x = rect_size.x / 2 - (text_node.get_child(0).get_font("font").get_string_size(text_node.get_child(0).text).x - 6) / 2 * text_node.current_scale
		elif (options.CJK_lang or text_node.forced_font != null or int(options.display_font) > 0) and not text_node.forced_pico:
			text_node.rect_position.x = rect_size.x / 2 - text_node.get_child(0).get_font("font").get_string_size(text_node.get_child(0).text).x / 2 * text_node.current_scale
		else:
			text_node.rect_position.x = rect_size.x / 2 + (4 * text_node.current_scale) - text_node.get_font("font").get_string_size(text_node.text).x / 2 * text_node.current_scale * 4.0 - 2 * text_node.current_scale
		if TranslationServer.get_locale() == "th":
			if text_node.forced_font != null:
				text_node.rect_position.y = -2
			else:
				text_node.rect_position.y = -10
	if shortcuts.size() > 0:
		var hotkey = preload("res://Outline Label.tscn").instance()
		if not $"/root/Main".displayed_hotkey_sources.has(self) and options.hotkeys.has("SPIN"):
			hotkey.raw_string = "<button_" + str(options.hotkeys[shortcuts[0]][1]) + ">"
			if hotkey.texts.size() > 7:
				hotkey.texts[8].icon_z_index = 25
			else:
				hotkey.icon_z_index = 25
				hotkey.scale_mod = -1
			hotkey.update()
			$"/root/Main/Hotkeys".add_child(hotkey)
			$"/root/Main".displayed_hotkey_sources.push_back(self)

func add_lines():
	if hotkey:
		return
	color = Color(options.colors3[color_type])
	background.color = color
	if options.colors3.has(color_type + "_text"):
		if not (options.CJK_lang or options.display_font > 0) and text_node.forced_font == null:
			text_node.texts[8].add_color_override("font_color", options.colors3[color_type + "_text"])
		else:
			text_node.get_child(0).add_color_override("font_color", options.colors3[color_type + "_text"])
	else:
		if not (options.CJK_lang or options.display_font > 0) and text_node.forced_font == null:
			text_node.texts[8].add_color_override("font_color", "#FFFFFF")
		else:
			text_node.get_child(0).add_color_override("font_color", "#FFFFFF")
	
	top.clear_points()
	bottom.clear_points()
	left.clear_points()
	right.clear_points()
	
	top.width = border_thickness
	bottom.width = border_thickness
	left.width = border_thickness
	right.width = border_thickness
	
	if not hotkey:
		top.default_color = Color(options.colors3["button_border"])
		top.add_point(Vector2(-2 - border_thickness / 2 + 2, 0 - border_thickness / 2 + 2))
		top.add_point(Vector2(rect_size.x + 2 + border_thickness / 2 - 2, 0 - border_thickness / 2 + 2))
		
		bottom.default_color = Color(options.colors3["button_border"])
		bottom.add_point(Vector2(-2 - border_thickness / 2 + 2, rect_size.y + border_thickness / 2 - 2))
		bottom.add_point(Vector2(rect_size.x + 2 + border_thickness / 2 - 2, rect_size.y + border_thickness / 2 - 2))
		
		left.default_color = Color(options.colors3["button_border"])
		left.add_point(Vector2(0, 0))
		left.add_point(Vector2(0, rect_size.y))
		
		right.default_color = Color(options.colors3["button_border"])
		right.add_point(Vector2(rect_size.x, 0))
		right.add_point(Vector2(rect_size.x, rect_size.y))

func reset_position():
	current_scale = 1.0
	correct_size()
	saved_rect_size = rect_size
	change_size()
