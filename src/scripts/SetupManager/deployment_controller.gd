extends Node

# Signals
signal unit_placed(unit: Node2D)  # Emitted when a unit is placed
signal placement_complete()  # Emitted when all units are deployed

# Exported Variables
@export var max_units: int = 2  # Max deployable units
@export var deployment_ui: Control  # UI for unit selection
@export var unit_container: Node  # Parent node for deployed units
@export var cursor: Node2D  # Reference to the cursor node

# Preloaded Resources
var blue_mage: PackedScene = preload("res://src/scenes/Unit/Characters/blue_mage.tscn")
var red_mage: PackedScene = preload("res://src/scenes/Unit/Characters/red_mage.tscn")

# State Variables
var grid: Grid = null  # Reference to the game grid
var setup_tiles: Array[Vector2i] = []  # Valid deployment positions
var placed_units: Array[Node2D] = []  # Deployed units
var deployment: Dictionary = {}  # Deployment zone data
var grid_overlay: Node = null  # Visual overlay for deployment zones
var _current_button: Button = null  # Selected UI button
var _current_unit: Node2D = null  # Selected unit for placement

#-----------------
# Initialization
#-----------------
func init(g: Grid, go: Node, d: Dictionary) -> void:
	# Inject dependencies
	self.grid = g
	self.grid_overlay = go
	self.deployment = d

#-----------------
# Deployment Setup
#-----------------
func begin_setup() -> void:
	# Ensure player deployment zones exist
	if not deployment.has("player") or deployment["player"].is_empty():
		return

	# Convert deployment zone coordinates to Vector2i
	setup_tiles.clear()
	for coords in deployment["player"]:
		setup_tiles.append(Vector2i(coords[0], coords[1]))

	# Highlight valid deployment tiles
	placed_units.clear()
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Create a button for deploying a unit
	_create_unit_button(blue_mage)

func _create_unit_button(unit_scene: PackedScene) -> void:
	# Create and configure a button for the given unit
	var button: Button = Button.new()
	var unit: Node2D = unit_scene.instantiate()
	button.text = unit.name
	button.flat = true
	button.pressed.connect(_on_unit_button_pressed.bind(unit, button))
	deployment_ui.get_node('DeployableUnits').add_child(button)

#-----------------
# Unit Selection
#-----------------
func _on_unit_button_pressed(unit: Node2D, button: Button) -> void:
	# Connect to cursor "moved" signal
	cursor.moved.connect(show_unit.bind(unit))

	# Handle unit selection from the UI
	_current_button = button
	_current_unit = unit
	unit_container.add_child(_current_unit)
	deployment_ui.visible = false

# Shows a faded unit on the cursor
func show_unit(prev_tile, new_tile, unit) -> void:
	if grid.get_unit_at(new_tile) or not setup_tiles.has(new_tile):
		# If a unit is already present, do not show the new unit
		return

	# Update the unit's position to follow the cursor
	unit.position = grid.calculate_map_position(new_tile)
	grid.place_unit(unit, new_tile)
	grid.remove_unit(prev_tile)

#-----------------
# Unit Placement
#-----------------
func handle_tile_click(tile: Vector2i) -> void:
	# Validate placement conditions
	if not _can_place_unit(tile):
		return

	# Place the unit on the grid
	_place_unit(tile)

	# Disconnect cursor signal
	cursor.moved.disconnect(show_unit)

	# Check if deployment is complete
	if placed_units.size() == max_units:
		emit_signal("placement_complete")

func _can_place_unit(tile: Vector2i) -> bool:
	# Ensure the tile is valid for placement
	return (
		setup_tiles.has(tile) and
		_current_unit != null and
		unit_container != null and
		placed_units.size() < max_units and
		grid.get_unit_at(tile) == null
	)

func _place_unit(tile: Vector2i) -> void:
	# Place the selected unit on the grid
	_current_unit.position = grid.calculate_map_position(tile)
	_current_unit.initialize(grid)
	grid.place_unit(_current_unit, tile)
	placed_units.append(_current_unit)

	# Update UI and state
	deployment_ui.visible = true
	_current_button.queue_free()
	emit_signal("unit_placed", _current_unit)
	_current_unit = null

#-----------------
# Cleanup
#-----------------
func cancel_setup() -> void:
	# Reset deployment state (to be implemented)
	pass
