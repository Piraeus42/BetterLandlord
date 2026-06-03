extends Node2D

var spin_button
var options_button
var deck_button
var removal_button
var left_button
var right_button
var tooltip_card = true

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _ready():
	spin_button = preload("res://TT Button.tscn").instance()
	
	spin_button.border_thickness = 8
	spin_button.button_text = tr("SPIN")
	spin_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
	spin_button.color_type = "button_color_continue"
	spin_button.target = $"/root/Main/Reels"
	spin_button.call = "spin"
	spin_button.shortcuts = ["SPIN"]
	spin_button.toggle = false
	spin_button.alignment_tags["dont"] = true
	spin_button.scale_mod = 4
	spin_button.centered_text_button = true
	spin_button.scale_with_thickness = false
	
	add_child(spin_button)
	
	spin_button.update_size()
	spin_button.correct_size()
	spin_button.rect_position.y = $"/root/Main/Options Sprite/Options".resolution_y - spin_button.rect_size.y - 6 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons
	spin_button.base_x = spin_button.rect_position.x
	spin_button.selector_alignment = "centered"
	
	if int($"/root/Main/Options Sprite/Options".display_font) == 1 and TranslationServer.get_locale() == "ar":
		spin_button.text_node.forced_font = preload("res://NotoSansAR_Spin.tres")
	
	options_button = preload("res://TT Button.tscn").instance()
	
	options_button.button_text = tr("options")
	options_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_options"])
	options_button.color_type = "button_color_options"
	options_button.target = $"/root/Main/Options Sprite/Options"
	options_button.call = "open"
	options_button.shortcuts = ["options"]
	options_button.toggle = false
	options_button.args = [options_button]
	options_button.alignment_tags["dont"] = true
	options_button.scale_mod = -1
	
	add_child(options_button)
	
	options_button.text_node.force_update = true
	options_button.text_node.update()
	options_button.button_text = options_button.text_node.text
	options_button.update_size()
	options_button.correct_size()
	options_button.button_text = options_button.text_node.raw_string
	
	deck_button = preload("res://TT Button.tscn").instance()
	
	deck_button.button_text = tr("inventory")
	deck_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_inventory"])
	deck_button.color_type = "button_color_inventory"
	deck_button.target = $"/root/Main/Pop-up Sprite/Pop-up"
	deck_button.call = "draw_prompt_deck"
	deck_button.shortcuts = ["inventory"]
	deck_button.toggle = false
	deck_button.alignment_tags["dont"] = true
	deck_button.scale_mod = -1
	
	add_child(deck_button)
	
	deck_button.text_node.force_update = true
	deck_button.text_node.update()
	deck_button.button_text = deck_button.text_node.text
	deck_button.update_size()
	deck_button.correct_size()
	deck_button.button_text = deck_button.text_node.raw_string
	deck_button.rect_position = Vector2(1016 - deck_button.rect_size.x, 570 - deck_button.rect_size.y)
	deck_button.base_x = deck_button.rect_position.x
	
	removal_button = preload("res://TT Button.tscn").instance()
	
	removal_button.button_text = tr("removal_pay")
	removal_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_removal"])
	removal_button.color_type = "button_color_removal"
	removal_button.target = $"/root/Main/Pop-up Sprite/Pop-up"
	removal_button.call = "draw_removal_prompt"
	removal_button.shortcuts = ["use_removal"]
	removal_button.args = [true]
	removal_button.toggle = false
	removal_button.visible = false
	removal_button.alignment_tags.bottom = true
	removal_button.aligned = false
	removal_button.saved_resolution = Vector2(1024, 576)
	removal_button.scale_mod = -1
	
	add_child(removal_button)
	
	removal_button.text_node.values = [$"/root/Main/Pop-up Sprite/Pop-up".removal_tokens]
	removal_button.text_node.force_update = true
	removal_button.text_node.diff_cjk_space = true
	removal_button.text_node.change_set_size(removal_button.text_node.base_scale)
	if $"/root/Main/Options Sprite/Options".CJK_lang or $"/root/Main/Options Sprite/Options".display_font > 0:
		removal_button.text_node.icon_z_index = 0
	else:
		removal_button.text_node.texts[8].icon_z_index = 0
	removal_button.text_node.update()
	removal_button.button_text = removal_button.text_node.text
	removal_button.change_size()
	removal_button.update_size()
	removal_button.correct_size()
	removal_button.button_text = removal_button.text_node.raw_string
	if $"/root/Main/Options Sprite/Options".ui_scaling.buttons > 1:
		removal_button.rect_position = Vector2(deck_button.rect_position.x - removal_button.rect_size.x - 8 * $"/root/Main/Options Sprite/Options".ui_scaling.buttons, deck_button.rect_position.y)
	else:
		removal_button.rect_position = Vector2(deck_button.rect_position.x - removal_button.rect_size.x - 8, deck_button.rect_position.y)
	removal_button.base_x = removal_button.rect_position.x

	spin_button.text_node.force_update = true
	spin_button.text_node.update()
	spin_button.update_size()
	spin_button.correct_size()
	spin_button.rect_position.x = $"/root/Main/Options Sprite/Options".resolution_x / 2 - spin_button.rect_size.x / 2

func add_item_buttons():
	left_button = preload("res://TT Button.tscn").instance()
	
	left_button.button_text = "<icon_left>"
	left_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_page"])
	left_button.color_type = "button_color_page"
	left_button.target = $"/root/Main/Items"
	left_button.call = "scroll_items_left"
	left_button.toggle = false
	left_button.scale_mod = -1
	
	add_child(left_button)

	left_button.text_node.force_update = true
	if $"/root/Main/Options Sprite/Options".CJK_lang or $"/root/Main/Options Sprite/Options".RTL_lang or $"/root/Main/Options Sprite/Options".display_font > 0:
		left_button.text_node.icon_z_index = 0
	else:
		left_button.text_node.texts[8].icon_z_index = 0
	left_button.text_node.update()
	left_button.button_text = left_button.text_node.text
	left_button.update_size()
	left_button.button_text = left_button.text_node.raw_string

	right_button = preload("res://TT Button.tscn").instance()

	right_button.button_text = "<icon_right>"
	right_button.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_page"])
	right_button.color_type = "button_color_page"
	right_button.target = $"/root/Main/Items"
	right_button.call = "scroll_items_right"
	right_button.toggle = false
	right_button.scale_mod = -1
	
	add_child(right_button)
	
	right_button.text_node.force_update = true
	if $"/root/Main/Options Sprite/Options".CJK_lang or $"/root/Main/Options Sprite/Options".display_font > 0:
		right_button.text_node.icon_z_index = 0
	else:
		right_button.text_node.texts[8].icon_z_index = 0
	right_button.text_node.update()
	right_button.button_text = right_button.text_node.text
	right_button.update_size()
	right_button.button_text = right_button.text_node.raw_string
	
	$"/root/Main".update_alignments()
