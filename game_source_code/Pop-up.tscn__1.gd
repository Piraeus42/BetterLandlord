extends Control

var border
var container
var sender_container
var rent_container
var label_text
var scroll_bar
var mods = {"symbols": [], "items": []}
var saved_mod_ids = {"symbols": {}, "items": {}, "symbol_groups": {}, "item_groups": {}, "emails": {}}
var rarity_bonuses = { "symbols": { "uncommon": 1, "rare": 1, "very_rare": 1 }, "items": { "uncommon": 1, "rare": 1, "very_rare": 1 } }
var forced_rarities = []
var forced_item_rarities = []
var hex_of_emptiness_trigger = false
var hex_of_hoarding_trigger = false
var comfy_pillow_triggers = 0
var comfy_pillow_essence_triggers = 0
var landlord_fates_data = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20]
var floor_selected = false
var current_floor = 1
var current_modded_floor
var modded_floor_string
var max_floor = 20
var comrade_values = [2, 2, 2]
var current_tip_num
var extra_symbol_choices = 0
var extra_item_choices = 0

var delay_timer = 0
var prompt_delay = 0
var hovering_in_main = false
var fossil_combined = false
var modded_run = false
var init_buttons = false
var tooltip_card = false

var spins = 0

var total_coins = 0

var closed = false

var button_textures = []
var close_button_textures = []

var offset_y = 1024
var extra_button_height = 0
var card_offset = 0
var locked_in_position = false

var page_height = 0

var emails = []

var buttons = []

var passed
var taken

var cards = []
var item_info_texts = []
var symbol_info_texts = []
var disabled_item_sprites = []
var saved_symbol_order = []
var saved_symbol_data = []
var saved_symbol_counts = []

var email_data = {}

var deck_button
var options_button

var scroll_bar_was_visible = false
var saved_label_text
var saved_label_values

var symbol_counts = {}
var destroyed_symbol_counts = {}
var destroyed_item_counts = {}
var removed_symbol_counts = {}
var symbol_data = []
var queued_symbols = []
var queued_items = []
var destroyed_symbol_types = []
var destroyed_symbol_types_size = 0
var removed_symbol_types = []
var symbols_added_this_spin = 0
var symbols_destroyed_this_spin = 0
var items_destroyed_this_spin = 0
var compost_heap_symbols_destroyed = 0
var fossil_diff = 0
var symbols_to_select = 0
var reels_to_select = 0

var rent_values = [25, 5]
var times_rent_paid = 0
var times_to_pay_rent = 0

var coin_node
var reels

var saved_card_types = []
var symbols_to_choose_from = 3
var symbols_to_choose_from_from_mods = 0
var items_to_choose_from = 3
var items_to_choose_from_from_mods = 0

var offset_top = 576
var space_for_buttons = false
var just_rerolled = false
var prompt_reroll = false

var total_runs = 0
var run_timestamp = 0
var endless_mode = false

var reroll_tokens = 0
var removal_tokens = 0
var essence_tokens = 0
var permanent_bonuses = []
var removing = false
var can_cycle_music = false
var essences_unlocked_this_game = false
var stats_unlocked_this_game = false
var floor_unlocked_this_game = false
var sme_this_spin = []
var respun_reel = -1
var respun_essence_reel = -1
var coffee_essence = false
var queued_essence_emails = 0
var prompts_passed = []
var displaying_inventory = false
var inv_open = false
var doing_boss_fight = false

var one_times = []
var tile_adding_effects = []
var item_adding_effects = []
var reroll_token_value_bonus_arr = []
var removal_token_value_bonus_arr = []
var essence_token_value_bonus_arr = []
var given_effect_hashes = []
var erased_effects = []
var icon_arr = []

var reroll_cost = 1
var removal_cost = 1

var transformed_coals = 0

var tmp_effects = []

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

class CustomSorter:
	static func icon_sort(a, b):
		if (not a.has("value") or int(a.value) < int(b.value) or a.type == "empty"):
			return true
		return false

func _input(event):
	if cards.size() > 0 and cards[0].active:
		var shortcuts = ["add_symbol_1", "add_symbol_2", "add_symbol_3"]
		shortcuts.resize(cards.size())
		if $"/root/Main/Options Sprite/Options".input_type == 0 and not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
			for s in shortcuts:
				var scancode = $"/root/Main/Options Sprite/Options".hotkeys[s][0]
				if event is InputEventKey and event.scancode == scancode and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
					resolve_event(cards[shortcuts.find(s)].data.type)
					return
				elif event is InputEventMouseButton and event.button_index == scancode and event.is_pressed() and not event.is_echo() and OS.is_window_focused():
					resolve_event(cards[shortcuts.find(s)].data.type)
					return
		if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
			for s in shortcuts:
				var scancode = $"/root/Main/Options Sprite/Options".hotkeys[s][0]
				if event is InputEventKey and event.scancode == scancode and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
					for b in shortcuts:
						if Input.is_key_pressed(scancode):
							return
					if $"/root/Main/Options Sprite/Options".input_type == 1:
						resolve_event(cards[shortcuts.find(s)].data.type)
					break
				elif event is InputEventMouseButton and event.button_index == scancode and not event.is_pressed() and not event.is_echo() and OS.is_window_focused():
					for b in shortcuts:
						if Input.is_mouse_button_pressed(scancode):
							return
					if $"/root/Main/Options Sprite/Options".input_type == 1:
						resolve_event(cards[shortcuts.find(s)].data.type)
					break

func _ready():
	container = $"Container"
	sender_container = $"Sender Container"
	rent_container = $"Rent Container"
	label_text = $"Container/Text"
	scroll_bar = $"Scroll Bar"
	border = $"Border"
	
	label_text.set_icon_size()
	
	if TranslationServer.get_locale() == "ar":
		label_text.need_to_left = true
		label_text.rect_position.x = -24
		container.get_child(1).need_to_left = true
		container.get_child(1).rect_position.x = -24
	else:
		label_text.rect_position.x = 12
		container.get_child(1).rect_position.x = 12
	
	scroll_bar.alignment_tags["dont"] = true
	
	coin_node = $"/root/Main/Coins"
	reels = $"/root/Main/Reels"
	
	if $"/root/Main/Options Sprite/Options".menu_speed == 0:
		offset_y = 0
			
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		container.get_child(1).change_font_size(0.125, false)
		rent_container.get_child(1).get_child(0).custom_max_width = 10000
		label_text.diff_cjk_space = true
	else:
		label_text.e_spaced = true
		label_text.base_scale = 1
		label_text.saved_scale = 1
	label_text.text_mod = -1
	label_text.change_set_size(label_text.base_scale)
	sender_container.rect_position.y = 54 * $"/root/Main/Options Sprite/Options".ui_scaling.emails + 2 / $"/root/Main/Options Sprite/Options".ui_scaling.emails
	container.rect_position.y = sender_container.rect_position.y + 54 * $"/root/Main/Options Sprite/Options".ui_scaling.emails + 2 / $"/root/Main/Options Sprite/Options".ui_scaling.emails
	
	if $"/root/Main".demo:
		times_to_pay_rent = 6

func load_emails():
	var file = File.new()
	file.open("res://JSON/Emails - JSON.json", file.READ)
	var text = file.get_as_text()
	email_data = JSON.parse(text)
	for e in email_data.result.keys():
		email_data.result[e]["type"] = e
		if not $"/root/Main".base_types.emails.has(e):
			$"/root/Main".base_types.emails.push_back(e)
		if e != "add_tile" and e != "add_item":
			email_data.result[e].text = tr(e)
	file.close()
	
	if emails.size() > 0 and (emails[0].type == "removal_token_prompt" or emails[0].type == "inventory"):
		emails.remove(0)

func update():
	if not $"/root/Main/Title".visible and $"/root/Main/Items".item_types.has($"/root/Main".existing_items["guillotine_essence"]) and $"/root/Main/Coins".coins + $"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value >= $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("guillotine_essence")].values[0] and not $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["guillotine_essence"])].disabled:
		delay_timer = 0
		locked_in_position = true
		return
	if $"/root/Main/Landlord".doing_entrance_anim or $"/root/Main/Landlord".queued_damage != 0 or $"/root/Main/Sums/HP Sum".visible:
		if $"/root/Main/Options Sprite/Options".menu_speed == 0:
			delay_timer = 0
		else:
			delay_timer = 30
		locked_in_position = true
		return
	if delay_timer > 0:
		var mod = 1
		if $"/root/Main/Options Sprite/Options".counting_speed != 0:
			mod = $"/root/Main/Options Sprite/Options".counting_speed + $"/root/Main/Options Sprite/Options".counting_speed_offset
		delay_timer -= 1 * mod
	var reset_pos = true
	if delay_timer == 0 and not just_rerolled and emails.size() > 0 and emails[0].extra_values.has("reset_position") and not emails[0].extra_values.reset_position:
		if emails[0].type == "removal_token_prompt":
			offset_y = -16
		elif emails[0].extra_values.has("saved_offset"):
			offset_y = emails[0].extra_values.saved_offset
		elif emails[0].type == "add_tile_prompt":
			if $"/root/Main/Options Sprite/Options".menu_speed != 0:
				offset_y = offset_top
			prompt_delay = 0
		else:
			offset_y = offset_top + 8
		reset_pos = false
		just_rerolled = true
	if ($"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0) and label_text.icons.size() > 0:
		displaying_inventory = true
	if displaying_inventory:
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			for i in label_text.icons:
				i.update_hitbox()
		elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in label_text.get_child(0).icons:
				i.update_hitbox()
		else:
			for i in label_text.texts[8].icons:
				i.update_hitbox()
		displaying_inventory = false
	if offset_y < $"/root/Main/Options Sprite/Options".resolution_y and closed:
		offset_y += 32
		if offset_y > $"/root/Main/Options Sprite/Options".resolution_y:
			offset_y = $"/root/Main/Options Sprite/Options".resolution_y
		rect_position.y = offset_y
	elif offset_y > offset_top and not closed and delay_timer <= 0 and emails.size() != 0:
		if $"/root/Main/Tooltips".get_children().size() > 0:
			for t in $"/root/Main/Tooltips".get_children():
				t.queue_free()
		if offset_y == $"/root/Main/Options Sprite/Options".resolution_y + 448 or not reset_pos:
			for i in $"/root/Main/Items".items:
				i.hovering = false
			if emails[0].type == "comrade_help" or emails[0].type == "init_comrade_help" or emails[0].type == "init_comrade_help_no_essence" or emails[0].type == "init_comrade_help_no_essence":
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					for i in label_text.icons:
						i.update_hitbox()
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					for i in label_text.get_child(0).icons:
						i.update_hitbox()
				else:
					for i in label_text.texts[8].icons:
						i.update_hitbox()
			var coin_text = rent_container.get_child(1)
			var floor_text = rent_container.get_child(2)
			
			coin_text.dont_scale = true
			coin_text.change_set_size(coin_text.base_scale)
			coin_text.can_display_decimals = false
			coin_text.diff_cjk_space = true
			
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				for b in buttons:
					for i in b.text_node.icons:
						i.update_hitbox()
			else:
				for b in buttons:
					for i in b.text_node.texts[8].icons:
						i.update_hitbox()
			
			if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
				coin_text.raw_string = "<color_FBF236>" + coin_text.parse_num_str(str(coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value)) + "<end>\u2009<icon_coin>"
				coin_text.rect_position.x = 12 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			else:
				coin_text.raw_string = "<icon_coin><color_FBF236>" + coin_text.parse_num_str(str(coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value)) + "<end>"
			
			coin_text.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
			
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				coin_text.rect_position.y = -1
				coin_text.change_font_size(0.125, false)
				floor_text.change_font_size(0.125, false)
			else:
				if $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.25:
					coin_text.scale_mod = 2
					sender_container.get_child(0).scale_mod = 2
				elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.5:
					coin_text.scale_mod = 3
					sender_container.get_child(0).scale_mod = 3
				elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.75:
					coin_text.scale_mod = 4
					sender_container.get_child(0).scale_mod = 4
				elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2:
					coin_text.scale_mod = 5
					sender_container.get_child(0).scale_mod = 5
				elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2.25:
					coin_text.scale_mod = 6
					sender_container.get_child(0).scale_mod = 6
				elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2.5:
					coin_text.scale_mod = 7
					sender_container.get_child(0).scale_mod = 7
				else:
					coin_text.scale_mod = 1
			
			coin_text.coin_icons_active = false
		
		if $"/root/Main/Options Sprite/Options".menu_speed == 0:
			offset_y = offset_top
		else:
			offset_y -= 32 * ($"/root/Main/Options Sprite/Options".menu_speed + $"/root/Main/Options Sprite/Options".menu_speed_offset) * $"/root/Main/Options Sprite/Options".resolution_y / 576
			
			if emails.size() > 0 and emails[0].prompt:
				offset_y -= 48 * ($"/root/Main/Options Sprite/Options".menu_speed + $"/root/Main/Options Sprite/Options".menu_speed_offset)
			
		if offset_y <= offset_top:
			for c in cards:
				c.update_hitboxes()
			if emails.size() > 0 and ((emails[0].prompt and prompt_delay == 0) or not emails[0].prompt or emails[0].type == "inventory" or emails[0].type == "removal_token_prompt"):
				for b in buttons:
					b.active = true
					b.can_be_offscreen = true
			elif prompt_delay > 0:
				prompt_delay -= 1
			for c in cards:
				c.active = true
			offset_y = offset_top
			for b in buttons:
				b.base_x = b.rect_position.x
				b.active = true
			locked_in_position = true
			if not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
				$"/root/Main".change_current_menu_path("email")
			tts()
	rect_position.y = offset_y
	
	if offset_y == offset_top or not init_buttons:
		if prompt_reroll:
			for b in buttons:
				b.active = true
				b.can_be_offscreen = true
			prompt_reroll = false
		if emails.size() > 0 and not just_rerolled and (emails[0].type == "comfy_pillow_prompt" or emails[0].type == "comfy_pillow_essence_prompt" or emails[0].type == "add_tile_prompt" or emails[0].type == "chili_powder_essence_prompt" or emails[0].type == "add_item_prompt") and prompt_delay == int(75 * $"/root/Main/Options Sprite/Options".menu_speed):
			for b in buttons:
				b.delayed = true
		if prompt_delay <= 0:
			for b in buttons:
				b.delayed = false
		elif prompt_delay != int(75 * $"/root/Main/Options Sprite/Options".menu_speed) and prompt_delay != -1:
			prompt_delay -= 1
		if (hovering_in_main and not $"/root/Main/Options Sprite/Options".visible and (not OS.is_window_focused() or (get_global_mouse_position().x < container.rect_global_position.x or get_global_mouse_position().x > container.rect_global_position.x + container.rect_size.x * 4.0 or get_global_mouse_position().y < container.rect_global_position.y or get_global_mouse_position().y > container.rect_global_position.y + container.rect_size.y * 4.0)) or not OS.is_window_focused()):
			hovering_in_main = false
		elif not hovering_in_main and OS.is_window_focused() and not (get_global_mouse_position().x < container.rect_global_position.x or get_global_mouse_position().x > container.rect_global_position.x + container.rect_size.x * 4.0 or get_global_mouse_position().y < container.rect_global_position.y or get_global_mouse_position().y > container.rect_global_position.y + container.rect_size.y * 4.0):
			hovering_in_main = true
		
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in label_text.get_child(0).icons:
				i.active = true
		else:
			for i in label_text.texts[8].icons:
				i.active = true
		
		if scroll_bar.visible:
			var tallest_height = 0
			var tallest_card
			for c in cards:
				if c.get_child(0).rect_size.y > tallest_height:
					tallest_height = c.get_child(0).rect_size.y
					tallest_card = c
			for c in cards:
				if tallest_height + extra_button_height > container.rect_size.y:
					c.rect_position.y = ceil(-(tallest_height + extra_button_height - container.rect_size.y) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)) + 20) - 24
				else:
					c.rect_position.y = -6
				if card_offset > extra_button_height:
					c.rect_position.y += card_offset
				else:
					c.rect_position.y += extra_button_height
			if cards.size() > 0:
				if buttons.size() > 0:
					container.get_child(1).rect_position.y = buttons[0].rect_position.y
			var font_offset
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				font_offset = (label_text.get_font("font").get_height() + 2) * label_text.current_scale
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				font_offset = (label_text.get_child(0).get_font("font").get_height() + 2) * label_text.current_scale
			else:
				if label_text.i_spaced:
					font_offset = (label_text.texts[8].get_font("font").get_height() + 3) * label_text.current_scale * 4
				else:
					font_offset = (label_text.get_font("font").get_height() + 4) * label_text.current_scale * 4
			if emails[0].type == "add_tile" or emails[0].type == "add_item":
				if int($"/root/Main/Options Sprite/Options".display_font) > 0:
					label_text.rect_position.y = -((label_text.get_child(0).get_font("font").get_height() * label_text.get_child(0).get_line_count() / 2) - container.rect_size.y) / 2 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)) + 12
				else:
					label_text.rect_position.y = -((label_text.get_font("font").get_height() * label_text.get_line_count() / 2) - container.rect_size.y) / 2 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top))
			var button_mod = 0
			var button_space_mod = 0
			if space_for_buttons and deck_button != null and (deck_button.text_node.raw_string == "   <icon_deny>   " or deck_button.text_node.raw_string == " <icon_deny> "):
				button_mod = -buttons.size() + 1
				button_space_mod = buttons.size()
			var button_size = 0
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if buttons.size() > 0:
					button_size = buttons[0].rect_size.y + 6
				if emails[0].type == "inventory" or emails[0].type == "removal_token_prompt":
					button_mod += 1
				elif inv_open:
					button_mod -= 1
				if emails[0].prompt:
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						label_text.rect_position.y = -((24 + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 2)) - container.rect_size.y + buttons.size() + button_space_mod) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)) + 12
					else:
						label_text.rect_position.y = -((24 + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 2)) - container.rect_size.y + buttons.size() + button_space_mod) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top))
				else:
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						label_text.rect_position.y = -((24 + button_size * buttons.size() + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)) + 12
					else:
						label_text.rect_position.y = -((24 + button_size * buttons.size() + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top))
			else:
				if buttons.size() > 0:
					button_size = buttons[0].rect_size.y + 11
				if emails[0].type == "inventory" or emails[0].type == "removal_token_prompt":
					button_mod += 1
				elif inv_open:
					button_mod -= 1
				if emails[0].prompt:
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						label_text.rect_position.y = 14 + -(((font_offset * buttons.size() + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) / 1 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top))) + 12
					else:
						label_text.rect_position.y = 2 + -(((font_offset * buttons.size() + font_offset * (label_text.text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) / 1 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)))
				else:
					if int($"/root/Main/Options Sprite/Options".display_font) > 0:
						label_text.rect_position.y = 14 + -(((button_size * buttons.size() + font_offset * (label_text.get_child(0).text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) / 1 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top))) + 12
					else:
						label_text.rect_position.y = 2 + -(((button_size * buttons.size() + font_offset * (label_text.text.count("\n") + button_mod + 1)) - container.rect_size.y + buttons.size() + button_space_mod) / 1 * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)))
		else:
			if cards.size() > 0:
				if buttons.size() > 0:
					container.get_child(1).rect_position.y = buttons[0].rect_position.y
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				label_text.rect_position.y = 0
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				label_text.rect_position.y = 12
			else:
				if inv_open or (emails.size() > 0 and (emails[0].type == "inventory" or emails[0].type == "removal_token_prompt")):
					label_text.rect_position.y = -12
				else:
					label_text.rect_position.y = 12
		init_buttons = true
		var font_offset
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			font_offset = (label_text.get_font("font").get_height() + 2) * label_text.current_scale
		elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
			font_offset = (label_text.get_child(0).get_font("font").get_height() + 2) * label_text.current_scale
		else:
			if label_text.i_spaced:
				font_offset = (label_text.texts[8].get_font("font").get_height() + 3) * label_text.current_scale * 4
			else:
				font_offset = (label_text.get_font("font").get_height() + 4) * label_text.current_scale * 4
		for b in range(buttons.size()):
			if scroll_bar.visible:
				if emails[0].type != "inventory" and emails[0].type != "removal_token_prompt" and deck_button != null and deck_button.text_node.raw_string != "   <icon_deny>   " and deck_button.text_node.raw_string != " <icon_deny> ":
					space_for_buttons = true
				if emails[0].type != "add_tile" and emails[0].type != "add_item" and emails[0].type != "inventory" and emails[0].type != "removal_token_prompt":
					if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
						buttons[b].rect_position.y = label_text.rect_position.y + 16 + ((buttons[b].rect_size.y + 8) * b) + (font_offset * (label_text.get_child(0).text.count("\n") + 1))
					else:
						buttons[b].rect_position.y = (label_text.rect_position.y + 3 * (buttons.size() - 1) + ((buttons[b].rect_size.y + 8) * b) + (font_offset * (label_text.text.count("\n") + 1)))
				elif emails[0].type == "inventory" or emails[0].type == "removal_token_prompt":
					if TranslationServer.get_locale() == "ar":
						buttons[b].rect_position = Vector2(16, label_text.rect_position.y + 16)
					else:
						buttons[b].rect_position = Vector2(container.rect_size.x - 16 - buttons[b].rect_size.x, label_text.rect_position.y + 16)
				else:
					var tallest_height = 0
					for c in cards:
						if c.get_child(0).rect_size.y > tallest_height:
							tallest_height = c.get_child(0).rect_size.y
					buttons[b].rect_position.y = ceil(-(tallest_height + extra_button_height - container.rect_size.y) * ((scroll_bar.rect_position.y - scroll_bar.top) / (scroll_bar.bottom - scroll_bar.top)) + 16 + b * (buttons[b].rect_size.y + 8)) - 8
			else:
				if emails[0].type != "inventory" and emails[0].type != "removal_token_prompt" and deck_button != null and deck_button.text_node.raw_string != "   <icon_deny>   " and deck_button.text_node.raw_string != " <icon_deny> ":
					space_for_buttons = false
				if emails[0].type != "add_tile" and emails[0].type != "add_item" and emails[0].type != "inventory" and emails[0].type != "removal_token_prompt":
					if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
						if emails[0].prompt:
							buttons[b].rect_position.y = container.rect_size.y - (buttons[b].rect_size.y + 8) + ((buttons[b].rect_size.y + 8) * b)
						else:
							buttons[b].rect_position.y = container.rect_size.y - ((buttons[b].rect_size.y + 8) * buttons.size()) + ((buttons[b].rect_size.y + 8) * b)
					else:
						if emails[0].prompt:
							buttons[b].rect_position.y = container.rect_size.y - (buttons[b].rect_size.y + 8) + ((buttons[b].rect_size.y + 8) * b)
						else:
							buttons[b].rect_position.y = container.rect_size.y - ((buttons[b].rect_size.y + 8) * buttons.size()) + ((buttons[b].rect_size.y + 8) * b)
				elif emails[0].type != "inventory" and emails[0].type != "removal_token_prompt":
					buttons[b].rect_position.y = b * (buttons[b].rect_size.y + 8) + 8
				else:
					if TranslationServer.get_locale() == "ar":
						buttons[b].rect_position = Vector2(16, label_text.rect_position.y + 16)
					else:
						buttons[b].rect_position = Vector2(container.rect_size.x - 16 - buttons[b].rect_size.x, label_text.rect_position.y + 16)
	elif offset_y != offset_top and emails.size() > 0 and not just_rerolled and emails[0].prompt:
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in label_text.get_child(0).icons:
				i.active = false
		else:
			for i in label_text.texts[8].icons:
				i.active = false
	if buttons.size() > 0:
		container.get_child(1).rect_position.y = buttons[0].rect_position.y
	if emails.size() > 0 and emails[0].prompt and buttons.size() == 2 and buttons[0].visible and buttons[1].visible:
		buttons[0].rect_position.x = container.rect_size.x / 2 - buttons[0].rect_size.x - 8
		buttons[1].rect_position.x = container.rect_size.x / 2 + 8
		buttons[1].rect_position.y = buttons[0].rect_position.y
	if is_inside_tree() and offset_y <= offset_top and OS.is_window_focused() and $"/root/Main/Selector Sprite/Selector".visible:
		if $"/root/Main".down_keys["add_symbol_1"] == 1 and cards.size() >= 1:
			$"/root/Main".down_keys["add_symbol_1"] += 1
			resolve_event(cards[0].data.type)
		elif $"/root/Main".down_keys["add_symbol_2"] == 2 and cards.size() >= 2:
			$"/root/Main".down_keys["add_symbol_2"] += 1
			resolve_event(cards[1].data.type)
		elif $"/root/Main".down_keys["add_symbol_3"] == 3 and cards.size() >= 3:
			$"/root/Main".down_keys["add_symbol_3"] += 1
			resolve_event(cards[2].data.type)
	if scroll_bar.last_pos_y != scroll_bar.rect_position.y and icon_arr.size() > 0:
		scroll_bar.last_pos_y = scroll_bar.rect_position.y
		var arr = icon_arr
		arr += symbol_info_texts
		arr += item_info_texts
		for i in arr:
			if (i.rect_global_position.y >= $"Container".rect_global_position.y + $"Container".rect_size.y) or (i.rect_global_position.y + i.rect_size.y <= $"Container".rect_global_position.y):
				i.set_process_input(false)
				i.visible = false
				i.off_screen = true
			elif not i.is_processing_input():
				i.set_process_input(true)
				i.visible = true
				i.off_screen = false
		for i in disabled_item_sprites:
			if (i.global_position.y >= $"Container".rect_global_position.y + $"Container".rect_size.y) or (i.global_position.y + i.texture.get_size().y * i.scale.y <= $"Container".rect_global_position.y):
				i.visible = false
			elif not i.is_processing_input():
				i.visible = true

