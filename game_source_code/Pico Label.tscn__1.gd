extends "res://addons/arabic-text/ALabel.gd"

var cant_start_line_zh = "!%),.:;?]}¢°·\'\"\"†‡›℃∶、。〃〆〕〗〞﹚﹜！＂％＇），．：；？！］｝～"
var cant_end_line_zh = "$(£¥·\'\"〈《「『【〔〖〝﹙﹛＄（．［｛￡￥"
var cant_break_line_zh = "-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,\u2003\u3000"

var cant_start_line_tc = "!),.:;?]}¢·–—'\"•、。〆〞〕〉》」︰︱︲︳﹐﹑﹒﹓﹔﹕﹖﹘﹚﹜！），．：；？︶︸︺︼︾﹀﹂﹗］｜｝､"
var cant_end_line_tc = "([{£¥\'\"‵〈《「『〔〝︴﹙﹛（｛︵︷︹︻︽︿﹁﹃﹏"

var cant_start_line_ja = ")]｝〕〉》」』】〙〗〟\'\"｠»ヽヾーァィゥェォッャュョヮヵヶぁぃぅぇぉっゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ々〻‐゠–〜?!‼⁇⁈⁉・、:;,。.%"
var cant_end_line_ja = "([｛〔〈《「『【〘〖〝\'\"｟«"
var cant_break_line_ja = "-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ—...‥〳〴〵,\u00A0"

var cant_start_line_th = "!%),.:;?]}¢°·\'\"\"†‡›℃∶、。〃〆〕〗〞﹚﹜！＂％＇），．：；？！］｝～ "

var cant_break_line_ar = "-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ—؏?\"|ڼ"

var icons = []
var icon_positions = []
var colors = []
var color_texts = []
var color_positions = []
var extra_color_texts = []
var values = [0, 0, 0, 0]
var dynamic_icons = []
var border_text = false
var icon_z_index
var forced_font
var custom_max_width
var icon_scale_override = 0
var can_display_decimals = true

var raw_string = ""
var cut_characters = 0
var saved_value_texts = []
var saved_pb_texts = []
var saved_pm_texts = []

var icon_offset = Vector2(0, 0)
var item_icon_offset = Vector2(0, 0)
var cjk = true
var ff_override = false
var v_spaced = false
var e_spaced = false
var i_spaced = false
var cjk_space = "\u200A"
var diff_cjk_space = false
var dynamic_icons_num = 0
var fine_print_icon_pos = -1
var tts = false
var rtl = false

var just_adding_linebreaks = false
var not_counting_tags = false
var tags = []

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
	if forced_font == null:
		if TranslationServer.get_locale() == "zh":
			add_font_override("font", preload("res://NotoSansSC_Resize.tres"))
		elif TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK":
			add_font_override("font", preload("res://NotoSansTC_Resize.tres"))
		elif TranslationServer.get_locale() == "ko":
			add_font_override("font", preload("res://NotoSansKR_Resize.tres"))
		elif TranslationServer.get_locale() == "ja":
			add_font_override("font", preload("res://NotoSansJP_Resize.tres"))
		elif TranslationServer.get_locale() == "vi" or TranslationServer.get_locale() == "hi":
			add_font_override("font", preload("res://NotoSans_Resize.tres"))
		elif TranslationServer.get_locale() == "th":
			add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
		elif not v_spaced and not e_spaced and not i_spaced:
			add_font_override("font", preload("res://PICO-8.tres"))
	if TranslationServer.get_locale() == "ar":
		rtl = true

func _ready():
	if TranslationServer.get_locale() != "zh" and TranslationServer.get_locale() != "zh_TW" and TranslationServer.get_locale() != "zh_HK" and TranslationServer.get_locale() != "ko" and TranslationServer.get_locale() != "ja":
		cjk = false
	
	if TranslationServer.get_locale() == "ar" and rtl:
		align = Label.ALIGN_RIGHT

func update_positions_on_insert(i):
	for icon_pos in range(icon_positions.size()):
		if icon_positions[icon_pos] >= i:
			icon_positions[icon_pos] += 1
	for icon_pos in range(color_positions.size()):
		if color_positions[icon_pos] >= i:
			color_positions[icon_pos] += 1

func change_icon_size_override(size, i_offset):
	var t
	if not cjk and forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0:
		if get_parent().get_node(get_path()).texts.size() > 0:
			t = get_parent().get_node(get_path()).texts[8]
			t.icon_scale_override = size
	else:
		t = self
		get_child(0).icon_scale_override = size
	if i_offset == null:
		match size:
			3:
				if cjk or forced_font != null:
					t.icon_offset = Vector2(2, 6)
				else:
					t.icon_offset = Vector2(2, -2)
			4:
				if cjk or forced_font != null:
					t.icon_offset = Vector2(2, -1)
				else:
					t.icon_offset = Vector2(-6, -6)
	elif not cjk and forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0:
		if t != null:
			t.icon_offset = i_offset
	else:
		get_child(0).icon_offset = i_offset

func parse_num_str(st):
	var num = float(st)
	var new_str = st
	var decimal_location = 0
	var decimal_pos = 0
	if ((get_path() != "/root/Main/Coins" and (num > 9999 or num < -9999)) or ((num > 999999999 or num < -99999999) and get_path() == "/root/Main/Coins")) and $"/root/Main/Options Sprite/Options".scientific_notation and raw_string != tr("guillotine_essence_desc"):
		var divnum
		if num < 0:
			divnum = -float(st.substr(1, 2)) / 10
			new_str = str(divnum) + "e" + str(st.length() - 2)
		else:
			divnum = float(st.substr(0, 2)) / 10
			new_str = str(divnum) + "e" + str(st.length() - 1)
	for s in range(new_str.length()):
		if new_str[new_str.length() - s - 1] == ".":
			new_str[new_str.length() - s - 1] = tr("decimal_separator")
			decimal_location = new_str.length() - s - 2
			decimal_pos = s
			break
	if ((get_path() != "/root/Main/Coins" and (num <= 9999 and num >= -9999)) or ((num <= 999999999 and num >= -99999999) and get_path() == "/root/Main/Coins")) or not $"/root/Main/Options Sprite/Options".scientific_notation or raw_string == tr("guillotine_essence_desc"):
		if $"/root/Main/Options Sprite/Options".digit_separators:
			var b = 0
			if decimal_pos != 0:
				b -= 1
			for s in range(1 + decimal_pos, st.length()):
				b += 1
				if b % int(tr("big_number_separator_interval")) == 0 and new_str[st.length() - b - decimal_location - 1] != "-" and s > decimal_pos + 1 and b != 0:
					new_str = new_str.insert(st.length() - s, tr("big_number_separator"))
	var n_str = ""
	if not can_display_decimals and not $"/root/Main/Options Sprite/Options".scientific_notation:
		for c in new_str:
			if c == tr("decimal_separator"):
				break
			else:
				n_str += c
	else:
		n_str = new_str
	return n_str

