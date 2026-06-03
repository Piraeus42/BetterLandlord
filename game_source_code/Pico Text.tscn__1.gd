extends Label

var dont_remove = false
var hyperlink
var active = true
var hovering = false
var background
var color
var hover_color
var delay = 0

var selectable = true
var off_screen = false
var cant_go_dirs = []
var selector_alignment = "dont"

func _input(event):
	if hovering and event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and not $"/root/Main".lmb_down:
		press()

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
	if TranslationServer.get_locale() == "zh":
		add_font_override("font", preload("res://NotoSansSC_Resize.tres"))
	elif TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK":
		add_font_override("font", preload("res://NotoSansTC_Resize.tres"))
	elif TranslationServer.get_locale() == "ko":
		add_font_override("font", preload("res://NotoSansKR_Resize.tres"))
	elif TranslationServer.get_locale() == "ja":
		add_font_override("font", preload("res://NotoSansJP_Resize.tres"))
	elif TranslationServer.get_locale() == "ar":
		add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
	elif TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "hi":
		add_font_override("font", preload("res://NotoSans_Resize.tres"))
	elif TranslationServer.get_locale() == "th":
		add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
	else:
		add_font_override("font", preload("res://PICO-8.tres"))

func _ready():
	background = $"Background"
	hover_color = color
	hover_color.v += 0.2
	
	if TranslationServer.get_locale() == "ar":
		if get_parent().rtl:
			align = Label.ALIGN_RIGHT
		if int($"/root/Main/Options Sprite/Options".display_font) == 0:
			add_font_override("font", get_parent().get_font("font"))
	
	var mod = rect_scale.x * 4.0
	
	if $"/root/Main/Options Sprite/Options".CJK_lang or get_parent().get_parent().forced_font != null or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		if get_parent().get_parent().forced_font != null:
			add_font_override("font", get_parent().get_parent().forced_font)
		else:
			match int($"/root/Main/Options Sprite/Options".display_font):
				1:
					if get_parent().get_parent().i_spaced and TranslationServer.get_locale() != "th":
						add_font_override("font", preload("res://NotoSans_Inventory.tres"))
					else:
						if TranslationServer.get_locale() == "th":
							add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
						elif TranslationServer.get_locale() == "ar":
							add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
						else:
							add_font_override("font", preload("res://NotoSans_Resize.tres"))
				2:
					if get_parent().get_parent().i_spaced:
						add_font_override("font", preload("res://OpenDyslexic_Inventory.tres"))
					else:
						add_font_override("font", preload("res://OpenDyslexic_Resize.tres"))
		background.rect_size = Vector2(get_font("font").get_string_size(text).x / 2 * (2 * get_parent().rect_scale.x) + mod, get_font("font").get_height())
	else:
		if get_parent().forced_font != null:
			add_font_override("font", get_parent().forced_font)
		background.rect_size = Vector2(get_font("font").get_string_size(text).x / 2 * (2 * get_parent().rect_scale.x) + mod, get_font("font").get_height())
	
	var h_num = get_parent().get_children().find(self)
	var hls = get_parent().get_parent().hyperlinks
	if h_num != -1 and hls.size() > h_num:
		hyperlink = hls[h_num]
		$"/root/Main/Options Sprite/Options".hyperlinks.push_back(self)

func update():
	if delay <= 0:
		if hyperlink != null:
			if is_inside_tree() and $"/root/Main".selected_node != null and $"/root/Main".selected_node == self and OS.is_window_focused() and $"/root/Main/Selector Sprite/Selector".visible:
				if $"/root/Main".down_keys["confirm_select"] == 1:
					$"/root/Main".down_keys["confirm_select"] += 1
					if not $"/root/Main/Selector Sprite/Selector".visible:
						$"/root/Main/Selector Sprite/Selector".visible = true
					else:
						press()
				elif $"/root/Main".down_keys["up"] == 1 or $"/root/Main".down_keys["down"] == 1:
					var h_tbe = []
					var num = 0
					for h in $"/root/Main/Options Sprite/Options".hyperlinks:
						if not is_instance_valid(h):
							h_tbe.push_back(num)
						num += 1
					for h in range(h_tbe.size()):
						$"/root/Main/Options Sprite/Options".hyperlinks.remove(h_tbe[h] - h)
					h_tbe.clear()
			selector_alignment = "hyperlink"
			if is_inside_tree() and not $"/root/Main/Selector Sprite/Selector".visible:
				if active and (hovering and (not OS.is_window_focused() or ((get_global_mouse_position().x < rect_global_position.x - 4 or get_global_mouse_position().x > rect_global_position.x - 4 + background.rect_size.x * rect_scale.x or get_global_mouse_position().y < rect_global_position.y + 2 or get_global_mouse_position().y > rect_global_position.y - 4 + background.rect_size.y * get_parent().rect_scale.y))) or not OS.is_window_focused()) and visible:
					hovering = false
					add_color_override("font_color", color)
				elif active and not hovering and OS.is_window_focused() and ((not (get_global_mouse_position().x < rect_global_position.x - 4 or get_global_mouse_position().x > rect_global_position.x - 4 + background.rect_size.x * rect_scale.x or get_global_mouse_position().y < rect_global_position.y + 2 or get_global_mouse_position().y > rect_global_position.y - 4 + background.rect_size.y * get_parent().rect_scale.y))) and visible and get_parent().get_parent().rect_position.y > -8:
					hovering = true
					add_color_override("font_color", hover_color)
	if not OS.is_window_focused():
		delay = 3
		hovering = false
	elif delay != 0:
		delay -= 1
	if text != tr(text):
		text = text + "\u200B"

func press():
	if hyperlink != null and OS.is_window_focused() and visible and $"/root/Main/Options Sprite/Options".visible:
		OS.shell_open(hyperlink)