func add_event(key, extra_values):
	if $"/root/Main/Landlord".hp - $"/root/Main/Coins".queued_increase - $"/root/Main/Sums/Coin Sum".value <= 0 and key == "ending":
		$"/root/Main/Stats Sprite/Stats".check_if_bossfight_unlocked()
		if (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)) and not $"/root/Main/Options Sprite/Options".old_endless_mode:
			rent_values[0] = 0
	var original_key = key
	if key == "oil_can_essence_prompt":
		key = "oil_can_prompt"
	elif key == "swapping_device_essence_prompt":
		key = "swap_prompt_1"
	if (key == "comrade_help" or key == "init_comrade_help") and not $"/root/Main/Stats Sprite/Stats".essences_unlocked:
		key += "_no_essence"
	var e = email_data.result[key].duplicate(true)
	var push_front = false
	if extra_values != null:
		e["extra_values"] = extra_values
		if extra_values.has("push_front"):
			push_front = true
	else:
		e["extra_values"] = []
	if key == "rent_due" and essence_tokens > 0:
		var s1 = tr("rent_due_text").substr(0, tr("rent_due_text").find("\n", 0) + 2)
		s1 += tr("rent_due_text").substr(s1.length(), tr("rent_due_text").substr(s1.length(), -1).find("\n", 0))
		var s2 = tr("rent_due_text").substr(s1.length(), -1)
		e.text = s1 + "\n" + tr("landlord_essence_partial") + s2
	coffee_essence = false
	if key == "rent_due":
		if $"/root/Main/Items".has_unmodded_item("coffee_essence"):
			coffee_essence = true
			$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["coffee_essence"])].temp_destroy()
	elif key == "boss_fight_1":
		e.text = tr(key + "_text") + "\n" + tr("landlord_thanks") + "\n" + tr("landlord_email_address")
	elif key == "boss_fight_2":
		e.text = tr(key + "_text") + "\n" + tr("commie_email_address")
	elif key == "chili_powder_essence_prompt":
		if $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko":
			e.text = tr("add_item_header") + "\n<group_item_pepper><last_item_pepper>"
		else:
			e.text = tr("add_item_header") + "\n<group_item_pepper> <last_item_pepper>"
	elif key == "add_item_prompt":
		e.text = tr("add_item_header") + "\n"
	elif key == "add_tile_prompt":
		e.text = tr("add_tile_header") + "\n"
	elif key == "fine_print":
		for w in emails:
			if w.type == "fine_print":
				return
		e.text = tr(key + "_text") + "\n"
		var v_num = 0
		if $"/root/Main".sandbox_mode and $"/root/Main".testing_fine_print:
			for i in range(38, $"/root/Main/Landlord".total_fine_print + 7):
				if not $"/root/Main".is_mod_disabled("fine_print_" + str(i) + "_STEAM_ID_" + str($"/root/Main".steam_id) + "_PACK_" + $"/root/Main".mod_pack_nums["fine_print_" + str(i) + "_STEAM_ID_" + str($"/root/Main".steam_id)]):
					var fp = $"/root/Main/Landlord".get_fine_print([i])
					$"/root/Main/Landlord".queued_fine_print.push_back(fp)
					$"/root/Main/Landlord".queued_fine_print[$"/root/Main/Landlord".queued_fine_print.size() - 1]["num"] = int(fp.fine_print_num)
		for f in $"/root/Main/Landlord".queued_fine_print:
			var f_str = tr("fine_print_" + str(f.num)) + "\n"
			if f.has("localized_text") and f.localized_text.has(TranslationServer.get_locale()):
				f_str = f.localized_text[TranslationServer.get_locale()] + "\n"
			elif f.has("text"):
				f_str = f.text + "\n"
			var last_pos = -1
			var pos_offset = 0
			while true:
				last_pos = f_str.substr(last_pos + 1 + pos_offset, -1).find("<value_")
				if last_pos != -1:
					v_num += 1
					f_str = f_str.substr(0, last_pos + 7) + str(v_num) + f_str.substr(last_pos + 8, -1)
					pos_offset = last_pos + 8
				else:
					break
			e.text += f_str
		e.text += "\n" + tr("give_up") + "\n" + tr("landlord_email_address")
	elif original_key == "oil_can_prompt":
		e.text = tr(key + "_text") + " <icon_oil_can>"
	elif original_key == "oil_can_essence_prompt":
		e.text = tr(key + "_text") + " <icon_oil_can_essence>"
	elif original_key == "swap_prompt_1":
		e.text = tr(key + "_text") + " <icon_swapping_device>"
	elif original_key == "swapping_device_essence_prompt":
		e.text = tr(key + "_text") + " <icon_swapping_device_essence>"
	elif (key == "game_over" or key == "out_of_money") and not endless_mode:
		$"/root/Main/Stats Sprite/Stats".add_to_games_lost(current_floor)
	if coffee_essence:
		reels.finalize_clumps()
	elif push_front:
		emails.push_front(e)
	else:
		emails.push_back(e)
	delay_timer = 30
	
	if e.type == "add_tile":
		symbols_to_choose_from = 3
		for fp in $"/root/Main/Landlord".fine_print:
			if fp.num == 30:
				symbols_to_choose_from -= fp.values[0]
				break
		if $"/root/Main/Items".has_unmodded_item("shattered_mirror") or $"/root/Main/Items".item_types_at_end_of_spin.has("shattered_mirror"):
			symbols_to_choose_from -= $"/root/Main/".item_database["shattered_mirror"].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["shattered_mirror"])].item_count
		if $"/root/Main/Items".has_unmodded_item("shattered_mirror_essence") or $"/root/Main/Items".item_types_at_end_of_spin.has("shattered_mirror_essence"):
			symbols_to_choose_from -= $"/root/Main/".item_database["shattered_mirror_essence"].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["shattered_mirror_essence"])].item_count
		if ($"/root/Main/Items".has_unmodded_item("credit_card") or $"/root/Main/Items".item_types_at_end_of_spin.has("credit_card")) and $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["credit_card"])].saved_value == 0 and not $"/root/Main/Items".just_added_items.has("credit_card"):
			symbols_to_choose_from += $"/root/Main/".item_database["credit_card"].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["credit_card"])].item_count
		if ($"/root/Main/Items".has_unmodded_item("credit_card_essence") or $"/root/Main/Items".has_just_destroyed_unmodded_item("credit_card_essence")) and not $"/root/Main/Items".just_added_items.has("credit_card_essence"):
			symbols_to_choose_from += $"/root/Main/".item_database["credit_card_essence"].values[0]
		symbols_to_choose_from += symbols_to_choose_from_from_mods
	elif e.type == "add_item":
		items_to_choose_from = 3
		items_to_choose_from += items_to_choose_from_from_mods
	if emails.size() > 1 and emails[0].type == "chili_powder_essence_prompt" and emails[1].type == "add_tile_prompt":
		visible = false
	if not $"/root/Main/Reels".effects_playing:
		display()

func update_cjk_text_size():
	var rent_text = rent_container.get_child(0)
	if $"/root/Main/Options Sprite/Options".ui_scaling.text == 0.5:
		label_text.scale_mod = -1
		rent_text.scale_mod = -1
		rent_container.get_child(1).scale_mod = -1
		sender_container.get_child(0).scale_mod = -1
	elif $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1:
		label_text.scale_mod = 0
	elif $"/root/Main/Options Sprite/Options".ui_scaling.text <= 1.5:
		label_text.scale_mod = -1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
	else:
		label_text.scale_mod = 1
	
	if $"/root/Main/Options Sprite/Options".ui_scaling.emails == 0.75:
		rent_text.scale_mod = 0
	else:
		rent_text.scale_mod = 1
		rent_container.get_child(1).scale_mod = 1
		sender_container.get_child(0).scale_mod = 1

