extends "res://Pico Label.tscn::1"

var color = "FFFFFF"
var texts = []
var saved_text = ""
var coin_icons_active = false
var force_update = false
var size_update = true
var need_to_center = false
var need_to_left = false
var current_scale = 1.0
var forced_font_size = -1
var font_set = false
var hyperlinks = []
var saved_line_count
var saved_scale = 1.0
var base_scale = 1.0
var dont_scale = false
var overwrite_scale = false
var alignment_tags = {"bottom": false, "right": false, "centered": false, "v_centered": false}
var button_text = false
var aligned = false
var saved_resolution = Vector2(1024, 576)
var scale_mod = 0
var text_mod = 0
var line_update = true
var force_size_change = false
var custom_icon_offset = Vector2(0, 0)
var tooltip_desc = false
var effect_text = false
var forced_pico = false
var off_screen = false
var base_x = 0
var offset_x = 0
var ar_offset = 0

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
	if TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "zh_TW" and TranslationServer.get_locale() != "zh_HK" and TranslationServer.get_locale() != "ko" and TranslationServer.get_locale() != "ja":
		cjk = false
		if TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "th" or TranslationServer.get_locale() == "hi":
			saved_scale = 0.5
			base_scale = 0.5
	else:
		add_child(preload("res://Pico Label.tscn").instance())
		add_child(Control.new())
		saved_scale = 0.5
		base_scale = 0.5
	if not cjk and forced_font == null:
		for i in range(9):
			if i != 4:
				texts.push_back(preload("res://Pico Label.tscn").instance())
				texts[texts.size() - 1].border_text = true
				texts[texts.size() - 1].rect_position.x = -4 + (i % 3) * 4
				texts[texts.size() - 1].rect_position.y = -4 + floor(i / 3) * 4
				texts[texts.size() - 1].add_color_override("font_color", Color(0,0,0))
				add_child(texts[texts.size() - 1])
		add_color_override("font_color", Color(0,0,0,0))
		texts.push_back(preload("res://Pico Label.tscn").instance())
		texts[texts.size() - 1].add_color_override("font_color", color)
		add_child(texts[texts.size() - 1])

func _ready():
	if (int($"/root/Main/Options Sprite/Options".display_font) > 0 and forced_font == null):
		if TranslationServer.get_locale() == "ar":
			saved_scale = 0.5
			base_scale = 0.5
		if texts.size() > 0 and texts[8] != null:
			for t in range(1, 9):
				if is_instance_valid(texts[t]):
					remove_child(texts[t])
					texts[t].queue_free()
			texts.clear()
		add_child(preload("res://Pico Label.tscn").instance())
		add_child(Control.new())
		add_color_override("font_color", Color(255,255,255))
	if $"/root/Main/Options Sprite/Options".ui_scaling.text != 1 and not get_parent() is TextureButton and scale_mod == 0:
		scale_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)

func remove_texts():
	if texts.size() > 0 and texts[8] != null:
		for t in get_children().slice(2, -1, true):
			if is_instance_valid(t):
				remove_child(t)
				t.queue_free()
		texts.clear()
		get_child(0).border_text = false

func add_texts():
	if texts.size() == 0:
		for i in range(9):
			if i != 4:
				texts.push_back(preload("res://Pico Label.tscn").instance())
				texts[texts.size() - 1].border_text = true
				texts[texts.size() - 1].rect_position.x = -4 + (i % 3) * 4
				texts[texts.size() - 1].rect_position.y = -4 + floor(i / 3) * 4
				texts[texts.size() - 1].add_color_override("font_color", Color(0,0,0))
				add_child(texts[texts.size() - 1])
		add_color_override("font_color", Color(0,0,0,0))
		texts.push_back(preload("res://Pico Label.tscn").instance())
		texts[texts.size() - 1].add_color_override("font_color", color)
		add_child(texts[texts.size() - 1])

func update_border():
	var i = 0
	for t in texts:
		if i != 9:
			t.rect_position.x = -4 * current_scale + (i % 3) * 4 * current_scale
			t.rect_position.y = -4 * current_scale + floor(i / 3) * 4 * current_scale
		i += 1
		if i == 4:
			i += 1
			
func remove_icons(force):
	var removed_colors = 0
	var removed_icons = 0
	if $"/root/Main/Options Sprite/Options".changing_languages:
		return
	if (not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0 and forced_font == null) or forced_pico:
		if texts.size() < 9:
			return
		if force:
			for t in texts[8].color_texts:
				texts[8].remove_child(t)
				t.queue_free()
			for t in texts[8].extra_color_texts:
				texts[8].remove_child(t)
				t.queue_free()
			for t in texts[8].icons:
				if texts[8].get_children().has(t):
					texts[8].remove_child(t)
				t.queue_free()
			texts[8].color_texts.clear()
			texts[8].colors.clear()
			texts[8].color_positions.clear()
			texts[8].extra_color_texts.clear()
			texts[8].icons.clear()
			texts[8].icon_positions.clear()
			return
		for c in range(texts[8].color_texts.size()):
			if not texts[8].color_texts[c - removed_colors].dont_remove:
				texts[8].color_texts[c - removed_colors].queue_free()
				texts[8].color_texts.remove(c - removed_colors)
				texts[8].colors.remove(c - removed_colors)
				texts[8].color_positions.remove(c - removed_colors)
				texts[8].color_positions.remove(c - removed_colors)
				removed_colors += 1
		removed_colors = 0
		for c in range(texts[8].extra_color_texts.size()):
			if not texts[8].extra_color_texts[c - removed_colors].dont_remove:
				texts[8].extra_color_texts[c - removed_colors].queue_free()
				texts[8].extra_color_texts.remove(c - removed_colors)
				removed_colors += 1
		for i in range(texts[8].icons.size()):
			if not texts[8].icons[i - removed_icons].dont_remove:
				texts[8].icons[i - removed_icons].queue_free()
				texts[8].icons.remove(i - removed_icons)
				texts[8].icon_positions.remove(i - removed_icons)
				texts[8].icon_positions.remove(i - removed_icons)
				removed_icons += 1
	else:
		var chi = get_child(0)
		if chi == null:
			return
		if force:
			for t in chi.color_texts:
				chi.remove_child(t)
				t.queue_free()
			for t in chi.extra_color_texts:
				chi.remove_child(t)
				t.queue_free()
			for t in chi.icons:
				get_child(1).remove_child(t)
				t.queue_free()
			chi.color_texts.clear()
			chi.colors.clear()
			chi.color_positions.clear()
			chi.extra_color_texts.clear()
			chi.icons.clear()
			chi.icon_positions.clear()
			return
		for c in range(chi.color_texts.size()):
			if not chi.color_texts[c - removed_colors].dont_remove:
				chi.color_texts[c - removed_colors].queue_free()
				chi.color_texts.remove(c - removed_colors)
				chi.colors.remove(c - removed_colors)
				chi.color_positions.remove(c - removed_colors)
				chi.color_positions.remove(c - removed_colors)
				removed_colors += 1
		removed_colors = 0
		for c in range(chi.extra_color_texts.size()):
			if not chi.extra_color_texts[c - removed_colors].dont_remove:
				chi.extra_color_texts[c - removed_colors].queue_free()
				chi.extra_color_texts.remove(c - removed_colors)
				removed_colors += 1
		for i in range(chi.icons.size()):
			if not chi.icons[i - removed_icons].dont_remove:
				chi.icons[i - removed_icons].queue_free()
				chi.icons.remove(i - removed_icons)
				chi.icon_positions.remove(i - removed_icons)
				chi.icon_positions.remove(i - removed_icons)
				removed_icons += 1

