class_name Grid
extends Resource

# The four cardinal directions used for pathfinding and movement
const DIRECTIONS = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
]

# grid size
@export var size := Vector2(20, 15)
# tile size
@export var tile_size := Vector2(32, 32)

# Dictionary tracking all units on the board using their tile coordinates as keys
var units = {}

# returns the coords of a tile's center in pixels
func calculate_map_position(position: Vector2) -> Vector2:
	var half_tile_size = tile_size / 2
	var new_position: Vector2
	new_position.x = position.x * tile_size.x + half_tile_size.x
	new_position.y = position.y * tile_size.y + tile_size.y
	return new_position


# returns coords of a tile in the grid given a position in pixels
func calculate_grid_coordinates(position: Vector2) -> Vector2:
	return (position / tile_size).floor()


# returns true if the given position is inside the grid
func is_within_bounds(position: Vector2) -> bool:
	return position.x >= 0 and position.x < size.x and position.y >= 0 and position.y < size.y


# clamp function for grid -- makes the position fit within the grid
func clamp(position: Vector2) -> Vector2:
	var out := position
	out.x = clamp(out.x, 0, size.x - 1)
	out.y = clamp(out.y, 0, size.y - 1)
	return out


# creates an index given a tile
func as_index(tile: Vector2) -> int:
	return int(tile.x) + int(size.x) * int(tile.y)


# Check if a tile position is occupied by any unit
# TODO: should check other things as well such as terrain
func is_occuppied(tile: Vector2) -> bool:
	return units.has(tile)


# Flood fill algorithm to find all accessible tiles within a given range
# Returns an array of Vector2 coordinates representing walkable tiles
func flood_fill(tile: Vector2, max_distance: int) -> Array:
	var visited = []  # Tiles we've already processed
	var queue = []    # Queue of tiles to process (with their distance from start)
	queue.push_back([tile, 0])  # Start with the initial tile at distance 0
	
	while queue:
		var current = queue.pop_front()
		var current_tile = current[0]
		var current_range = current[1]
	
		# Skip tiles outside the grid boundaries
		if current_tile.x < 0 or current_tile.y < 0 or current_tile.x >= size.x or current_tile.y >= size.y:
			continue
			
		# Skip if we've exceeded the maximum movement range
		if current_range > max_distance:
			continue
			
		# Skip already visited tiles
		if visited.has(current_tile):
			continue
			
		# Mark this tile as visited
		visited.push_back(current_tile)
	
		# Add all adjacent tiles to the queue
		for direction in DIRECTIONS:
			var neighbor = current_tile + direction
			if visited.has(neighbor):
				continue
			if is_occuppied(neighbor):
				continue
			queue.push_back([neighbor, current_range + 1])
		
	return visited