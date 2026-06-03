extends Node2D

var buttons_menu

var current_menu = "buttons"

func _ready():
	buttons_menu = preload("res://Buttons Menu.tscn").instance()
#	stats_menu = preload("res://Stats Menu.tscn").instance()
#	shop_menu = preload("res://Shop Menu.tscn").instance()
#	items_menu = preload("res://Items Menu.tscn").instance()
	
	add_child(buttons_menu)
#	add_child(stats_menu)
#	add_child(shop_menu)
#	add_child(items_menu)
	
	load_menu("buttons")

func update():
	if buttons_menu.get_child(0).down and buttons_menu.get_child(0).active:
		$"/root/Main/Reels".spin()

func load_menu(menu_type):
	current_menu = menu_type
	
	buttons_menu.visible = false
#	stats_menu.visible = false
#	shop_menu.visible = false
#	items_menu.visible = false
	
	match menu_type:
		"buttons":
			buttons_menu.visible = true
#		"stats":
#			stats_menu.visible = true
#		"shop":
#			shop_menu.visible = true
#		"items":
#			items_menu.visible = true
