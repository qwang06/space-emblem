extends Node

#-----------------
# Signals
#-----------------
signal unit_deployed(unit: Unit)  # Emitted when a unit is placed
signal unit_returned(unit: Unit)  # Emitted when a unit is returned to the pool
signal unit_reselected(unit: Unit)  # Emitted when a unit is reselected
signal placement_complete()  # Emitted when all units are deployed
signal setup_finished()  # Emitted when setup is canceled

#-----------------
# Constants
#-----------------
const DEPLOY_UNIT_MESSAGE = "Left-click to place [%s]"
const RETURN_UNIT_MESSAGE = "Right-click to return [%s]"

#-----------------
# Exported Variables
#-----------------
@export var max_units: int = 2  # Max deployable units
@export var deployment_ui: Control  # UI for unit selection
@export var tooltip_panel: Control  # Tooltip panel for hints
@export var unit_container: Node  # Parent node for deployed units
@export var cursor: Node2D  # Reference to the cursor node

#-----------------
# Preloaded Resources
#-----------------
var blue_mage: PackedScene = preload("res://src/scenes/Unit/Characters/blue_mage.tscn")
var red_mage: PackedScene = preload("res://src/scenes/Unit/Characters/red_mage.tscn")

var unit_scenes: Array[PackedScene] = [
	blue_mage,
	red_mage,
]

#-----------------
# State Variables
#-----------------
var grid: Grid = null  # Reference to the game grid
var setup_tiles: Array[Vector2i] = []  # Valid deployment positions
var deployed_units: Array[Node2D] = []  # Deployed units
var deployment: Dictionary = {}  # Deployment zone data
var deployable_units_ui: Control = null  # UI node for deployable units
var grid_overlay: Node = null  # Visual overlay for deployment zones
var _current_button: Button = null  # Selected UI button
var _current_unit: Node2D = null  # Selected unit for placement

#-----------------
# Initialization
# 
# Inject dependencies into the deployment controller.
# 	:param g: The game grid reference.
# 	:param go: The grid overlay for visual feedback.
# 	:param d: Deployment zone data.
#-----------------
func init(g: Grid, go: Node, d: Dictionary) -> void:
	# Inject dependencies
	self.grid = g
	self.grid_overlay = go
	self.deployment = d

#-----------------
# Deployment Setup
#
# Begin the deployment phase by preparing the UI and highlighting valid tiles.
#-----------------
func begin_setup() -> void:
	# Ensure player deployment zones exist
	if not deployment.has("player") or deployment["player"].is_empty():
		return
	
	deployable_units_ui = deployment_ui.get_node('DeployableUnits')
	deployed_units.clear()
	setup_tiles.clear()

	# Convert deployment zone coordinates to Vector2i
	for coords in deployment["player"]:
		setup_tiles.append(Vector2i(coords[0], coords[1]))

	# Highlight valid deployment tiles
	grid_overlay.set_highlighted_tiles(setup_tiles)

	# Connect to cursor "cancel_pressed"
	cursor.cancel_pressed.connect(handle_return_unit.bind())
	cursor.moved.connect(handle_cursor_moved.bind())
	unit_returned.connect(_on_unit_returned.bind())
	unit_deployed.connect(_on_unit_deployed.bind())
	unit_reselected.connect(_on_unit_reselected.bind())

	# Create a button for deploying a unit
	for unit_scene in unit_scenes:
		var unit = unit_scene.instantiate()
		unit_container.add_child(unit)
		unit.initialize(grid)
		_create_unit_button(unit)


# Create and configure a button for the given unit.
# 	:param unit: The unit for which the button is created.
func _create_unit_button(unit: Unit) -> void:
	# Create and configure a button for the given unit
	var button: Button = Button.new()
	button.text = unit.name
	button.flat = true
	button.pressed.connect(_on_unit_button_pressed.bind(unit, button))
	deployable_units_ui.add_child(button)

#-----------------
# Unit Selection
# 
# Event handler for when a unit button is pressed.
# 	:param unit: The unit selected by the player.
# 	:param button: The button associated with the selected unit.
#-----------------
func _on_unit_button_pressed(unit, button: Button) -> void:
	deployment_ui.visible = false
	# Handle unit selection from the UI
	_current_button = button
	_current_unit = unit

	# Check if unit is already a child of the unit container
	_current_unit.modulate = Color(1, 1, 1, 0.5)  # Faded out for preview
	tooltip_panel.show_tooltip(DEPLOY_UNIT_MESSAGE % unit.name, 0)

# Event handler for when the return action is triggered.
# 	:param tile: The tile where the return action is triggered.
func handle_return_unit(tile: Vector2i) -> void:
	if _current_unit:
		# Unit is on cursor and has not been placed
		_current_unit.set_position_zero()
		_current_unit = null
	else:
		# Check if a unit is on the clicked tile
		var unit = grid.get_unit_at(tile)
		if unit == null:
			return

		var command = ReturnUnitCommand.new(unit, tile, self)
		CommandCenter.run(command)

	tooltip_panel.hide_tooltip()
	deployment_ui.visible = true


func _on_unit_returned(unit: Unit) -> void:
	_create_unit_button(unit)


