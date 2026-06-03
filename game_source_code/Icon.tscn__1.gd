extends Sprite

var type

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func set_type(_type):
	type = _type
	if type == null or type == "empty":
		type = "empty"
		texture = preload("res://icons/empty_border.png")
	elif type == "hover_coin":
		var t = "hover_coin"
		for m in $"/root/Main".mod_data.symbols:
			if m.substr(0, m.find("_STEAM_ID_")) == "coin" or ($"/root/Main".art_replacement_nums.has("coin") and $"/root/Main".art_replacement_nums["coin"].has(m.substr(5, -1)) and m.substr(0, 5) == "coin_") and not $"/root/Main".is_mod_disabled(m):
				t = m
				break
		texture = $"/root/Main".get_replacement_texture(t)
	else:
		texture = $"/root/Main".get_replacement_texture(type)
