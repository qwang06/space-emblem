extends Node

# Signals
signal unit_placed(unit: Unit)  # Emitted when a unit is placed
signal unit_deselected(unit: Unit)  # Emitted when a unit is deselected for repositioning
signal placement_complete()  # Emitted when all units are deployed
signal setup_finished()  # Emitted when setup is canceled

# Exported Variables
@export var max_units: int = 2  # Max deployable units
@export var deployment_ui: Control  # UI for unit selection
@export var tooltip_panel: Control  # Tooltip panel for hints
@export var unit_container: Node  # Parent node for deployed units
@export var cursor: Node2D  # Reference to the cursor node

# Preloaded Resources
var blue_mage: PackedScene = preload("res://src/scenes/Unit/Characters/blue_mage.tscn")
var red_mage: PackedScene = preload("res://src/scenes/Unit/Characters/red_mage.tscn")

var unit_scenes: Array[PackedScene] = [
	blue_mage,
	red_mage,
]

# State Variables
var grid: Grid = null  # Reference to the game grid
var setup_tiles: Array[Vector2i] = []  # Valid deployment positions
var placed_units: Array[Node2D] = []  # Deployed units
var deployment: Dictionary = {}  # Deployment zone data
var deployable_units_ui: Control = null  # UI node for deployable units
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
	
	deployable_units_ui = deployment_ui.get_node('DeployableUnits')
	placed_units.clear()
	setup_tiles.clear()

	# Convert deployment zone coordinates to Vector2i
	for coords in deployment["player"]:
		setup_tiles.append(Vector2i(coords[0], coords[1]))

	# Highlight valid deployment tiles
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Create a button for deploying a unit
	for unit_scene in unit_scenes:
		_create_unit_button(unit_scene.instantiate())


func _create_unit_button(unit: Unit) -> void:
	# Create and configure a button for the given unit
	var button: Button = Button.new()
	button.text = unit.name
	button.flat = true
	button.pressed.connect(_on_unit_button_pressed.bind(unit, button))
	deployable_units_ui.add_child(button)

#-----------------
# Unit Selection
#-----------------
func _on_unit_button_pressed(unit: Unit, button: Button) -> void:
	deployment_ui.visible = false
	# Handle unit selection from the UI
	_current_button = button
	_current_unit = unit

	# Check if unit is already a child of the unit container
	unit_container.add_child(_current_unit)
	_current_unit.initialize(grid)
	_current_unit.modulate = Color(1, 1, 1, 0.5)  # Faded out for preview
	tooltip_panel.show_tooltip("Position " + unit.name, 0)

	# Connect to cursor "moved" signal
	cursor.moved.connect(handle_show_unit.bind(_current_unit))
	# Connect to cursor "cancel_pressed"
	cursor.cancel_pressed.connect(handle_return_unit.bind())


func handle_return_unit(tile: Vector2i) -> void:
	if _current_unit:
		# Unit is on cursor and has not been placed
		_current_unit = null
		cursor.moved.disconnect(handle_show_unit)
	else:
		var unit = grid.get_unit_at(tile)
		_create_unit_button(unit)
		grid.remove_unit(unit.tile)
		unit.queue_free()

	cursor.cancel_pressed.disconnect(handle_return_unit)
	tooltip_panel.hide_tooltip()
	deployment_ui.visible = true


# Show unit on the cursor
func handle_show_unit(_prev_tile: Vector2i, new_tile: Vector2i, unit: Node2D) -> void:
	# Check if the new tile is valid
	if setup_tiles.has(new_tile):
		# Update the unit's position to follow the cursor
		unit.position = grid.calculate_map_position(new_tile)
		unit.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent to indicate preview
	else:
		# Hide the unit if the cursor is outside setup tiles
		unit.modulate = Color(1, 1, 1, 0)  # Fully transparent


func _reselect_unit(unit: Node2D, tile: Vector2i) -> void:
	if _current_unit:
		return
	
	# Remove the unit from the grid
	grid.remove_unit(tile)
	placed_units.erase(unit)

	# Set the unit to preview mode
	unit.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
	_current_unit = unit

	# Highlight valid deployment tiles
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Connect the cursor's movement signal for preview
	cursor.moved.connect(handle_show_unit.bind(_current_unit))

	# Emit signal for unit deselection
	emit_signal("unit_deselected", unit)

	# Show a hint in the UI
	tooltip_panel.show_tooltip("Position " + unit.name)


#-----------------
# Unit Placement
#-----------------
func handle_tile_click(tile: Vector2i) -> void:
	# Check if a unit is already on the clicked tile
	var unit_on_tile: Node2D = grid.get_unit_at(tile)

	if unit_on_tile != null and not _current_unit:
		# Reselect the unit for repositioning
		_reselect_unit(unit_on_tile, tile)
		return
	
	# Validate placement conditions
	if not _can_place_unit(tile):
		return

	# Place the unit on the grid
	_place_unit(tile)

	# Hide the tooltip panel
	tooltip_panel.hide_tooltip()

	# Disconnect cursor signal
	cursor.moved.disconnect(handle_show_unit)

	# Check if deployment is complete
	if placed_units.size() == max_units:
		# Emit signal for setup completion
		emit_signal("placement_complete")
		deployment_ui.visible = false
		grid_overlay.clear()
		finish_setup()
	else:
		# Show UI for next unit
		deployment_ui.visible = true

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
	_current_unit.modulate = Color(1, 1, 1, 1)
	_current_unit.position = grid.calculate_map_position(tile)

	# Update the grid with the new unit
	grid.place_unit(_current_unit, tile)
	placed_units.append(_current_unit)

	# Update UI and state
	emit_signal("unit_placed", _current_unit)
	_current_unit = null
	if _current_button:
		_current_button.queue_free()
		_current_button = null


#-----------------
# Cleanup
#-----------------
func finish_setup() -> void:
	# Reset deployment state
	placed_units.clear()
	setup_tiles.clear()
	grid_overlay.clear()

	deployment_ui.visible = false

	# Emit signal to indicate setup completion
	emit_signal("setup_finished")


func cancel_setup() -> void:
	# Reset deployment state (to be implemented)
	pass
