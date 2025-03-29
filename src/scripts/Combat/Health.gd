# Health component for units
# This component manages the health of a unit, including taking damage and healing.
# It is designed to be used with any unit that has health, such as characters or enemies.
class_name Health
extends Node

signal damage_taken(damage: int)
signal healed(heal: int)
signal died()
signal revived()
signal health_changed(current_health: int, max_health: int)

@export var max_health: int = 100
@export var current_health: int = max_health

var utils = Utils.new()
var _is_dead: bool = false

func set_health(health: int) -> void:
	current_health = health
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0 and not _is_dead:
		_is_dead = true
		emit_signal("died")
	elif current_health > 0 and _is_dead:
		_is_dead = false
		emit_signal("revived")

func take_damage(damage: int) -> void:
	if _is_dead:
		return

	current_health -= damage
	emit_signal("damage_taken", damage)
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		_is_dead = true
		emit_signal("died")

func heal(heal_amount: int) -> void:
	if _is_dead:
		return

	current_health += heal_amount
	if current_health > max_health:
		current_health = max_health

	emit_signal("healed", heal_amount)
	emit_signal("health_changed", current_health, max_health)

func revive(health: int) -> void:
	if not _is_dead or health <= 0:
		return

	_is_dead = false
	if health >= max_health:
		current_health = max_health
	else:
		current_health = health
	emit_signal("revived")
	emit_signal("health_changed", current_health, max_health)

func is_dead() -> bool:
	return _is_dead