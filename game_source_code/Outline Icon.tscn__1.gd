extends Sprite

var type

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _ready():
	if type == null:
		type = "empty"
	
	if get_parent().get_parent().get_path() != "/root/Main/Pop-up Sprite/Pop-up/Container":
		get_child(5).set_texture($"/root/Main".get_replacement_texture(type))
