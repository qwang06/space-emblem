extends Node

signal unit_placed(unit: Node2D)
signal placement_complete()

@export var max_units := 2
@export var deployment_ui: Control

# Ideally units should come from player's save file, this is just for testing
var blue_mage: PackedScene = preload("res://src/scenes/Unit/Characters/blue_mage.tscn")
var red_mage: PackedScene = preload("res://src/scenes/Unit/Characters/red_mage.tscn")

var grid: Grid = null  # Injected
var setup_tiles: Array[Vector2i] = []
var placed_units: Array[Node2D] = []
var deployment = {}
var grid_overlay 

func init(g: Grid, go, d):
	grid = g
	deployment = d
	grid_overlay = go
	

func begin_setup():
	if (
		not deployment.has("player")
		or deployment["player"].size() == 0
	):
		return

	# loop through deployment_zones["player"] and convert to Vector2i
	for i in range(deployment["player"].size()):
		setup_tiles.append(
			Vector2i(deployment["player"][i][0],
			deployment["player"][i][1])
		)
	placed_units.clear()
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Display the units in the deployment UI
	# Create the unit buttons and add them to the UI
	var button = Button.new()
	var unit1 = blue_mage.instantiate()
	button.text = unit1.name
	button.connect("pressed", Callable(self, "handle_unit_click").bind(unit1))

	deployment_ui.add_child(button)


func handle_unit_click(unit: Node2D) -> void:
	print("Unit clicked: ", unit.name)


func handle_tile_click(tile: Vector2i) -> void:
	if not setup_tiles.has(tile):
		return

	if placed_units.size() >= max_units:
		print("Max units placed")
		return

	if grid.get_unit_at(tile) != null:
		print("Tile already occupied")
		return

	var unit = red_mage.instantiate()
	unit.position = grid.calculate_map_position(tile)
	get_tree().current_scene.add_child(unit)
	unit.initialize(grid)

	grid.place_unit(unit, tile)
	placed_units.append(unit)
	emit_signal("unit_placed", unit)

	if placed_units.size() == max_units:
		emit_signal("placement_complete")

func cancel_setup():
	# Cleanup visuals, reset state if needed
	pass
