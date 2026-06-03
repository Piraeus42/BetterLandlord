extends Node2D

var alignment_tags = {"bottom": false, "right": false, "centered": true, "v_centered": true}
var aligned = true
var saved_resolution = Vector2(1024, 576)

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _ready():
	$"Border".color = Color($"/root/Main/Options Sprite/Options".colors3["reel_border"])
	$"Container/Line".color = Color($"/root/Main/Options Sprite/Options".colors3["reel_border"])