func _on_unit_deployed(unit: Unit) -> void:
	# Reset current unit and button
	_current_unit = null

	# Find the button associated with the deployed unit and remove it
	for child in deployable_units_ui.get_children():
		if child is Button and child.text == unit.name:
			child.queue_free()
			break

	# Check if deployment is complete
	if deployed_units.size() == max_units:
		# Emit signal for setup completion
		placement_complete.emit()
		deployment_ui.visible = false
		grid_overlay.clear()
		finish_setup()
	else:
		# Show UI for next unit
		deployment_ui.visible = true


func _on_unit_reselected(unit: Unit) -> void:
	# Show a hint in the UI
	tooltip_panel.show_tooltip(DEPLOY_UNIT_MESSAGE % unit.name)


# Show the unit on the cursor for preview.
# 	:param new_tile: The tile where the cursor is currently located.
# 	:param unit: The unit being previewed.
func _preview_unit(new_tile: Vector2i, unit: Node2D) -> void:
	# Check if the new tile is valid
	if setup_tiles.has(new_tile):
		# Update the unit's position to follow the cursor
		unit.set_tile_at(new_tile)
		unit.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent to indicate preview
	else:
		# Hide the unit if the cursor is outside setup tiles
		unit.modulate = Color(1, 1, 1, 0)  # Fully transparent


# Update the unit's position based on cursor movement.
# 	:param _prev_tile: The previous tile the cursor was on.
# 	:param new_tile: The new tile the cursor has moved to.
func handle_cursor_moved(_prev_tile: Vector2i, new_tile: Vector2i) -> void:
	# Update the unit's position based on cursor movement
	if _current_unit:
		_preview_unit(new_tile, _current_unit)
	else:
		# Hover feedback for placed units
		var unit = grid.get_unit_at(new_tile)
		if unit and deployed_units.has(unit):
			# Show tooltip to show you can return the unit
			tooltip_panel.show_tooltip(RETURN_UNIT_MESSAGE % unit.name, 0)
		else:
			if tooltip_panel.is_visible():
				tooltip_panel.hide_tooltip()


#-----------------
# Unit Placement
# 
# Handle tile selection for placing or repositioning a unit.
# 	:param tile: The tile where the click occurred.
#-----------------
func handle_tile_click(tile: Vector2i) -> void:
	# Check if a unit is already on the clicked tile
	var unit_on_tile: Node2D = grid.get_unit_at(tile)

	if unit_on_tile != null and not _current_unit:
		# Reselect the unit for repositioning
		CommandCenter.run(ReselectUnitCommand.new(unit_on_tile, tile, self))
		return
	
	# Validate placement conditions
	if not _can_place_unit(tile):
		return

	# Cursor should be on top of the unit so it can be returned
	tooltip_panel.show_tooltip(RETURN_UNIT_MESSAGE % _current_unit.name, 0)
	CommandCenter.run(DeployUnitCommand.new(_current_unit, tile, self))


# Check if a unit can be placed on the given tile.
# 	:param tile: The tile to validate.
# 	:return: True if the unit can be placed, False otherwise.
func _can_place_unit(tile: Vector2i) -> bool:
	# Ensure the tile is valid for placement
	return (
		setup_tiles.has(tile) and
		_current_unit != null and
		unit_container != null and
		deployed_units.size() < max_units and
		grid.get_unit_at(tile) == null
	)


# Deploy the selected unit on the grid.
# :param tile: The tile where the unit will be placed.
func deploy_unit(tile: Vector2i, unit: Unit) -> void:
	# Place the selected unit on the grid
	unit.modulate = Color(1, 1, 1, 1)
	unit.set_tile_at(tile)

	# Update the grid with the new unit
	grid.place_unit(unit, tile)

	# Remove highlight from the grid
	grid_overlay.clear_highlighted_tiles([tile] as Array[Vector2i])
	deployed_units.append(unit)

	# Update UI and state
	unit_deployed.emit(unit)


# Return a unit to the pool.
# 	:param tile: The tile where the unit is located.
# 	:param unit: The unit to be returned.
func return_unit(tile: Vector2i, unit: Node2D) -> void:
	unit.modulate = Color(1, 1, 1, 0)  # Fully transparent
	unit.set_position_zero()
	_remove_deployed_unit(tile, unit)

	unit_returned.emit(unit)


# Reselect a unit for repositioning
func reselect_unit(tile: Vector2i, unit: Node2D) -> void:
	if _current_unit:
		# Cursor already has a unit
		return

	_current_unit = unit
	unit.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
	_remove_deployed_unit(tile, unit)

	# Highlight valid deployment tiles
	# grid_overlay.set_highlighted_tiles(setup_tiles)
	unit_reselected.emit(unit)


func _remove_deployed_unit(tile: Vector2i, unit: Unit) -> void:
	# Remove the unit from the grid
	grid.remove_unit(tile)

	# Add highlight back to the grid
	grid_overlay.add_highlighted_tiles([tile] as Array[Vector2i])

	# Remove from deployed_units
	if deployed_units.has(unit):
		deployed_units.erase(unit)


#-----------------
# Cleanup
#
# Finalize the deployment phase and reset the state.
#-----------------
func finish_setup() -> void:
	# Reset deployment state
	deployed_units.clear()
	setup_tiles.clear()
	grid_overlay.clear()

	deployment_ui.visible = false

	# Emit signal to indicate setup completion
	setup_finished.emit()


func cancel_setup() -> void:
	# Reset deployment state (to be implemented)
	pass