func display():
	if emails.size() > 0 and not visible:
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			update_cjk_text_size()
		elif int($"/root/Main/Options Sprite/Options".display_font) == 0:
			label_text.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
			label_text.text_mod = -1
			label_text.dont_scale = false
		else:
			label_text.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
			label_text.dont_scale = false
		label_text.force_update = true
		label_text.change_set_size(label_text.base_scale)
		for x in range(reels.reel_width):
			for y in range(reels.reel_height):
				if reels.displayed_icons[y][x] == null:
					break
				if reels.displayed_icons[y][x].type == "dog" or reels.displayed_icons[y][x].type == "rabbit":
					reels.displayed_icons[y][x].stop_animations()
					reels.displayed_icons[y][x].sfx_player.stop()
		var email = emails[0]
		scroll_bar.first_email_input = false
		
		if email.type == "inventory" or emails[0].type == "removal_token_prompt":
			rect_size.x = $"/root/Main/Options Sprite/Options".resolution_x - 64
			rect_size.y = $"/root/Main/Options Sprite/Options".resolution_y
			offset_top = -96
			scroll_bar.bottom = 608
		elif email.prompt:
			if email.type == "comfy_pillow_prompt" or email.type == "comfy_pillow_essence_prompt":
				rect_size.x = $"/root/Main/Options Sprite/Options".resolution_x - 64 * $"/root/Main/Options Sprite/Options".ui_scaling.text * 5.5
			else:
				rect_size.x = $"/root/Main/Options Sprite/Options".resolution_x - 64
			rect_size.y = 128 * ($"/root/Main/Options Sprite/Options".resolution_y / 576)
			offset_top = $"/root/Main/Options Sprite/Options".resolution_y - 224 - 128 * (($"/root/Main/Options Sprite/Options".resolution_y / 576) - 1)
			displaying_inventory = true
		else:
			rect_size.x = 960 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			rect_size.y = 464 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			scroll_bar.bottom = 512
			
		container.rect_size.x = rect_size.x
		
		if email.prompt:
			container.rect_size.y = rect_size.y
		else:
			container.rect_size.y = rect_size.y - 16
		
		add_buttons()
		
		var total_button_height = 0
		for b in buttons:
			total_button_height += b.rect_size.y + 8
		
		if not email.prompt:
			sender_container.rect_size.x = container.rect_size.x
			sender_container.rect_size.y = 48 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			sender_container.rect_position.y = 54 * $"/root/Main/Options Sprite/Options".ui_scaling.emails + 2 / $"/root/Main/Options Sprite/Options".ui_scaling.emails
			
			rent_container.rect_size.x = container.rect_size.x
			rent_container.rect_size.y = 48 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			
			container.rect_position.y = sender_container.rect_position.y + 54 * $"/root/Main/Options Sprite/Options".ui_scaling.emails + 2 / $"/root/Main/Options Sprite/Options".ui_scaling.emails
			border.rect_size = Vector2(rect_size.x + 16, container.rect_position.y + container.rect_size.y + 16)
			border.color = Color($"/root/Main/Options Sprite/Options".colors3["email_border"])
			offset_top = ($"/root/Main/Options Sprite/Options".resolution_y - border.rect_size.y) / 2 + 8
			
			var floor_text = rent_container.get_child(2)
			floor_text.dont_scale = true
			floor_text.change_set_size(floor_text.base_scale)
			if current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING:
				floor_text.raw_string = "<color_1DA1F2>" + str(current_modded_floor.floor_num) + "<end>"
			else:
				floor_text.raw_string = "<color_1DA1F2>" + str(current_floor) + "<end>"
			floor_text.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
			floor_text.update()
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				floor_text.rect_position = Vector2(rent_container.rect_size.x - floor_text.get_font("font").get_string_size(floor_text.get_child(0).text).x * floor_text.current_scale - 8 * floor_text.current_scale, 0)
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				floor_text.rect_position = Vector2(rent_container.rect_size.x - floor_text.get_child(0).get_font("font").get_string_size(floor_text.get_child(0).text).x * floor_text.current_scale - 8 * floor_text.current_scale, 4)
			else:
				floor_text.rect_position = Vector2(rent_container.rect_size.x - floor_text.get_font("font").get_string_size(floor_text.text).x * floor_text.current_scale * 4 - 8 * floor_text.current_scale, 4)
			
			add_deck_button(tr("inventory"))
			add_options_button()
			
			deck_button.visible = true
			options_button.visible = true
			
			if not $"/root/Main/Options Sprite/Options".deck_setting:
				if email.type == "add_tile" or email.type == "add_item":
					container.get_child(1).visible = true
					if $"/root/Main/Options Sprite/Options".CJK_lang:
						container.get_child(1).raw_string = tr("payments") + "<text_color_keyword>" + str(times_rent_paid) + "<end>／<text_color_keyword>"
					elif TranslationServer.get_locale() == "ar":
						container.get_child(1).raw_string = tr("payments") + " <text_color_keyword>" + str(times_to_pay_rent) + "<end>/<text_color_keyword>"
					else:
						container.get_child(1).raw_string = tr("payments") + " <text_color_keyword>" + str(times_rent_paid) + "<end>/<text_color_keyword>"
					if TranslationServer.get_locale() == "ar":
						container.get_child(1).raw_string += str(times_rent_paid) + "<end>"
					else:
						container.get_child(1).raw_string += str(times_to_pay_rent) + "<end>"
					container.get_child(1).text_mod = -1
					
					var extra_values_obj = {}
					
					if email.extra_values.has("forced_rarity"):
						extra_values_obj["forced_rarity"] = email.extra_values.forced_rarity
						if email.extra_values.has("all_symbols_same"):
							extra_values_obj["all_symbols_same"] = email.extra_values.all_symbols_same
						elif email.extra_values.has("all_rarities_same"):
							extra_values_obj["all_rarities_same"] = email.extra_values.all_rarities_same
					if email.extra_values.has("forced_group"):
						extra_values_obj["forced_group"] = email.extra_values.forced_group
					if email.type == "add_tile":
						add_cards(extra_values_obj)
					elif not hex_of_emptiness_trigger or email.type == "add_item":
						add_cards({})
				else:
					container.get_child(1).visible = false
		else:
			container.get_child(1).visible = false
			sender_container.visible = false
			if deck_button != null:
				deck_button.visible = false
			if options_button != null:
				options_button.visible = false
			if email.type == "add_tile_prompt" or email.type == "add_item_prompt":
				var extra_values_obj = {}
				
				if email.extra_values.has("forced_rarity"):
					extra_values_obj["forced_rarity"] = email.extra_values.forced_rarity
				if email.extra_values.has("forced_group"):
					extra_values_obj["forced_group"] = email.extra_values.forced_group
				add_cards(extra_values_obj)
	
		var header_text = sender_container.get_child(0)
		var rent_text = rent_container.get_child(0)
		
		header_text.dont_scale = true
		header_text.change_set_size(header_text.base_scale)
		
		rent_text.dont_scale = true
		rent_text.change_set_size(rent_text.base_scale)
		rent_text.values = rent_values.duplicate(true)
		rent_text.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
		if TranslationServer.get_locale() == "th" or (TranslationServer.get_locale() == "ar" and int($"/root/Main/Options Sprite/Options".display_font) == 2):
			rent_text.text_mod -= 1
			rent_text.rect_position.y = 12
		if times_rent_paid < times_to_pay_rent or email.type == "boss_fight_1" or email.type == "boss_fight_2" or doing_boss_fight:
			if rent_values[1] == 1:
				rent_text.raw_string = tr("non_plural_spins_left")
			else:
				rent_text.raw_string = tr("spins_left")
			if TranslationServer.get_locale() == "pl":
				rent_text.force_update = true
				rent_text.text_mod -= 1
				if $"/root/Main/Options Sprite/Options".ui_scaling.emails > 1:
					rent_text.text_mod -= floor(($"/root/Main/Options Sprite/Options".ui_scaling.emails - 1) * 2)
				if int($"/root/Main/Options Sprite/Options".display_font) == 2:
					rent_text.text_mod -= 1
					rent_text.base_scale = 0.5
					rent_text.change_set_size(0.5)
					rent_text.rect_position.y = 16
				else:
					rent_text.change_set_size(1)
					rent_text.rect_position.y = 10
		elif not doing_boss_fight:
			rent_text.raw_string = tr("win_header")
		rent_text.force_update = true
		rent_text.diff_cjk_space = true
		if TranslationServer.get_locale() == "fr":
			rent_text.custom_icon_offset.x = 5
		
		var t = tr(email.type + "_header")
		if email.has("header"):
			header_text.raw_string = email.header
		elif t == email.type + "_header" or email.type == "win":
			header_text.raw_string = tr("new_email_header")
		else:
			header_text.raw_string = t
		header_text.text_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
		if TranslationServer.get_locale() == "th":
			header_text.text_mod -= 1
		rent_text.set_icon_size()
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			header_text.update()
			header_text.rect_position = Vector2(rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.get_child(0).text).x / 2 * header_text.current_scale, 0)
			rent_text.update()
			rent_text.rect_position = Vector2(rect_size.x / 2 - rent_text.get_font("font").get_string_size(rent_text.get_child(0).text).x / 2 * rent_text.current_scale, -1)
			rent_text.force_update = true
			rent_text.update()
			rent_text.coin_icons_active = false
		else:
			if $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.25:
				rent_text.scale_mod = 2
			elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.5:
				rent_text.scale_mod = 3
			elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 1.75:
				rent_text.scale_mod = 4
			elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2:
				rent_text.scale_mod = 5
			elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2.25:
				rent_text.scale_mod = 6
			elif $"/root/Main/Options Sprite/Options".ui_scaling.emails == 2.5:
				rent_text.scale_mod = 7
			else:
				rent_text.scale_mod = 1
			header_text.update()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				header_text.rect_position.x = rect_size.x / 2 - header_text.get_child(0).get_font("font").get_string_size(header_text.get_child(0).text).x * header_text.current_scale / 2
			else:
				header_text.rect_position.x = rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.text).x * header_text.current_scale * 2
			rent_text.update()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				rent_text.rect_position.x = rect_size.x / 2 - rent_text.get_child(0).get_font("font").get_string_size(rent_text.get_child(0).text).x * rent_text.current_scale / 2
			else:
				rent_text.rect_position.x = rect_size.x / 2 - rent_text.get_font("font").get_string_size(rent_text.text).x * rent_text.current_scale * 2
			rent_text.coin_icons_active = false
			header_text.rect_position.y = 8
			if TranslationServer.get_locale() == "th":
				header_text.rect_position.y += 6
		
		if emails[0].type != "removal_token_prompt":
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				label_text.change_font_size(0.125, true)
			else:
				label_text.change_font_size(1, true)
		
		if email.has("text"):
			if email.type == "ending" and not $"/root/Main".demo:
				$"/root/Main/Stats Sprite/Stats".check_if_bossfight_unlocked()
				if (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)):
					var ll_fate
					if $"/root/Main/Stats Sprite/Stats".saved_ll_fate != null:
						ll_fate = $"/root/Main/Stats Sprite/Stats".saved_ll_fate
					elif false:
						if $"/root/Main/Stats Sprite/Stats".landlord_fates_not_seen.find(13) != -1:
							ll_fate = 13
						else:
							ll_fate = $"/root/Main/Stats Sprite/Stats".landlord_fates_not_seen[0]
						$"/root/Main/Stats Sprite/Stats".saved_ll_fate = ll_fate
						$"/root/Main/Stats Sprite/Stats".landlord_fates_seen.push_back(ll_fate)
						$"/root/Main/Stats Sprite/Stats".landlord_fates_not_seen.erase(ll_fate)
					else:
						ll_fate = landlord_fates_data[floor(rand_range(0, landlord_fates_data.size() - 1))]
						$"/root/Main/Stats Sprite/Stats".saved_ll_fate = ll_fate
					label_text.raw_string = tr("landlord_defeated_1") + "<text_color_keyword>" + tr("landlord_fate_" + str(ll_fate)) + "<end>"
				else:
					label_text.values = [current_floor + 1]
					label_text.raw_string = tr("pre_boss_ending_text")
				if floor_unlocked_this_game:
					floor_unlocked_this_game = false
					label_text.values = [$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor]
					label_text.raw_string += "\n" + tr("floor_unlocked")
				if essences_unlocked_this_game:
					essences_unlocked_this_game = false
					label_text.raw_string += "\n" + tr("essences_unlocked")
				if stats_unlocked_this_game:
					stats_unlocked_this_game = false
					label_text.raw_string += "\n" + tr("stats_unlocked")
				$"/root/Main".save_stats()
				if (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)):
					label_text.raw_string += "\n" + tr("landlord_defeated_2") + tr("commie_email_address")
			elif email.type == "comfy_pillow_prompt" and not $"/root/Main".demo:
				label_text.values = [rent_values[0], rent_values[1], $"/root/Main".item_database[$"/root/Main".existing_items["comfy_pillow"]].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow"])].item_count]
				if rent_values[1] == 1:
					label_text.raw_string = tr("non_plural_spins_left")
				else:
					label_text.raw_string = tr("spins_left")
				label_text.raw_string += "\n\n" + tr("comfy_pillow_prompt_text")
			elif email.type == "comfy_pillow_essence_prompt" and not $"/root/Main".demo:
				label_text.values = [rent_values[0], rent_values[1], $"/root/Main".item_database[$"/root/Main".existing_items["comfy_pillow_essence"]].values[2], $"/root/Main".item_database[$"/root/Main".existing_items["comfy_pillow_essence"]].values[1]]
				if rent_values[1] == 1:
					label_text.raw_string = tr("non_plural_spins_left")
				else:
					label_text.raw_string = tr("spins_left")
				label_text.raw_string += "\n\n" + tr("comfy_pillow_essence_prompt_text")
			elif (email.type == "rent_due" and essence_tokens > 0) or email.type == "chili_powder_essence_prompt" or email.type == "oil_can_prompt" or email.type == "swap_prompt_1" or email.type == "add_tile_prompt" or email.type == "add_item_prompt":
				label_text.raw_string = email.text
				if email.type == "rent_due" and essence_tokens > 0:
					var s1 = tr("rent_due_text").substr(0, tr("rent_due_text").find("\n", 0) + 2)
					s1 += tr("rent_due_text").substr(s1.length(), tr("rent_due_text").substr(s1.length(), -1).find("\n", 0))
					var s2 = tr("rent_due_text").substr(s1.length(), -1)
					label_text.raw_string = s1 + "\n" + tr("landlord_essence_partial") + s2
			elif email.type == "comrade_help" or email.type == "comrade_help_no_essence" or email.type == "init_comrade_help" or email.type == "init_comrade_help_no_essence":
				label_text.values = comrade_values.duplicate(true)
				var tips = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 19, 20, 21, 23, 24]
				current_tip_num = int(tips[floor(rand_range(0, tips.size()))])
				set_tip_values()
				if $"/root/Main/Stats Sprite/Stats".get_converted_stat("total_games_played", "all") > 1:
					label_text.raw_string = tr(email.type + "_text") + "\n<color_C4C4C4>" + tr("tip") + " <end>" + tr("tip_" + str(current_tip_num))
				else:
					label_text.raw_string = tr(email.type + "_text")
			elif email.type == "fine_print":
				label_text.raw_string = email.text
				label_text.values.clear()
				label_text.dynamic_icons.clear()
				for f in $"/root/Main/Landlord".queued_fine_print:
					var f_str = tr("fine_print_" + str(f.num))
					if f.has("localized_text") and f.localized_text.has(TranslationServer.get_locale()):
						f_str = f.localized_text[TranslationServer.get_locale()]
					elif f.has("text"):
						f_str = f.text
					if f.dynamic_icon != null and f_str.find("<dynamic_") != -1:
						label_text.dynamic_icons.push_back(f.dynamic_icon)
					label_text.values += f.values
			elif email.type == "boss_fight_1" or email.type == "boss_fight_2":
				label_text.raw_string = email.text
			elif tr(email.type + "_text") == email.type + "_text":
				label_text.raw_string = email.text
			else:
				label_text.raw_string = tr(email.type + "_text")
		if not visible:
			draw()
		if email.prompt and email.type != "inventory" and email.type != "removal_token_prompt":
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				rect_size.y = 64 + (label_text.get_child(0).get_line_count() + 1) * (label_text.get_font("font").get_height() + 2) * label_text.current_scale
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				rect_size.y = 64 + (label_text.get_child(0).get_line_count() + 1) * label_text.get_child(0).get_font("font").get_height() * label_text.current_scale
			else:
				rect_size.y = 128 + (label_text.get_line_count() + 1) * label_text.get_font("font").get_height() * 4 * label_text.current_scale
			offset_top = $"/root/Main/Options Sprite/Options".resolution_y - rect_size.y - 108 * $"/root/Main/Options Sprite/Options".ui_scaling.emails
			container.rect_size.y = rect_size.y
			for b in buttons:
				b.correct_size()
		if email.type == "comrade_help" or email.type == "init_comrade_help" or email.type == "comrade_help_no_essence" or email.type == "init_comrade_help_no_essence":
			if not $"/root/Main/Options Sprite/Options".CJK_lang and int($"/root/Main/Options Sprite/Options".display_font) == 0:
				for i in label_text.texts[8].icons:
					i.rect_size = Vector2(224, 224)
		elif email.type == "chili_powder_essence_prompt" or email.type == "add_tile_prompt" or email.type == "add_item_prompt":
			for r in reels.reels:
				for i in r.icons:
					i.active = false
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				for i in label_text.icons:
					i.update_hitbox()
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				for i in label_text.get_child(0).icons:
					i.update_hitbox()
			else:
				for i in label_text.texts[8].icons:
					i.update_hitbox()
		var f_mod = 0
		if label_text.i_spaced or label_text.e_spaced:
			f_mod = 3
		if email.prompt and email.type != "inventory" and email.type != "removal_token_prompt":
			if (not $"/root/Main/Options Sprite/Options".CJK_lang and ((label_text.get_line_count() + 1) * (label_text.get_font("font").get_height() + f_mod) * label_text.current_scale * 4 > container.rect_size.y)) or ($"/root/Main/Options Sprite/Options".CJK_lang and (label_text.get_child(0).get_line_count() + 1) * (label_text.get_font("font").get_height() + 2) * label_text.current_scale > container.rect_size.y) or (int($"/root/Main/Options Sprite/Options".display_font) > 0 and label_text.get_child(0).get_line_count() * (label_text.get_child(0).get_font("font").get_height() + f_mod) * label_text.current_scale > container.rect_size.y):
				scroll_bar.visible = true
		elif (not $"/root/Main/Options Sprite/Options".CJK_lang and (label_text.get_line_count() * (label_text.get_font("font").get_height() + f_mod) * label_text.current_scale * 4 + total_button_height > container.rect_size.y)) or ($"/root/Main/Options Sprite/Options".CJK_lang and label_text.get_child(0).get_line_count() * (label_text.get_font("font").get_height() + 2) * label_text.current_scale + total_button_height > container.rect_size.y) or (int($"/root/Main/Options Sprite/Options".display_font) > 0 and label_text.get_child(0).get_line_count() * (label_text.get_child(0).get_font("font").get_height() + f_mod) * label_text.current_scale + total_button_height > container.rect_size.y):
			scroll_bar.visible = true
		scroll_bar.rect_scale = Vector2($"/root/Main/Options Sprite/Options".ui_scaling.emails, $"/root/Main/Options Sprite/Options".ui_scaling.emails)
		scroll_bar.top = container.rect_position.y
		if not emails[0].prompt:
			scroll_bar.rect_position.x = border.rect_size.x - 8 - scroll_bar.get_child(0).rect_size.x / 2 * scroll_bar.rect_scale.x
			scroll_bar.bottom = round(border.rect_size.y - container.rect_position.y + scroll_bar.rect_size.y * scroll_bar.rect_scale.y)
		else:
			scroll_bar.rect_position.x = container.rect_size.x - scroll_bar.get_child(0).rect_size.x / 2 * scroll_bar.rect_scale.x
			scroll_bar.bottom = round(container.rect_size.y + scroll_bar.get_child(0).rect_size.y * scroll_bar.rect_scale.y)
		scroll_bar.rect_position.y = scroll_bar.top

func add_buttons():
	var email = emails[0]
	var replies = email.replies.duplicate(true)
	var num = email.replies.size()
	
	if email.type == "rent_due":
		if $"/root/Main/Items".has_unmodded_item("devils_deal"):
			replies.push_front("<icon_" + $"/root/Main".existing_items["devils_deal"] + ">")
		if $"/root/Main/Items".has_unmodded_item("piggy_bank"):
			replies.push_front("<icon_" + $"/root/Main".existing_items["piggy_bank"] + ">")
		if $"/root/Main/Items".has_unmodded_item("swear_jar"):
			replies.push_front("<icon_" + $"/root/Main".existing_items["swear_jar"] + ">")
		if $"/root/Main/Items".has_unmodded_item("coffee") and coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value < rent_values[0]:
			replies.push_front("<icon_" + $"/root/Main".existing_items["coffee"] + ">")
		for m in mods.items:
			if m.can_be_destroyed_before_rent and $"/root/Main/Items".item_types.has(m.type):
				replies.push_front("<icon_" + m.type + ">")
	elif email.type == "add_tile" or email.type == "add_tile_prompt":
		if reroll_tokens > reroll_cost - 1 and not hex_of_emptiness_trigger:
			replies.push_back("reroll_pay")
		replies.push_back("skip")
	elif email.type == "add_item" or email.type == "add_item_prompt":
		replies.push_back("skip")
	elif $"/root/Main".demo and email.type == "win" and OS.get_unix_time() < 1610128800:
		replies.erase("early_access_timer_2")
	
	var reply_to_be_removed
	
	for b in buttons:
		b.queue_free()
	buttons.clear()
	
	for b in range(replies.size()):
		if replies[b] == "pay_reply" and coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value < rent_values[0]:
			reply_to_be_removed = replies[b]
		else:
			var button = preload("res://TT Button.tscn").instance()
			var reply_text = tr(replies[b])
			button.button_text = tr(replies[b])
			var devils_deal = "<icon_" + $"/root/Main".existing_items["devils_deal"] + ">"
			var piggy_bank = "<icon_" + $"/root/Main".existing_items["piggy_bank"] + ">"
			var swear_jar = "<icon_" + $"/root/Main".existing_items["swear_jar"] + ">"
			var coffee = "<icon_" + $"/root/Main".existing_items["coffee"] + ">"
			match replies[b]:
				devils_deal, piggy_bank, swear_jar, coffee:
					button.color = Color($"/root/Main/Options Sprite/Options".colors3["item_background"])
					button.color_type = "item_background"
				"<icon_confirm>":
					button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_misc"])
					button.color_type = "button_color_misc"
				"<icon_deny>":
					button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_misc"])
					button.color_type = "button_color_misc"
					if email.type == "inventory":
						button.shortcuts = ["deny_cancel", "inventory"]
					else:
						button.shortcuts = ["deny_cancel"]
				_:
					button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_misc"])
					button.color_type = "button_color_misc"
			if email.type != "add_tile" and email.type != "add_item":
				button.selector_alignment = "omni"
			for m in mods.items:
				if m.can_be_destroyed_before_rent and $"/root/Main/Items".item_types.has(replies[b].substr(6, replies[b].length() - 7)):
					button.color = Color($"/root/Main/Options Sprite/Options".colors3["item_background"])
					break
			button.target = self
			match replies[b]:
				"wishlist_button", "early_access_timer_2", "steam_button":
					button.call = "store_page"
				"discord_button":
					button.call = "discord"
				"twitter_button":
					button.call = "twitter"
				"newsletter_button":
					button.call = "newsletter"
				_:
					button.call = "resolve_event"
					button.args = [replies[b]]
					button.args = [replies[b]]
			button.active = false
			button.can_be_offscreen = true
			
			buttons.push_back(button)
	if buttons.size() > 0:
		container.get_child(1).rect_position.y = buttons[0].rect_position.y
	replies.erase(reply_to_be_removed)
	
	var total_button_width = 0
	for b in range(buttons.size()):
		container.add_child(buttons[b])
		if replies[b] == "pay_reply":
			buttons[b].text_node.values = [rent_values[0]]
		elif replies[b] == "reroll_pay":
			buttons[b].text_node.values = [reroll_tokens]
			buttons[b].shortcuts = ["use_reroll"]
		elif buttons[b].button_text == tr("skip"):
			buttons[b].shortcuts = ["skip"]
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			buttons[b].text_node.get_child(0).custom_max_width = 10000
		else:
			buttons[b].text_node.texts[8].custom_max_width = 10000
		buttons[b].text_node.force_update = true
		buttons[b].text_node.update()
		buttons[b].button_text = buttons[b].text_node.text
		buttons[b].update_size()
		buttons[b].base_x = buttons[b].rect_position.x
		buttons[b].active = false
		buttons[b].email_button = true
	for b in buttons:
		b.correct_size()
		b.rect_position.x = container.rect_size.x / 2 - b.rect_size.x / 2
		b.visible = false

func add_cards(f_rarities):
	var email = emails[0]
	var database
	
	if not visible and (symbols_to_choose_from != cards.size() or symbols_to_choose_from == 0):
		var card_pool
		var r_chances
		if email.type == "add_tile" or email.type == "add_tile_prompt":
			if email.extra_values.has("forced_group"):
				card_pool = $"/root/Main/".rarity_database["symbols"].duplicate(true)
				for c in card_pool.keys():
					var c_tbe = []
					for i in card_pool[c]:
						if $"/root/Main/".group_database["symbols"][email.extra_values.forced_group].find(i) == -1:
							c_tbe.push_back(i)
					for z in c_tbe:
						card_pool[c].erase(z)
			else:
				card_pool = $"/root/Main/".rarity_database["symbols"].duplicate(true)
				if not reels.can_add_highlander():
					card_pool["very_rare"].erase("highlander")
			r_chances = $"/root/Main/".rarity_chances["symbols"].duplicate(true)
			database = $"/root/Main/".tile_database
			for r in r_chances.keys():
				r_chances[r] *= rarity_bonuses["symbols"][r]
			if not $"/root/Main/Stats Sprite/Stats".essences_unlocked and not $"/root/Main".demo:
				if database.has("essence_capsule"):
					card_pool[database["essence_capsule"].rarity].erase("essence_capsule")
		elif email.type == "add_item" or email.type == "add_item_prompt":
			database = $"/root/Main/".item_database
			card_pool = $"/root/Main/".rarity_database["items"].duplicate(true)
			for i in $"/root/Main/Items".items:
				card_pool[i.rarity].erase(i.type)
			for i in $"/root/Main/Items".recently_destroyed_items:
				card_pool[i.rarity].erase(i.type)
			r_chances = $"/root/Main/".rarity_chances["items"].duplicate(true)
			for r in r_chances.keys():
				r_chances[r] *= rarity_bonuses["items"][r]
			if email.extra_values.hash() != {"forced_rarity": ["essence", "essence", "essence"]}.hash():
				if comfy_pillow_triggers > 0:
					email.extra_values = {"forced_rarity": []}
					for i in range(comfy_pillow_triggers):
						email.extra_values.forced_rarity.push_back("rare")
					comfy_pillow_triggers = 0
				if comfy_pillow_essence_triggers > 0:
					email.extra_values = {"forced_rarity": []}
					for i in range(comfy_pillow_essence_triggers):
						email.extra_values.forced_rarity.push_back("very_rare")
					comfy_pillow_essence_triggers = 0
			if not $"/root/Main/Stats Sprite/Stats".essences_unlocked and not $"/root/Main".demo:
				if database.has("dishwasher"):
					card_pool[database["dishwasher"].rarity].erase("dishwasher")
				if database.has("popsicle"):
					card_pool[database["popsicle"].rarity].erase("popsicle")
		var c_tbe = {}
		for r in card_pool.keys():
			c_tbe[r] = []
			for c in card_pool[r]:
				if $"/root/Main".is_mod_disabled(c):
					c_tbe[r].push_back(c)
		for r in c_tbe.keys():
			for c in c_tbe[r]:
				card_pool[r].erase(c)
		if email.type == "add_tile":
			symbols_to_choose_from = 3
			for fp in $"/root/Main/Landlord".fine_print:
				if fp.num == 30:
					symbols_to_choose_from -= fp.values[0]
					break
			if $"/root/Main/Items".items.size() == $"/root/Main/Items".item_types.size():
				if $"/root/Main/Items".has_unmodded_item("shattered_mirror") or $"/root/Main/Items".item_types_at_end_of_spin.has("shattered_mirror"):
					symbols_to_choose_from -= $"/root/Main/".item_database["shattered_mirror"].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("shattered_mirror")].item_count
				if $"/root/Main/Items".has_unmodded_item("shattered_mirror_essence") or $"/root/Main/Items".item_types_at_end_of_spin.has("shattered_mirror_essence"):
					symbols_to_choose_from -= $"/root/Main/".item_database["shattered_mirror_essence"].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("shattered_mirror_essence")].item_count
				if ($"/root/Main/Items".has_unmodded_item("credit_card") or $"/root/Main/Items".item_types_at_end_of_spin.has("credit_card")) and $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("credit_card")].saved_value == 0 and not $"/root/Main/Items".just_added_items.has("credit_card"):
					symbols_to_choose_from += $"/root/Main/".item_database["credit_card"].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("credit_card")].item_count
				if ($"/root/Main/Items".has_unmodded_item("credit_card_essence") or $"/root/Main/Items".has_just_destroyed_unmodded_item("credit_card_essence")) and not $"/root/Main/Items".just_added_items.has("credit_card_essence"):
					symbols_to_choose_from += $"/root/Main/".item_database["credit_card_essence"].values[0]
			symbols_to_choose_from += symbols_to_choose_from_from_mods
		elif email.type == "add_item":
			items_to_choose_from = 3
			items_to_choose_from += items_to_choose_from_from_mods
		
		var stcf = 3
		
		if symbols_to_choose_from > 3 and email.type == "add_tile":
			emails.remove(0)
			buttons.clear()
			var f_rar
			if email.has("extra_values") and email.extra_values.has("forced_rarity"):
				f_rar = email.extra_values
			else:
				f_rar = f_rarities.duplicate(true)
			delay_timer = 0
			f_rar["push_front"] = true
			add_event("add_tile_prompt", f_rar)
			return
		elif items_to_choose_from > 3 and email.type == "add_item":
			emails.remove(0)
			buttons.clear()
			var f_rar
			if email.has("extra_values") and email.extra_values.has("forced_rarity"):
				f_rar = email.extra_values
			else:
				f_rar = f_rarities.duplicate(true)
			delay_timer = 0
			f_rar["push_front"] = true
			add_event("add_item_prompt", f_rar)
			return
		
		if email.type == "add_item" or email.type == "add_item_prompt":
			stcf = items_to_choose_from
		else:
			stcf = symbols_to_choose_from
		
		for c in range(stcf - cards.size()):
			var rarity
			var card
			if stcf <= 3:
				card = preload("res://Card.tscn").instance()
				if email.type == "add_item":
					card.item = true
			if saved_card_types.size() < stcf or (c < saved_card_types.size() - 1 and saved_card_types[c] == null) or (email.extra_values.has("forced_rarity") and (email.extra_values.forced_rarity.has("all_symbols_same") or email.extra_values.forced_rarity.has("all_rarities_same"))):
				randomize()
				var rand_num = rand_range(0, 1)
				
				var forced_rarity_arr = []
				if email.extra_values.has("forced_rarity"):
					forced_rarity_arr = email.extra_values.forced_rarity
					if c == 0:
						forced_rarity_arr.shuffle()
				
				if c < forced_rarity_arr.size() and ((email.extra_values.has("or_better") and not email.extra_values.or_better) or (not email.extra_values.has("or_better"))):
					rarity = forced_rarity_arr[c]
					if typeof(card_pool) == TYPE_DICTIONARY and not card.item:
						if rarity == "very_rare" and card_pool["very_rare"].size() == 0:
							rarity = "rare"
						if rarity == "rare" and card_pool["rare"].size() == 0:
							rarity = "uncommon"
						if rarity == "uncommon" and card_pool["uncommon"].size() == 0:
							rarity = "common"
				elif email.extra_values.has("forced_rarity") and (email.extra_values.has("all_symbols_same") or email.extra_values.has("all_rarities_same")):
					rarity = forced_rarity_arr[0]
					if typeof(card_pool) == TYPE_DICTIONARY and not card.item:
						if rarity == "very_rare" and card_pool["very_rare"].size() == 0:
							rarity = "rare"
						if rarity == "rare" and card_pool["rare"].size() == 0:
							rarity = "uncommon"
						if rarity == "uncommon" and card_pool["uncommon"].size() == 0:
							rarity = "common"
				elif card_pool.has("very_rare") and rand_num < r_chances.very_rare and card_pool["very_rare"].size() > 0:
					rarity = "very_rare"
				elif card_pool.has("rare") and rand_num < r_chances.very_rare + r_chances.rare and card_pool["rare"].size() > 0:
					rarity = "rare"
				elif card_pool.has("uncommon") and rand_num < r_chances.very_rare + r_chances.rare + r_chances.uncommon and card_pool["uncommon"].size() > 0:
					rarity = "uncommon"
				elif card_pool.has("common") and card_pool["common"].size() > 0:
					rarity = "common"
					
				if c < forced_rarity_arr.size() and email.extra_values.has("or_better") and email.extra_values.or_better:
					var rarity_order = ["common", "uncommon", "rare", "very_rare"]
					if rarity_order.find(forced_rarity_arr[c]) > rarity_order.find(rarity):
						rarity = forced_rarity_arr[c]
				randomize()
				if rarity != null and card_pool.has(rarity) and card_pool[rarity].size() > 0:
					var rand_symbol
					if stcf <= 3:
						card.data = database[card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]]
					elif email.extra_values.has("loaded_data"):
						pass
					elif $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko":
						rand_symbol = card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]
						if rand_symbol == "coin":
							email.text += "<icon_hover_coin>"
						else:
							email.text += "<icon_" + rand_symbol + ">"
						card_pool[rarity].erase(rand_symbol)
					else:
						rand_symbol = card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]
						if rand_symbol == "coin":
							email.text += "<icon_hover_coin> "
						else:
							email.text += "<icon_" + rand_symbol + "> "
						card_pool[rarity].erase(rand_symbol)
					if rand_symbol != null and not $"/root/Main/".group_database.symbols.taken.has(rand_symbol) and not $"/root/Main/".group_database.symbols.passed.has(rand_symbol) and email.type == "add_tile_prompt":
						$"/root/Main/".group_database.symbols.passed.push_back(rand_symbol)
				elif email.type == "add_item":
					if c < forced_rarity_arr.size() and ((email.extra_values.has("or_better") and not email.extra_values.or_better) or (not email.extra_values.has("or_better"))):
						rarity = forced_rarity_arr[c]
					elif rand_num < r_chances.very_rare:
						rarity = "very_rare"
					elif rand_num < r_chances.very_rare + r_chances.rare:
						rarity = "rare"
					elif rand_num < r_chances.very_rare + r_chances.rare + r_chances.uncommon:
						rarity = "uncommon"
					else:
						rarity = "common"
					match rarity:
						"essence":
							card.data = database["pool_ball_essence"]
						_:
							card_pool = $"/root/Main/".rarity_database["items"][rarity].duplicate(true)
							for d in cards:
								card_pool.erase(d.data.type)
							card.data = database[card_pool[rand_range(0, card_pool.size())]]
				else:
					if stcf <= 3:
						if database.has("coin"):
							card.data = database["coin"]
						else:
							card.data = database["missing"]
					elif email.extra_values.has("loaded_data"):
						pass
					elif $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko":
						if email.type == "add_item_prompt":
							email.text += "<icon_pool_ball>"
						else:
							email.text += "<icon_hover_coin>"
					else:
						if email.type == "add_item_prompt":
							email.text += "<icon_pool_ball> "
						else:
							email.text += "<icon_hover_coin> "
				if stcf <= 3:
					if rarity != null and card_pool.has(rarity):
						card_pool[rarity].erase(card.data.type)
					saved_card_types.push_back(card.data.type)
					cards.push_back(card)
			else:
				if database.has(saved_card_types[c]):
					card.data = database[saved_card_types[c]]
				elif email.type == "add_tile":
					card.data = $"/root/Main/".tile_database["missing"]
				elif email.type == "add_item":
					card.data = $"/root/Main/".item_database["item_missing"]
				cards.push_back(card)
			if stcf <= 3 and not $"/root/Main/".group_database.symbols.taken.has(card.data.type) and not $"/root/Main/".group_database.symbols.passed.has(card.data.type) and email.type == "add_tile":
				$"/root/Main/".group_database.symbols.passed.push_back(card.data.type)
		if typeof(email.extra_values) == TYPE_DICTIONARY:
			email.extra_values["loaded_data"] = true
		$"/root/Main".save_game()
		update_card_positions()
		card_pool.clear()

