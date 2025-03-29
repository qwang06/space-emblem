# Find the path between two points among walkable tiles using A* algorithm
class_name PathFinder
extends RefCounted

const DIRECTIONS = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
]

var _grid: Resource
# variable that will do the pathfinding
var _astar := AStar2D.new()

func _init(grid: Grid, walkable_cells: Array) -> void:
	_grid = grid
	# To create the A* graph, we need the index value of each
	# walkable cell. 
	var cell_mappings := {}
	for cell in walkable_cells:
		cell_mappings[cell] = _grid.as_index(cell)

	# Create the A* graph
	_add_and_connect_points(cell_mappings)

# Add and connect points to the A* graph
func _add_and_connect_points(cell_mappings: Dictionary) -> void:
	# Register each walkable cell as a point in the A* graph
	for point in cell_mappings:
		_astar.add_point(cell_mappings[point], point)

	# Connect each point to its neighbors
	for point in cell_mappings:
		for neighbor_index in _find_neighbor_indices(point, cell_mappings):
			_astar.connect_points(cell_mappings[point], neighbor_index)

# Returns an array of the cell's connectable neighbors
func _find_neighbor_indices(point: Vector2, cell_mappings: Dictionary) -> Array:
	var neighbors := []
	# Check each direction for a neighbor that is a walkable
	# and not already connected
	for direction in DIRECTIONS:
		var neighbor: Vector2 = point + direction
		if not cell_mappings.has(neighbor):
			continue

		if not _astar.are_points_connected(cell_mappings[point], cell_mappings[neighbor]):
			neighbors.push_back(cell_mappings[neighbor])

	return neighbors

func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var start_index = _grid.as_index(start)
	var end_index = _grid.as_index(end)

	if _astar.has_point(start_index) and _astar.has_point(end_index):
		return _astar.get_point_path(start_index, end_index)
	else:
		return PackedVector2Array()
