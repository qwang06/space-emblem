# This is a camera that follows moves the camera around the screen based on WASD input

extends Camera2D

@export var grid := preload("res://Grid.tres")
@export var lerp_smoothing := 20
@export var camera_speed := 25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	limit_bottom = int(grid.size.y * grid.tile_size.y)
	limit_right = int(grid.size.x * grid.tile_size.x)

func _process(delta: float) -> void:
	var direction = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	
	# the camera's position is actually the top left corner of the screen
	# so we need to add the screen size to the position to get the bounds
	if not direction == Vector2.ZERO:
		var target_position = global_position + direction * camera_speed
		var viewport_size = get_viewport().get_visible_rect().size

		# clamp to screen size
		if target_position.x < 0:
			target_position.x = 0
		if target_position.y < 0:
			target_position.y = 0
		if target_position.x > limit_right:
			target_position.x = limit_right
		if target_position.y > limit_bottom:
			target_position.y = limit_bottom
		# get the right edge of the camera
		var right_edge = target_position.x + viewport_size.x;
		# get the bottom edge of the camera
		var bottom_edge = target_position.y + viewport_size.y;

		# if the right edge is greater than the right limit, set out of bounds
		if right_edge > limit_right:
			target_position.x = limit_right - viewport_size.x
		# if the bottom edge is greater than the bottom limit, set out of bounds
		if bottom_edge > limit_bottom:
			target_position.y = limit_bottom - viewport_size.y

		# make sure the camera is within the grid
		if target_position.x >= 0 and target_position.y >= 0 and target_position.x <= limit_right and target_position.y <= limit_bottom:
			# if global_position is less than 1px, snap to 0
			if global_position.distance_to(target_position) < 1:
				global_position = target_position
			else:
				global_position = global_position.lerp(target_position, 1.0 - exp(-delta * lerp_smoothing))
		else:
			print("out of bounds")

# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_pressed():
# 		var direction = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
# 		var screen_size = get_viewport().get_visible_rect().size
# 		var grid_size = grid.size * grid.tile_size
# 		var new_position = position + direction * SPEED
# 		if new_position.x >= 0 and new_position.y >= 0 and new_position.x <= limit_right and new_position.y <= limit_bottom:
# 			position = new_position
# 			print(position, screen_size, grid_size)
# 		else:
# 			print("out of bounds")
	