func update_card_positions():
	var total_card_width = 0
	var tallest_height = 0
	for c in cards:
		container.add_child(c)
		total_card_width += c.border.rect_size.x
		if tallest_height < (c.background.rect_size.y + 2) / 2:
			tallest_height = (c.background.rect_size.y + 2) / 2
	var width_so_far = 0
	var last_pos = 0
	for c in cards:
		c.rect_position.x = rect_size.x / 2 - total_card_width / 2 + last_pos - 4
		width_so_far += c.border.rect_size.x + 8
		last_pos = c.rect_position.x + c.border.rect_size.x - cards[0].rect_position.x + 8

func draw():
	offset_y = $"/root/Main/Options Sprite/Options".resolution_y + 448
	init_buttons = false
	
	rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - rect_size.x / 2
	rect_position.y = offset_y
	visible = true
	container.visible = true
	label_text.visible = true
	if emails[0].prompt:
		container.color = Color("F5" + $"/root/Main/Options Sprite/Options".colors3["inventory_background"])
		if deck_button != null:
			deck_button.visible = false
		if options_button != null:
			options_button.visible = false
	else:
		border.visible = true
		sender_container.visible = true
		if emails[0].type == "add_tile" or emails[0].type == "add_item":
			rent_container.visible = true
		rent_container.visible = true
		container.color = Color($"/root/Main/Options Sprite/Options".colors3["email_background"])
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		label_text.update()
		page_height = float(label_text.get_line_count() - 4.0)
		if buttons.size() > 0:
			page_height += 1
	extra_button_height = 16
	for b in buttons:
		b.update_size()
		b.correct_size()
		extra_button_height += b.rect_size.y + 8
	var payment_text = container.get_child(1)
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		if payment_text.get_child(0).get_font("font").get_height() * payment_text.current_scale > extra_button_height:
			card_offset = payment_text.get_child(0).get_font("font").get_height() * payment_text.current_scale
	else:
		if payment_text.get_font("font").get_height() * payment_text.current_scale * 4 > extra_button_height:
			card_offset = payment_text.get_font("font").get_height() * payment_text.current_scale * 4
	if extra_button_height > 0:
		for c in cards:
			c.rect_position.y = -6
	for c in cards:
		c.rect_position.y += extra_button_height
		if c.get_child(0).rect_size.y + extra_button_height >= container.rect_size.y:
			scroll_bar.visible = true
			break
	set_tip_values()
	label_text.update()
	
	for b in buttons:
		if hex_of_hoarding_trigger and (b.button_text == tr("skip") or b.text_node.raw_string == tr("skip") or b.text_node.get_child(0).text == tr("skip")) and symbols_to_choose_from > 0:
			b.visible = false
		else:
			b.visible = true
		b.get_child(1).rect_size.y = 56

func add_options_button():
	if options_button != null:
		options_button.queue_free()
		sender_container.remove_child(options_button)
	options_button = preload("res://TT Button.tscn").instance()

	options_button.can_be_offscreen = true
	options_button.border_thickness = (floor(($"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25) * 2) - 2
	options_button.button_text = tr("options")
	options_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_options"])
	options_button.color_type = "button_color_options"
	options_button.target = $"/root/Main/Options Sprite/Options"
	options_button.call = "open"
	options_button.toggle = false
	options_button.args = [options_button]
	options_button.shortcuts = ["options"]
	options_button.email_button = true
	options_button.dont_scale = true
	options_button.scale_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
	options_button.selector_alignment = "above_icons"
	
	sender_container.add_child(options_button)
	
	if int($"/root/Main/Options Sprite/Options".display_font) > 0 and TranslationServer.get_locale() != "th":
		options_button.text_node.get_child(0).rect_position = Vector2(0, 0)
	
	options_button.rect_position = Vector2(0, 0)
	options_button.base_x = 0
	options_button.update_size()

func remove(last_email):
	if emails.size() == 0:
		if last_email != null and not last_email.prompt:
			hex_of_emptiness_trigger = false
			hex_of_hoarding_trigger = false
		if total_coins > 0:
			$"/root/Main/Sums/Coin Sum".add_value(total_coins)
			$"/root/Main/Sums/Coin Sum".adding = true
			$"/root/Main/Sums/HP Sum".add_value(total_coins)
			$"/root/Main/Sums/HP Sum".adding = true
			total_coins = 0
	if deck_button != null:
		deck_button.queue_free()
		sender_container.remove_child(deck_button)
		deck_button = null
	if options_button != null:
		options_button.queue_free()
		sender_container.remove_child(options_button)
		options_button = null
	
	for b in buttons:
		b.queue_free()
		container.remove_child(b)
	buttons.clear()
	
	for c in cards:
		c.queue_free()
		container.remove_child(c)
	cards.clear()
	
	prompt_delay = int(75 * $"/root/Main/Options Sprite/Options".menu_speed)
	
	visible = false
	border.visible = false
	container.visible = false
	sender_container.visible = false
	rent_container.visible = false
	label_text.visible = false
	scroll_bar.visible = false
	
	label_text.raw_string = ""

func update_saved_symbol_order(arr):
	if saved_symbol_order.size() == 0:
		for s in arr:
			if not saved_symbol_order.has(s.type + s.value_text + s.permanent_multiplier + s.permanent_bonus):
				saved_symbol_order.push_back(s.type + s.value_text + s.permanent_multiplier + s.permanent_bonus)

func add_deck_button(s):
	if emails.size() > 0 and emails[0].type == "removal_token_prompt":
		return
	if deck_button != null:
		deck_button.queue_free()
		sender_container.remove_child(deck_button)
	deck_button = preload("res://TT Button.tscn").instance()

	deck_button.can_be_offscreen = true
	deck_button.border_thickness = (floor(($"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25) * 2) - 2
	deck_button.button_text = s
	deck_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_inventory"])
	deck_button.color_type = "button_color_inventory"
	deck_button.target = self
	deck_button.call = "draw_deck"
	deck_button.shortcuts = ["inventory"]
	deck_button.toggle = false
	deck_button.email_button = true
	deck_button.dont_scale = true
	deck_button.scale_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.emails) / 0.25)
	
	sender_container.add_child(deck_button)
	
	deck_button.text_node.force_update = true
	deck_button.text_node.update()
	deck_button.button_text = deck_button.text_node.text
	deck_button.update_size()
	deck_button.button_text = deck_button.text_node.raw_string
	deck_button.rect_position = Vector2(sender_container.rect_size.x - deck_button.rect_size.x, 0)
	deck_button.base_x = deck_button.rect_position.x
	deck_button.selector_alignment = "above_icons"
	
	if int($"/root/Main/Options Sprite/Options".display_font) > 0 and TranslationServer.get_locale() != "th":
		deck_button.text_node.get_child(0).rect_position = Vector2(0, 0)
	
	symbol_counts.clear()
	symbol_data.clear()
	destroyed_symbol_counts.clear()
	destroyed_item_counts.clear()
	removed_symbol_counts.clear()

func draw_prompt_deck():
	for e in $"/root/Main/Reels".texts:
		if e.effect_timer > 0:
			return
	for r in $"/root/Main/Reels".reels:
		if r.spinning:
			return
	if not $"/root/Main/Reels".effects_playing:
		add_event("inventory", null)
		delay_timer = 0
		draw_deck()

func draw_removal_prompt(first_prompt):
	for e in $"/root/Main/Reels".texts:
		if e.effect_timer > 0:
			return
	for r in $"/root/Main/Reels".reels:
		if r.spinning:
			return
	if not $"/root/Main/Reels".effects_playing:
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in $"/root/Main/Menus".buttons_menu.removal_button.text_node.icons:
				i.active = false
		else:
			for i in $"/root/Main/Menus".buttons_menu.removal_button.text_node.texts[8].icons:
				i.active = false
		removing = true
		if first_prompt:
			add_event("removal_token_prompt", null)
		else:
			add_event("removal_token_prompt", {"push_front": true, "reset_position": false})
		delay_timer = 0
		draw_deck()
		if int($"/root/Main/Options Sprite/Options".display_font) > 0:
			icon_arr = label_text.get_child(0).icons
			for i in icon_arr:
				if i.type == "removal_token":
					i.rect_position.x -= 8

func check_spend_triggers(effect_type):
	var currency_values = {"coins": 0, "reroll": 0, "removal": 0, "essence": 0}
	match effect_type:
		"spend_removal_token":
			if $"/root/Main/Items".has_unmodded_item("gray_pepper"):
				var gp = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["gray_pepper"])]
				currency_values["coins"] += gp.values[0] * gp.item_count
			if $"/root/Main/Items".has_unmodded_item("gray_pepper_essence"):
				var gpe = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["gray_pepper_essence"])]
				gpe.destroy()
				currency_values["coins"] += gpe.values[0] * gpe.item_count
		"spend_reroll_token":
			if $"/root/Main/Items".has_unmodded_item("lime_pepper"):
				var lp = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["lime_pepper"])]
				$"/root/Main/Sums/Coin Sum".add_value(lp.values[0] * lp.item_count)
				$"/root/Main/Sums/Coin Sum".adding = true
				$"/root/Main/Sums/HP Sum".add_value(lp.values[0] * lp.item_count)
				$"/root/Main/Sums/HP Sum".adding = true
			if $"/root/Main/Items".has_unmodded_item("lime_pepper_essence"):
				var lpe = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["lime_pepper_essence"])]
				lpe.destroy()
				$"/root/Main/Sums/Coin Sum".add_value(lpe.values[0])
				$"/root/Main/Sums/Coin Sum".adding = true
				$"/root/Main/Sums/HP Sum".add_value(lpe.values[0])
				$"/root/Main/Sums/HP Sum".adding = true
		"skip":
			if $"/root/Main/Items".has_unmodded_item("pink_pepper"):
				var pp = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["pink_pepper"])]
				$"/root/Main/Sums/Coin Sum".add_value(pp.values[0] * pp.item_count)
				$"/root/Main/Sums/Coin Sum".adding = true
				$"/root/Main/Sums/HP Sum".add_value(pp.values[0] * pp.item_count)
				$"/root/Main/Sums/HP Sum".adding = true
			if $"/root/Main/Items".has_unmodded_item("pink_pepper_essence"):
				var ppe = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["pink_pepper_essence"])]
				ppe.destroy()
				$"/root/Main/Sums/Coin Sum".add_value(ppe.values[0])
				$"/root/Main/Sums/Coin Sum".adding = true
				$"/root/Main/Sums/HP Sum".add_value(ppe.values[0])
				$"/root/Main/Sums/HP Sum".adding = true
	if currency_values["coins"] != 0:
		$"/root/Main/Sums/Coin Sum".add_value(currency_values["coins"])
		$"/root/Main/Sums/Coin Sum".adding = true
		$"/root/Main/Sums/HP Sum".add_value(currency_values["coins"])
		$"/root/Main/Sums/HP Sum".adding = true
	if currency_values["reroll"] != 0 or currency_values["removal"] != 0 or currency_values["essence"] != 0:
		$"/root/Main/Sums/Extra Sum".add_value(currency_values["reroll"], currency_values["removal"], currency_values["essence"])
		$"/root/Main/Sums/Extra Sum".adding = true
		removal_tokens += currency_values["removal"]
		reroll_tokens += currency_values["reroll"]
		essence_tokens += currency_values["essence"]

func set_tip_values():
	if $"/root/Main/Stats Sprite/Stats".get_converted_stat("total_games_played", "all") > 1 and emails.size() > 0 and (emails[0].type == "comrade_help" or emails[0].type == "comrade_help_no_essence" or emails[0].type == "init_comrade_help" or emails[0].type == "init_comrade_help_no_essence"):
		match current_tip_num:
			2:
				label_text.values.resize(4)
				label_text.values[3] = 20
			4:
				label_text.values.resize(4)
				label_text.values[3] = 23
			14:
				label_text.values.resize(6)
				label_text.values[3] = 7
				label_text.values[4] = 1
				label_text.values[5] = 6
			16:
				label_text.values.resize(4)
				label_text.values[3] = 1
			24:
				label_text.values.resize(6)
				label_text.values[3] = 10
				label_text.values[4] = 1
				label_text.values[5] = 10

func invert_ar_rows(arr, n1, n2):
	var a = arr.duplicate(true)
	a = a.slice(n1, n2)
	var a2 = []
	var y_postiions = {}
	for i in a:
		if not y_postiions.has(i.rect_position.y):
			y_postiions[i.rect_position.y] = []
		y_postiions[i.rect_position.y].push_front(i)
	for k in y_postiions.keys():
		a2 += y_postiions[k]
	return a2

