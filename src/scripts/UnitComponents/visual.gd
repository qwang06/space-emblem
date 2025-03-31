extends Node

var _parent
var _path_follow
var _sprite

func _ready() -> void:
	_parent = get_parent()
	_path_follow = get_parent().get_node("PathFollow2D")
	_sprite = get_parent().get_node("PathFollow2D/AnimatedSprite2D")

func highlight():
	# make the unit's sprite brighter
	_sprite.modulate = Color(1.5, 1.5, 1.5)

func clear_highlight():
	_sprite.modulate = Color(1, 1, 1)

func update_animation() -> void:	
	# Calculate movement direction between points
	var movement_direction = Vector2.ZERO
	var curve = _parent.curve

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