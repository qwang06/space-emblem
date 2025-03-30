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

@onready var _sprite := $PathFollow2D/AnimatedSprite2D
@onready var _portrait := $Portrait

# Components
@onready var action := $ActionComponent
@onready var movement := $MovementComponent
@onready var stats := $StatsComponent
@onready var turn := $TurnComponent
@onready var visual := $VisualComponent

# selected status
var selected := false:
	set = set_selected
var tile: Vector2:
	get = get_tile, set = set_tile

func _ready() -> void:
	set_process(false)
	# play idle animation
	_sprite.play("idle_front")

	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func initialize(grid_ref: Grid) -> void:
	movement.grid = grid_ref
	tile = grid_ref.calculate_grid_coordinates(position)
	position = grid_ref.calculate_map_position(tile)


# Get the unit's portrait
func get_portrait() -> Texture:
	return _portrait.texture


func get_tile() -> Vector2:
	return movement.tile


func set_tile(value: Vector2) -> void:
	movement.tile = value


func set_selected(value: bool) -> void:
	selected = value
	if selected:
		visual.highlight()
	else:
		visual.clear_highlight()