func draw_deck():
	if emails.size() > 0 and emails[0].type == "add_tile_prompt":
		return
	
	label_text.dont_scale = true
	displaying_inventory = true
	inv_open = true
	
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		label_text.scale_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		label_text.i_spaced = true
		label_text.scale_mod = -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
	else:
		label_text.i_spaced = true
		label_text.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
	
	if $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 1:
		label_text.text_mod = -1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
		if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
			label_text.scale_mod -= 1
	
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
			label_text.scale_mod -= 2
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
			label_text.scale_mod -= 3
	
	var text_color = "<color_" + $"/root/Main/Options Sprite/Options".colors3["inventory_text"] + ">"
	
	if emails.size() > 0 and emails[0].type != "inventory" and emails[0].type != "removal_token_prompt":
		container.get_child(1).visible = false
		saved_label_values = label_text.values.duplicate(true)
		var header_text = sender_container.get_child(0)
		header_text.raw_string = tr("inventory")
		header_text.update()
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			header_text.rect_position.x = rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.get_child(0).text).x / 2 * header_text.current_scale
		elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
			header_text.rect_position.x = rect_size.x / 2 - header_text.get_child(0).get_font("font").get_string_size(header_text.get_child(0).text).x * header_text.current_scale / 2
		else:
			header_text.rect_position.x = rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.text).x * header_text.current_scale * 2
		
		if $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko" and TranslationServer.get_locale() != "ja":
			add_deck_button(" <icon_deny> ")
		elif int($"/root/Main/Options Sprite/Options".display_font) == 1:
			add_deck_button("     <icon_deny>     ")
		elif TranslationServer.get_locale() != "ja":
			add_deck_button("  <icon_deny>  ")
		else:
			add_deck_button("   <icon_deny>   ")
		deck_button.call = "undraw_deck"
	
		for c in cards:
			c.visible = false
			c.active = false
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				for i in c.get_node("Background/Description").get_child(0).icons:
					i.active = false
			else:
				for i in c.get_node("Background/Description").texts[8].icons:
					i.active = false
				
		for b in buttons:
			b.visible = false
			b.active = false
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				for i in b.text_node.icons:
					i.active = false
			else:
				for i in b.text_node.texts[8].icons:
					i.active = false
		$"/root/Main".change_current_menu_path("inventory")

	var total_symbols = 0
	
	var time_machine_diff = 0
	if $"/root/Main/Items".has_unmodded_item("time_machine_essence"):
		time_machine_diff = 1000000
	elif $"/root/Main/Items".has_unmodded_item("time_machine"):
		time_machine_diff = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["time_machine"])].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["time_machine"])].item_count
	
	if fossil_combined:
		var f_tbe = []
		for s in saved_symbol_data:
			if s.type == "frozen_fossil" and s.value_text == "":
				f_tbe.push_back(s)
		f_tbe.pop_front()
		for f in f_tbe:
			saved_symbol_data.erase(f)
		fossil_combined = false
		
	if saved_symbol_order.size() == 0:
		var sorted_symbol_arr = []
		for s in reels.symbol_arr:
			s.update_value_text()
			var vt = s.get_child(1).raw_string
			var pm = s.get_child(2).raw_string
			var pb = s.get_child(3).raw_string
			var symbol_s = s.type + vt + pb + pm
			if s.type == "frozen_fossil" and s.values[0] - time_machine_diff - fossil_diff * s.values[1] - s.times_displayed > 0:
				vt = "<color_" + $"/root/Main/Options Sprite/Options".colors3["symbol_reminder_down_text"] + ">" + s.get_child(1).parse_num_str(str(s.values[0] - time_machine_diff - fossil_diff * s.values[1] - s.times_displayed)) + "<end>"
				symbol_s = s.type + vt + pb + pm
			if not symbol_counts.has(symbol_s):
				if vt != s.type:
					symbol_counts[symbol_s] = {"count": 1, "value_text": vt, "permanent_bonus": pb, "permanent_multiplier": pm}
					symbol_data.push_back({"type": s.type, "rarity": s.rarity, "value": s.value, "value_text": vt, "permanent_bonus": pb, "permanent_multiplier": pm, "times_displayed": s.times_displayed})
				else:
					symbol_counts[symbol_s] = {"count": 1, "value_text": "", "permanent_bonus": "", "permanent_multiplier": ""}
					symbol_data.push_back({"type": s.type, "rarity": s.rarity, "value": s.value, "value_text": "", "permanent_bonus": "", "permanent_multiplier": "", "times_displayed": s.times_displayed})
			else:
				symbol_counts[symbol_s].count += 1
			total_symbols += 1
		
		for r in reels.reels:
			var increment = 0
			for t in r.icon_types_to_be_added:
				var s = $"/root/Main".tile_database[t]
				var identifier = t
				identifier += r.icon_types_tba_bonus_texts[increment][2] + r.icon_types_tba_bonus_texts[increment][0] + r.icon_types_tba_bonus_texts[increment][1]
				if not symbol_counts.has(identifier):
					symbol_counts[identifier] = {"count": 1, "value_text": r.icon_types_tba_bonus_texts[increment][2], "permanent_bonus": r.icon_types_tba_bonus_texts[increment][0], "permanent_multiplier": r.icon_types_tba_bonus_texts[increment][1]}
					symbol_data.push_back({"type": s.type, "rarity": s.rarity, "value": s.value, "value_text": r.icon_types_tba_bonus_texts[increment][2], "permanent_bonus": r.icon_types_tba_bonus_texts[increment][0], "permanent_multiplier": r.icon_types_tba_bonus_texts[increment][1]})
				else:
					symbol_counts[identifier].count += 1
				total_symbols += 1
				increment += 1
				
		symbol_data.sort_custom(CustomSorter, "icon_sort")
		saved_symbol_data = symbol_data.duplicate(true)
		saved_symbol_counts = symbol_counts.duplicate(true)
	else:
		for s in saved_symbol_counts.keys():
			total_symbols += saved_symbol_counts[s].count
	
	var devils_deal = false
	
	var e_str = $"/root/Main".get_empty_data()
	
	if saved_symbol_counts.has(e_str) and not devils_deal:
		if total_symbols - saved_symbol_counts[e_str].count >= 20:
			for s in range(saved_symbol_data.size()):
				if saved_symbol_data[s].type == e_str:
					saved_symbol_data.remove(s)
					break
			total_symbols -= saved_symbol_counts[e_str].count
			saved_symbol_counts.erase(e_str)
			saved_symbol_order.erase(e_str)
		else:
			saved_symbol_counts[e_str].count = 20 - (total_symbols - saved_symbol_counts[e_str].count)
			total_symbols = 20
			
	for s in destroyed_symbol_types:
		if not destroyed_symbol_counts.has(s):
			destroyed_symbol_counts[s] = 1
		else:
			destroyed_symbol_counts[s] += 1
			
	for s in $"/root/Main/Items".destroyed_item_types:
		if not destroyed_item_counts.has(s):
			destroyed_item_counts[s] = 1
		else:
			destroyed_item_counts[s] += 1
			
	for s in removed_symbol_types:
		if not removed_symbol_counts.has(s):
			removed_symbol_counts[s] = 1
		else:
			removed_symbol_counts[s] += 1
	
	saved_label_text = label_text.raw_string
	
	label_text.values.resize(7)
	
	label_text.values[2] = total_symbols
	label_text.values[3] = 0
	label_text.values[4] = destroyed_symbol_types_size
	label_text.values[5] = $"/root/Main/Items".destroyed_item_types.size()
	label_text.values[6] = removed_symbol_types.size()
	
	var space = " "
	if $"/root/Main/Options Sprite/Options".CJK_lang and TranslationServer.get_locale() != "ko":
		space = "\u00A0"
	
	var sc = $"/root/Main/Options Sprite/Options".ui_scaling.inventory
	
	var ar_space = ""
	if TranslationServer.get_locale() == "ar" and sc >= 2:
		ar_space = "\u00A0"
	
	if emails.size() > 0 and emails[0].type != "removal_token_prompt":
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			label_text.raw_string = tr("payments") + "<text_color_keyword>" + str(times_rent_paid) + "<end>／<text_color_keyword>"
		elif TranslationServer.get_locale() == "ar":
			label_text.raw_string = tr("payments") + " <text_color_keyword>" + str(times_to_pay_rent) + "<end>/<text_color_keyword>"
		else:
			label_text.raw_string = tr("payments") + " <text_color_keyword>" + str(times_rent_paid) + "<end>/<text_color_keyword>"
		if TranslationServer.get_locale() == "ar":
			label_text.raw_string += str(times_rent_paid) + "<end>" + space
		else:
			label_text.raw_string += str(times_to_pay_rent) + "<end>" + space
		
		if TranslationServer.get_locale() == "de" or TranslationServer.get_locale() == "it" or TranslationServer.get_locale() == "pl" or TranslationServer.get_locale() == "es_ES":
			if reroll_tokens != 0:
				label_text.raw_string += "<color_49AA10>" + label_text.parse_num_str(str(reroll_tokens)) + "<end><icon_reroll_token>" + space
			if removal_tokens != 0:
				label_text.raw_string += "<color_6B6B6B>" + label_text.parse_num_str(str(removal_tokens)) + "<end><icon_removal_token>" + space
			if essence_tokens != 0:
				label_text.raw_string += "<text_color_essence>" + label_text.parse_num_str(str(essence_tokens)) + "<end><icon_essence_token>" + space
		else:
			if reroll_tokens != 0:
				label_text.raw_string += "<icon_reroll_token><color_49AA10>" + label_text.parse_num_str(str(reroll_tokens)) + "<end>" + space
			if removal_tokens != 0:
				label_text.raw_string += "<icon_removal_token><color_6B6B6B>" + label_text.parse_num_str(str(removal_tokens)) + "<end>" + space
			if essence_tokens != 0:
				label_text.raw_string += "<icon_essence_token><text_color_essence>" + label_text.parse_num_str(str(essence_tokens)) + "<end>" + space
	elif emails.size() > 0 and emails[0].type == "removal_token_prompt":
		match TranslationServer.get_locale():
			"ru", "it", "de", "pl", "tr":
				label_text.raw_string += " <color_6B6B6B>" + str(removal_tokens) + " <icon_removal_token><end>"
			"zh", "zh_TW", "ja", "ko":
				label_text.raw_string += label_text.cjk_space + "<icon_removal_token><color_6B6B6B>" + str(removal_tokens) + "<end>"
			_:
				label_text.raw_string += " <icon_removal_token><color_6B6B6B>" + str(removal_tokens) + "<end>"
	label_text.raw_string += "\n" + tr("symbols") + "\n"
	
	update_saved_symbol_order(saved_symbol_data)
	
	for k in range(saved_symbol_data.size()):
		if saved_symbol_data[k].type == "coin":
			label_text.raw_string += text_color + str(saved_symbol_counts[saved_symbol_data[k].type + saved_symbol_data[k].value_text + saved_symbol_data[k].permanent_bonus + saved_symbol_data[k].permanent_multiplier].count) + "<end>" + ar_space + "<icon_hover_coin>" + space
		else:
			label_text.raw_string += text_color + str(saved_symbol_counts[saved_symbol_data[k].type + saved_symbol_data[k].value_text + saved_symbol_data[k].permanent_bonus + saved_symbol_data[k].permanent_multiplier].count) + "<end>" + ar_space + "<icon_" + saved_symbol_data[k].type + ">" + space
			
	if reels.items.size() > 0:
		label_text.raw_string += "\n"
		label_text.raw_string += tr("items") + "\n"
		
		for i in reels.items:
			label_text.values[3] += i.item_count
			label_text.raw_string += "<icon_" + i.type + ">" + space
	
	if emails.size() > 0 and emails[0].type != "removal_token_prompt":
		if destroyed_symbol_types_size > 0 or $"/root/Main/Items".destroyed_item_types.size() > 0 or removed_symbol_types.size():
			label_text.raw_string += "\n"
		
		if destroyed_symbol_types_size > 0:
			label_text.raw_string += "\n"
			label_text.raw_string += tr("destroyed_symbols") + "\n"
			
			for i in destroyed_symbol_counts.keys():
				if i == "coin":
					label_text.raw_string += text_color + str(destroyed_symbol_counts[i]) + "<end>" + ar_space + "<icon_hover_coin>" + space
				else:
					label_text.raw_string += text_color + str(destroyed_symbol_counts[i]) + "<end>" + ar_space + "<icon_" + i + ">" + space
		
		if $"/root/Main/Items".destroyed_item_types.size() > 0:
			label_text.raw_string += "\n"
			label_text.raw_string += tr("destroyed_items") + "\n"
			
			for i in destroyed_item_counts.keys():
				label_text.raw_string += "<icon_" + i + ">" + space
				
		if removed_symbol_types.size() > 0:
			label_text.raw_string += "\n"
			label_text.raw_string += tr("removed_symbols") + "\n"
			
			for i in removed_symbol_counts.keys():
				if i == "coin":
					label_text.raw_string += text_color + str(removed_symbol_counts[i]) + "<end>" + ar_space + "<icon_hover_coin>" + space
				else:
					label_text.raw_string += text_color + str(removed_symbol_counts[i]) + "<end>" + ar_space + "<icon_" + i + ">" + space
		
		if $"/root/Main/Landlord".fine_print.size() > 0:
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				label_text.get_child(0).fine_print_icon_pos = label_text.raw_string.length()
			else:
				label_text.texts[8].fine_print_icon_pos = label_text.raw_string.length()
			label_text.raw_string += "\n"
			label_text.dynamic_icons.clear()
			var v_num = 7
			for fp in $"/root/Main/Landlord".fine_print:
				var f_str = "\n" + tr("fine_print_" + str(fp.num))
				if fp.has("localized_text") and fp.localized_text.has(TranslationServer.get_locale()):
					f_str = "\n" + fp.localized_text[TranslationServer.get_locale()]
				elif fp.has("text"):
					f_str = "\n" + fp.text
				var last_pos = -1
				var pos_offset = 0
				while true:
					last_pos = f_str.substr(last_pos + 1 + pos_offset, -1).find("<value_")
					if last_pos != -1:
						v_num += 1
						f_str = f_str.substr(0, last_pos + 7) + str(v_num) + f_str.substr(last_pos + 8, -1)
						pos_offset = last_pos + 8
					else:
						break
				label_text.raw_string += f_str
				if fp.dynamic_icon != null and f_str.substr(f_str.find("\n") + 1, -1).find("<dynamic_") != -1:
					label_text.dynamic_icons.push_back(fp.dynamic_icon)
				label_text.values += fp.values
	
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1:
			label_text.custom_icon_offset = Vector2(4 / sc, -2)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
			label_text.custom_icon_offset = Vector2(4 / sc, -8)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.5:
			label_text.custom_icon_offset = Vector2(4 / sc, -14)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
			label_text.custom_icon_offset = Vector2(4 / sc, -8)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2.25:
			label_text.custom_icon_offset = Vector2(4 / sc, -24)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2.5:
			label_text.custom_icon_offset = Vector2(4 / sc, -24)
		else:
			label_text.custom_icon_offset = Vector2(4 / sc, 4 / sc)
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1:
			label_text.custom_icon_offset = Vector2(4 / sc, 14)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
			label_text.custom_icon_offset = Vector2(4 / sc, 16)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.5:
			label_text.custom_icon_offset = Vector2(4 / sc, 18)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
			label_text.custom_icon_offset = Vector2(4 / sc, 34)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
			label_text.custom_icon_offset = Vector2(4 / sc, 36)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2.25:
			label_text.custom_icon_offset = Vector2(4 / sc, 38)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2.5:
			label_text.custom_icon_offset = Vector2(4 / sc, 40)
		else:
			label_text.custom_icon_offset = Vector2(4 / sc, 4 / sc)
	else:
		if $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 2:
			label_text.custom_icon_offset = Vector2(12, 22 + sc * 12)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 1.75:
			label_text.custom_icon_offset = Vector2(10, 22 + sc * 8)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 1.5:
			label_text.custom_icon_offset = Vector2(6, 30 + sc * 4)
		elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory > 1:
			label_text.custom_icon_offset = Vector2(6, 22 + sc * 4)
		else:
			label_text.custom_icon_offset = Vector2(-4 + 8 / sc, 10 + 8 / sc)
		
	label_text.change_set_size(label_text.base_scale)
	label_text.update()
	label_text.offset_x = 0
	
	if TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK":
		label_text.change_font_size(0.125, true)
		label_text.rect_position.y = 0
		label_text.cant_break_line_zh = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\u3000"
	elif TranslationServer.get_locale() == "ja":
		label_text.change_font_size(0.125, true)
		label_text.rect_position.y = 0
		label_text.cant_break_line_ja = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ—...‥〳〴〵\u3000"
	elif TranslationServer.get_locale() == "ko":
		label_text.change_font_size(0.125, true)
		label_text.rect_position.y = 0
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		if TranslationServer.get_locale() == "ar":
			icon_arr = label_text.get_child(0).icons.duplicate(true)
		else:
			icon_arr = label_text.get_child(0).icons
	else:
		if TranslationServer.get_locale() == "ar":
			icon_arr = label_text.texts[8].icons.duplicate(true)
		else:
			icon_arr = label_text.texts[8].icons
		if int($"/root/Main/Options Sprite/Options".display_font) == 0:
			label_text.change_font_size(0.625, true)
		for i in icon_arr:
			if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
				i.rect_position.y -= 4
			i.update_hitbox()
	var symbol_index = 0
	
	if emails.size() > 0 and emails[0].type == "removal_token_prompt":
		symbol_index += 1
	
	if reroll_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		symbol_index += 1
	if removal_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		symbol_index += 1
	if essence_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		symbol_index += 1
	
	if TranslationServer.get_locale() == "ar":
		icon_arr = invert_ar_rows(icon_arr, 0, saved_symbol_data.size() + symbol_index)
	
	for i in saved_symbol_data:
		if i != null:
			icon_arr[symbol_index].count = saved_symbol_counts[i.type + i.value_text + i.permanent_bonus + i.permanent_multiplier].count
		if i != null and (i.value_text != "" or i.permanent_bonus != "" or i.permanent_multiplier != ""):
			var s = Node2D.new()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.z_index = 4
			else:
				s.z_index = 3
			if i.value_text != "":
				symbol_info_texts.push_back(preload("res://Outline Label.tscn").instance())
				var t = symbol_info_texts[symbol_info_texts.size() - 1]
				s.add_child(t)
				t.raw_string = i.value_text
				t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
				if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
						pass
					elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
						t.text_mod -= 1
					else:
						t.text_mod -= 2
				icon_arr[symbol_index].get_parent().add_child(s)
				icon_arr[symbol_index].value_text = i.value_text
				t.dont_scale = true
				t.update()
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x, icon_arr[symbol_index].rect_position.y - 6 * sc)
					t.change_font_size(0.625, true)
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x, 4 + icon_arr[symbol_index].rect_position.y - 6 * sc)
					t.change_font_size(0.625, true)
				else:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x, icon_arr[symbol_index].rect_position.y - 6 * sc)
					t.change_font_size(0.75, true)
			if i.permanent_bonus != "":
				symbol_info_texts.push_back(preload("res://Outline Label.tscn").instance())
				var t = symbol_info_texts[symbol_info_texts.size() - 1]
				s.add_child(t)
				t.raw_string = i.permanent_bonus
				t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
				if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
						pass
					elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
						t.text_mod -= 1
					else:
						t.text_mod -= 2
				icon_arr[symbol_index].get_parent().add_child(s)
				icon_arr[symbol_index].permanent_bonus = i.permanent_bonus
				t.dont_scale = true
				t.update()
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x, icon_arr[symbol_index].rect_position.y + 24 * sc)
					t.change_font_size(0.625, true)
				else:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x, icon_arr[symbol_index].rect_position.y + 24 * sc)
					t.change_font_size(0.75, true)
			if i.permanent_multiplier != "":
				symbol_info_texts.push_back(preload("res://Outline Label.tscn").instance())
				var t = symbol_info_texts[symbol_info_texts.size() - 1]
				s.add_child(t)
				t.raw_string = i.permanent_multiplier
				t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
				if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
						pass
					elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
						t.text_mod -= 1
					else:
						t.text_mod -= 2
				if not icon_arr[symbol_index].get_parent().get_children().has(s):
					icon_arr[symbol_index].get_parent().add_child(s)
				t.force_update = true
				icon_arr[symbol_index].permanent_multiplier = i.permanent_multiplier
				t.dont_scale = true
				t.update()
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x + icon_arr[symbol_index].rect_size.x - round(11 - (t.get_font("font").get_string_size(t.text).x * t.rect_scale.x / 4.0)), icon_arr[symbol_index].rect_position.y - 10 * sc)
					t.change_font_size(0.625, true)
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x + icon_arr[symbol_index].rect_size.x - round(11 - (t.get_font("font").get_string_size(t.text).x * t.rect_scale.x / 4.0)), 4 + icon_arr[symbol_index].rect_position.y - 6 * sc)
					t.change_font_size(0.625, true)
				else:
					t.rect_position = Vector2(icon_arr[symbol_index].rect_position.x + icon_arr[symbol_index].rect_size.x - round(11 - (t.get_font("font").get_string_size(t.text).x * t.rect_scale.x / 4.0)), icon_arr[symbol_index].rect_position.y - 6 * sc)
					t.change_font_size(0.75, true)
		symbol_index += 1
	
	var icon_index = saved_symbol_counts.size()
	
	if emails.size() > 0 and emails[0].type == "removal_token_prompt":
		icon_index += 1
	
	if reroll_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		icon_index += 1
	if removal_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		icon_index += 1
	if essence_tokens != 0 and emails.size() > 0 and emails[0].type != "removal_token_prompt":
		icon_index += 1
	
	if TranslationServer.get_locale() == "ar":
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			icon_arr = label_text.get_child(0).icons.duplicate(true)
		else:
			icon_arr = label_text.texts[8].icons.duplicate(true)
	
	if emails.size() > 0 and (emails[0].type == "inventory" or inv_open) and emails[0].type != "removal_token_prompt":
		var i_offset = reels.items.size()
		for s in destroyed_symbol_counts.keys():
			var t = icon_arr[icon_index + i_offset].type
			if t == "hover_coin":
				t = "coin"
			icon_arr[icon_index + i_offset].count = destroyed_symbol_counts[t]
			icon_arr[icon_index + i_offset].inv_pos = tr("destroyed_symbols_no_value") + "\n"
			i_offset += 1
		i_offset += destroyed_item_counts.size()
		for s in removed_symbol_counts.keys():
			var t = icon_arr[icon_index + i_offset].type
			if t == "hover_coin":
				t = "coin"
			icon_arr[icon_index + i_offset].count = removed_symbol_counts[t]
			icon_arr[icon_index + i_offset].inv_pos = tr("removed_symbols_no_value") + "\n"
			i_offset += 1
	
	var item_start = icon_index
	
	if TranslationServer.get_locale() == "ar":
		icon_index = 0
		icon_arr = invert_ar_rows(icon_arr, item_start, item_start + reels.items.size())
	
	for i in reels.items:
		if i.item_count > 1:
			var s = Node2D.new()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.z_index = 4
			else:
				s.z_index = 3
			item_info_texts.push_back(preload("res://Outline Label.tscn").instance())
			var t = item_info_texts[item_info_texts.size() - 1]
			t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
					pass
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
					t.text_mod -= 1
				else:
					t.text_mod -= 2
			s.add_child(t)
			t.raw_string = i.get_child(0).raw_string
			t.dont_scale = true
			icon_arr[icon_index].count = i.item_count
			icon_arr[icon_index].get_parent().add_child(s)
			t.force_update = true
			t.update()
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_child(0).get_font("font").get_string_size(t.get_child(0).text).x * t.current_scale)), icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_child(0).get_font("font").get_height() - 12) * t.current_scale)
				t.change_font_size(0.625, true)
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_child(0).get_font("font").get_string_size(t.get_child(0).text).x * t.current_scale)) + 8, icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_child(0).get_font("font").get_height() - 12) * t.current_scale + 8)
				t.change_font_size(0.625, true)
			else:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_font("font").get_string_size(t.text).x * t.current_scale * 4)), icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_font("font").get_height() - 3) * t.current_scale * 4)
				t.change_font_size(0.75, true)
		if i.get_child(1).raw_string != "":
			var s = Node2D.new()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.z_index = 4
			else:
				s.z_index = 3
			item_info_texts.push_back(preload("res://Outline Label.tscn").instance())
			var t = item_info_texts[item_info_texts.size() - 1]
			t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
					pass
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
					t.text_mod -= 1
				else:
					t.text_mod -= 2
			s.add_child(t)
			t.raw_string = i.get_child(1).raw_string
			t.dont_scale = true
			icon_arr[icon_index].item_value_text = i.get_child(1).raw_string
			icon_arr[icon_index].get_parent().add_child(s)
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x, icon_arr[icon_index].rect_position.y - 6 * sc)
				t.change_font_size(0.625, true)
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + 2, icon_arr[icon_index].rect_position.y - 6 * sc + 2)
				t.change_font_size(0.625, true)
			else:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x, icon_arr[icon_index].rect_position.y - 6 * sc)
				t.change_font_size(0.75, true)
		if i.destroy_counters > 1:
			var s = Node2D.new()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.z_index = 4
			else:
				s.z_index = 3
			item_info_texts.push_back(preload("res://Outline Label.tscn").instance())
			var t = item_info_texts[item_info_texts.size() - 1]
			t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
					pass
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
					t.text_mod -= 1
				else:
					t.text_mod -= 2
			s.add_child(t)
			t.raw_string = i.get_child(2).raw_string
			t.dont_scale = true
			icon_arr[icon_index].get_parent().add_child(s)
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - 12 * sc, icon_arr[icon_index].rect_position.y - 6 * sc)
				t.change_font_size(0.625, true)
			elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - 12 * sc + 6, icon_arr[icon_index].rect_position.y - 6 * sc + 2)
				t.change_font_size(0.625, true)
			else:
				t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - 12 * sc, icon_arr[icon_index].rect_position.y - 6 * sc)
				t.change_font_size(0.75, true)
		if i.disabled:
			var s = Sprite.new()
			if int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.z_index = 4
			else:
				s.z_index = 3
			s.scale = Vector2(2+ -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25), 2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25))
			s.texture = preload("res://item_disabled.png")
			disabled_item_sprites.push_back(s)
			icon_arr[icon_index].get_parent().add_child(s)
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				s.position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x / 2, icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y / 2)
			else:
				s.position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x / 2, icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y / 2)
		icon_index += 1
	
	var item_end = icon_index
	
	if emails.size() > 0 and emails[0].type != "removal_token_prompt":
		icon_index += destroyed_symbol_counts.keys().size()
		if TranslationServer.get_locale() == "ar":
			if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
				icon_arr = label_text.get_child(0).icons.duplicate(true)
			else:
				icon_arr = label_text.texts[8].icons.duplicate(true)
			icon_index = 0
			item_end = item_start + reels.items.size()
			icon_arr = invert_ar_rows(icon_arr, icon_arr.size() - destroyed_item_counts.keys().size() - removed_symbol_counts.keys().size(), icon_arr.size())

		for i in destroyed_item_counts.keys():
			icon_arr[icon_index].inv_pos = tr("destroyed_items_no_value") + "\n"
			if destroyed_item_counts[i] > 1:
				icon_arr[icon_index].count = destroyed_item_counts[i]
				var s = Node2D.new()
				if int($"/root/Main/Options Sprite/Options".display_font) > 0:
					s.z_index = 4
				else:
					s.z_index = 3
				item_info_texts.push_back(preload("res://Outline Label.tscn").instance())
				var t = item_info_texts[item_info_texts.size() - 1]
				t.text_mod = -2 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.inventory) / 0.25)
				if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
					if $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1:
						pass
					elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory <= 1.5:
						t.text_mod -= 1
					else:
						t.text_mod -= 2
				s.add_child(t)
				t.raw_string = "<color_" + $"/root/Main/Options Sprite/Options".colors3["item_count_text"] + ">" + str(destroyed_item_counts[i]) + "<end>"
				t.dont_scale = true
				icon_arr[icon_index].get_parent().add_child(s)
				t.force_update = true
				t.update()
				if $"/root/Main/Options Sprite/Options".CJK_lang:
					t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_child(0).get_font("font").get_string_size(t.get_child(0).text).x * t.current_scale)), icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_child(0).get_font("font").get_height() - 12) * t.current_scale)
					t.change_font_size(0.625, true)
				elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
					t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_child(0).get_font("font").get_string_size(t.get_child(0).text).x * t.current_scale)) + 8, icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_child(0).get_font("font").get_height() - 12) * t.current_scale + 8)
					t.change_font_size(0.625, true)
				else:
					t.rect_position = Vector2(icon_arr[icon_index].rect_position.x + icon_arr[icon_index].rect_size.x - round((t.get_font("font").get_string_size(t.text).x * t.current_scale * 4)), icon_arr[icon_index].rect_position.y + icon_arr[icon_index].rect_size.y - (t.get_font("font").get_height() - 3) * t.current_scale * 4)
					t.change_font_size(0.75, true)
			icon_index += 1
			
	scroll_bar_was_visible = scroll_bar.visible
	
	for i in icon_arr:
		label_text.saved_value_texts.push_back(i.value_text)
		label_text.saved_pb_texts.push_back(i.permanent_bonus)
		label_text.saved_pm_texts.push_back(i.permanent_multiplier)
	label_text.update()
	label_text.offset_x = 0
	for i in symbol_info_texts:
		i.change_set_size(i.base_scale)
		i.force_update = true
		i.update()
	for i in item_info_texts:
		i.dont_scale = true
		i.change_set_size(i.base_scale)
		i.force_update = true
		i.update()
	if emails.size() > 0 and emails[0].type != "add_item" and emails[0].type != "add_tile" and emails[0].type != "inventory" and emails[0].type != "removal_token_prompt" and emails[0].type != "chili_powder_essence_prompt" and emails[0].type != "intro" and emails[0].type != "rent_increase" and emails[0].type != "game_over" and emails[0].type != "out_of_money" and emails[0].type != "ending" and emails[0].type != "add_item_prompt":
		for i in icon_arr:
			i.rect_size = Vector2(128, 128)
	for i in range(icon_arr.size()):
		if i >= item_start and i < item_end:
			icon_arr[i].item = true
		icon_arr[i].update_hitbox()
	var f_mod = 0
	if label_text.i_spaced:
		f_mod = 3
	elif $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		f_mod = 2
	if (not $"/root/Main/Options Sprite/Options".CJK_lang and ((label_text.get_line_count() + 1) * (label_text.get_font("font").get_height() + f_mod) * label_text.current_scale * 4 > container.rect_size.y)) or ($"/root/Main/Options Sprite/Options".CJK_lang and label_text.get_child(0).get_line_count() * (label_text.get_font("font").get_height() + f_mod) * label_text.current_scale > container.rect_size.y):
		scroll_bar.visible = true
	elif (int($"/root/Main/Options Sprite/Options".display_font) > 0 and label_text.get_child(0).get_line_count() * (label_text.get_child(0).get_font("font").get_height() + f_mod) * label_text.current_scale > container.rect_size.y):
		scroll_bar.visible = true
	else:
		scroll_bar.visible = false
	if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
		icon_arr = label_text.get_child(0).icons
		for i in icon_arr:
			if i.type == "reroll_token" or i.type == "removal_token" or i.type == "essence_token" or i.fine_print:
				if $"/root/Main/Options Sprite/Options".CJK_lang and $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
					pass
				else:
					i.rect_position.x -= 6
				if $"/root/Main".item_database.has(i.type):
					i.rect_position.x += 2
					i.rect_position.y += 6
			if $"/root/Main/Options Sprite/Options".CJK_lang:
				if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
					i.rect_position.x += 4
					i.rect_position.y += 10
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.5:
					i.rect_position.y += 10
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
					i.rect_position.x += 12
					i.rect_position.y += 2
				elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
					i.rect_position.x += 10
					i.rect_position.y += 6
			i.update_hitbox()
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
				for s in symbol_info_texts:
					s.rect_position.x += 4
					s.rect_position.y += 10
				for i in item_info_texts:
					i.rect_position.x += 4
					i.rect_position.y += 10
			elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.5:
				for s in symbol_info_texts:
					s.rect_position.y += 10
				for i in item_info_texts:
					i.rect_position.y += 10
			elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.75:
				for s in symbol_info_texts:
					s.rect_position.x += 2
					s.rect_position.y += 12
				for i in item_info_texts:
					i.rect_position.x += 2
					i.rect_position.y += 12
			elif $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 2:
				for s in symbol_info_texts:
					s.rect_position.x += 10
					s.rect_position.y += 6
				for i in item_info_texts:
					i.rect_position.x += 10
					i.rect_position.y += 6
	else:
		icon_arr = label_text.texts[8].icons
		if int($"/root/Main/Options Sprite/Options".display_font) == 0:
			label_text.change_font_size(0.625, true)
		for i in icon_arr:
			if $"/root/Main/Options Sprite/Options".ui_scaling.inventory == 1.25:
				i.rect_position.y -= 4
			if i.type == "reroll_token" or i.type == "removal_token" or i.type == "essence_token" or i.fine_print:
				i.rect_position.x -= 6
				if $"/root/Main".item_database.has(i.type):
					i.rect_position.x += 4
					i.rect_position.y += 12
			i.update_hitbox()
	tts()

