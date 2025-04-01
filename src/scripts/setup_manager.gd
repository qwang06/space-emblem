extends Node

signal unit_placed(unit: Node2D)
signal placement_complete()

@export var max_units := 5

var grid: Grid = null  # Injected
var setup_tiles: Array[Vector2i] = []
var placed_units: Array[Node2D] = []
var unit_scene: PackedScene = preload("res://src/scenes/Unit/unit.tscn")
var tile_highlighter

func begin_setup(allowed_tiles: Array[Vector2i]):
	setup_tiles = allowed_tiles
	placed_units.clear()
	tile_highlighter = get_parent().get_node("TileHighlighter")
	tile_highlighter.set_highlighted_tiles(setup_tiles)


func handle_tile_click(tile: Vector2i) -> void:
	if not setup_tiles.has(tile):
		return

	if placed_units.size() >= max_units:
		print("Max units placed")
		return

	if grid.get_unit_at(tile) != null:
		print("Tile already occupied")
		return

	var unit = unit_scene.instantiate()
	unit.position = grid.map_to_world(tile)
	get_tree().current_scene.add_child(unit)

	grid.place_unit(tile, unit)
	placed_units.append(unit)
	emit_signal("unit_placed", unit)

	if placed_units.size() == max_units:
		emit_signal("placement_complete")

func cancel_setup():
	# Cleanup visuals, reset state if needed
	pass