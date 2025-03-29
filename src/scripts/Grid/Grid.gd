class_name Grid
extends Resource

# grid size
@export var size := Vector2(20, 15)
# tile size
@export var tile_size := Vector2(32, 32)

var half_tile_size = tile_size / 2

# returns the coords of a tile's center in pixels
func calculate_map_position(position: Vector2) -> Vector2:
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