func check_locale():
	var string_width = 0
	var start = 0
	var i = 0
	var escape_string = ""
	var match_string = ""
	var max_width = 992
	if custom_max_width != null:
		max_width = custom_max_width
	else:
		if get_parent().has_method("remove_icons") and not ff_override and forced_font == null and get_parent().forced_font != null:
			forced_font = get_parent().forced_font
			ff_override = true
		var parent = get_parent().get_parent()
		if parent.get("rect_size") != null:
			if parent.has_method("update_size"):
				parent.update_size()
			if parent.get_path() == "/root/Main/Tooltips/Tooltip/Card/Background":
				max_width = parent.rect_size.x - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.tooltips - 1
			elif parent.get_parent().get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container" and str(parent.get_path()).substr(str(parent.get_path()).length() - 11, -1) == "/Background":
				max_width = parent.rect_size.x - 16 * $"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections - 1
			else:
				max_width = parent.rect_size.x - 16 - 1
		if max_width < 138:
			max_width = 138
	var parent = get_parent()
	var color_tag = ""
	var end_tag = ""
	var reached_end = false
	for t in range(tags.size()):
		if tags[t][1] == "e":
			end_tag = "ڼ" + str(t) + "ڼ"
			break
	dynamic_icons_num = 0
	var loop_mod = 1
	var inserted_end_tag = 0
	var color_tag_diff = 0
	var last_number_pos = -1
	var last_icon_pos = -1
	if TranslationServer.get_locale() == "th" and forced_font == null:
		loop_mod = 0
	while i < text.length() - loop_mod:
		if text[i] == "฿":
			text[i] = "\u200B"
		elif TranslationServer.get_locale() == "ar" and text[i] == "|" and not_counting_tags and not just_adding_linebreaks:
			last_number_pos = i
			var o_num = 1
			while text[i + o_num] != "|":
				o_num += 1
			if tags[int(text.substr(i, o_num))].find("value_") != -1:
				var num = str(tags[int(text.substr(i, o_num))].substr(7, -1))
				string_width += get_font("font").get_string_size(str(values[int(num.substr(0, num.length() - 1)) - 1])).x * rect_scale.x * parent.rect_scale.x
			i += o_num
		elif text[i] == "؏" and not_counting_tags and not just_adding_linebreaks:
			last_icon_pos = i
			var o_num = 1
			while text[i + o_num] != "؏":
				o_num += 1
			if tags[int(text.substr(i, o_num))].find("icon_") != -1:
				match int($"/root/Main/Options Sprite/Options".display_font):
					0:
						string_width += get_font("font").get_string_size("\u2009 ").x * rect_scale.x * parent.rect_scale.x
					1:
						string_width += get_font("font").get_string_size("\u2009   ").x * rect_scale.x * parent.rect_scale.x
					2:
						string_width += get_font("font").get_string_size("\u2009 ").x * rect_scale.x * parent.rect_scale.x
			i += o_num
		elif text[i] == "؈" and not_counting_tags and not just_adding_linebreaks:
			var o_num = 1
			while text[i + o_num] != "؈":
				o_num += 1
			if rtl:
				color_tag_diff += 2
				if inserted_end_tag == 0:
					color_tag = text.substr(i, o_num) + "؈"
			i += o_num
		elif text[i] == "ڼ" and not_counting_tags and not just_adding_linebreaks:
			var o_num = 1
			while text[i + o_num] != "ڼ":
				o_num += 1
			if rtl:
				color_tag_diff -= 2
				end_tag = text.substr(i, o_num) + "ڼ"
			i += o_num
			if rtl and inserted_end_tag != 0 and i + 1 < text.length():
				reached_end = true
		elif text[i] == "<":
			start = i
			match_string += text[i]
			text = text.substr(0, i) + text.substr(i + 1, -1)
			while text.length() > 0:
				escape_string += text[i]
				match_string += text[i]
				text = text.substr(0, i) + text.substr(i + 1, -1)
				if text[i] == ">":
					break
			var dont_remove = false
			
			if raw_string.substr(i + cut_characters, match_string.length()) == match_string:
				dont_remove = true
			parse_escape(escape_string, i, start, dont_remove)
			cut_characters += match_string.length()
			match_string = ""
			escape_string = ""
			i -= 1
		elif text[i] == "\n":
			if not_counting_tags and not just_adding_linebreaks:
				if abs(color_tag_diff) >= 2 and inserted_end_tag == 0:
					text = text.insert(i, end_tag)
					inserted_end_tag += 1
					reached_end = false
					i += end_tag.length()
					color_tag_diff = 0
				elif inserted_end_tag == 1:
					if not reached_end:
						text = text.insert(i, end_tag)
						i += end_tag.length()
					text = text.insert(text.substr(0, i - 1).find_last("\n") + 1, color_tag)
					inserted_end_tag = 0
					i += color_tag.length()
					color_tag_diff = 0
					if not reached_end:
						color_tag_diff = 2
						inserted_end_tag = 1
			string_width = 0
		else:
			string_width += get_font("font").get_string_size(text[i]).x * rect_scale.x * parent.rect_scale.x
		var saved_i = 0
		if string_width >= max_width and not just_adding_linebreaks:
			saved_i = i
			if (TranslationServer.get_locale() == "zh" and forced_font == null) or (forced_font != null and forced_font.font_data.font_path == "res://NotoSansSC-Regular.otf"):
				var insert_flag = false
				while i > 0:
					var can_insert = true
					for c in range(cant_start_line_zh.length()):
						if cant_start_line_zh[c] == text[i]:
							i -= 1
							can_insert = false
							break
					if can_insert:
						if text[i - 1] == "\u2003" and text[i] == cjk_space:
							i -= 1
							can_insert = false
						else:
							for c in range(cant_end_line_zh.length()):
								if cant_end_line_zh[c] == text[i - 1]:
									i -= 1
									can_insert = false
									break
					if can_insert:
						var broken_out = false
						for c in range(cant_break_line_zh.length()):
							if cant_break_line_zh[c] == text[i - 1]:
								for d in range(cant_break_line_zh.length()):
									if cant_break_line_zh[d] == text[i]:
										i -= 1
										can_insert = false
										broken_out = true
										break
							if broken_out:
								break
					if can_insert:
						if text[i] == cjk_space and i > 1 and cant_break_line_zh.find(text[i - 2]) == -1 and cant_start_line_zh.find(text[i + 1]) == -1:
							text[i] = "\u2028"
							text[i - 1] = "\u2028"
							text = text.insert(i, "\n")
						else:
							if not insert_flag and (text[i] == cjk_space or text[i] == " ") and cant_start_line_zh.find(text[i + 1]) == -1:
								text[i] = "\n"
							else:
								if cant_break_line_zh.find(text[i - 1]) != -1 or cant_start_line_zh.find(text[i + 1]) != -1:
									insert_flag = true
									i -= 1
									continue
								text = text.insert(i, "\n")
							update_positions_on_insert(i)
						string_width = 0
						i -= 1
						break
			elif ((TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK") and forced_font == null) or (forced_font != null and (forced_font.font_data.font_path == "res://NotoSansTC-Regular.otf" or forced_font.font_data.font_path == "res://NotoSansHK-Regular.otf")):
				var insert_flag = false
				while i > 0:
					var can_insert = true
					for c in range(cant_start_line_tc.length()):
						if cant_start_line_tc[c] == text[i]:
							i -= 1
							can_insert = false
							break
					if can_insert:
						for c in range(cant_end_line_tc.length()):
							if cant_end_line_tc[c] == text[i - 1]:
								i -= 1
								can_insert = false
								break
					if can_insert:
						var broken_out = false
						for c in range(cant_break_line_zh.length()):
							if cant_break_line_zh[c] == text[i - 1]:
								for d in range(cant_break_line_zh.length()):
									if cant_break_line_zh[d] == text[i]:
										i -= 1
										can_insert = false
										broken_out = true
										break
							if broken_out:
								break
					if can_insert:
						if text[i] == cjk_space and i > 1 and cant_break_line_zh.find(text[i - 2]) == -1 and cant_start_line_tc.find(text[i + 1]) == -1:
							text[i] = "\u2028"
							text[i - 1] = "\u2028"
							text = text.insert(i, "\n")
						else:
							if not insert_flag and (text[i] == cjk_space or text[i] == " ") and cant_start_line_tc.find(text[i + 1]) == -1:
								text[i] = "\n"
							else:
								if cant_break_line_zh.find(text[i - 1]) != -1 or cant_start_line_tc.find(text[i + 1]) != -1:
									insert_flag = true
									i -= 1
									continue
								text = text.insert(i, "\n")
							update_positions_on_insert(i)
						string_width = 0
						i -= 1
						break
			elif (TranslationServer.get_locale() == "ja" and forced_font == null) or (forced_font != null and forced_font.font_data.font_path == "res://NotoSansJP-Regular.otf"):
				var insert_flag = false
				while i > 0:
					var can_insert = true
					for c in range(cant_start_line_ja.length()):
						if cant_start_line_ja[c] == text[i]:
							i -= 1
							can_insert = false
							break
					if can_insert:
						for c in range(cant_end_line_ja.length()):
							if cant_end_line_ja[c] == text[i - 1]:
								i -= 1
								can_insert = false
								break
					if can_insert:
						var broken_out = false
						for c in range(cant_break_line_ja.length()):
							if cant_break_line_ja[c] == text[i - 1]:
								for d in range(cant_break_line_ja.length()):
									if cant_break_line_ja[d] == text[i]:
										i -= 1
										can_insert = false
										broken_out = true
										break
							if broken_out:
								break
					if can_insert:
						if text[i] == cjk_space and i > 1 and cant_break_line_ja.find(text[i - 2]) == -1 and cant_start_line_ja.find(text[i + 1]) == -1:
							text[i] = "\u2028"
							text[i - 1] = "\u2028"
							text = text.insert(i, "\n")
							insert_flag = false
						else:
							if not insert_flag and (text[i] == cjk_space or text[i] == " ") and cant_start_line_ja.find(text[i + 1]) == -1:
								text[i] = "\n"
								insert_flag = false
							else:
								if cant_break_line_ja.find(text[i - 1]) != -1 or cant_start_line_ja.find(text[i + 1]) != -1:
									insert_flag = true
									i -= 1
									continue
								text = text.insert(i, "\n")
							update_positions_on_insert(i)
						string_width = 0
						i -= 1
						break
			else:
				var insert_flag = false
				var start_pos = i
				while not_counting_tags or TranslationServer.get_locale() != "ar":
					var can_insert = true
					if TranslationServer.get_locale() == "ar":
						if can_insert and i > -1:
							var broken_out = false
							if text[i] == " ":
								var was_number = false
								var check_num = 1
								while i - check_num >= 0 and text[i + 1] == "؏":
									if text[i - check_num] == "|":
										was_number = true
										break
									elif ("ابجدهوزحطيكلمنسعفصقرشتثخذضظغ" + "؏").find(text[i - check_num]) != -1:
										break
									check_num += 1
								while was_number:
									i -= 1
									if text[i] == "؈" or text[i] == "ڼ":
										i -= 1
										while text[i] != "؈" and text[i] != "ڼ":
											i -= 1
									elif text[i] == "|":
										was_number = true
									elif text[i] == " ":
										break
							else:
								for c in range(cant_break_line_ar.length()):
									if cant_break_line_ar[c] == text[i - 1]:
										for d in range(cant_break_line_ar.length()):
											if cant_break_line_ar[d] == text[i]:
												i -= 1
												can_insert = false
												broken_out = true
												break
									if broken_out:
										break
						if can_insert:
							var s_num = 1
							while text[i - s_num] == " " or  text[i - s_num] == "\u2009":
								s_num += 1
							if text[i - s_num] == "|":
								if last_icon_pos != -1 and last_icon_pos - i > 0:
									can_insert = false
									if text.substr(last_icon_pos, last_icon_pos - i).find("\n") == -1:
										for a in text.substr(last_icon_pos, last_icon_pos - i):
											if "1234567890؏؈ڼ \u2009".find(text[i]) == -1:
												can_insert = true
												break
							elif text[i - s_num] == "؏":
								if last_number_pos != -1 and last_number_pos - i > 0:
									can_insert = false
									if text.substr(last_number_pos, last_number_pos - i).find("\n") == -1:
										for a in text.substr(last_number_pos, last_number_pos - i):
											if "1234567890|؈ڼ \u2009".find(text[i]) == -1:
												can_insert = true
												break
					if ((text[i] == " " or text[i] == "\u200B" or text[i] == "\u2009" or text[i] == "\u2003" or text[i] == cjk_space) and icon_positions.find(i) == -1 and (i == text.length() or ((cant_start_line_th.find(text[i + 1]) == -1 and (TranslationServer.get_locale() == "th" or (TranslationServer.get_locale() == "ar" and text[i - 1] != "|"))) or (TranslationServer.get_locale() != "th" and TranslationServer.get_locale() != "ar")))) and can_insert:
						if not_counting_tags and not just_adding_linebreaks:
							if abs(color_tag_diff) >= 2 and inserted_end_tag == 0:
								text = text.insert(i, end_tag + "\n")
								inserted_end_tag += 1
								reached_end = false
								i += end_tag.length()
								color_tag_diff = 0
							elif inserted_end_tag == 1:
								if not reached_end:
									text = text.insert(i, end_tag)
									i += end_tag.length()
								text[i] = "\n"
								text = text.insert(text.substr(0, i - 1).find_last("\n") + 1, color_tag)
								inserted_end_tag = 0
								i += color_tag.length()
								color_tag_diff = 0
								if not reached_end:
									color_tag_diff = 2
									inserted_end_tag = 1
							else:
								text[i] = "\n"
						else:
							text[i] = "\n"
						string_width = 0
						break
					elif i == -1 or (text[i] == "\n" and can_insert):
						var swzero = true
						while true:
							start_pos += 1
							if start_pos >= text.length() or text[start_pos] == "<":
								i = start_pos - 2
								swzero = false
								break
							elif text[start_pos] == " " or text[i] == "\u200B" or text[i] == "\u2009" or text[i] == "\u2003" or text[i] == cjk_space:
								if not_counting_tags and not just_adding_linebreaks:
									if abs(color_tag_diff) >= 2 and inserted_end_tag == 0:
										text = text.insert(start_pos - 1, end_tag + "\n")
										inserted_end_tag += 1
										reached_end = false
										i += end_tag.length()
										color_tag_diff = 0
									elif inserted_end_tag == 1:
										text[start_pos] = "\n"
										text = text.insert(text.substr(0, text.substr(0, start_pos - 1).find_last("\n")).find_last("\n") + 1, color_tag)
										inserted_end_tag = 0
										i += color_tag.length()
										color_tag_diff = 0
									else:
										text[start_pos] = "\n"
								else:
									text[start_pos] = "\n"
								i = start_pos - 1
								break
						if swzero:
							string_width = 0
						i += 1
						break
					i -= 1
					if not_counting_tags and not just_adding_linebreaks and inserted_end_tag == 0 and color_tag_diff != 0 and (text[i] == "؈" or text[i] == "ڼ"):
						color_tag_diff = 0
			if i == 0:
				string_width = 0
				if saved_i != 0:
					i = saved_i
		i += 1
	if TranslationServer.get_locale() == "ar" and not_counting_tags and not just_adding_linebreaks and inserted_end_tag == 1:
		if not reached_end:
			text = text.insert(i, end_tag)
			i += end_tag.length()
		text = text.insert(text.substr(0, i - 1).find_last("\n") + 1, color_tag)
		inserted_end_tag = 0
		color_tag_diff = 0
		if not reached_end:
			color_tag_diff = 2
			inserted_end_tag = 1
	var y_multi
	var line_length = get_font("font").get_string_size(text.substr(0, text.find("\n"))).x * rect_scale.x
	y_multi = get_font("font").get_height() + 3
	if TranslationServer.get_locale() == "ar" and get_parent().need_to_left and not just_adding_linebreaks and not not_counting_tags:
		var tmp_text = text
		while true:
			if get_font("font").get_string_size(tmp_text.substr(0, tmp_text.find("\n"))).x * rect_scale.x > line_length:
				line_length = get_font("font").get_string_size(tmp_text.substr(0, tmp_text.find("\n"))).x * rect_scale.x
			if tmp_text.find("\n") == -1:
				break
			tmp_text = tmp_text.substr(tmp_text.find("\n") + 1, -1)
		get_parent().offset_x = max_width - line_length

	for icon_num in range(icons.size()):
		var y_diff = 0
		if e_spaced:
			y_diff = -2
		var last_break
		var x_string_value
		if cjk or forced_font != null:
			last_break = text.substr(0, icon_positions[floor(icon_num * 2)] + 1).find_last("\n")
		else:
			last_break = text.substr(0, icon_positions[floor(icon_num * 2)]).find_last("\n")
		x_string_value = icon_positions[floor(icon_num * 2)] - last_break - 1
		if x_string_value == -1:
			x_string_value = 0
		var h_count = 0
		if last_break == -1:
			h_count = -1
		if icons[icon_num].get_parent() != self:
			if cjk or forced_font != null or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if not parent.get_child(1).get_children().has(icons[icon_num]):
					parent.get_child(1).add_child(icons[icon_num])
			elif not parent.get_children().has(icons[icon_num]):
				parent.add_child(icons[icon_num])
			var icon = icons[icon_num].sprite
			icon.centered = false
			if icon_z_index == null:
				icon.z_index = 8
			else:
				icon.z_index = icon_z_index
			icon.set_type(icons[icon_num].type)
			var offset_pos = Vector2(0, 0)
			if cjk or (forced_font != null and (forced_font.get_path() != "res://PICO-8.tres" and forced_font.get_path() != "res://PICO-8_Tooltips.tres" and forced_font.get_path() != "res://PICO-8_Emails.tres" and forced_font.get_path() != "res://Title_Font.tres")):
				offset_pos = rect_position
			var icon_scale = 3
			var i_offset = icon_offset
			if icon_scale_override != 0:
				icon_scale = icon_scale_override
				if icon.texture.get_size().x >= 17:
					if icon_scale > 1:
						icon_scale -= 1
					if $"/root/Main/Options Sprite/Options".menu == "mods" and $"/root/Main/Options Sprite/Options".ui_scaling.text >= 1.75:
						icon_scale -= 2
					elif $"/root/Main/Options Sprite/Options".menu == "mods" and $"/root/Main/Options Sprite/Options".ui_scaling.text == 1.5:
						icon_scale -= 1
					if (int($"/root/Main/Options Sprite/Options".display_font) == 0 and int(get_parent().current_scale * 4 + get_parent().scale_mod) == 3) or (int($"/root/Main/Options Sprite/Options".display_font) == 2 and str(get_parent().current_scale + (get_parent().scale_mod - 1) / 8.0) == "0.125") and str(get_path()).find("Mod Text") != -1:
						icon_scale += 1
						if int($"/root/Main/Options Sprite/Options".display_font) == 0:
							item_icon_offset.x = -6
					if ($"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0) and str(get_path()).find("Mod Text") != -1 and str(get_parent().current_scale + (get_parent().scale_mod + 1.0) / 8.0) == "1.25":
						icon_scale -= 2
					if (($"/root/Main/Options Sprite/Options".ui_scaling.text > 1 and $"/root/Main/Pop-up Sprite/Pop-up/".emails.size() > 0 and $"/root/Main/Pop-up Sprite/Pop-up/".emails[0].prompt) or ($"/root/Main/Pop-up Sprite/Pop-up/".inv_open and $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 1)) and get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container/Text":
						icon_scale -= 1
						if cjk:
							if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25 or $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.5 or $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
								icon_scale -= 1
							elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 2:
								icon_scale -= 2
						elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
							if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
								icon_scale += 1
							elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory >= 2.25:
								icon_scale -= 1
						else:
							if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
								icon_scale -= 1
							elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory >= 2:
								icon_scale -= 2
					elif get_parent().get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Title":
						if $"/root/Main/Options Sprite/Options".ui_scaling.tooltips > 2:
							icon_scale -= 2
						elif str($"/root/Main/Options Sprite/Options".ui_scaling.tooltips) == "2":
							icon_scale -= 1
					elif get_parent().get_parent() is TextureButton:
						if $"/root/Main/Options Sprite/Options".ui_scaling.buttons == 0.75 and (cjk or int($"/root/Main/Options Sprite/Options".display_font) > 0):
							icon_scale -= 1
						if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1:
							icon_scale -= 1
						if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1.5:
							icon_scale -= 1
					elif get_parent().get_path() == "/root/Main/Tooltips/Tooltip/Card/Background/Description":
						if cjk:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.tooltips):
								"1":
									item_icon_offset.y = -4
								"1.25":
									pass
								"1.75":
									item_icon_offset.x = -4
									item_icon_offset.y = 2
								"2.25":
									icon_scale -= 2
									item_icon_offset.x = 4
									item_icon_offset.y = 12
								"2.5":
									icon_scale -= 2
									item_icon_offset.x = -2
									item_icon_offset.y = 10
								_:
									icon_scale -= 1
									item_icon_offset.y = 8
						elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.tooltips):
								"1":
									item_icon_offset.x = 8
									item_icon_offset.y = -2
								"1.25":
									if int($"/root/Main/Options Sprite/Options".display_font) == 2:
										icon_scale -= 1
										item_icon_offset.x = 12
										item_icon_offset.y = 2
									else:
										item_icon_offset.x = 4
										item_icon_offset.y = -2
								"1.5":
									icon_scale -= 1
									item_icon_offset.x = 10
									item_icon_offset.y = -2
								"1.75":
									icon_scale -= 2
									item_icon_offset.x = 12
									item_icon_offset.y = 4
								"2", "2.25", "2.5":
									icon_scale -= 2
									item_icon_offset.x = 6
									item_icon_offset.y = 2
								_:
									icon_scale -= 1
									item_icon_offset.y = 8
						else:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.tooltips):
								"0.5":
									icon_scale += 1
								"0.75", "1":
									pass
								"1.75", "2", "2.25":
									icon_scale -= 2
								"2.5":
									icon_scale -= 3
								_:
									icon_scale -= 1
					elif get_parent().get_parent().get_parent().get_parent() != null and get_parent().get_parent().get_parent().get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container":
						if cjk:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections):
								"1":
									item_icon_offset.y = -4
								"1.25":
									pass
								"1.75":
									item_icon_offset.x = -4
									item_icon_offset.y = 2
								"2.25":
									icon_scale -= 2
									item_icon_offset.x = 4
									item_icon_offset.y = 12
								"2.5":
									icon_scale -= 2
									item_icon_offset.x = -2
									item_icon_offset.y = 10
								_:
									icon_scale -= 1
									item_icon_offset.y = 8
						elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections):
								"1":
									item_icon_offset.x = 8
									item_icon_offset.y = -2
								"1.25":
									if int($"/root/Main/Options Sprite/Options".display_font) == 2:
										icon_scale -= 1
										item_icon_offset.x = 12
										item_icon_offset.y = 2
									else:
										item_icon_offset.x = 4
										item_icon_offset.y = -2
								"1.5":
									icon_scale -= 1
									item_icon_offset.x = 10
									item_icon_offset.y = -2
								"1.75":
									icon_scale -= 2
									item_icon_offset.x = 12
									item_icon_offset.y = 4
								"2", "2.25", "2.5":
									icon_scale -= 2
									item_icon_offset.x = 6
									item_icon_offset.y = 2
								_:
									icon_scale -= 1
									item_icon_offset.y = 8
						else:
							match str($"/root/Main/Options Sprite/Options".ui_scaling.symbol_item_selections):
								"0.5":
									icon_scale += 1
								"0.75", "1":
									pass
								"1.75", "2", "2.25":
									icon_scale -= 2
								"2.5":
									icon_scale -= 3
								_:
									icon_scale -= 1
					elif get_parent().get_parent().get_path() == "/root/Main/Pop-up Sprite/Pop-up/Container":
						if $"/root/Main/Options Sprite/Options".ui_scaling.text > 1:
							icon_scale -= 1
						if $"/root/Main/Options Sprite/Options".ui_scaling.text > 1.5:
							icon_scale -= 1
					if cjk or forced_font != null:
						if get_parent().get_parent() is TextureButton:
							match $"/root/Main/Options Sprite/Options".ui_scaling.buttons:
								0.5:
									i_offset = Vector2(7, 2)
								0.75:
									i_offset = Vector2(14, 7)
								1, 1.0:
									i_offset = Vector2(1, 2)
								1.25:
									i_offset = Vector2(6, 9)
								1.5:
									i_offset = Vector2(1, 2)
								1.75:
									i_offset = Vector2(6, 9)
								2, 2.0:
									i_offset = Vector2(1, 2)
						else:
							i_offset = Vector2(-2, 0)
					else:
						if get_parent().get_parent() is TextureButton:
							match $"/root/Main/Options Sprite/Options".ui_scaling.buttons:
								0.5:
									i_offset = Vector2(-4, -2)
								0.75:
									i_offset = Vector2(0, 0)
								1, 1.0:
									i_offset = Vector2(-7, -6)
								1.25:
									i_offset = Vector2(-3, -2)
								1.5:
									i_offset = Vector2(-11, -10)
								1.75:
									i_offset = Vector2(-7, -6)
								2, 2.0:
									i_offset = Vector2(-11, -10)
								2.25:
									i_offset = Vector2(-12, -11)
									icon_scale -= 1
								2.5:
									i_offset = Vector2(-19, -18)
									icon_scale -= 1
						elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
							i_offset.x -= 9
							i_offset.y -= 2
						elif TranslationServer.get_locale() != "ar":
							i_offset = Vector2(-7, -6)
				if TranslationServer.get_locale() == "ar" and i_spaced:
					if icon.texture.get_size().x >= 17:
						i_offset.x += 7
					else:
						i_offset.x -= 6
				i_offset.x += item_icon_offset.x
				i_offset.y += item_icon_offset.y
				item_icon_offset = Vector2(0, 0)
			y_diff += 2 * (ceil(icon_scale / 3.0) - 1)
			icon.scale = Vector2(icon_scale, icon_scale)
			var x_diff = 0
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if get_parent().get_parent() is TextureButton:
					y_diff = 6
					x_diff = 6
				else:
					y_diff = -6
			icons[icon_num].rect_position = Vector2(round(get_font("font").get_string_size(text.substr(last_break + 1, x_string_value)).x) * rect_scale.x + i_offset.x + offset_pos.x, round((text.count("\n", h_count, last_break + 1)) * y_multi * rect_scale.y + ((icon_scale / icon.texture.get_size().y) / 2)) + 1 + i_offset.y + offset_pos.y + y_diff)
			if TranslationServer.get_locale() == "ar" and get_parent().need_to_left:
				icons[icon_num].rect_position.x += line_length - round(get_font("font").get_string_size(text.substr(last_break + 1, text.substr(last_break + 1, -1).find("\n"))).x) * rect_scale.x + i_offset.x + offset_pos.x
			icons[icon_num].update_hitbox()
	var to_be_added = []
	
	for b in range(color_texts.size()):
		var s = text.substr(color_positions[b * 2], color_positions[b * 2 + 1] - color_positions[b * 2])
		
		color_texts[b].add_color_override("font_color", colors[b])
		color_texts[b].color = colors[b]
		color_texts[b].text = ""
		
		var num = 0
		var extra = false

		while s.length() > 0:
			if not extra:
				color_texts[b].text += s[0]
			else:
				extra_color_texts[extra_color_texts.size() - 1].text += s[0]
			num += 1
			if s[0] == "\n":
				extra = true
				var n = preload("res://Pico Text.tscn").instance()
				n.add_color_override("font_color", colors[b])
				n.color = colors[b]
				if not cjk and forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0:
					if v_spaced:
						n.add_font_override("font", preload("res://PICO-8_Tooltips.tres"))
					elif i_spaced:
						n.add_font_override("font", preload("res://PICO-8_Inventory.tres"))
					elif e_spaced:
						n.add_font_override("font", preload("res://PICO-8_Emails.tres"))
					elif forced_font == null:
						n.add_font_override("font", preload("res://PICO-8.tres"))
					else:
						n.add_font_override("font", forced_font)
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if i_spaced:
						if int($"/root/Main/Options Sprite/Options".display_font) == 1:
							n.add_font_override("font", preload("res://NotoSans_Inventory.tres"))
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							n.add_font_override("font", preload("res://OpenDyslexic_Inventory.tres"))
				elif forced_font != null:
					n.add_font_override("font", forced_font)
				else:
					match int($"/root/Main/Options Sprite/Options".display_font):
						1:
							if TranslationServer.get_locale() == "th":
								n.add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
							elif TranslationServer.get_locale() == "ar":
								n.add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
							elif not i_spaced:
								n.add_font_override("font", preload("res://NotoSans_Resize.tres"))
						2:
							if not i_spaced:
								n.add_font_override("font", preload("res://OpenDyslexic_Resize.tres"))
				n.rect_position.y = text.count("\n", 0, color_positions[b * 2] + num) * ceil(y_multi)
				n.dont_remove = color_texts[b].dont_remove
				add_child(n)
				extra_color_texts.push_back(n)
			if TranslationServer.get_locale() == "ar" and extra and rtl:
				extra_color_texts[extra_color_texts.size() - 1].rect_position.x = -get_font("font").get_string_size(text.substr(color_positions[b * 2] + num, text.substr(color_positions[b * 2] + num, -1).find("\n"))).x
			s = s.substr(1, -1)

		var last_break = text.substr(0, color_positions[b * 2]).find_last("\n")
		var h_count = 0
		if last_break == -1:
			h_count = -1
		if TranslationServer.get_locale() == "ar" and rtl:
			color_texts[b].rect_position = Vector2(-get_font("font").get_string_size(text.substr(color_positions[b * 2], text.substr(color_positions[b * 2], -1).find("\n"))).x + get_font("font").get_string_size(color_texts[b].text).x, (text.count("\n", h_count, color_positions[b * 2]) * ceil(y_multi)))
		else:
			color_texts[b].rect_position = Vector2(get_font("font").get_string_size(text.substr(last_break + 1, color_positions[b * 2] - last_break - 1)).x, (text.count("\n", h_count, color_positions[b * 2]) * ceil(y_multi)))
		if color_texts[b].get_parent() != self:
			add_child(color_texts[b])
	cut_characters = 0

