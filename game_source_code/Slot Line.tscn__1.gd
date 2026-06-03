extends Node2D

var line

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _ready():
	line = $"Line"
	line.default_color = Color("06799F")
	line.add_point(Vector2(0, 0))
	line.add_point(Vector2(0, 0))
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.round_precision = 3
	line.width = 3
