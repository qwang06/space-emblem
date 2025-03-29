extends Node

@onready var background = %Background

var tileSize

func _ready() -> void:
	tileSize = background.get("tile_set").tile_size.x; # should be same as y

# given a position in cartesian coordinates, return a position in pixel coordinates
func place(object, x, y) -> void:
	# sprites are centered along the y axis but stands on top of the x axis
	#     |
	#	  _[ ]_  <- sprite
	#		  |
	object.position.x = x * tileSize + tileSize / 2.0
	object.position.y = y * tileSize + tileSize

func getTileSize() -> int:
	return tileSize