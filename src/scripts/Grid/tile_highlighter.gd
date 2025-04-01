extends Node2D

var tile_positions: Array[Vector2i] = []
@export var tile_size := Vector2i(32, 32)
@export var highlight_color := Color(0.2, 0.6, 1.0, 0.4)

func set_highlighted_tiles(tiles: Array[Vector2i]) -> void:
	tile_positions = tiles

func clear_highlights():
	tile_positions.clear()

func _draw():
	for tile in tile_positions:
		var pos = tile * tile_size
		draw_rect(Rect2(pos, tile_size), highlight_color)