func reset_deck():
	undraw_deck()
	draw_deck()
	if cards.size() > 0:
		if buttons.size() > 0:
			container.get_child(1).rect_position.y = buttons[0].rect_position.y
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		label_text.rect_position.y = 0
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		label_text.rect_position.y = 12
	else:
		if inv_open or (emails.size() > 0 and (emails[0].type == "inventory" or emails[0].type == "removal_token_prompt")):
			label_text.rect_position.y = -12
		else:
			label_text.rect_position.y = 12

func undraw_deck():
	var header_text = sender_container.get_child(0)
	label_text.dont_scale = false
	displaying_inventory = false
	inv_open = false
	label_text.text_mod = -1
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		label_text.i_spaced = false
		update_cjk_text_size()
	else:
		label_text.i_spaced = false
		label_text.e_spaced = true
		label_text.scale_mod = 1 + -floor((1 - $"/root/Main/Options Sprite/Options".ui_scaling.text) / 0.25)
	label_text.custom_icon_offset = Vector2(0, 0)
	if emails.size() > 0:
		var t = tr(emails[0].type + "_header")
		if emails[0].has("header"):
			header_text.raw_string = emails[0].header
		elif t == emails[0].type + "_header" or emails[0].type == "win":
			header_text.raw_string = tr("new_email_header")
		else:
			header_text.raw_string = t
		if emails[0].type == "fine_print":
			label_text.dynamic_icons.clear()
			for f in $"/root/Main/Landlord".queued_fine_print:
				var f_str = tr("fine_print_" + str(f.num))
				if f.has("localized_text") and f.localized_text.has(TranslationServer.get_locale()):
					f_str = f.localized_text[TranslationServer.get_locale()]
				elif f.has("text"):
					f_str = f.text
				if f.dynamic_icon != null and f_str.find("<dynamic_") != -1:
					label_text.dynamic_icons.push_back(f.dynamic_icon)
				label_text.values += f.values
	header_text.update()
	if $"/root/Main/Options Sprite/Options".CJK_lang:
		header_text.rect_position.x = rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.get_child(0).text).x / 2 * header_text.current_scale
	elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
		header_text.rect_position.x = rect_size.x / 2 - header_text.get_child(0).get_font("font").get_string_size(header_text.get_child(0).text).x * header_text.current_scale / 2
	else:
		header_text.rect_position.x = rect_size.x / 2 - header_text.get_font("font").get_string_size(header_text.text).x * header_text.current_scale * 2
	
	add_deck_button(tr("inventory"))
	
	for c in cards:
		c.visible = true
		c.active = true
		if TranslationServer.get_locale() == "zh" or TranslationServer.get_locale() == "zh_TW" or TranslationServer.get_locale() == "zh_HK":
			label_text.cant_break_line_zh = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		elif TranslationServer.get_locale() == "ja":
			label_text.cant_break_line_ja = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ—...‥〳〴〵"
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in c.get_node("Background/Description").get_child(0).icons:
				i.active = true
		else:
			for i in c.get_node("Background/Description").texts[8].icons:
				i.active = true
	
	for b in buttons:
		if hex_of_hoarding_trigger and (b.button_text == tr("skip") or b.text_node.get_child(0).text == tr("skip")) and symbols_to_choose_from > 0:
			b.visible = false
		else:
			b.visible = true
			b.active = true
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			for i in b.text_node.icons:
				i.active = true
		else:
			for i in b.text_node.texts[8].icons:
				i.active = true
	
	for i in item_info_texts:
		if get_children().has(i.get_parent()):
			remove_child(i.get_parent())
		i.get_parent().queue_free()
	item_info_texts.clear()
	
	for s in symbol_info_texts:
		if get_children().has(s.get_parent()):
			remove_child(s.get_parent())
		s.get_parent().queue_free()
	symbol_info_texts.clear()
	
	for s in disabled_item_sprites:
		if get_children().has(s):
			remove_child(s)
		s.queue_free()
	disabled_item_sprites.clear()
	
	if emails.size() > 0:
		if emails[0].type == "comrade_help" or emails[0].type == "init_comrade_help" or emails[0].type == "init_comrade_help_no_essence" or emails[0].type == "init_comrade_help_no_essence":
			label_text.values = comrade_values.duplicate(true)
			set_tip_values()
		elif emails[0].type != "inventory" and emails[0].type != "removal_token_prompt":
			label_text.values = saved_label_values.duplicate(true)

	label_text.raw_string = saved_label_text
	saved_label_text = ""
	
	scroll_bar.visible = scroll_bar_was_visible
	
	if emails.size() > 0:
		if $"/root/Main/Options Sprite/Options".CJK_lang:
			label_text.rect_position.y = 0
		elif int($"/root/Main/Options Sprite/Options".display_font) > 0:
			label_text.rect_position.y = 12
		else:
			label_text.change_font_size(1, true)
			label_text.rect_position.y = 12
			if emails[0].type == "comrade_help" or emails[0].type == "init_comrade_help" or emails[0].type == "init_comrade_help_no_essence" or emails[0].type == "init_comrade_help_no_essence":
				if not $"/root/Main/Options Sprite/Options".CJK_lang:
					for i in label_text.texts[8].icons:
						i.rect_size = Vector2(224, 224)
		if emails[0].type == "add_tile" or emails[0].type == "add_item":
			container.get_child(1).visible = true
		label_text.force_update = true
		label_text.update()
		label_text.offset_x = 0
		if emails[0].type == "inventory":
			$"/root/Main".change_current_menu_path("inventory")
		elif emails[0].type != "removal_token_prompt":
			$"/root/Main".change_current_menu_path("email")
		tts()
	scroll_bar.visible = scroll_bar_was_visible
	if TranslationServer.get_locale() == "ar" and label_text.raw_string != null:
		label_text.force_update = true
		label_text.update()
	tts()

func tts():
	if not $"/root/Main/Options Sprite/Options".screen_reader:
		return
	if visible and offset_y <= offset_top:
		var t_label = preload("res://Outline Label.tscn").instance()
		t_label.visible = false
		add_child(t_label)
		
		t_label.raw_string = $"Rent Container/Coin Text".raw_string
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			t_label.get_child(0).custom_max_width = 10000000
		else:
			t_label.custom_max_width = 10000000
		t_label.tts = true
		t_label.update()
		var rent
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			rent = t_label.get_child(0).text
		else:
			rent = t_label.text
		
		t_label.raw_string = $"Rent Container/Text".raw_string
		t_label.tts = true
		t_label.values = $"Rent Container/Text".values
		t_label.force_update = true
		t_label.update()
		var rent_due
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			rent_due = t_label.get_child(0).text
		else:
			rent_due = t_label.text
		
		t_label.raw_string = $"Sender Container/Text".raw_string
		t_label.tts = true
		t_label.force_update = true
		t_label.update()
		
		var sender
		if $"/root/Main/Options Sprite/Options".CJK_lang or int($"/root/Main/Options Sprite/Options".display_font) > 0:
			sender = t_label.get_child(0).text
		else:
			sender = t_label.text
		
		var email_text = ""
		
		if label_text.raw_string != "":
			t_label.raw_string = label_text.raw_string
			t_label.values = label_text.values
			t_label.tts = true
			t_label.force_update = true
			t_label.update()
			email_text = t_label.raw_string
		
		remove_child(t_label)
		t_label.queue_free()
		
		$"/root/Main".tts(rent + "\n" + rent_due + "\n" + sender + "\n" + email_text, label_text.values, self)

func update_rent_values():
	if not endless_mode and not doing_boss_fight and (current_modded_floor == null or (typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.rent_values.has("base"))):
		match int(times_rent_paid):
			1:
				rent_values[0] = 50
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.1, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
			2:
				rent_values[0] = 100
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.2, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.1, "rare": 0, "very_rare": 0 } }
			3:
				rent_values[0] = 150
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.25, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.2, "rare": 0.025, "very_rare": 0 } }
			4:
				rent_values[0] = 225
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.29, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.25, "rare": 0.025, "very_rare": 0 } }
			5:
				rent_values[0] = 300
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.3, "rare": 0.0375, "very_rare": 0.0125 } }
			6:
				rent_values[0] = 350
				if current_floor >= 2:
					rent_values[0] += 25
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.375, "rare": 0.05, "very_rare": 0.015 } }
			7:
				rent_values[0] = 425
				if current_floor >= 3:
					rent_values[0] += 25
			8:
				rent_values[0] = 575
				if current_floor >= 18:
					rent_values[0] += 25
			9:
				rent_values[0] = 625
				if current_floor >= 6:
					rent_values[0] += 25
			10:
				rent_values[0] = 675
				if current_floor >= 8:
					rent_values[0] += 25
			11:
				rent_values[0] = 777
	elif current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and int(times_rent_paid) < current_modded_floor.rent_payments:
		rent_values = current_modded_floor.rent_values[times_rent_paid].duplicate(true)
		match int(times_rent_paid):
			1:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.1, "rare": 0, "very_rare": 0 }, "items": { "uncommon": 0, "rare": 0, "very_rare": 0 } }
			2:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.2, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.1, "rare": 0, "very_rare": 0 } }
			3:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.25, "rare": 0.01, "very_rare": 0 }, "items": { "uncommon": 0.2, "rare": 0.025, "very_rare": 0 } }
			4:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.29, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.25, "rare": 0.025, "very_rare": 0 } }
			5:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.3, "rare": 0.0375, "very_rare": 0.0125 } }
			6:
				$"/root/Main".rarity_chances = { "symbols": { "uncommon": 0.3, "rare": 0.015, "very_rare": 0.005 }, "items": { "uncommon": 0.375, "rare": 0.05, "very_rare": 0.015 } }
	elif not $"/root/Main".demo:
		times_to_pay_rent += 1
		var base_payments = 12
		if current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING:
			base_payments = current_modded_floor.rent_payments
		if rent_values[0] != 0:
			rent_values[0] = 500 + (times_to_pay_rent - base_payments) * 500
		rent_values[1] = 10

func can_try_to_pay_rent():
	var relevant_item = false
	if $"/root/Main/Items".has_unmodded_item("piggy_bank") or $"/root/Main/Items".has_unmodded_item("swear_jar") or $"/root/Main/Items".has_unmodded_item("devils_deal") or $"/root/Main/Items".has_unmodded_item("coffee") or $"/root/Main/Items".has_unmodded_item("coffee_essence"):
		relevant_item = true
	if not relevant_item:
		for m in mods.items:
			if m.can_be_destroyed_before_rent and $"/root/Main/Items".item_types.has(m.type):
				relevant_item = true
				break
	return (coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value >= rent_values[0] or relevant_item)

func spin_modifying_effects():
	var relevant_items = []
	if $"/root/Main/Items".has_unmodded_item("oil_can"):
		var oil_can = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["oil_can"])]
		if oil_can.saved_value >= oil_can.values[0] - 1:
			relevant_items.push_back("oil_can")
			oil_can.saved_value -= oil_can.values[0]
	if $"/root/Main/Items".has_unmodded_item("oil_can_essence"):
		relevant_items.push_back("oil_can_essence")
	if $"/root/Main/Items".has_unmodded_item("swapping_device"):
		relevant_items.push_back("swapping_device")
	if $"/root/Main/Items".has_unmodded_item("swapping_device_essence"):
		relevant_items.push_back("swapping_device_essence")
	if relevant_items.has("oil_can") and not sme_this_spin.has("oil_can"):
		add_event("oil_can_prompt", null)
		delay_timer = 0
		reels_to_select = 1
	elif relevant_items.has("oil_can_essence") and not sme_this_spin.has("oil_can_essence"):
		add_event("oil_can_essence_prompt", null)
		delay_timer = 0
		reels_to_select = 1
	elif relevant_items.has("swapping_device") and not sme_this_spin.has("swapping_device"):
		label_text.values = $"/root/Main".item_database["swapping_device"].values.duplicate(true)
		add_event("swap_prompt_1", null)
		delay_timer = 0
		symbols_to_select = $"/root/Main".item_database["swapping_device"].values[0]
	elif relevant_items.has("swapping_device_essence") and not sme_this_spin.has("swapping_device_essence"):
		label_text.values = [$"/root/Main".item_database["swapping_device_essence"].values[1]]
		add_event("swapping_device_essence_prompt", null)
		delay_timer = 0
		symbols_to_select = $"/root/Main".item_database["swapping_device_essence"].values[1]
	elif emails.size() == 1:
		reels.write_pre_effects_log()
		reels.add_effects()
		reels.checking_effects = true
		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
		reels.check_effects()
	$"/root/Main".save_game()

