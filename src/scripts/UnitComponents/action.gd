extends Node

@export var actions := ["Attack", "Wait"]

# func perform_action(action: String, target := null) -> void:
#     match action:
#         "Attack":
#             _attack(target)
#         "Wait":
#             _wait()

func _attack(target):
    if target == null:
        return
    var stats = get_parent().get_node("StatsComponent")
    var target_stats = target.get_node("StatsComponent")
    target_stats.apply_damage(stats.attack)

func _wait():
    var turn = get_parent().get_node("TurnComponent")
    turn.end_turn()
