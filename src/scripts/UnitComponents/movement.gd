extends Node

signal walk_finished

@export var move_range := 4
@export var move_speed := 100.0

var grid: Grid = null
var current_path := []

var tile := Vector2i.ZERO:
	set = set_tile
var _walking := false:
	set = set_walking

var _parent
var _path_follow
var _visual_component

func _ready() -> void:
	set_process(false)

	_parent = get_parent()
	_path_follow = _parent.get_node("PathFollow2D")
	_visual_component = _parent.get_node("VisualComponent")

func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta

	if _walking:
		_visual_component.update_animation()

	if _path_follow.progress_ratio >= 1.0:
		_walking = false
		_path_follow.progress = 0.0
		_parent.set_tile_at(tile)
		_parent.curve.clear_points()
		walk_finished.emit()

# clamp unit's position to the grid
func set_tile(value: Vector2) -> void:
	tile = grid.clamp(value)

func set_walking(value: bool) -> void:
	_walking = value
	set_process(_walking)

func walk_along(path: Array) -> void:
	if path.is_empty():
		return

	var curve = _parent.curve

	# Clear existing curve points
	curve.clear_points()
	
	# Add the unit's current position as the starting point
	var new_position = Vector2.ZERO
	curve.add_point(new_position)
	
	# Skip the first point if it's the unit's current position
	var start_index = 0
	if path.size() > 0 and path[0] == tile:
		start_index = 1

	# Add the remaining points in the path
	for i in range(start_index, path.size()):
		new_position = grid.calculate_map_position(path[i]) - _parent.position

		if new_position != curve.get_point_position(curve.get_point_count() - 1):
			curve.add_point(new_position)

		# Set the destination tile to the last point in the path
		if path.size() > 0:
			tile = path[-1]
		
		# Only start walking if we have at least two points
		if curve.get_point_count() >= 2:
			_walking = true
		else:
			# If we only have one point, we're already there
			walk_finished.emit()

# Calculate all tiles the unit can walk to based on its movement range
func get_walkable_tiles() -> Array:
	return grid.flood_fill(tile, move_range)

# Move the selected unit to the target tile
func move_to(new_tile: Vector2i, path: Array) -> void:
	if grid.is_occuppied(new_tile):
		return

	# Update units dictionary with the unit's new position
	grid.units.erase(tile)
	grid.units[new_tile] = _parent
	
	# Make the unit walk along the calculated path
	walk_along(path)
	# Wait until the unit finishes walking
	await walk_finished