func set_icon_size():
	if cjk or forced_font != null or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		var vi_mod = Vector2(0, 0)
		if i_spaced and TranslationServer.get_locale() == "th":
			vi_mod.y = -14
		var font_mod = 0
		if (int($"/root/Main/Options Sprite/Options".display_font) > 0 and get_path() != "/root/Main/Coins" and get_parent().get_path() != "/root/Main/Sums"):
			font_mod = -1
		var os = Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
		match str(current_scale + (scale_mod + font_mod) / 8.0):
			"-0.25", "-0.125":
				if get_parent() is TextureButton:
					if raw_string == tr("reroll_pay"):
						if int($"/root/Main/Options Sprite/Options".display_font) == 1:
							os = Vector2(10 + custom_icon_offset.x + vi_mod.x, -6 + custom_icon_offset.y + vi_mod.y)
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							os = Vector2(5 + custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
				elif str(get_path()).find("Mod Text") != -1:
					os = Vector2(-5 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
				elif v_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-4 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
				elif e_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-3 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
				change_icon_size_override(1, os)
			"0":
				if get_parent() is TextureButton:
					if cjk:
						os = Vector2(-1 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
					elif raw_string == tr("removal_pay"):
						if int($"/root/Main/Options Sprite/Options".display_font) == 1:
							os = Vector2(-3 + custom_icon_offset.x + vi_mod.x, -11 + custom_icon_offset.y + vi_mod.y)
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							os = Vector2(-7 + custom_icon_offset.x + vi_mod.x, -11 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(11 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
				elif tooltip_desc:
					os = Vector2(custom_icon_offset.x + vi_mod.x, -4 + custom_icon_offset.y + vi_mod.y)
				if effect_text:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-3 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y)
					change_icon_size_override(2, os)
				elif i_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
						change_icon_size_override(3, os)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-9 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y)
						change_icon_size_override(3, os)
					else:
						change_icon_size_override(1, os)
				elif v_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-4 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
						change_icon_size_override(2, os)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
						change_icon_size_override(2, os)
				elif str(get_path()).find("Mod Text") != -1 and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(2, os)
				else:
					change_icon_size_override(2, os)
			"0.125":
				if get_parent() is TextureButton:
					if cjk:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
					elif raw_string == tr("removal_pay"):
						if int($"/root/Main/Options Sprite/Options".display_font) == 1:
							os = Vector2(-4 + custom_icon_offset.x + vi_mod.x, -12 + custom_icon_offset.y + vi_mod.y)
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							os = Vector2(-4 + custom_icon_offset.x + vi_mod.x, -12 + custom_icon_offset.y + vi_mod.y)
					elif raw_string == tr("reroll_pay"):
						os = Vector2(4 + custom_icon_offset.x + vi_mod.x, -6 + custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
						os = Vector2(-3 + custom_icon_offset.x + vi_mod.x, -9 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
				elif tooltip_desc:
					os = Vector2(custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y)
					elif i_spaced:
						os = Vector2(1 + custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y)
					elif e_spaced:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
					elif str(get_path()).find("Mod Text") != -1:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(-7 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
					elif i_spaced:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 9 + custom_icon_offset.y + vi_mod.y)
					elif str(get_path()).find("Mod Text") != -1 and $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1.0:
						os = Vector2(-7 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
					elif e_spaced:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(4 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
				if str(get_path()).find("Mod Text") != -1 and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(2, os)
				elif i_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						change_icon_size_override(3, os)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						change_icon_size_override(3, os)
					else:
						change_icon_size_override(2, os)
				elif raw_string == tr("dedication"):
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						change_icon_size_override(3, os)
					elif cjk:
						change_icon_size_override(1, os)
				elif get_parent() is TextureButton:
					if cjk:
						change_icon_size_override(1, os)
					elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
						change_icon_size_override(2, os)
					else:
						change_icon_size_override(3, os)
				else:
					change_icon_size_override(2, os)
			"0.25":
				if get_parent() is TextureButton:
					if TranslationServer.get_locale() == "th":
						os = Vector2(1 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
					else:
						if (raw_string.find("<icon_right>") != -1 or raw_string.find("<icon_left>") != -1):
							os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
						else:
							os = Vector2(custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
				elif tooltip_desc:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-4 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-7 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(2 + custom_icon_offset.x + vi_mod.x, -6 + custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y)
					elif str(get_path()).find("Mod Text") != -1:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -1 + custom_icon_offset.y + vi_mod.y)
					elif i_spaced:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -1 + custom_icon_offset.y + vi_mod.y)
					elif e_spaced:
						os = Vector2(custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -1 + custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y)
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						if $"/root/Main/Options Sprite/Options".ui_scaling.emails == 0.5:
							os = Vector2(-5 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
						else:
							os = Vector2(-5 + custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y)
					elif i_spaced:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					elif e_spaced:
						if str(get_path()).find("Mod Text") != -1 and $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1.0:
							os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
						elif str(get_path()).find("Mod Text") != -1:
							os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, -1 + custom_icon_offset.y + vi_mod.y)
						else:
							os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, -4 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(-5 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
				elif cjk and str(get_path()).find("Mod Text") != -1:
					os = Vector2(custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y)
				if str(get_path()).find("Mod Text") != -1 and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(3, os)
				elif get_parent() is TextureButton:
					change_icon_size_override(2, os)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2 and e_spaced and str(get_path()).find("Mod Text") != -1 and $"/root/Main/Options Sprite/Options".ui_scaling.text > 1:
					change_icon_size_override(4, os)
				elif raw_string == tr("dedication"):
					if cjk:
						change_icon_size_override(3, os)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						change_icon_size_override(4, os)
				elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
					if TranslationServer.get_locale() == "pl" and $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1 and get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container" and int($"/root/Main/Options Sprite/Options".display_font) == 2:
						change_icon_size_override(3, os)
					else:
						change_icon_size_override(2, os)
				elif TranslationServer.get_locale() == "th" and raw_string == tr("removal_pay"):
					os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
					change_icon_size_override(3, os)
				elif cjk and (raw_string == tr("removal_pay") or get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container"):
					change_icon_size_override(2, os)
				else:
					change_icon_size_override(3, os)
			"0.375":
				if cjk and str(get_path()).find("Mod Text") != -1:
					if TranslationServer.get_locale() == "ko":
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y)
				elif v_spaced or e_spaced:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						if str(get_path()).find("Mod Text") != -1:
							os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
						else:
							os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						if e_spaced and str(get_path()).find("Mod Text") != -1:
							os = Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
						elif e_spaced:
							os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
						else:
							os = Vector2(2 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y)
				elif get_parent() is TextureButton:
					if raw_string == tr("reroll_pay") or raw_string == tr("removal_pay"):
						if int($"/root/Main/Options Sprite/Options".display_font) == 0:
							custom_icon_offset.x = -6
							custom_icon_offset.y = -12
						elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
							if raw_string == tr("reroll_pay"):
								custom_icon_offset.y = -4
							else:
								custom_icon_offset.y = -8
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							if raw_string == tr("reroll_pay"):
								custom_icon_offset.x = -6
								custom_icon_offset.y = -1
							else:
								custom_icon_offset.x = -12
								custom_icon_offset.y = -6
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, -3 + custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(3 + custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, -1 + custom_icon_offset.y + vi_mod.y)
				elif tooltip_desc:
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						os = Vector2(custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y)
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
					else:
						os = Vector2(-6 + custom_icon_offset.x + vi_mod.x, 10 + custom_icon_offset.y + vi_mod.y)
				elif cjk and effect_text:
					os = Vector2(6 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y)
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1 and effect_text:
					os = Vector2(-1 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y)
				if str(get_path()).find("Mod Text") != -1 and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if TranslationServer.get_locale() == "ar":
						change_icon_size_override(4, os)
					else:
						change_icon_size_override(3, os)
				elif e_spaced and str(get_path()).find("Mod Text") != -1 and not cjk:
					change_icon_size_override(4, os)
				elif (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums") and $"/root/Main/Options Sprite/Options".ui_scaling.text == 0.5 and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						os = Vector2(-2 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y)
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						os = Vector2(-8 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y)
					if cjk:
						change_icon_size_override(3, os)
					else:
						change_icon_size_override(2, os)
				elif cjk and get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
					change_icon_size_override(2, os)
				else:
					change_icon_size_override(3, os)
			"0.5":
				if v_spaced and int($"/root/Main/Options Sprite/Options".display_font) == 1:
					change_icon_size_override(3, Vector2(-1 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y))
				elif v_spaced and int($"/root/Main/Options Sprite/Options".display_font) == 2:
					change_icon_size_override(4, Vector2(-9 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif get_parent() is TextureButton:
					change_icon_size_override(3, Vector2(-2 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(3, Vector2(20 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				else:
					if int($"/root/Main/Options Sprite/Options".display_font) == 1:
						if effect_text:
							change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
						elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
							change_icon_size_override(3, Vector2(custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
						elif get_path() == "/root/Main/Landlord/Temp":
							if TranslationServer.get_locale() == "th":
								change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x + 7, custom_icon_offset.y + vi_mod.y))
							else:
								change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x - 13, custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
						if effect_text:
							change_icon_size_override(4, Vector2(-11 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
						elif TranslationServer.get_locale() == "pl" and get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container/Text":
							change_icon_size_override(4, Vector2(-7 + custom_icon_offset.x + vi_mod.x, -6 + custom_icon_offset.y + vi_mod.y))
						elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
							change_icon_size_override(3, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
						elif i_spaced:
							change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
						elif e_spaced:
							change_icon_size_override(4, Vector2(2 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(4, Vector2(-7 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"0.625":
				if get_parent() is TextureButton:
					if raw_string.find("<icon_left>") != -1 or raw_string.find("<icon_right>") != -1:
						custom_icon_offset.x = -12
					elif raw_string == tr("reroll_pay") or raw_string == tr("removal_pay") or TranslationServer.get_locale() == "ko":
						custom_icon_offset.x = -6
					elif raw_string == "  <icon_deny>  ":
						custom_icon_offset.y = 12
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						change_icon_size_override(4, Vector2(-3 + custom_icon_offset.x + vi_mod.x, -8 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(4, Vector2(3 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(4, Vector2(4 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(5, Vector2(4 + custom_icon_offset.x + vi_mod.x, -16 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(4, Vector2(2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif TranslationServer.get_locale() == "ar" and (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums" or effect_text):
						change_icon_size_override(4, Vector2(-4 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if i_spaced:
						change_icon_size_override(4, Vector2(4 + custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y))
					elif effect_text:
						change_icon_size_override(4, Vector2(10 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
					elif str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(4, Vector2(10 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(4, Vector2(-8 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
						if TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "es_ES":
							change_icon_size_override(4, Vector2(-5 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(4, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(4, Vector2(5 + custom_icon_offset.x + vi_mod.x, 10 + custom_icon_offset.y + vi_mod.y))
				elif tooltip_desc:
					change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y))
				elif cjk:
					if effect_text:
						change_icon_size_override(4, Vector2(18 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
					elif str(get_path()).find("Mod Text") != -1:
						if TranslationServer.get_locale() == "ko":
							change_icon_size_override(4, Vector2(-6 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(4, Vector2(4 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, -3 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(4, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"0.75":
				if get_parent() is TextureButton:
					if raw_string == tr("reroll_pay") or raw_string == tr("removal_pay") or TranslationServer.get_locale() == "ko":
						custom_icon_offset.x = -5
					change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(5, Vector2(-1 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced and TranslationServer.get_locale() == "th":
						change_icon_size_override(5, Vector2(custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y))
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						change_icon_size_override(5, Vector2(-3 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif v_spaced:
						var size_num
						if get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Title":
							size_num = 4
						else:
							size_num = 5
						if TranslationServer.get_locale() == "ru" or TranslationServer.get_locale() == "th":
							change_icon_size_override(size_num, Vector2(-2 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(size_num, Vector2(-15 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
					elif str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(5, Vector2(-15 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(5, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
					elif str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(5, Vector2(8 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif cjk and (effect_text or raw_string == tr("dedication")):
					change_icon_size_override(4, Vector2(20 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				elif cjk and str(get_path()).find("Mod Text") != -1:
					if TranslationServer.get_locale() == "ko":
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif tooltip_desc:
					change_icon_size_override(5, Vector2(custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"0.875":
				if get_parent() is TextureButton:
					if TranslationServer.get_locale() == "ko":
						custom_icon_offset.x = -11
					elif raw_string == tr("reroll_pay") or raw_string == tr("removal_pay"):
						custom_icon_offset.x = -5
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						change_icon_size_override(5, Vector2(-4 + custom_icon_offset.x + vi_mod.x, -9 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(6, Vector2(2 + custom_icon_offset.x + vi_mod.x, 3 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if TranslationServer.get_locale() == "ar" and (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums"):
						change_icon_size_override(5, Vector2(-5 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
					elif str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(5, Vector2(12 + custom_icon_offset.x + vi_mod.x, 14 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						if TranslationServer.get_locale() == "th":
							change_icon_size_override(6, Vector2(4 + custom_icon_offset.x + vi_mod.x, -16 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(6, Vector2(4 + custom_icon_offset.x + vi_mod.x, -4 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(5, Vector2(2 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if str(get_path()).find("Mod Text") != -1:
						change_icon_size_override(6, Vector2(6 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(5, Vector2(4 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(5, Vector2(-9 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif tooltip_desc:
					change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y))
				elif cjk and (effect_text or raw_string == tr("dedication")):
					change_icon_size_override(5, Vector2(22 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
				elif cjk and str(get_path()).find("Mod Text") != -1:
					if TranslationServer.get_locale() == "ko":
						change_icon_size_override(6, Vector2(-14 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(6, Vector2(2 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1":
				if (raw_string == tr("removal_pay") or raw_string == tr("reroll_pay")) and TranslationServer.get_locale() == "th":
					change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, -3 + custom_icon_offset.y + vi_mod.y))
				elif get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, 7 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif v_spaced:
						var size_num
						if get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Title":
							size_num = 5
						else:
							size_num = 6
						if TranslationServer.get_locale() == "ru":
							change_icon_size_override(size_num, Vector2(-2 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(size_num, Vector2(-16 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						change_icon_size_override(6, Vector2(-2 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(6, Vector2(-16 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					change_icon_size_override(6, Vector2(-9 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and raw_string == tr("dedication"):
					change_icon_size_override(5, Vector2(-9 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and str(get_path()).find("Mod Text") != -1:
					if TranslationServer.get_locale() == "ko":
						change_icon_size_override(7, Vector2(-16 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif tooltip_desc:
					change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
				elif cjk and get_parent() is TextureButton:
					change_icon_size_override(7, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.125":
				if get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(6, Vector2(-8 + custom_icon_offset.x + vi_mod.x, -10 + custom_icon_offset.y + vi_mod.y))
				elif TranslationServer.get_locale() == "ko" and get_parent() is TextureButton:
					change_icon_size_override(8, Vector2(-12 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and raw_string == tr("reroll_pay"):
					change_icon_size_override(8, Vector2(-12 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if TranslationServer.get_locale() == "ar" and (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums"):
						change_icon_size_override(6, Vector2(-6 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(6, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					change_icon_size_override(6, Vector2(-11 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and (effect_text or raw_string == tr("dedication")):
					if effect_text:
						if str(get_path()).find("/Items") != -1:
							change_icon_size_override(6, Vector2(24 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(6, Vector2(34 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(6, Vector2(24 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				elif tooltip_desc:
					change_icon_size_override(8, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(8, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.25":
				if get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif TranslationServer.get_locale() == "ko" and get_parent() is TextureButton:
					change_icon_size_override(9, Vector2(-14 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and raw_string == tr("reroll_pay"):
					change_icon_size_override(9, Vector2(-12 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						if TranslationServer.get_locale() == "ar":
							change_icon_size_override(7, Vector2(-4 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(7, Vector2(7 + custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y))
					elif v_spaced:
						var size_num
						if get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Title":
							size_num = 6
						else:
							size_num = 7
						if TranslationServer.get_locale() == "ru":
							change_icon_size_override(size_num, Vector2(-2 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(size_num, Vector2(-18 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						change_icon_size_override(7, Vector2(-2 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(-18 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(7, Vector2(-12 + custom_icon_offset.x + vi_mod.x, 10 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(-12 + custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(7, Vector2(24 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(9, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.375":
				if get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(7, Vector2(-10 + custom_icon_offset.x + vi_mod.x, -11 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(7, Vector2(24 + custom_icon_offset.x + vi_mod.x, 13 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(7, Vector2(4 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
					elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
						change_icon_size_override(7, Vector2(6 + custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(14 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 16 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(7, Vector2(-12 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(-6 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(7, Vector2(36 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(10, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.5":
				if (raw_string == tr("removal_pay") or raw_string == tr("reroll_pay")) and TranslationServer.get_locale() == "th":
					change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 4 + custom_icon_offset.y + vi_mod.y))
				elif get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(7, Vector2(-10 + custom_icon_offset.x + vi_mod.x, -11 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						if TranslationServer.get_locale() == "ar":
							change_icon_size_override(7, Vector2(10 + custom_icon_offset.x + vi_mod.x, 13 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(7, Vector2(24 + custom_icon_offset.x + vi_mod.x, 13 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						if TranslationServer.get_locale() == "th":
							change_icon_size_override(7, Vector2(4 + custom_icon_offset.x + vi_mod.x, -22 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(7, Vector2(-4 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(-10 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 16 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(7, Vector2(custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(7, Vector2(-6 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(7, Vector2(40 + custom_icon_offset.x + vi_mod.x, 8 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(10, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.625":
				if get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(8, Vector2(-10 + custom_icon_offset.x + vi_mod.x, -12 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if TranslationServer.get_locale() == "ar" and (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums"):
						change_icon_size_override(8, Vector2(-5 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif effect_text:
						change_icon_size_override(8, Vector2(24 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(8, Vector2(4 + custom_icon_offset.x + vi_mod.x, -2 + custom_icon_offset.y + vi_mod.y))
					elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
						change_icon_size_override(8, Vector2(4 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(8, Vector2(12 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(8, Vector2(2 + custom_icon_offset.x + vi_mod.x, 18 + custom_icon_offset.y + vi_mod.y))
					elif e_spaced:
						change_icon_size_override(8, Vector2(-16 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(8, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				elif cjk:
					if effect_text:
						change_icon_size_override(8, Vector2(44 + custom_icon_offset.x + vi_mod.x, 10 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(8, Vector2(14 + custom_icon_offset.x + vi_mod.x, 22 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.75":
				if (raw_string == tr("removal_pay") or raw_string == tr("reroll_pay")) and TranslationServer.get_locale() == "th":
					change_icon_size_override(8, Vector2(custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				elif get_parent() is TextureButton and int($"/root/Main/Options Sprite/Options".display_font) > 0:
					change_icon_size_override(8, Vector2(-10 + custom_icon_offset.x + vi_mod.x, -12 + custom_icon_offset.y + vi_mod.y))
				elif cjk and raw_string == tr("removal_pay"):
					change_icon_size_override(8, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(8, Vector2(24 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						if TranslationServer.get_locale() == "th":
							change_icon_size_override(8, Vector2(8 + custom_icon_offset.x + vi_mod.x, -22 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(8, Vector2(-6 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
					elif get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Rent Container":
						change_icon_size_override(8, Vector2(custom_icon_offset.x + vi_mod.x, 5 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(8, Vector2(-16 + custom_icon_offset.x + vi_mod.x, 2 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(8, Vector2(2 + custom_icon_offset.x + vi_mod.x, 18 + custom_icon_offset.y + vi_mod.y))
					elif i_spaced:
						change_icon_size_override(8, Vector2(2 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(8, Vector2(-8 + custom_icon_offset.x + vi_mod.x, 6 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"1.875":
				if get_parent() is TextureButton and (int($"/root/Main/Options Sprite/Options".display_font) > 0 or cjk):
					change_icon_size_override(9, Vector2(-12 + custom_icon_offset.x + vi_mod.x, -13 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
					change_icon_size_override(9, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if e_spaced:
						change_icon_size_override(9, Vector2(-18 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
						change_icon_size_override(9, Vector2(-11 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(9, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk:
					if effect_text:
						change_icon_size_override(9, Vector2(50 + custom_icon_offset.x + vi_mod.x, 14 + custom_icon_offset.y + vi_mod.y))
					elif raw_string == tr("removal_pay"):
						change_icon_size_override(9, Vector2(-2 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(9, Vector2(14 + custom_icon_offset.x + vi_mod.x, 20 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(12, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2":
				if int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if TranslationServer.get_locale() == "ar" and (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums"):
						change_icon_size_override(10, Vector2(-4 + custom_icon_offset.x + vi_mod.x, -5 + custom_icon_offset.y + vi_mod.y))
					elif effect_text:
						if TranslationServer.get_locale() == "ar":
							change_icon_size_override(10, Vector2(custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(10, Vector2(12 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(10, Vector2(custom_icon_offset.x + vi_mod.x, 1 + custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(10, Vector2(-12 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					elif get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
						change_icon_size_override(10, Vector2(-12 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(10, Vector2(-20 + custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(10, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2.125":
				if int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(11, Vector2(24 + custom_icon_offset.x + vi_mod.x, 16 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(11, Vector2(-4 + custom_icon_offset.x + vi_mod.x, 24 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(11, Vector2(48 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2.25":
				if int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(11, Vector2(12 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(11, Vector2(-12 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(11, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2.375":
				if int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						change_icon_size_override(12, Vector2(30 + custom_icon_offset.x + vi_mod.x, 18 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(12, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(12, Vector2(-4 + custom_icon_offset.x + vi_mod.x, 20 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(12, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(12, Vector2(44 + custom_icon_offset.x + vi_mod.x, 12 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(12, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2.5", "2.625":
				if int($"/root/Main/Options Sprite/Options".display_font) == 1:
					if effect_text:
						if TranslationServer.get_locale() == "ar":
							change_icon_size_override(13, Vector2(16 + custom_icon_offset.x + vi_mod.x, 10 + custom_icon_offset.y + vi_mod.y))
						else:
							change_icon_size_override(13, Vector2(30 + custom_icon_offset.x + vi_mod.x, 18 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(13, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
					if effect_text:
						change_icon_size_override(13, Vector2(-4 + custom_icon_offset.x + vi_mod.x, 20 + custom_icon_offset.y + vi_mod.y))
					else:
						change_icon_size_override(13, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
				elif cjk and effect_text:
					change_icon_size_override(13, Vector2(54 + custom_icon_offset.x + vi_mod.x, 18 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(13, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"2.875", "3":
				if cjk and effect_text:
					change_icon_size_override(13, Vector2(86 + custom_icon_offset.x + vi_mod.x, 20 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(13, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
			"3.125":
				if cjk and effect_text:
					change_icon_size_override(14, Vector2(86 + custom_icon_offset.x + vi_mod.x, 20 + custom_icon_offset.y + vi_mod.y))
				else:
					change_icon_size_override(14, Vector2(custom_icon_offset.x + vi_mod.x, custom_icon_offset.y + vi_mod.y))
	else:
		var sc = int(round(current_scale * 4 + scale_mod))
		match sc:
			-1, -2, -3:
				if get_parent() is TextureButton:
					change_icon_size_override(1, Vector2(custom_icon_offset.x, 2 + custom_icon_offset.y))
				else:
					change_icon_size_override(1, Vector2(-3 + custom_icon_offset.x, -2 + custom_icon_offset.y))
			0:
				if get_parent() is TextureButton:
					if raw_string == tr("reroll_pay"):
						change_icon_size_override(2, Vector2(-4 + custom_icon_offset.x, -4 + custom_icon_offset.y))
					else:
						change_icon_size_override(1, Vector2(custom_icon_offset.x, 2 + custom_icon_offset.y))
				else:
					change_icon_size_override(1, Vector2(-3 + custom_icon_offset.x, -2 + custom_icon_offset.y))
			1:
				change_icon_size_override(2, Vector2(-8 + custom_icon_offset.x, -5 + custom_icon_offset.y))
			2:
				if get_parent() is TextureButton:
					if raw_string == tr("removal_pay"):
						change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
					elif raw_string == tr("reroll_pay") or get_parent().title_button:
						change_icon_size_override(3, Vector2(-4 + custom_icon_offset.x, -5 + custom_icon_offset.y))
					else:
						change_icon_size_override(2, Vector2(-2 + custom_icon_offset.x, -1 + custom_icon_offset.y))
				elif v_spaced:
					if get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Title":
						change_icon_size_override(1, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
					else:
						change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(1, Vector2(-2 + custom_icon_offset.x, -2 + custom_icon_offset.y))
				elif e_spaced:
					change_icon_size_override(2, Vector2(-2 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif effect_text:
					change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				else:
					change_icon_size_override(3, Vector2(-12 + custom_icon_offset.x, -12 + custom_icon_offset.y))
			3:
				if effect_text:
					change_icon_size_override(3, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif v_spaced:
					change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif get_path() == "/root/Main/Coins" or get_parent().get_path() == "/root/Main/Sums" or raw_string == tr("dedication"):
					change_icon_size_override(2, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				else:
					change_icon_size_override(3, Vector2(-6 + custom_icon_offset.x, -6 + custom_icon_offset.y))
			4:
				if TranslationServer.get_locale() == "ar" and raw_string == tr("dedication") and $"/root/Main/Options Sprite/Options".ui_scaling.text == 1 and $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1:
					change_icon_size_override(3, Vector2(20 + custom_icon_offset.x, -3 + custom_icon_offset.y))
				elif get_parent() is TextureButton:
					change_icon_size_override(3, Vector2(-3 + custom_icon_offset.x, custom_icon_offset.y))
				else:
					change_icon_size_override(3, Vector2(-3 + custom_icon_offset.x, -3 + custom_icon_offset.y))
			5:
				if (get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums") and (TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "es_ES" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "de"):
					change_icon_size_override(4, Vector2(-3 + custom_icon_offset.x, -6 + custom_icon_offset.y))
				else:
					change_icon_size_override(4, Vector2(-7 + custom_icon_offset.x, -6 + custom_icon_offset.y))
			6:
				if TranslationServer.get_locale() == "ar" and raw_string == tr("dedication"):
					change_icon_size_override(4, Vector2(24 + custom_icon_offset.x, -8 + custom_icon_offset.y))
				elif get_parent() is TextureButton:
					change_icon_size_override(4, Vector2(-6 + custom_icon_offset.x, -6 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(4, Vector2(2 + custom_icon_offset.x, -1 + custom_icon_offset.y))
				else:
					change_icon_size_override(4, Vector2(-4 + custom_icon_offset.x, -6 + custom_icon_offset.y))
			7:
				if get_parent() is TextureButton:
					change_icon_size_override(5, Vector2(-6 + custom_icon_offset.x, -6 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(5, Vector2(custom_icon_offset.x, -2 + custom_icon_offset.y))
				elif raw_string == tr("dedication"):
					if TranslationServer.get_locale() == "ar":
						change_icon_size_override(4, Vector2(36 + custom_icon_offset.x, -8 + custom_icon_offset.y))
					elif $"/root/Main/Options Sprite/Options".ui_scaling.text < 2:
						change_icon_size_override(4, Vector2(-8 + custom_icon_offset.x, -8 + custom_icon_offset.y))
					else:
						change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x, -8 + custom_icon_offset.y))
				else:
					change_icon_size_override(5, Vector2(-8 + custom_icon_offset.x, -8 + custom_icon_offset.y))
			8:
				if get_parent() is TextureButton:
					change_icon_size_override(5, Vector2(-10 + custom_icon_offset.x, -6 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(5, Vector2(10 + custom_icon_offset.x, 2 + custom_icon_offset.y))
				else:
					change_icon_size_override(5, Vector2(-5 + custom_icon_offset.x, -6 + custom_icon_offset.y))
			9:
				if str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(6, Vector2(8 + custom_icon_offset.x, 2 + custom_icon_offset.y))
				else:
					change_icon_size_override(6, Vector2(-7 + custom_icon_offset.x, -9 + custom_icon_offset.y))
			10:
				if get_parent() is TextureButton:
					change_icon_size_override(6, Vector2(-12 + custom_icon_offset.x, -10 + custom_icon_offset.y))
				elif str(get_path()).find("Mod Text") != -1:
					change_icon_size_override(8, Vector2(-12 + custom_icon_offset.x, -12 + custom_icon_offset.y))
				else:
					change_icon_size_override(6, Vector2(-7 + custom_icon_offset.x, -9 + custom_icon_offset.y))
			11:
				if get_path() == "/root/Main/Coins" or effect_text or get_parent().get_path() == "/root/Main/Sums":
					change_icon_size_override(7, Vector2(-8 + custom_icon_offset.x, -8 + custom_icon_offset.y))
				else:
					change_icon_size_override(7, Vector2(-8 + custom_icon_offset.x, -12 + custom_icon_offset.y))
			12:
				if get_parent() is TextureButton:
					change_icon_size_override(7, Vector2(-17 + custom_icon_offset.x, -14 + custom_icon_offset.y))
				else:
					change_icon_size_override(7, Vector2(-8 + custom_icon_offset.x, -12 + custom_icon_offset.y))
			13:
				change_icon_size_override(8, Vector2(-8 + custom_icon_offset.x, -13 + custom_icon_offset.y))
			14:
				if get_parent() is TextureButton:
					change_icon_size_override(8, Vector2(-20 + custom_icon_offset.x, -13 + custom_icon_offset.y))
				else:
					change_icon_size_override(8, Vector2(-8 + custom_icon_offset.x, -13 + custom_icon_offset.y))
			15:
				change_icon_size_override(9, Vector2(-10 + custom_icon_offset.x, -14 + custom_icon_offset.y))
			16:
				if get_parent() is TextureButton:
					change_icon_size_override(9, Vector2(-22 + custom_icon_offset.x, -16 + custom_icon_offset.y))
				else:
					change_icon_size_override(9, Vector2(-6 + custom_icon_offset.x, -12 + custom_icon_offset.y))
			17, 18:
				change_icon_size_override(10, Vector2(-12 + custom_icon_offset.x, -12 + custom_icon_offset.y))
		if sc >= 19:
			change_icon_size_override(12, Vector2(-2 + custom_icon_offset.x, -8 + custom_icon_offset.y))

func change_set_size(n):
	set_font()
	if (forced_font != null and forced_font.get_path() == "res://NotoSans_Resize.tres") or get_child(0).get_font("font").get_path() == "res://NotoSans_Resize.tres":
		base_scale = 0.5
		saved_scale = 0.5
	force_size_change = false
	var sc
	var o_sc
	if get_parent() is TextureButton or dont_scale:
		o_sc = 1.0
	else:
		o_sc = $"/root/Main/Options Sprite/Options".ui_scaling.text
	if (cjk or (forced_font != null and forced_font.get_path() != "res://Title_Font.tres") or int($"/root/Main/Options Sprite/Options".display_font) > 0) and not forced_pico:
		sc = n - (0.5 - o_sc / 2.0) + text_mod * 0.125
	else:
		sc = n - (1.0 - o_sc) + text_mod * 0.25
	if sc <= 0 and get_path() != "/root/Main/Title/Background/Title Text" and get_path() != "/root/Main/Title/Background/Title Text 2":
		if (cjk or int($"/root/Main/Options Sprite/Options".display_font) > 0) and not forced_pico:
			sc = 0.125
		else:
			sc = 0.25
	if TranslationServer.get_locale() == "th" and get_parent() is TextureButton:
		base_scale -= 0.125
		saved_scale -= 0.125
		sc -= 0.125
	current_scale = sc
	forced_font_size = sc
	if get_parent() is TextureButton and (not get_parent().dont_scale or (cjk and get_parent().get_parent().get_parent().get_path() == "/root/Main/Menus/Buttons")):
		if cjk:
			if $"/root/Main/Options Sprite/Options".ui_scaling.buttons <= 1:
				scale_mod = -floor((1 - get_parent().current_scale) / 0.25)
			elif $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 1.25:
				scale_mod = -1 + -floor((1 - get_parent().current_scale) / 0.25)
			elif $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 1.5:
				scale_mod = -2 + -floor((1 - get_parent().current_scale) / 0.25)
			elif $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 1.75:
				scale_mod = -3 + -floor((1 - get_parent().current_scale) / 0.25)
			elif $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 2:
				scale_mod = -4 + -floor((1 - get_parent().current_scale) / 0.25)
		else:
			scale_mod = -floor((1 - get_parent().current_scale) / 0.25)
		if get_parent().get_parent().get_path() == "/root/Main/Menus/Buttons" or (cjk and get_parent().get_parent().get_parent().get_path() == "/root/Main/Menus/Buttons"):
			if cjk:
				if $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 1:
					custom_icon_offset = Vector2(0, -5)
				elif $"/root/Main/Options Sprite/Options".ui_scaling.buttons >= 1.25:
					custom_icon_offset = Vector2(0, -4)
				else:
					custom_icon_offset = Vector2(0, 0)
			else:
				if $"/root/Main/Options Sprite/Options".ui_scaling.buttons >= 1:
					custom_icon_offset = Vector2(0, -4)
				else:
					custom_icon_offset = Vector2(0, 0)
			scale_mod += 2
		elif cjk:
			if $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 0.75:
				scale_mod = 1
				custom_icon_offset = Vector2(4, -7)
	if overwrite_scale:
		overwrite_scale = false
		saved_scale = sc
	if not line_update:
		size_update = true
	set_icon_size()

func set_font():
	if not font_set and (cjk or (forced_font != null and forced_font.get_path() != "res://Title_Font.tres")):
		font_set = true
		if forced_font == null and not forced_pico:
			if TranslationServer.get_locale() == "zh":
				get_child(0).add_font_override("font", preload("res://NotoSansSC_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "zh_TW":
				get_child(0).add_font_override("font", preload("res://NotoSansTC_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "ko":
				get_child(0).add_font_override("font", preload("res://NotoSansKR_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "ja":
				get_child(0).add_font_override("font", preload("res://NotoSansJP_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "ar" and int($"/root/Main/Options Sprite/Options".display_font) == 1:
				get_child(0).add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "hi":
				get_child(0).add_font_override("font", preload("res://NotoSans_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			elif TranslationServer.get_locale() == "th":
				get_child(0).add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
		else:
			get_child(0).add_font_override("font", forced_font)
			if get_parent() is TextureButton:
				get_child(0).add_color_override("font_color", Color(255,255,255))
			else:
				get_child(0).add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
			current_scale = 0.5
			base_scale = 0.5
			change_font_size(0, false)
	elif forced_font == null and not forced_pico:
		get_child(0).border_text = false
		match int($"/root/Main/Options Sprite/Options".display_font):
			1:
				if TranslationServer.get_locale() == "ar":
					if not i_spaced:
						get_child(0).add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
					if get_parent() is TextureButton:
						get_child(0).add_color_override("font_color", Color(255,255,255))
					else:
						get_child(0).add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
				elif TranslationServer.get_locale() == "zh":
					get_child(0).add_font_override("font", preload("res://NotoSansSC_Resize.tres"))
				elif TranslationServer.get_locale() == "zh_TW":
					get_child(0).add_font_override("font", preload("res://NotoSansTC_Resize.tres"))
				elif TranslationServer.get_locale() == "ko":
					get_child(0).add_font_override("font", preload("res://NotoSansKR_Resize.tres"))
				elif TranslationServer.get_locale() == "ja":
					get_child(0).add_font_override("font", preload("res://NotoSansJP_Resize.tres"))
				elif TranslationServer.get_locale() == "th":
					get_child(0).add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
				elif not i_spaced:
					get_child(0).add_font_override("font", preload("res://NotoSans_Resize.tres"))
				if get_parent() is TextureButton:
					get_child(0).add_color_override("font_color", Color(255,255,255))
				else:
					get_child(0).add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)
			2:
				if not i_spaced:
					get_child(0).add_font_override("font", preload("res://OpenDyslexic_Resize.tres"))
				if get_parent() is TextureButton:
					get_child(0).add_color_override("font_color", Color(255,255,255))
				else:
					get_child(0).add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
				current_scale = 0.5
				base_scale = 0.5
				change_font_size(0, false)

func change_font_size(s, do_update):
	size_update = false
	if forced_font == null and TranslationServer.get_locale() == "zh":
		add_font_override("font", preload("res://NotoSansSC_Resize.tres"))
	elif forced_font == null and (TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK"):
		add_font_override("font", preload("res://NotoSansTC_Resize.tres"))
	elif forced_font == null and TranslationServer.get_locale() == "ko":
		add_font_override("font", preload("res://NotoSansKR_Resize.tres"))
	elif forced_font == null and TranslationServer.get_locale() == "ja":
		add_font_override("font", preload("res://NotoSansJP_Resize.tres"))
	elif forced_font == null and TranslationServer.get_locale() == "ar" and int($"/root/Main/Options Sprite/Options".display_font) > 0 and not forced_pico:
		add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
	elif forced_font == null and (TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "hi"):
		add_font_override("font", preload("res://NotoSans_Resize.tres"))
	elif forced_font == null and TranslationServer.get_locale() == "th":
		add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
	elif (forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0) or forced_pico:
		update_border()
	elif forced_font != null and forced_font.get_path() != "res://PICO-8.tres" and forced_font.get_path() != "res://PICO-8_Tooltips.tres" and forced_font.get_path() != "res://Title_Font.tres":
		add_color_override("font_color", Color(0,0,0,0))
		if get_child(0) != null:
			get_child(0).add_font_override("font", forced_font)
			get_child(0).rect_scale = Vector2(current_scale, current_scale)
	if forced_font_size != -1:
		current_scale = forced_font_size
	if cjk or (forced_font != null and forced_font.get_path() != "res://Title_Font.tres"):
		if get_child(0) != null:
			get_child(0).rect_scale = Vector2(current_scale, current_scale)
	elif forced_font != null and forced_font.get_path() == "res://Title_Font.tres":
		rect_scale = Vector2(current_scale, current_scale)
	elif (forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0) or forced_pico:
		for t in texts:
			t.rect_scale = Vector2(current_scale * 4.0, current_scale * 4.0)
			t.align = align
	if do_update:
		update()

func update():
	if TranslationServer.get_locale() == "ar" and rtl:
		if need_to_left and base_x == 0 and rect_position.x != 0 and offset_x == 0:
			base_x = rect_position.x
			if str(get_path()).find("/Main/Pop-up Sprite/Pop-up/Container/Text") != -1:
				pass
		for t in texts:
			if not is_instance_valid(t):
				break
			elif t.rect_size.x != 0:
				t.rect_size.x = 0
		if rect_size.x != 0:
			rect_size.x = 0
		if get_child(0).rect_size.x != 0:
			get_child(0).rect_size.x = 0
	var s_raw = raw_string
	if (raw_string != saved_text or force_update or size_update or line_update) and is_inside_tree() and not off_screen:
		if raw_string.length() != saved_text.length() or force_update or size_update:
			remove_icons(true)
		else:
			remove_icons(false)
		if size_update:
			change_font_size(0, false)
		if not get_parent() is TextureButton:
			if (not ($"/root/Main/Options Sprite/Options".CJK_lang or $"/root/Main/Options Sprite/Options".display_font > 0) or (forced_font != null and forced_font.get_path() == "res://Title_Font.tres")) and texts.size() > 7:
				texts[8].add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
			else:
				get_child(0).add_color_override("font_color", $"/root/Main/Options Sprite/Options".colors3["text_color_misc"])
		var text_str
		if texts.size() > 0 and (not forced_font or forced_font.get_path() == "res://PICO-8.tres" or forced_font.get_path() == "res://Title_Font.tres"):
			if v_spaced and texts[8].get_font("font").get_path() != "res://PICO-8_Tooltips.tres":
				add_font_override("font", preload("res://PICO-8_Tooltips.tres"))
				for t in texts:
					t.add_font_override("font", preload("res://PICO-8_Tooltips.tres"))
				texts[8].v_spaced = v_spaced
			elif e_spaced and texts[8].get_font("font").get_path() != "res://PICO-8_Emails.tres":
				add_font_override("font", preload("res://PICO-8_Emails.tres"))
				for t in texts:
					t.add_font_override("font", preload("res://PICO-8_Emails.tres"))
				texts[8].e_spaced = e_spaced
			elif i_spaced and texts[8].get_font("font").get_path() != "res://PICO-8_Inventory.tres":
				add_font_override("font", preload("res://PICO-8_Inventory.tres"))
				for t in texts:
					t.add_font_override("font", preload("res://PICO-8_Inventory.tres"))
				texts[8].i_spaced = i_spaced
			texts[8].values = values
			texts[8].dynamic_icons = dynamic_icons
			if rtl:
				var alphabet = "ابجدهوزحطيكلمنسعفصقرشتثخذضظغ"
				for a in range(alphabet.length()):
					if raw_string.find(alphabet[a]) != -1:
						raw_string = "\u200F" + raw_string + "\u200F"
						break
			texts[8].text = raw_string
			texts[8].raw_string = raw_string
			if get_parent() is TextureButton and get_parent().title_button:
				texts[8].icon_z_index = icon_z_index
			texts[8].tts = tts
			if rtl and raw_string.find("\u200F") != -1:
				texts[8].just_adding_linebreaks = true
				texts[8].check_locale()
				texts[8].just_adding_linebreaks = false
				texts[8].not_counting_tags = true
				texts[8].check_locale()
				texts[8].not_counting_tags = false
				texts[8].display()
				while texts[8].text.find("؏") != -1:
					var first_one = texts[8].text.find("؏")
					texts[8].text[texts[8].text.find("؏")] = ""
					var last_one = texts[8].text.find("؏")
					texts[8].text[texts[8].text.find("؏")] = ""
					var num = int(texts[8].text.substr(first_one, last_one - first_one))
					texts[8].text = texts[8].text.substr(0, first_one) + texts[8].tags[num] + texts[8].text.substr(last_one, -1)
				while texts[8].text.find("؈") != -1:
					var first_one = texts[8].text.find("؈")
					texts[8].text[texts[8].text.find("؈")] = ""
					var last_one = texts[8].text.find("؈")
					texts[8].text[texts[8].text.find("؈")] = ""
					var num = int(texts[8].text.substr(first_one, last_one - first_one))
					texts[8].text = texts[8].text.substr(0, first_one) + texts[8].tags[num] + texts[8].text.substr(last_one, -1)
				while texts[8].text.find("ڼ") != -1:
					var first_one = texts[8].text.find("ڼ")
					texts[8].text[texts[8].text.find("ڼ")] = ""
					var last_one = texts[8].text.find("ڼ")
					texts[8].text[texts[8].text.find("ڼ")] = ""
					var num = int(texts[8].text.substr(first_one, last_one - first_one))
					texts[8].text = texts[8].text.substr(0, first_one) + texts[8].tags[num] + texts[8].text.substr(last_one, -1)
				while texts[8].text.find("|") != -1:
					var first_one = texts[8].text.find("|")
					texts[8].text[texts[8].text.find("|")] = ""
					var last_one = texts[8].text.find("|")
					texts[8].text[texts[8].text.find("|")] = ""
					var num = int(texts[8].text.substr(first_one, last_one - first_one))
					texts[8].text = texts[8].text.substr(0, first_one) + texts[8].tags[num] + texts[8].text.substr(last_one, -1)
				texts[8].tags.clear()
				texts[8].check_locale()
			else:
				texts[8].not_counting_tags = true
				texts[8].check_locale()
			texts[8].e_spaced = false
			texts[8].i_spaced = false
			text_str = texts[8].text
			for i in texts[8].icons:
				if i.type == "coin":
					i.active = coin_icons_active
			for t in texts:
				if t == null:
					continue
				t.rtl = rtl
				t.values = values
				t.dynamic_icons = dynamic_icons
				t.raw_string = raw_string
				t.text = texts[8].text
			text = texts[8].text
			raw_string = s_raw
		else:
			if texts.size() > 0 and texts[8] != null:
				for t in range(1, 9):
					if is_instance_valid(texts[t]):
						remove_child(texts[t])
						texts[t].queue_free()
			if i_spaced and int($"/root/Main/Options Sprite/Options".display_font) == 1 and get_child(0).get_font("font").get_path() != "res://NotoSans_Inventory.tres":
				get_child(0).add_font_override("font", preload("res://NotoSans_Inventory.tres"))
				get_child(0).i_spaced = i_spaced
			elif i_spaced and int($"/root/Main/Options Sprite/Options".display_font) == 2 and get_child(0).get_font("font").get_path() != "res://OpenDyslexic_Inventory.tres":
				get_child(0).add_font_override("font", preload("res://OpenDyslexic_Inventory.tres"))
				get_child(0).i_spaced = i_spaced
			get_child(0).rtl = rtl
			get_child(0).values = values
			get_child(0).dynamic_icons = dynamic_icons
			if rtl:
				var alphabet = "ابجدهوزحطيكلمنسعفصقرشتثخذضظغ"
				for a in range(alphabet.length()):
					if raw_string.find(alphabet[a]) != -1:
						raw_string = "\u200F" + raw_string + "\u200F"
						break
			get_child(0).text = raw_string
			get_child(0).raw_string = raw_string
			get_child(0).rect_scale = Vector2(current_scale, current_scale)
			get_child(0).icon_z_index = icon_z_index
			get_child(0).diff_cjk_space = diff_cjk_space
			get_child(0).align = align
			get_child(0).tts = tts
			set_font()
			if rtl and raw_string.find("\u200F") != -1:
				get_child(0).just_adding_linebreaks = true
				get_child(0).check_locale()
				get_child(0).just_adding_linebreaks = false
				get_child(0).not_counting_tags = true
				get_child(0).check_locale()
				get_child(0).not_counting_tags = false
				get_child(0).display()
				while get_child(0).text.find("؏") != -1:
					var first_one = get_child(0).text.find("؏")
					get_child(0).text[get_child(0).text.find("؏")] = ""
					var last_one = get_child(0).text.find("؏")
					get_child(0).text[get_child(0).text.find("؏")] = ""
					var num = int(get_child(0).text.substr(first_one, last_one - first_one))
					get_child(0).text = get_child(0).text.substr(0, first_one) + get_child(0).tags[num] + get_child(0).text.substr(last_one, -1)
				while get_child(0).text.find("؈") != -1:
					var first_one = get_child(0).text.find("؈")
					get_child(0).text[get_child(0).text.find("؈")] = ""
					var last_one = get_child(0).text.find("؈")
					get_child(0).text[get_child(0).text.find("؈")] = ""
					var num = int(get_child(0).text.substr(first_one, last_one - first_one))
					get_child(0).text = get_child(0).text.substr(0, first_one) + get_child(0).tags[num] + get_child(0).text.substr(last_one, -1)
				while get_child(0).text.find("ڼ") != -1:
					var first_one = get_child(0).text.find("ڼ")
					get_child(0).text[get_child(0).text.find("ڼ")] = ""
					var last_one = get_child(0).text.find("ڼ")
					get_child(0).text[get_child(0).text.find("ڼ")] = ""
					var num = int(get_child(0).text.substr(first_one, last_one - first_one))
					get_child(0).text = get_child(0).text.substr(0, first_one) + get_child(0).tags[num] + get_child(0).text.substr(last_one, -1)
				while get_child(0).text.find("|") != -1:
					var first_one = get_child(0).text.find("|")
					get_child(0).text[get_child(0).text.find("|")] = ""
					var last_one = get_child(0).text.find("|")
					get_child(0).text[get_child(0).text.find("|")] = ""
					var num = int(get_child(0).text.substr(first_one, last_one - first_one))
					get_child(0).text = get_child(0).text.substr(0, first_one) + get_child(0).tags[num] + get_child(0).text.substr(last_one, -1)
				get_child(0).tags.clear()
				get_child(0).check_locale()
			else:
				get_child(0).not_counting_tags = true
				get_child(0).check_locale()
			get_child(0).rect_size = rect_size
			text_str = get_child(0).text
			for i in icons:
				if i.type == "coin":
					i.active = coin_icons_active
			raw_string = s_raw
		if cjk or forced_font != null or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			if line_update or raw_string.length() != saved_text.length():
				saved_line_count = get_child(0).get_line_count()
				line_update = false
				if not get_parent() is TextureButton:
					change_set_size(base_scale)
			saved_text = get_child(0).raw_string
		else:
			if (line_update or raw_string.length() != saved_text.length()) and texts.size() > 0:
				saved_line_count = texts[8].get_line_count()
				line_update = false
				if not get_parent() is TextureButton:
					change_set_size(base_scale)
			saved_text = raw_string
		force_update = false
		if get_parent().has_method("update_size"):
			get_parent().update_size()
		saved_value_texts.clear()
		saved_pb_texts.clear()
		saved_pm_texts.clear()
		var font = get_font("font")
		if saved_scale != current_scale:
			var font_mod
			if cjk or forced_font != null:
				font_mod = 1.0
			else:
				font_mod = 4.0
			if alignment_tags.v_centered:
				rect_position.y += font.get_height() * saved_scale * font_mod * saved_line_count / 2.0 - font.get_height() * current_scale * font_mod * saved_line_count / 2.0
			elif alignment_tags.bottom:
				rect_position.y += font.get_height() * saved_scale * font_mod * saved_line_count - font.get_height() * current_scale * font_mod * saved_line_count
			if alignment_tags.centered:
				rect_position.x += font.get_string_size(text_str).x / 2 * saved_scale * font_mod - font.get_string_size(text_str).x / 2 * current_scale * font_mod
			elif alignment_tags.right:
				rect_position.x += font.get_string_size(text_str).x * saved_scale * font_mod - font.get_string_size(text_str).x * current_scale * font_mod
			saved_scale = current_scale
		if need_to_center:
			rect_position.x = get_parent().rect_size.x / 2 - font.get_string_size(raw_string).x * rect_scale.x
			need_to_center = false
		elif need_to_left and rtl:
			rect_position.x = base_x + offset_x
		saved_text = s_raw