func parse_escape(s, pos, n, dr):
	var already_there = false
	var parent = get_parent()
	match s.substr(0, 1):
		"i":
			var type = s.substr(5, -1)
			if type.find("_STEAM_ID_") != -1:
				type = type.substr(0, type.find("_STEAM_ID_"))
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(type):
				type += "_STEAM_ID_" + str($"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])
				if $"/root/Main".mod_pack_nums.has(type):
					type += "_PACK_" + $"/root/Main".mod_pack_nums[type]
				if $"/root/Main".is_mod_disabled(type) and $"/root/Main".tile_database.has(type.substr(0, type.find("_STEAM_ID_"))):
					type = type.substr(0, type.find("_STEAM_ID_"))
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(type):
				type += "_STEAM_ID_" + str($"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[type])
				if $"/root/Main".mod_pack_nums.has(type):
					type += "_PACK_" + $"/root/Main".mod_pack_nums[type]
				if $"/root/Main".is_mod_disabled(type) and $"/root/Main".item_database.has(type.substr(0, type.find("_STEAM_ID_"))):
					type = type.substr(0, type.find("_STEAM_ID_"))
			elif not $"/root/Main".icon_texture_database.has(type):
				type = "missing"
			if TranslationServer.get_locale() == "ar":
				match int($"/root/Main/Options Sprite/Options".display_font):
					0:
						text[n] = "\u2009 "
						cut_characters -= 2
					1:
						text[n] = "\u2009   "
						cut_characters -= 4
					2:
						text[n] = "\u2009 "
						cut_characters -= 2
			elif $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko" and forced_font == null:
				if rect_scale.x <= 0.375 or diff_cjk_space:
					cjk_space = "\u2002"
				if type == "coin" or type == "reroll_token" or type == "removal_token" or type == "essence_token":
					if str(get_path()).find("Mod Text") != -1:
						text[n] = "  "
					else:
						text[n] = "\u2003" + cjk_space
				else:
					text[n] = "\u3000" + cjk_space
				cut_characters -= 2
			elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
				if rect_scale.x <= 0.375 or diff_cjk_space:
					cjk_space = "\u2002"
				text[n] = " " + cjk_space
				cut_characters -= 2
			elif int($"/root/Main/Options Sprite/Options".display_font) != 0 or (TranslationServer.get_locale() == "ko" and forced_font == null):
				if rect_scale.x <= 0.375 or diff_cjk_space:
					cjk_space = "\u2002"
				if TranslationServer.get_locale() == "th":
					if n == text.length() - 1:
						text[n] = "    "
					else:
						text[n] = "฿    "
				else:
					text[n] = "\u2003" + cjk_space
				cut_characters -= 2
			elif tts:
				text[n] = " "
				cut_characters -= 1
			else:
				text[n] = "\u2009 "
				cut_characters -= 2
			for icon in icons:
				if icon.pos == pos and icon.type == type:
					already_there = true
					break
			if not already_there and not tts and not just_adding_linebreaks:
				if not border_text:
					var i = preload("res://Hover Icon.tscn").instance()
					i.pos = pos
					
					i.type = type
					
					i.dont_remove = dr
					
					if cjk or forced_font != null:
						if saved_value_texts.size() > 0:
							i.value_text = saved_value_texts[icons.size()]
						if saved_pb_texts.size() > 0:
							i.permanent_bonus = saved_pb_texts[icons.size()]
						if saved_pm_texts.size() > 0:
							i.permanent_multiplier = saved_pm_texts[icons.size()]
					else:
						if parent.saved_value_texts.size() > 0:
							i.value_text = parent.saved_value_texts[icons.size()]
						if parent.saved_pb_texts.size() > 0:
							i.permanent_bonus = parent.saved_pb_texts[icons.size()]
						if parent.saved_pm_texts.size() > 0:
							i.permanent_multiplier = parent.saved_pm_texts[icons.size()]
					if fine_print_icon_pos != -1 and raw_string.length() - text.length() + pos >= fine_print_icon_pos:
						i.fine_print = true
					icons.push_back(i)
				icon_positions.push_back(n)
				icon_positions.push_back(n + 1)
			elif just_adding_linebreaks:
				text[n] = "؏" + str(tags.size()) + "؏"
				tags.push_back("<" + s + ">")
			elif tts:
				if ($"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko") or int($"/root/Main/Options Sprite/Options".display_font) != 0:
					text[n] = ""
				if text.length() == 0:
					text += tr(type)
				else:
					text[n] = tr(type)
		"c":
			if not just_adding_linebreaks:
				text = text.substr(0, n) + text.substr(n + 1, -1)
			cut_characters += 1
			
			var ar_num = 0
			if TranslationServer.get_locale() == "ar":
				ar_num = 1
			
			for color_pos in range(color_positions.size()):
				if color_pos % 2 == ar_num and color_positions[color_pos] == pos:
					already_there = true
					break
			
			if not already_there and not tts and not just_adding_linebreaks:
				color_positions.push_back(n)
				colors.push_back(Color(s.substr(6, -1)))
				
				var c = preload("res://Pico Text.tscn").instance()
				if not $"/root/Main/Options Sprite/Options".CJK_lang and forced_font == null and int($"/root/Main/Options Sprite/Options".display_font) == 0:
					if v_spaced:
						c.add_font_override("font", preload("res://PICO-8_Tooltips.tres"))
					elif i_spaced:
						c.add_font_override("font", preload("res://PICO-8_Inventory.tres"))
					elif e_spaced:
						c.add_font_override("font", preload("res://PICO-8_Emails.tres"))
					elif forced_font == null:
						c.add_font_override("font", preload("res://PICO-8.tres"))
					else:
						c.add_font_override("font", forced_font)
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0 and TranslationServer.get_locale() != "th":
					if i_spaced:
						if int($"/root/Main/Options Sprite/Options".display_font) == 1:
							c.add_font_override("font", preload("res://NotoSans_Inventory.tres"))
						elif int($"/root/Main/Options Sprite/Options".display_font) == 2:
							c.add_font_override("font", preload("res://OpenDyslexic_Inventory.tres"))
				elif forced_font != null:
					c.add_font_override("font", forced_font)
				else:
					match int($"/root/Main/Options Sprite/Options".display_font):
						1:
							if TranslationServer.get_locale() == "th":
								c.add_font_override("font", preload("res://NotoSansTH_Resize.tres"))
							elif TranslationServer.get_locale() == "ar":
								c.add_font_override("font", preload("res://NotoSansAR_Resize.tres"))
							elif not i_spaced:
								c.add_font_override("font", preload("res://NotoSans_Resize.tres"))
						2:
							if not i_spaced:
								c.add_font_override("font", preload("res://OpenDyslexic_Resize.tres"))
				c.dont_remove = dr
				color_texts.push_back(c)
			elif just_adding_linebreaks:
				text[n] = "؈" + str(tags.size()) + "؈"
				tags.push_back("<" + s + ">")
		"e":
			if not just_adding_linebreaks:
				text = text.substr(0, n) + text.substr(n + 1, -1)
			cut_characters += 1
			var ar_num = 0
			if TranslationServer.get_locale() == "ar":
				ar_num = -1
			for color_pos in range(color_positions.size()):
				if color_pos % 2 == 1 + ar_num and color_positions[color_pos] == pos:
					already_there = true
					break
			if not already_there and not tts and not just_adding_linebreaks:
				color_positions.push_back(n)
			elif just_adding_linebreaks:
				text[n] = "ڼ" + str(tags.size()) + "ڼ"
				tags.push_back("<" + s + ">")
		"v":
			if just_adding_linebreaks:
				text[n] = "|" + str(tags.size()) + "|"
				tags.push_back("<" + s + ">")
			else:
				if tts:
					text[n] = " " + parse_num_str(str(values[int(s.substr(6, -1)) - 1])) + " "
				else:
					text[n] = parse_num_str(str(values[int(s.substr(6, -1)) - 1]))
				cut_characters -= 1
		"h":
			if str(Input.get_joy_name(0)) == "":
				text[n] = $"/root/Main/Options Sprite/Options".hotkeys[s.substr(7, -1)][2]
			else:
				text[n] = $"/root/Main/Options Sprite/Options".hotkeys[s.substr(7, -1)][2] + "/" + $"/root/Main/Options Sprite/Options".hotkeys[s.substr(7, -1)][3]
			cut_characters -= 1
		"g":
			var icon_str = ""
			var group_arr
			var symbols = $"/root/Main/".tile_database
			if s.substr(0, 11) == "group_item_":
				if $"/root/Main/".group_database["items"].has(s.substr(11, -1)):
					group_arr = $"/root/Main/".group_database["items"][s.substr(11, -1)]
				else:
					group_arr = ["item_missing", "item_missing"]
				symbols = $"/root/Main/".item_database
			else:
				if $"/root/Main/".group_database["symbols"].has(s.substr(6, -1)):
					group_arr = $"/root/Main/".group_database["symbols"][s.substr(6, -1)]
				else:
					group_arr = ["missing", "missing"]
			var final_arr = []
			
			var offset_num = 0
			
			for g in group_arr:
				if symbols.has(g):
					final_arr.push_back(symbols[g])
				else:
					final_arr.push_back(symbols["missing"])
			if group_arr.size() == 1:
				offset_num += 1
			
			final_arr.sort_custom($"/root/Main/Pop-up Sprite/Pop-up".CustomSorter, "icon_sort")
			
			if (cjk or TranslationServer.get_locale() == "th" or TranslationServer.get_locale() == "ar") and TranslationServer.get_locale() != "ko" and forced_font == null:
				for num in range(final_arr.size() - 1 + offset_num):
					if final_arr[num].type != "coin":
						var type = final_arr[num].type
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(type):
							type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])
						elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(type):
							type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[type])
						icon_str += "<icon_" + type + ">"
					else:
						icon_str += "<icon_hover_coin>"
				icon_str += cjk_space
			else:
				for num in range(final_arr.size() - 1 + offset_num):
					if final_arr[num].type != "coin":
						var type = final_arr[num].type
						if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(type):
							type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])
						elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(type):
							type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[type])
						icon_str += "<icon_" + type + "> "
					else:
						icon_str += "<icon_hover_coin> "
			icon_str = icon_str.substr(0, icon_str.length() - 1)
				
			text[n] = icon_str
			cut_characters -= icon_str.length() + 1
		"l":
			var space_string = ""
			var group_arr
			var symbols = $"/root/Main/".tile_database
			if s.substr(0, 10) == "last_item_":
				var l_type = $"/root/Main".append_steam_id(s.substr(10, -1), $"/root/Main".steam_id)
				if $"/root/Main/".group_database["items"].has(l_type):
					group_arr = $"/root/Main/".group_database["items"][l_type]
				else:
					group_arr = ["item_missing"]
				symbols = $"/root/Main/".item_database
			else:
				var l_type = $"/root/Main".append_steam_id(s.substr(5, -1), $"/root/Main".steam_id)
				if $"/root/Main/".group_database["symbols"].has(l_type):
					group_arr = $"/root/Main/".group_database["symbols"][l_type]
				else:
					group_arr = ["missing"]
			
			var final_arr = []
			
			for g in group_arr:
				if symbols.has(g):
					final_arr.push_back(symbols[g])
				else:
					final_arr.push_back(symbols["missing"])
			
			final_arr.sort_custom($"/root/Main/Pop-up Sprite/Pop-up".CustomSorter, "icon_sort")
			
			if final_arr.size() == 0:
				final_arr = [symbols["missing"]]
			
			var type = final_arr[final_arr.size() - 1].type
			if $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols.has(type):
				type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.symbols[type])
			elif $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items.has(type):
				type = $"/root/Main".append_steam_id(type, $"/root/Main/Pop-up Sprite/Pop-up".saved_mod_ids.items[type])
			
			space_string = "<icon_" + type + ">"
			text[n] = space_string
			cut_characters -= 2
		"d":
			cut_characters -= 1
			if dynamic_icons.size() > dynamic_icons_num and dynamic_icons[dynamic_icons_num] != null:
				text[n] = "<icon_" + dynamic_icons[dynamic_icons_num] + ">"
				dynamic_icons_num += 1
			else:
				text[n] = "<icon_missing>"
		"b":
			if not $"/root/Main".hotkey_button_strings.has(get_parent()):
				$"/root/Main".hotkey_button_strings.push_back(get_parent())
			var b = s.substr(7, -1)
			var button = "BTN_" + b
			cut_characters -= 1
			match b:
				"0":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_A>"
					elif $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_cross>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_B>"
					else:
						button = "<icon_switch_A>"
				"1":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_B>"
					elif $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_circle>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_A>"
					else:
						button = "<icon_switch_B>"
				"2":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_X>"
					elif $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_square>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_Y>"
					else:
						button = "<icon_switch_X>"
				"3":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_Y>"
					elif $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_triangle>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_X>"
					else:
						button = "<icon_switch_Y>"
				"4":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_lb>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_l>"
					else:
						button = "<icon_ps_l1>"
				"5":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_rb>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_r>"
					else:
						button = "<icon_ps_r1>"
				"6":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_lt>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_zl>"
					else:
						button = "<icon_ps_l2>"
				"7":
					if $"/root/Main".controller_type == "xbox":
						button = "<icon_xbox_rt>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_zr>"
					else:
						button = "<icon_ps_r2>"
				"8":
					button = "<icon_leftstick_click>"
				"9":
					button = "<icon_rightstick_click>"
				"10":
					if $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_select>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_minus>"
					else:
						button = "<icon_xbox_select>"
				"11":
					if $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_start>"
					elif $"/root/Main".controller_type == "nintendo":
						button = "<icon_switch_plus>"
					else:
						button = "<icon_xbox_start>"
				"12":
					button = "<icon_dpad_up>"
				"13":
					button = "<icon_dpad_down>"
				"14":
					button = "<icon_dpad_left>"
				"15":
					button = "<icon_dpad_right>"
				"22":
					if $"/root/Main".controller_type == "playstation":
						button = "<icon_ps_touchpad>"
			text[n] = button
		"t":
			cut_characters -= 1
			text[n] = "<color_" + $"/root/Main/Options Sprite/Options".colors3[s] + ">"