func post_rent_symbol_choice():
	var f_rarities = get_forced_rarities(3)
	var rent_rarity_arr = []
	
	for e in range(queued_essence_emails):
		add_event("add_item", {"forced_rarity": ["essence", "essence", "essence"]})
	
	queued_essence_emails = 0
	
	match int(times_rent_paid):
		0:
			pass
		1, 2, 3, 4, 5:
			rent_rarity_arr = ["uncommon", "uncommon", "uncommon"]
		6, 7, 8:
			rent_rarity_arr = ["rare", "uncommon", "uncommon"]
		9:
			rent_rarity_arr = ["rare", "rare", "uncommon"]
		_:
			rent_rarity_arr = ["rare", "rare", "rare"]
	rent_rarity_arr.resize(symbols_to_choose_from)
	for r in rent_rarity_arr:
		if f_rarities.forced_rarity.size() <= 2:
			f_rarities.forced_rarity.push_back(r)
		else:
			break
			
	add_event("add_tile", f_rarities)
	for i in $"/root/Main/Items".items:
		if (i.type == "frozen_pizza" and i.saved_value >= i.values[0]) or i.type == "frozen_pizza_essence":
			for b in range(i.item_count):
				hex_of_hoarding_trigger = false
				if i.type == "frozen_pizza":
					i.saved_value = 0
					$"/root/Main/Items".saved_item_data[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["frozen_pizza"])] = i.saved_value
					i.check_conditional_effects()
				if forced_rarities.size() > 0:
					add_event("add_tile", get_forced_rarities(symbols_to_choose_from))
				else:
					add_event("add_tile", {"forced_rarity": []})
				delay_timer = 0
			break
	for e in range(extra_symbol_choices):
		if forced_rarities.size() > 0:
			add_event("add_tile", get_forced_rarities(symbols_to_choose_from))
		else:
			add_event("add_tile", {"forced_rarity": []})
		delay_timer = 0
	extra_symbol_choices = 0
	if forced_item_rarities.size() > 0:
		add_event("add_item", get_forced_item_rarities(3))
	else:
		add_event("add_item", null)
	if $"/root/Main/Items".has_unmodded_item("bag_of_holding"):
		for i in $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["bag_of_holding"])].item_count:
			queued_items.push_back(null)
	for e in range(extra_item_choices):
		queued_items.push_back(null)
	extra_item_choices = 0
	if $"/root/Main/Items".has_unmodded_item("chili_powder_essence"):
		$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["chili_powder_essence"])].destroy()
		add_event("chili_powder_essence_prompt", {"push_front": true})
	delay_timer = 0

func retry():
	if $"/root/Main".sandbox_mode:
		$"/root/Main".sandbox_reloading = true
		$"/root/Main".new_game()
		$"/root/Main".sandbox_reloading = false
		if removal_tokens > removal_cost - 1:
			$"/root/Main/Menus".buttons_menu.removal_button.text_node.values = [removal_tokens]
			$"/root/Main/Menus".buttons_menu.removal_button.update_size()
			$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
			$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
			$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
			$"/root/Main/Menus".buttons_menu.removal_button.visible = true
		return true
	elif current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING:
		update_rent_values()
		$"/root/Main/Title".temp_modded_floor = current_modded_floor
		$"/root/Main".new_game()
	else:
		$"/root/Main/Title".temp_floor = current_floor
		$"/root/Main".new_game()
	return false

func start_bossfight():
	doing_boss_fight = true
	update_rent_values()
	label_text.values = rent_values.duplicate(true)
	$"/root/Main/Landlord".spawn()
	if not (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING):
		add_event("rent_increase", null)
	delay_timer = 0
	randomize()
	if rand_range(0, 1) < 0.5:
		$"/root/Main/Music Player".play_set_music("Landlocked")
	else:
		$"/root/Main/Music Player".play_set_music("Mad for Money")

func start_endless_mode():
	endless_mode = true
	doing_boss_fight = false
	if (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)):
		update_rent_values()
		label_text.values = rent_values.duplicate(true)
		delay_timer = 0
		if not $"/root/Main/Options Sprite/Options".old_endless_mode:
			times_rent_paid -= 1
			times_to_pay_rent -= 2
			endless_rent_email()
		else:
			times_to_pay_rent -= 1
			add_event("rent_increase", null)
	else:
		update_rent_values()
		label_text.values = rent_values.duplicate(true)
		delay_timer = 0
		add_event("rent_increase", null)

func resolve_event(choice):
	var dont_save = false
	var hoht = false
	
	for e in reels.texts:
		if e.effect_timer > 0:
			return
	
	if emails.size() == 0 or (emails.size() > 0 and offset_y != offset_top) or ($"/root/Main/Landlord".anim_time > 0 and choice != "dont"):
		return
	
	if Steam.isSteamRunningOnSteamDeck():
		$"/root/Main".press_timer = 0
	
	var prev_email_type = emails[0].type
	
	if (emails[0].type == "win" or emails[0].type == "ending") and choice != "main_menu" and choice != "continue_in_endless":
		pass
	else:
		$"/root/Main/Menus".buttons_menu.spin_button.down = false
		$"/root/Main/Menus".buttons_menu.spin_button.visual_reset()
		$"/root/Main/Menus".buttons_menu.deck_button.down = false
		$"/root/Main/Menus".buttons_menu.deck_button.visual_reset()
		$"/root/Main/Menus".buttons_menu.removal_button.down = false
		$"/root/Main/Menus".buttons_menu.removal_button.visual_reset()
		$"/root/Main/Menus".buttons_menu.left_button.down = false
		$"/root/Main/Menus".buttons_menu.left_button.visual_reset()
		$"/root/Main/Menus".buttons_menu.right_button.down = false
		$"/root/Main/Menus".buttons_menu.right_button.visual_reset()
		for b in buttons:
			b.queue_free()
		buttons.clear()
		
		for c in cards:
			c.queue_free()
		cards.clear()
		
		var email_to_resolve = emails[0]
		
		can_cycle_music = true
		
		saved_card_types.clear()
		if choice != "dont":
			match email_to_resolve.type:
				"add_tile":
					if choice != null and choice == "skip":
						check_spend_triggers("skip")
						$"/root/Main".write_log("Skipped symbols")
					elif choice == "reroll_pay":
						check_spend_triggers("spend_reroll_token")
						reroll_tokens -= reroll_cost
						var extra_values_obj = {"push_front": true, "reset_position": false}
						if email_to_resolve.extra_values.has("forced_rarity"):
							extra_values_obj["forced_rarity"] = email_to_resolve.extra_values.forced_rarity
						if email_to_resolve.extra_values.has("forced_group"):
							extra_values_obj["forced_group"] = email_to_resolve.extra_values.forced_group
						queued_symbols.push_front(extra_values_obj)
						hoht = hex_of_hoarding_trigger
					else:
						if not $"/root/Main/".group_database.symbols.taken.has(choice) and choice != "coin":
							$"/root/Main/".group_database.symbols.taken.push_back(choice)
							$"/root/Main/".group_database.symbols.passed.erase(choice)
						if emails[0].extra_values.has("forced_rarity") and choice == "hex_of_tedium" and emails[0].extra_values.forced_rarity.has("common"):
							$"/root/Main/Stats Sprite/Stats".unlock_achievement(72, true)
						elif emails[0].extra_values.has("forced_rarity") and $"/root/Main".rarity_database["symbols"]["common"].has(choice) and emails[0].extra_values.forced_rarity.has("rare") and rent_values[1] != 0:
							$"/root/Main/Stats Sprite/Stats".unlock_achievement(116, true)
						reels.add_tile([choice])
						reels.update_icon_types()
						$"Add Object".play()
					if queued_symbols.size() > 0:
						add_event("add_tile", queued_symbols[0])
						queued_symbols.remove(0)
						delay_timer = 0
					else:
						var e_types = []
						for e in emails:
							e_types.push_back(e.type)
						if $"/root/Main/Items".has_unmodded_item("comfy_pillow") and not e_types.has("comfy_pillow_prompt") and not prompts_passed.has("comfy_pillow_prompt"):
							if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow"])].values[0]:
								add_event("comfy_pillow_prompt", null)
								delay_timer = 0
						if $"/root/Main/Items".has_unmodded_item("comfy_pillow_essence") and not e_types.has("comfy_pillow_essence_prompt") and not prompts_passed.has("comfy_pillow_essence_prompt"):
							if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].values[0]:
								add_event("comfy_pillow_essence_prompt", null)
								delay_timer = 0
						if $"/root/Main/Landlord".queued_fine_print.size() > 0:
							add_event("fine_print", null)
							delay_timer = 0
					$"/root/Main".save_log()
				"add_item":
					if choice != "skip":
						$"/root/Main/Items".add_item(choice)
						if $"/root/Main/Items".has_unmodded_item("shattered_mirror"):
							symbols_to_choose_from -= $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["shattered_mirror"])].values[2]
					else:
						check_spend_triggers("skip")
						if $"/root/Main/Items".has_unmodded_item("bag_of_holding_essence"):
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["bag_of_holding_essence"])].destroy()
						$"/root/Main".write_log("Skipped items")
					if queued_items.size() > 0:
						add_event("add_item", queued_items[0])
						queued_items.remove(0)
						delay_timer = 0
					elif coin_node.coins + coin_node.queued_increase + $"/root/Main/Sums/Coin Sum".value == 0:
						$"/root/Main/Sums/Coin Sum".add_value(1)
						$"/root/Main/Sums/Coin Sum".adding = true
						$"/root/Main/Sums/HP Sum".add_value(1)
						$"/root/Main/Sums/HP Sum".adding = true
					$"Add Object".play()
					$"/root/Main".save_log()
				"rent_due":
					can_cycle_music = false
					var rent_paid = false
					var repeating_item = false
					if choice == "<icon_devils_deal>":
						if "<icon_" + $"/root/Main".existing_items["devils_deal"] + ">":
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["devils_deal"])].destroy()
							rent_paid = true
					elif choice == "<icon_" + $"/root/Main".existing_items["piggy_bank"] + ">":
						if $"/root/Main/Items".has_unmodded_item("piggy_bank"):
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["piggy_bank"])].destroy()
						repeating_item = true
					elif choice == "<icon_" + $"/root/Main".existing_items["swear_jar"] + ">":
						if $"/root/Main/Items".has_unmodded_item("swear_jar"):
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["swear_jar"])].destroy()
						repeating_item = true
					elif choice == "<icon_" + $"/root/Main".existing_items["coffee"] + ">":
						if $"/root/Main/Items".has_unmodded_item("coffee"):
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["coffee"])].destroy()
						hex_of_hoarding_trigger = false
						repeating_item = true
						if forced_rarities.size() > 0:
							add_event("add_tile", get_forced_rarities(symbols_to_choose_from))
						else:
							add_event("add_tile", {"forced_rarity": []})
						delay_timer = 0
					if not repeating_item:
						var relevant_item
						for m in mods.items:
							if m.can_be_destroyed_before_rent and $"/root/Main/Items".item_types.has(m.type) and choice.substr(6, choice.length() - 7) == m.type:
								relevant_item = m.type
								if m.skip_rent_on_destroy:
									rent_paid = m.skip_rent_on_destroy
									break
								break
						if relevant_item != null:
							$"/root/Main/Items".items[$"/root/Main/Items".item_types.find(relevant_item)].destroy()
							delay_timer = 0
						else:
							if not rent_paid:
								$"/root/Main/Sums/Coin Sum".add_value(-rent_values[0])
								$"/root/Main/Sums/Coin Sum".adding = true
							$"/root/Main/Sums/Extra Sum".add_value(0, 0, -essence_tokens)
							$"/root/Main/Sums/Extra Sum".adding = true
							if essence_tokens > 0:
								queued_essence_emails = essence_tokens
							essence_tokens = 0
							$"Confirm Select".play()
							rent_paid = true
					if $"/root/Main/Landlord".hp - $"/root/Main/Coins".queued_increase - $"/root/Main/Sums/Coin Sum".value <= 0 and doing_boss_fight:
						pass
					elif rent_paid:
						$"/root/Main/Menus".buttons_menu.spin_button.down = false
						times_rent_paid += 1
						for e in $"/root/Main".mod_on_rent_paid_effects:
							var item_num = $"/root/Main/Items".item_types.find($"/root/Main".existing_items[e.type])
							if item_num == -1:
								continue
							var i = $"/root/Main/Items".items[item_num]
							i.addding_post_spin_effects = true
							i.add_conditional_effects()
							i.addding_post_spin_effects = false
							i.check_conditional_effects()
							i.c_effects.clear()
						if not endless_mode and times_rent_paid < times_to_pay_rent:
							rent_values[1] += 5 + floor(times_rent_paid / 2)
						update_rent_values()
						label_text.values = rent_values.duplicate(true)
						if times_rent_paid < times_to_pay_rent:
							add_event("rent_increase", null)
						else:
							$"/root/Main/Stats Sprite/Stats".check_if_bossfight_unlocked()
							if $"/root/Main".demo:
								add_event("win", null)
							elif not (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)):
								$"/root/Main/Stats Sprite/Stats".add_to_games_won(current_floor)
								var prev_essences_unlocked = $"/root/Main/Stats Sprite/Stats".essences_unlocked
								var prev_stats_unlocked = $"/root/Main/Stats Sprite/Stats".stats_unlocked
								if $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor < max_floor and current_floor == $"/root/Main/Stats Sprite/Stats".highest_unlocked_floor:
									floor_unlocked_this_game = true
									$"/root/Main/Stats Sprite/Stats".highest_unlocked_floor += 1
								$"/root/Main/Stats Sprite/Stats".check_if_essences_unlocked()
								if prev_essences_unlocked != $"/root/Main/Stats Sprite/Stats".essences_unlocked:
									essences_unlocked_this_game = true
								$"/root/Main/Stats Sprite/Stats".check_if_stats_unlocked()
								if prev_stats_unlocked != $"/root/Main/Stats Sprite/Stats".stats_unlocked:
									stats_unlocked_this_game = true
								$"/root/Main/Stats Sprite/Stats".check_if_bossfight_unlocked()
								$"/root/Main".write_log("VICTORY")
								$"/root/Main".save_log()
							if not $"/root/Main".demo:
								if (($"/root/Main/Stats Sprite/Stats".bossfight_unlocked and current_modded_floor == null) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.has_bossfight)):
									add_event("boss_fight_1", null)
									if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
										$"/root/Main/Music Player".fully_fade_out()
								elif current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING:
									for e in current_modded_floor.ending_emails:
										var e_type = e.type
										if saved_mod_ids.emails.has(e_type):
											e_type += "_STEAM_ID_" + saved_mod_ids.emails[e_type]
										if $"/root/Main".mod_pack_nums.has(e_type):
											e_type += "_PACK_" + str($"/root/Main".mod_pack_nums[e_type])
										if e.keys().size() > 1:
											var extra_values = e.duplicate(true)
											extra_values.erase("type")
											extra_values["push_front"] = true
											add_event(e_type, extra_values)
										else:
											add_event(e_type, null)
								else:
									add_event("ending", null)
					elif rent_values[1] <= 0:
						if can_try_to_pay_rent():
							add_event("rent_due", null)
						else:
							add_event("game_over", null)
							$"/root/Main".write_log("GAME OVER")
							$"/root/Main".save_log()
					if choice == "<icon_devils_deal>":
						delay_timer = 0
				"rent_increase":
					hex_of_emptiness_trigger = false
					hex_of_hoarding_trigger = false
					label_text.values = comrade_values.duplicate(true)
					var i_tbe = []
					for i in $"/root/Main/Items".recently_destroyed_items:
						if i.payments <= 0:
							i_tbe.push_back(i)
						i.payments -= 1
					for i in i_tbe:
						$"/root/Main/Items".recently_destroyed_items.erase(i)
					if int(times_rent_paid) == 3 and not $"/root/Main".demo:
						add_event("init_comrade_help", null)
						delay_timer = 0
					elif int(times_rent_paid) > 3 and int(times_rent_paid) % 2 == 1 and not $"/root/Main".demo:
						add_event("comrade_help", null)
						delay_timer = 0
					else:
						post_rent_symbol_choice()
					$"/root/Main".save_stats()
				"comrade_help", "init_comrade_help", "comrade_help_no_essence", "init_comrade_help_no_essence":
					if $"/root/Main/Stats Sprite/Stats".essences_unlocked:
						$"/root/Main/Sums/Extra Sum".add_value(label_text.values[0], label_text.values[1], label_text.values[2])
						essence_tokens += label_text.values[2]
					else:
						$"/root/Main/Sums/Extra Sum".add_value(label_text.values[0], label_text.values[1], 0)
					$"/root/Main/Sums/Extra Sum".adding = true
					reroll_tokens += label_text.values[0]
					removal_tokens += label_text.values[1]
					post_rent_symbol_choice()
				"lang_select":
					pass
				"intro":
					$"Confirm Select".play()
				"game_over", "out_of_money":
					if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
						$"/root/Main/Music Player".fully_fade_out()
						$"/root/Main/Music Player".play_rand_music()
						$"/root/Main/Music Player".fade_in()
					if choice == "retry":
						if retry():
							return
					else:
						$"/root/Main".reset_values()
						$"/root/Main".title()
				"win", "ending":
					if choice == "main_menu":
						$"/root/Main".reset_values()
						$"/root/Main".title()
					elif email_to_resolve.type == "ending" and choice == "continue_in_endless":
						start_endless_mode()
				"fine_print":
					$"/root/Main/Landlord".fine_print += $"/root/Main/Landlord".queued_fine_print.duplicate(true)
					for q in $"/root/Main/Landlord".queued_fine_print:
						match int(q.num):
							1, 2, 3:
								var items = $"/root/Main/Items"
								var pos = items.item_types.find(q.dynamic_icon)
								var item = items.items[pos]
								if item.item_count == 1:
									reels.texts.remove(reels.texts.size() - 1)
									items.item_types.remove(pos)
									items.saved_item_data.remove(pos)
									items.item_count_data.remove(pos)
									items.saved_destroy_counters.remove(pos)
									items.items.remove(pos)
									
									while items.page * items.visible_items >= items.items.size() and items.items.size() != 0:
										items.page -= 1
									items.update_page_buttons()
									items.update_positions()
									items.remove_child(item)
								else:
									item.item_count -= 1
									item.update_value_text()
								$"/root/Main/Landlord".stolen_items.push_back(q.dynamic_icon)
							4:
								$"/root/Main/Reels".add_tile(["dud"])
							5, 6, 7:
								var donezo = false
								for r in reels.reels:
									for i in r.icons:
										if i.type == q.dynamic_icon:
											for t in item_info_texts:
												if get_children().has(t.get_parent()):
													remove_child(t.get_parent())
												t.get_parent().queue_free()
											item_info_texts.clear()
											for s in symbol_info_texts:
												if get_children().has(s.get_parent()):
													remove_child(s.get_parent())
												s.get_parent().queue_free()
											symbol_info_texts.clear()
											for s in disabled_item_sprites:
												if get_children().has(s):
													remove_child(s)
												s.queue_free()
											
											disabled_item_sprites.clear()
											symbol_counts.clear()
											symbol_data.clear()
											destroyed_symbol_counts.clear()
											destroyed_item_counts.clear()
											removed_symbol_counts.clear()
											
											i.change_type("empty", false)
											i.prev_data.clear()
											i.update_value_text()
											donezo = true
											break
									if donezo:
										break
								reels.update_icon_types()
								$"/root/Main/Landlord".stolen_symbols.push_back(q.dynamic_icon)
							14:
								$"/root/Main/Reels".add_tile(["hex_of_destruction"])
							24:
								reroll_cost = 1 + q.values[0]
							25:
								removal_cost = 1 + q.values[0]
					$"/root/Main/Landlord".queued_fine_print.clear()
				"boss_fight_1":
					add_event("boss_fight_2", null)
					delay_timer = 0
				"swap_prompt_1", "swapping_device_essence_prompt":
					if email_to_resolve.text != tr("swap_prompt_1_text") + " <icon_swapping_device_essence>":
						sme_this_spin.push_back("swapping_device")
					else:
						sme_this_spin.push_back("swapping_device_essence")
					if choice == "<icon_deny>":
						for i in reels.selected_icons:
							i.stop_animations()
						symbols_to_select = 0
						reels.selected_icons.clear()
						reels.update_icon_types()
						spin_modifying_effects()
					elif symbols_to_select == 0:
						for i in reels.selected_icons:
							i.stop_animations()
						reels.swap_icon_positions(reels.selected_icons[0], reels.selected_icons[1])
						reels.selected_icons[0].update_value_text()
						reels.selected_icons[1].update_value_text()
						reels.update_icon_types()
						if $"/root/Main/Items".has_unmodded_item("swapping_device_essence"):
							var sde = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["swapping_device_essence"])]
							if email_to_resolve.text == tr("swap_prompt_1_text") + " <icon_swapping_device_essence>":
								sde.symbol_trigger = true
								sde.affected_symbols.push_back(reels.selected_icons[0])
								sde.affected_symbols.push_back(reels.selected_icons[1])
							sde.saved_value += 1
							sde.update_value_text()
							if sde.saved_value >= sde.values[0]:
								sde.temp_destroy()
						reels.selected_icons.clear()
						spin_modifying_effects()
					else:
						dont_save = true
					sme_this_spin.push_back("swapping_device")
				"inventory", "removal_token_prompt":
					for i in item_info_texts:
						if get_children().has(i.get_parent()):
							remove_child(i.get_parent())
						i.get_parent().queue_free()
					item_info_texts.clear()
					for s in symbol_info_texts:
						if get_children().has(s.get_parent()):
							remove_child(s.get_parent())
						s.get_parent().queue_free()
					symbol_info_texts.clear()
					for s in disabled_item_sprites:
						if get_children().has(s):
							remove_child(s)
						s.queue_free()
					disabled_item_sprites.clear()
					symbol_counts.clear()
					symbol_data.clear()
					destroyed_symbol_counts.clear()
					destroyed_item_counts.clear()
					removed_symbol_counts.clear()
					inv_open = false
					label_text.i_spaced = false
					label_text.e_spaced = true
					label_text.raw_string = ""
					label_text.force_update = true
					label_text.update()
					$"/root/Main/Menus".buttons_menu.deck_button.down = false
					$"/root/Main/Menus".buttons_menu.deck_button.visual_reset()
					removing = false
					if choice != "<icon_deny>" and removal_tokens > removal_cost - 1:
						draw_removal_prompt(false)
						delay_timer = 0
					else:
						saved_symbol_order.clear()
						saved_symbol_data.clear()
						saved_symbol_counts.clear()
				"oil_can_prompt", "oil_can_essence_prompt":
					var mod = int(round(112 * $"/root/Main/Options Sprite/Options".ui_scaling.reels_ui))
					if email_to_resolve.text != tr("oil_can_prompt_text") + " <icon_oil_can_essence>":
						sme_this_spin.push_back("oil_can")
						if choice != "<icon_deny>":
							respun_reel = reels.selected_reels[0].reel_num
					else:
						sme_this_spin.push_back("oil_can_essence")
						if choice != "<icon_deny>":
							respun_essence_reel = reels.selected_reels[0].reel_num
					if choice == "<icon_deny>":
						reels_to_select = 0
						reels.selected_reels.clear()
						reels.update_icon_types()
						spin_modifying_effects()
					elif reels_to_select == 0:
						var selected_reel = reels.selected_reels[0]
						var pool = selected_reel.icons.duplicate(true)
						selected_reel.icons.clear()
						selected_reel.max_icons = 0
						
						var nice_empties = true
						
						if $"/root/Main/Items".has_unmodded_item("oil_can_essence"):
							var oce = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["oil_can_essence"])]
							oce.saved_value += 1
							oce.update_value_text()
							if oce.saved_value >= oce.values[0]:
								oce.temp_destroy()
						
						var e_str = $"/root/Main".get_empty_data()
						
						for r in reels.reels:
							var r_tbe = []
							if r != selected_reel:
								for i in r.icons:
									if r.y_positions.find(int(i.position.y)) == -1 and i.position.y != -mod and (i.type != e_str or not nice_empties):
										pool.push_back(i)
										r_tbe.push_back(i)
								for i in r_tbe:
									r.icons.erase(i)
									r.remove_child(i)
									r.max_icons -= 1
						if (not $"/root/Main".sandbox_mode or ($"/root/Main".sandbox_mode and not $"/root/Main".sandbox_consistent)) and (current_modded_floor == null or typeof(current_modded_floor) == TYPE_STRING or not current_modded_floor.consistent_spins):
							randomize()
							pool.shuffle()
						for i in range(pool.size()):
							selected_reel.remove_child(pool[i])
							selected_reel.icons.push_back(pool[i])
							selected_reel.add_child(pool[i])
							selected_reel.max_icons += 1
						var increment = 0
						var offscreen_nons = []
						var onscreen_empties = []
						for i in selected_reel.icons:
							var y_pos = int((increment * mod + (mod * (selected_reel.max_spin_delay + 1) + 15 * mod)) % (selected_reel.icons.size() * mod) - mod)
							if ($"/root/Main".sandbox_mode and $"/root/Main".sandbox_consistent) or (current_modded_floor != null and typeof(current_modded_floor) != TYPE_STRING and current_modded_floor.consistent_spins):
								y_pos = (increment * mod) % (selected_reel.icons.size() * mod) - mod
							if selected_reel.y_positions.find(y_pos) != -1 and i.type == e_str:
								onscreen_empties.push_back(i)
							elif selected_reel.y_positions.find(y_pos) == -1 and i.type != e_str:
								offscreen_nons.push_back(i)
							increment += 1
						for empty in onscreen_empties:
							for non in offscreen_nons:
								offscreen_nons.erase(non)
								reels.swap_icon_positions(empty, non)
								break
						offscreen_nons.clear()
						onscreen_empties.clear()
						pool.clear()
						
						reels.spinning = true
						selected_reel.spinning = true
						selected_reel.mini_spin = true
						reels_to_select = 0
						reels.selected_reels.clear()
				"comfy_pillow_prompt", "comfy_pillow_essence_prompt":
					if choice != "<icon_deny>":
						if email_to_resolve.type == "comfy_pillow_prompt":
							rent_values[1] -= 1
							comfy_pillow_triggers += $"/root/Main".item_database[$"/root/Main".existing_items["comfy_pillow"]].values[1] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow"])].item_count
						else:
							if $"/root/Main/Items".has_unmodded_item("comfy_pillow_essence"):
								rent_values[1] -= $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].values[1]
								comfy_pillow_essence_triggers += $"/root/Main".item_database[$"/root/Main".existing_items["comfy_pillow_essence"]].values[2] * $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].item_count
								$"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].temp_destroy()
						if $"/root/Main/Items".has_unmodded_item("devils_deal_essence"):
							var dde = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["devils_deal_essence"])]
							while $"/root/Main/Coins".coins + $"/root/Main/Coins".queued_increase + $"/root/Main/Sums/Coin Sum".value < rent_values[0] and dde.destroy_counters >= 0:
								$"/root/Main/Sums/Coin Sum".add_value(dde.values[0])
								$"/root/Main/Sums/Coin Sum".adding = true
								$"/root/Main/Sums/HP Sum".add_value(dde.values[0])
								$"/root/Main/Sums/HP Sum".adding = true
								dde.destroy()
						if rent_values[0] == 0:
							endless_rent_email()
						elif can_try_to_pay_rent():
							if int(times_rent_paid + 1) % 4 == 0 and can_try_to_pay_rent() and can_cycle_music and $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
								$"/root/Main/Music Player".fully_fade_out()
								$"/root/Main/Music Player".play_rand_music()
								$"/root/Main/Music Player".fade_in()
							add_event("rent_due", null)
						else:
							add_event("game_over", null)
						delay_timer = 0
					else:
						prompts_passed.push_back(email_to_resolve.type)
				"hex_of_emptiness_trigger":
					check_spend_triggers("skip")
					var e_types = []
					for e in emails:
						e_types.push_back(e.type)
					if $"/root/Main/Items".has_unmodded_item("comfy_pillow") and not e_types.has("comfy_pillow_prompt") and not prompts_passed.has("comfy_pillow_prompt"):
						if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow"])].values[0]:
							add_event("comfy_pillow_prompt", null)
							delay_timer = 0
					if $"/root/Main/Items".has_unmodded_item("comfy_pillow_essence") and not e_types.has("comfy_pillow_essence_prompt") and not prompts_passed.has("comfy_pillow_essence_prompt"):
						if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].values[0]:
							add_event("comfy_pillow_essence_prompt", null)
							delay_timer = 0
					if $"/root/Main/Landlord".queued_fine_print.size() > 0:
						add_event("fine_print", null)
						delay_timer = 0
				"chili_powder_essence_prompt":
					if choice != null and choice == "skip":
						check_spend_triggers("skip")
				"add_item_prompt":
					if choice != null and choice == "skip":
						check_spend_triggers("skip")
					if queued_items.size() > 0:
						add_event("add_item_prompt", queued_items[0])
						queued_items.remove(0)
						delay_timer = 0
					else:
						var e_types = []
						for e in emails:
							e_types.push_back(e.type)
					$"/root/Main".save_log()
				"add_tile_prompt":
					if choice != null and choice == "skip":
						check_spend_triggers("skip")
					elif choice == "reroll_pay":
						check_spend_triggers("spend_reroll_token")
						reroll_tokens -= reroll_cost
						var extra_values_obj = {"push_front": true, "reset_position": false}
						if email_to_resolve.extra_values.has("forced_rarity"):
							extra_values_obj["forced_rarity"] = email_to_resolve.extra_values.forced_rarity
						if email_to_resolve.extra_values.has("forced_group"):
							extra_values_obj["forced_group"] = email_to_resolve.extra_values.forced_group
						queued_symbols.push_front(extra_values_obj)
						hoht = hex_of_hoarding_trigger
						prompt_reroll = true
					if queued_symbols.size() > 0:
						add_event("add_tile_prompt", queued_symbols[0])
						queued_symbols.remove(0)
						delay_timer = 0
					else:
						var e_types = []
						for e in emails:
							e_types.push_back(e.type)
						if $"/root/Main/Items".has_unmodded_item("comfy_pillow") and not e_types.has("comfy_pillow_prompt") and not prompts_passed.has("comfy_pillow_prompt"):
							if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow"])].values[0]:
								add_event("comfy_pillow_prompt", null)
								delay_timer = 0
						if $"/root/Main/Items".has_unmodded_item("comfy_pillow_essence") and not e_types.has("comfy_pillow_essence_prompt") and not prompts_passed.has("comfy_pillow_essence_prompt"):
							if rent_values[1] == $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["comfy_pillow_essence"])].values[0]:
								add_event("comfy_pillow_essence_prompt", null)
								delay_timer = 0
					if $"/root/Main/Landlord".queued_fine_print.size() > 0:
						add_event("fine_print", null)
						delay_timer = 0
					$"/root/Main".save_log()
		var going_to_main_menu = false
		if email_to_resolve.has("reply_results") and email_to_resolve.has("replies") and email_to_resolve.replies.find(choice) != -1:
			var r = email_to_resolve.reply_results[email_to_resolve.replies.find(choice)]
			var z = load("res://Slot Icon.tscn").instance()
			
			var eff = r.duplicate(true)
			
			if eff.has("unlock_next_floor") and eff.unlock_next_floor and not $"/root/Main".sandbox_mode:
				if not $"/root/Main/Stats Sprite/Stats".unlocked_modded_floors.has("apartment_floor_" + current_modded_floor.type + "_" + str(current_modded_floor.floor_num + 1) + "_STEAM_ID_" + current_modded_floor.author_id + "_PACK_" + current_modded_floor.pack_num) and $"/root/Main".apartment_floor_database.has("apartment_floor_" + current_modded_floor.type + "_" + str(current_modded_floor.floor_num + 1) + "_STEAM_ID_" + current_modded_floor.author_id + "_PACK_" + current_modded_floor.pack_num):
					$"/root/Main/Stats Sprite/Stats".unlocked_modded_floors.push_back("apartment_floor_" + current_modded_floor.type + "_" + str(current_modded_floor.floor_num + 1) + "_STEAM_ID_" + current_modded_floor.author_id + "_PACK_" + current_modded_floor.pack_num)
				$"/root/Main".save_stats()
			if eff.has("back_to_main_menu") and eff.back_to_main_menu:
				$"/root/Main".backup_stats()
				$"/root/Main".reset_values()
				$"/root/Main".title()
				going_to_main_menu = true
			elif eff.has("start_endless_mode") and eff.start_endless_mode:
				start_endless_mode()
			elif eff.has("start_bossfight") and eff.start_bossfight:
				start_bossfight()
			elif eff.has("retry") and eff.retry:
				if retry():
					$"/root/Main".backup_stats()
					return
					
			z.type = "missing"
			z.in_reels = false
			add_child(z)
			z.soft_changing = true
			
			if not eff.has("comparisons"):
				eff["comparisons"] = []
			eff["target"] = null
			
			z.add_effect(eff)
			z.check_conditional_effects(tmp_effects)
			tmp_effects.clear()
			
			remove_child(z)
			z.queue_free()
		if email_to_resolve.type == "ending" or email_to_resolve.type == "game_over" or email_to_resolve.type == "out_of_money":
			$"/root/Main".backup_stats()
		if emails.size() == 1 and not email_to_resolve.prompt:
			if email_to_resolve.type == "boss_fight_2" and not $"/root/Main".demo:
				start_bossfight()
			elif email_to_resolve.type == "add_tile" or email_to_resolve.type == "add_item" or email_to_resolve.type == "add_tile_prompt" or email_to_resolve.type == "hex_of_emptiness_trigger":
				if $"/root/Main/Items".has_unmodded_item("frozen_pizza") and $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("frozen_pizza")].saved_value >= $"/root/Main/Items".items[$"/root/Main/Items".item_types.find("frozen_pizza")].values[0]:
					var fp = $"/root/Main/Items".items[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["frozen_pizza"])]
					hex_of_hoarding_trigger = false
					
					fp.saved_value = 0
					$"/root/Main/Items".saved_item_data[$"/root/Main/Items".item_types.find($"/root/Main".existing_items["frozen_pizza"])] = fp.saved_value
					fp.check_conditional_effects()
					if forced_rarities.size() > 0:
						add_event("add_tile", get_forced_rarities(symbols_to_choose_from))
					else:
						add_event("add_tile", {"forced_rarity": []})
					delay_timer = 0
				for e in range(extra_symbol_choices):
					if forced_rarities.size() > 0:
						add_event("add_tile", get_forced_rarities(symbols_to_choose_from))
					else:
						add_event("add_tile", {"forced_rarity": []})
					delay_timer = 0
				extra_symbol_choices = 0
		if emails.size() > 0:
			if emails.size() == 1 and (email_to_resolve.type == "add_tile" or email_to_resolve.type == "add_item" or email_to_resolve.type == "add_tile_prompt" or email_to_resolve.type == "hex_of_emptiness_trigger"):
				if $"/root/Main".sandbox_mode and current_modded_floor == null:
					add_event("add_tile", null)
					$"/root/Main".sandbox_reloading = true
					$"/root/Main".load_sandbox()
					$"/root/Main".new_game()
					$"/root/Main".sandbox_reloading = false
					if removal_tokens > removal_cost - 1:
						$"/root/Main/Menus".buttons_menu.removal_button.text_node.values = [removal_tokens]
						$"/root/Main/Menus".buttons_menu.removal_button.update_size()
						$"/root/Main/Menus".buttons_menu.removal_button.text_node.force_update = true
						$"/root/Main/Menus".buttons_menu.removal_button.text_node.update()
						$"/root/Main/Menus".buttons_menu.removal_button.correct_size()
						$"/root/Main/Menus".buttons_menu.removal_button.visible = true
					return
		if choice != "dont":
			emails.erase(email_to_resolve)
		remove(email_to_resolve)
		if choice != "dont":
			label_text.custom_icon_offset = Vector2(0, 0)
			display()
		for t in $"/root/Main/Tooltips".get_children():
			t.queue_free()
		if not dont_save:
			hex_of_emptiness_trigger = false
			hex_of_hoarding_trigger = hoht
			just_rerolled = false
			$"/root/Main".save_game()
		if emails.size() == 0:
			for r in reels.reels:
				for i in r.icons:
					if r.y_positions.find(int(i.position.y)) != -1:
						i.active = true
			$"/root/Main/Items".items_destroyed_this_spin.clear()
			$"/root/Main/Items".item_types_at_end_of_spin.clear()
			if removal_tokens < removal_cost:
				$"/root/Main/Menus".buttons_menu.removal_button.visible = false
			else:
				$"/root/Main/Menus".buttons_menu.removal_button.visible = true
			if choice != "main_menu" and not going_to_main_menu:
				$"/root/Main".change_current_menu_path("slots")
		scroll_bar.rect_position.y = scroll_bar.top
		offset_y = $"/root/Main/Options Sprite/Options".resolution_y + 448
	locked_in_position = false
	if $"/root/Main".sandbox_mode and (prev_email_type == "add_tile" or prev_email_type == "add_item" or prev_email_type == "add_tile_prompt") and emails.size() == 0 and current_modded_floor == null:
		rent_values = [25, 5]
		if $"/root/Main".sandbox_icons.size() > 0 and $"/root/Main".sandbox_mode:
			for r in reels.reels:
				r.load_icons()

