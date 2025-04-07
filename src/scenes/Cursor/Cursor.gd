@tool
class_name Cursor
extends Node2D

signal confirm_pressed(tile)
signal moved(tile)
signal cancel_pressed

@export var grid := preload("res://Grid.tres")
@export var ui_cooldown := 0.1 # prevent spam
var tile := Vector2.ZERO:
	set = set_tile

@onready var _timer := $Timer
@onready var camera = %Camera2D

func _ready() -> void:
	_timer.wait_time = ui_cooldown
	position = grid.calculate_map_position(tile)

# on input event
func _unhandled_input(event: InputEvent) -> void:
	var isMouseClick := bool(event is InputEventMouseButton and event.pressed)
	if event is InputEventMouseMotion:
		# move cursor based on mouse position
		tile = grid.calculate_grid_coordinates(get_global_mouse_position() / camera.zoom)
	elif (
		(isMouseClick and event.button_index == MOUSE_BUTTON_LEFT)
	 	or event.is_action_pressed("confirm")
	):
		# left click or confirm action (e.g. space key)
		confirm_pressed.emit(tile)
		# stop propagation
		get_viewport().set_input_as_handled()
		return
	elif (
		(isMouseClick and event.button_index == MOUSE_BUTTON_RIGHT)
	 	or event.is_action_pressed("cancel")
	):
		# right click or cancel action (e.g. escape key)
		cancel_pressed.emit()
		print("cancel pressed")
		# stop propagation
		get_viewport().set_input_as_handled()
		return

	var should_move := event.is_pressed()
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()

	if not should_move:
		return

	if event.is_action("move_up"):
		tile += Vector2.UP
	elif event.is_action("move_down"):
		tile += Vector2.DOWN
	elif event.is_action("move_left"):
		tile += Vector2.LEFT
	elif event.is_action("move_right"):
		tile += Vector2.RIGHT

# func _draw() -> void:
# 	draw_rect(Rect2(-grid.tile_size / 2, grid.tile_size), Color.ALICE_BLUE, false, 2.0)

func set_tile(value: Vector2) -> void:
	var new_tile = grid.clamp(value)
	if new_tile.is_equal_approx(tile):
		return

	tile = new_tile
	position = grid.calculate_map_position(tile)
	moved.emit(tile)
	_timer.start()
