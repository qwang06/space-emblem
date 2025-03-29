# Godot 4.3
# Coding guidelines:
# - Use snake_case for variables and functions.
# - Use PascalCase for classes.
# - Use snake_case for signals.
# - Do not use deprecated functions.
# - Use tab characters for indentation with tab size 2.
@tool
class_name Unit
extends Path2D

signal walk_finished

@export var grid := preload("res://Grid.tres")
@export var move_range := 4
@export var move_speed := 600.0
@export var skin: Texture:
  set = set_skin
@export var skin_offset := Vector2.ZERO:
  set = set_skin_offset

# unit's tile
var tile := Vector2.ZERO:
  set = set_tile
# selected status
var _selected := false:
  set = set_selected
# is unit walking
var _walking := false:
  set = set_walking

@onready var _sprite := $PathFollow2D/AnimatedSprite2D
@onready var _path_follow := $PathFollow2D
@onready var _portrait := $Portrait
@onready var _health := $Health

func _ready() -> void:
  set_process(false)
  # play idle animation
  _sprite.play("idle_front")

  tile = grid.calculate_grid_coordinates(position)
  position = grid.calculate_map_position(tile)

  if not Engine.is_editor_hint():
    curve = Curve2D.new()

func _process(delta: float) -> void:
  _path_follow.progress += move_speed * delta

  update_animation()

  if _path_follow.progress_ratio >= 1.0:
    _walking = false
    _path_follow.progress = 0.0
    position = grid.calculate_map_position(tile)
    curve.clear_points()
  emit_signal("walk_finished")

# Get the unit's portrait
func get_portrait() -> Texture:
  return _portrait.texture

# clamp unit's position to the grid
func set_tile(value: Vector2) -> void:
  tile = grid.clamp(value)

func set_selected(value: bool) -> void:
  _selected = value
  if _selected:
    # make the unit's sprite brighter
    _sprite.modulate = Color(1.5, 1.5, 1.5)
  else:
    _sprite.modulate = Color(1, 1, 1)

# set the unit's skin
func set_skin(texture: Texture) -> void:
  skin = texture
  if not _sprite:
    await self.is_ready
  _sprite.texture = texture

func set_skin_offset(value: Vector2) -> void:
  skin_offset = value
  if not _sprite:
    await self.is_ready
  _sprite.position = value

func set_walking(value: bool) -> void:
  _walking = value
  set_process(_walking)

func walk_along(path: Array) -> void:
  if path.is_empty():
    return

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
    new_position = grid.calculate_map_position(path[i]) - position

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
      emit_signal("walk_finished")

func update_animation() -> void:
  if (!_walking):
    return
  
  # Calculate movement direction between points
  var movement_direction = Vector2.ZERO
  
  # Get current and target positions on the curve based on progress
  if curve.get_point_count() > 1:
    # Find which segment we're currently on
    var progress_ratio = _path_follow.progress_ratio
    var point_count = curve.get_point_count()
    
    # Calculate which segment we're on (0 to point_count-2)
    var segment_length = 1.0 / (point_count - 1)
    var current_segment = floor(progress_ratio / segment_length)
    current_segment = min(current_segment, point_count - 2)
    
    # Get direction from current segment to next point
    var current_point = curve.get_point_position(current_segment)
    var next_point = curve.get_point_position(current_segment + 1)
    movement_direction = (next_point - current_point).normalized()
  
    # Determine which of the 4 directions is dominant
    if abs(movement_direction.x) > abs(movement_direction.y):
      # Horizontal movement is dominant
      if movement_direction.x > 0:
        _sprite.play("walk_right")
      else:
        _sprite.play("walk_left")
    else:
      # Vertical movement is dominant
      if movement_direction.y > 0:
        _sprite.play("walk_front")
      else:
        _sprite.play("walk_back")

  # if progress is complete, play the correct idle animation based on the last direction
  if _path_follow.progress_ratio >= 1.0:
    if _sprite.animation == "walk_right":
      _sprite.play("idle_right")
    elif _sprite.animation == "walk_left":
      _sprite.play("idle_left")
    elif _sprite.animation == "walk_front":
      _sprite.play("idle_front")
    elif _sprite.animation == "walk_back":
      _sprite.play("idle_back")

# Return string representation of the health status
func get_health_string() -> String:
  return str(_health.current_health) + " / " + str(_health.max_health)