func endless_rent_email():
	can_cycle_music = true
	$"/root/Main/Sums/Extra Sum".add_value(0, 0, -essence_tokens)
	$"/root/Main/Sums/Extra Sum".adding = true
	hex_of_emptiness_trigger = false
	hex_of_hoarding_trigger = false
	if int(times_rent_paid + 1) % 4 == 0 and can_try_to_pay_rent() and can_cycle_music and $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
		$"/root/Main/Music Player".fully_fade_out()
		$"/root/Main/Music Player".play_rand_music()
		$"/root/Main/Music Player".fade_in()
		can_cycle_music = false
	queued_essence_emails = essence_tokens
	essence_tokens = 0
	$"Confirm Select".play()
	$"/root/Main/Menus".buttons_menu.spin_button.down = false
	times_rent_paid += 1
	for e in $"/root/Main".mod_on_rent_paid_effects:
		var item_num = $"/root/Main/Items".item_types.find($"/root/Main".existing_items[e.type])
		if item_num == -1:
			continue
		var i = $"/root/Main/Items".items[item_num]
		i.addding_post_spin_effects = true
		i.add_conditional_effects()
		i.addding_post_spin_effects = false
		i.check_conditional_effects()
		i.c_effects.clear()
	update_rent_values()
	
	var i_tbe = []
	for i in $"/root/Main/Items".recently_destroyed_items:
		if i.payments <= 0:
			i_tbe.push_back(i)
		i.payments -= 1
	for i in i_tbe:
		$"/root/Main/Items".recently_destroyed_items.erase(i)

	if int(times_rent_paid) % 2 == 1 and not $"/root/Main".demo:
		if $"/root/Main/Stats Sprite/Stats".essences_unlocked:
			$"/root/Main/Sums/Extra Sum".add_value(comrade_values[0], comrade_values[1], comrade_values[2])
			essence_tokens += comrade_values[2]
		else:
			$"/root/Main/Sums/Extra Sum".add_value(comrade_values[0], comrade_values[1], 0)
		$"/root/Main/Sums/Extra Sum".adding = true
		reroll_tokens += comrade_values[0]
		removal_tokens += comrade_values[1]

	post_rent_symbol_choice()

func get_forced_rarities(num):
	var arr = []
	var f = 0
	var ob = true
	if forced_rarities.size() > 0 and forced_rarities[0].has("or_better"):
		ob = forced_rarities[0].or_better
	while f < num and forced_rarities.size() > 0:
		f += 1
		arr.push_back(forced_rarities[0].forced_rarity[0])
		forced_rarities[0].forced_rarity.remove(0)
		if forced_rarities[0].forced_rarity.size() == 0:
			forced_rarities.remove(0)
	return {"forced_rarity": arr, "or_better": ob}

func get_forced_item_rarities(num):
	var arr = []
	var f = 0
	var ob = true
	if forced_item_rarities.size() > 0 and forced_item_rarities[0].has("or_better"):
		ob = forced_item_rarities[0].or_better
	while f < num and forced_item_rarities.size() > 0:
		f += 1
		arr.push_back(forced_item_rarities[0].forced_rarity[0])
		forced_item_rarities[0].forced_rarity.remove(0)
		if forced_item_rarities[0].forced_rarity.size() == 0:
			forced_item_rarities.remove(0)
	return {"forced_rarity": arr, "or_better": ob}

func store_page():
	OS.shell_open("https://store.steampowered.com/app/1404850/Luck_be_a_Landlord")

func discord():
	OS.shell_open("https://TrampolineTales.com/discord")

func twitter():
	OS.shell_open("https://twitter.com/TrampolineTales")

func newsletter():
	OS.shell_open("https://blog.TrampolineTales.com/")

func save():
	var save_dict = {
		"path" : get_path(),
		"emails": emails,
		"rent_values": rent_values,
		"times_rent_paid": times_rent_paid,
		"times_to_pay_rent": times_to_pay_rent,
		"saved_card_types": saved_card_types,
		"queued_symbols": queued_symbols,
		"queued_items": queued_items,
		"spins": spins,
		"total_runs": total_runs,
		"run_timestamp": run_timestamp,
		"current_floor": current_floor,
		"modded_floor_string": modded_floor_string,
		"hex_of_emptiness_trigger": hex_of_emptiness_trigger,
		"hex_of_hoarding_trigger": hex_of_hoarding_trigger,
		"comfy_pillow_triggers": comfy_pillow_triggers,
		"comfy_pillow_essence_triggers": comfy_pillow_essence_triggers,
		"destroyed_symbol_types": destroyed_symbol_types,
		"destroyed_symbol_types_size": destroyed_symbol_types_size,
		"removed_symbol_types": removed_symbol_types,
		"symbols_added_this_spin": symbols_added_this_spin,
		"symbols_destroyed_this_spin": symbols_destroyed_this_spin,
		"items_destroyed_this_spin": items_destroyed_this_spin,
		"compost_heap_symbols_destroyed": compost_heap_symbols_destroyed,
		"fossil_diff": fossil_diff,
		"symbols_to_choose_from": symbols_to_choose_from,
		"items_to_choose_from": items_to_choose_from,
		"symbols_to_select": symbols_to_select,
		"reels_to_select": reels_to_select,
		"reroll_tokens": reroll_tokens,
		"removal_tokens": removal_tokens,
		"essence_tokens": essence_tokens,
		"sme_this_spin": sme_this_spin,
		"respun_essence_reel": respun_essence_reel,
		"respun_reel": respun_reel,
		"queued_essence_emails": queued_essence_emails,
		"permanent_bonuses": permanent_bonuses,
		"rarity_bonuses": rarity_bonuses,
		"forced_rarities": forced_rarities,
		"forced_item_rarities": forced_item_rarities,
		"endless_mode": endless_mode,
		"extra_symbol_choices": extra_symbol_choices,
		"extra_item_choices": extra_item_choices,
		"current_tip_num": current_tip_num,
		"saved_mod_ids": saved_mod_ids,
		"modded_run": modded_run,
		"prompts_passed": prompts_passed,
		"doing_boss_fight": doing_boss_fight,
		"reroll_cost": reroll_cost,
		"removal_cost": removal_cost,
		"transformed_coals": transformed_coals,
		"passed": $"/root/Main".group_database.symbols.passed,
		"taken": $"/root/Main".group_database.symbols.taken
	}
	return save_dict
