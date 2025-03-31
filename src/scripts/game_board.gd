# GameBoard class manages the game's tactical grid and all unit interactions
# It handles unit selection, movement, displaying movement ranges, and 
# coordinating the interface between user input and game state
class_name GameBoard
extends Node2D

# Reference to the grid resource containing tile size and grid dimensions
@export var grid := preload("res://Grid.tres")

# References to child nodes
@onready var _unit_path: UnitPath = $UnitPath
@onready var actions_menu = %ActionsMenu
@onready var tile_info = %TileInfo
@onready var dialog = %Dialog
@onready var terrain = %Terrain

# Currently selected unit
var _active_unit: Unit
# Array of tiles the active unit can walk to
var _walkable_tiles = []
var turn_manager

# Function to get the "type" custom data from a tile
func get_tile_type(position_to_check: Vector2) -> String:
	# Convert global position to map coordinates
	var map_position = terrain.local_to_map(terrain.to_local(position_to_check))
	
	# Get the tile data
	var tile_data = terrain.get_cell_tile_data(Vector2(map_position.x, map_position.y))
	
	# Return the custom data if it exists
	if tile_data:
		return tile_data.get_custom_data("type")
	
	return ""


# Example usage in _on_cursor_moved to get and display tile type
func get_tile_type_at(tile: Vector2) -> String:
	# Convert tile coordinates to global position
	var global_pos = tile * grid.tile_size + grid.tile_size / 2
	return get_tile_type(global_pos)

# ===================================================================
# Internal functions for the game board
# These functions are used to manage the game state and unit interactions
# ==================================================================

func _display_tile_info(tile: Vector2) -> void:
	var utils = Utils.new()
	# Get custom data from tileset to determine the terrain type
	# Check what is under the cursor to display tile info
	var unit = grid.units.get(tile)
	var terrain_type = get_tile_type_at(tile)
	# Find the labels in the descendant nodes
	var health_label = utils.find_descendant_by_name(tile_info, "Health")
	var mana_label = utils.find_descendant_by_name(tile_info, "Mana")
	var type_label = utils.find_descendant_by_name(tile_info, "Terrain")
	if unit:
		# Update the labels with the unit's health and mana
		health_label.text = unit.stats.get_health_string()
		mana_label.text = unit.stats.get_mana_string()
		# Show the labels
		health_label.show()
		mana_label.show()
		# Show tile_info
		tile_info.show()
	elif terrain_type != "":
		# Update the label with the terrain type
		type_label.text = terrain_type
		# Show the label
		type_label.show()
		# Show tile_info with the terrain type
		tile_info.show()
	else:
		# Hide the labels if no unit or terrain type is found
		health_label.hide()
		mana_label.hide()
		type_label.hide()
		# Hide tile_info if no unit is found
		tile_info.hide()


# Initialize the board when the scene is ready
func _ready() -> void:
	_reinitialize()

	# set up the turn manager
	turn_manager = get_node("../TurnManager")
	print(turn_manager)

	# set up an example dialog scenario with the dialog node and chapter 1
	# dialog.set_dialog_data_by_chapter("ch1")
	# dialog.start()


# Draw debugging visuals for walkable tiles
func _draw() -> void:
	for tile in _walkable_tiles:
		draw_rect(Rect2(tile * grid.tile_size, grid.tile_size), Color(0, 0, 0, 0.5))


# Populate the units dictionary by collecting all Unit nodes
func _reinitialize() -> void:
	grid.units.clear()
	for child in get_children():
		if child is not Unit:
			continue

		child.initialize(grid)
		grid.units[child.tile] = child


# Select a unit at the specified tile position
# Does nothing if no unit exists at that position
func _select_unit(tile: Vector2) -> void:
	if not grid.units.has(tile):
		return

	_active_unit = grid.units[tile]
	_active_unit.selected = true


# Calculate and display all walkable tiles for the active unit
# Used when player activates the "Move" action
func _show_walkable_tiles() -> void:
	_walkable_tiles = _active_unit.movement.get_walkable_tiles()
	_unit_path.initialize(_walkable_tiles)
	queue_redraw()


# Visually deselect the active unit and clear the movement path
func _deselect_active_unit() -> void:
	_active_unit.selected = false
	_unit_path.stop()


# Clear the active unit reference and related visual elements
func _clear_active_unit() -> void:
	if not _active_unit:
		return

	_active_unit = null
	queue_redraw()
	_walkable_tiles.clear()

# ===================================================================
# Input handling functions for the game board
# These functions respond to user input events and update the game state accordingly
# ==================================================================

# Handler for when the cursor confirms a selection (e.g., player presses Enter/Space)
# Handles both unit selection and movement commands
func _on_cursor_confirm_pressed(tile: Vector2) -> void:
	if not _active_unit:
		# If no unit is selected, try to select one at the cursor position
		_select_unit(tile)
	
		# If a unit was successfully selected, show the actions menu
		if _active_unit:
			actions_menu.show()
	elif _active_unit.selected and tile in _walkable_tiles:
		_deselect_active_unit()
		# If a unit is already selected, try to move it to the cursor position
		await _active_unit.movement.move_to(tile, _unit_path.current_path)
		_clear_active_unit()


# Handler for when the cursor cancels an action (e.g., player presses Escape)
func _on_cursor_cancel_pressed() -> void:
	if actions_menu.is_visible():
		actions_menu.hide()
	if _active_unit:
		_deselect_active_unit()
		_clear_active_unit()


# Handler for when the cursor moves to a new tile
# Updates the visual path from the active unit to the cursor's position
func _on_cursor_moved(tile: Vector2) -> void:
	if _active_unit and _active_unit.selected:
		_unit_path.draw(_active_unit.tile, tile)
	else:
		_display_tile_info(tile)


# Handler for when the "Move" action is selected from the actions menu
func _on_move_pressed() -> void:
	if not _active_unit:
		return

	_show_walkable_tiles()
	# Hide the actions menu after selecting the move action
	actions_menu.hide()
