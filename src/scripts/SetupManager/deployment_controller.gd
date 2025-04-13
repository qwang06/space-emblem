extends Node

# Signals emitted when a unit is placed and when all units have been deployed
signal unit_placed(unit: Node2D)
signal placement_complete()

# Maximum number of units that can be deployed
@export var max_units := 2
# Reference to the UI container for unit selection
@export var deployment_ui: Control
# Container node where deployed units will be added as children
@export var unit_container: Node

# Preloaded unit scenes for testing purposes
# TODO: Replace with dynamic loading from save file
var blue_mage: PackedScene = preload("res://src/scenes/Unit/Characters/blue_mage.tscn")
var red_mage: PackedScene = preload("res://src/scenes/Unit/Characters/red_mage.tscn")

# Reference to the game grid system
var grid: Grid = null  # Injected
# Array of valid deployment positions
var setup_tiles: Array[Vector2i] = []
# Array to track units that have been placed on the grid
var placed_units: Array[Node2D] = []
# Dictionary containing deployment zone information
var deployment = {}
# Reference to visual overlay for highlighting valid deployment zones
var grid_overlay
# Currently selected UI button and unit
var _current_button = null
var _current_unit = null

# Initialize the controller with required dependencies
func init(g: Grid, go, d):
	grid = g
	deployment = d
	grid_overlay = go

# Start the deployment setup phase
func begin_setup():
	# Exit if no player deployment zones are defined
	if (
		not deployment.has("player")
		or deployment["player"].size() == 0
	):
		return

	# Convert deployment zone coordinates to Vector2i format
	for i in range(deployment["player"].size()):
		setup_tiles.append(
			Vector2i(deployment["player"][i][0],
			deployment["player"][i][1])
		)
	placed_units.clear()
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Create UI button for unit deployment
	var button = Button.new()
	var unit1 = blue_mage.instantiate()
	button.text = unit1.name
	button.flat = true
	button.connect("pressed", Callable(self, "handle_unit_click").bind(unit1, button))

	deployment_ui.add_child(button)

# Handle unit selection from the deployment UI
func handle_unit_click(unit: Node2D, button: Button) -> void:
	_current_button = button
	_current_unit = unit
	deployment_ui.visible = false

# Handle tile selection for unit placement
func handle_tile_click(tile: Vector2i) -> void:
	# Validate placement conditions
	if (
		not setup_tiles.has(tile) or
		_current_unit == null or
		unit_container == null or
		placed_units.size() >= max_units or 
		grid.get_unit_at(tile) != null
	):
		return

	# Place the unit on the grid
	_current_unit.position = grid.calculate_map_position(tile)
	unit_container.add_child(_current_unit)
	_current_unit.initialize(grid)

	# Update game state
	deployment_ui.visible = true
	_current_button.queue_free()
	_current_unit = null
	emit_signal("unit_placed", _current_unit)

	# Check if deployment is complete
	if placed_units.size() == max_units:
		emit_signal("placement_complete")

# Cancel the deployment setup
func cancel_setup():
	# TODO: Implement cleanup and state reset
	pass
