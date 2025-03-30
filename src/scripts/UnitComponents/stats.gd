extends Node

@export var max_health := 10
@export var max_mana := 5
@export var attack := 3
@export var defense := 1

var current_health := max_health
var current_mana := max_mana
var is_dead := false

func apply_damage(damage: int) -> void:
    current_health -= damage

    if current_health <= 0:
        current_health = 0
        is_dead = true


func apply_healing(healing: int) -> void:
    current_health += healing
    current_health = clamp(current_health, 0, max_health)


func apply_mana(mana: int) -> void:
    current_mana += mana
    current_mana = clamp(current_mana, 0, max_mana)


func get_health_string() -> String:
    return str(current_health) + "/" + str(max_health)


func get_mana_string() -> String:
    return str(current_mana) + "/" + str(max_mana)


func is_alive() -> bool:
    return not is_dead
    