extends Node

signal phase_started(phase: Phase)
signal phase_ended(phase: Phase)

enum Phase {
	SETUP,
	PLAYER,
	ALLY,
	ENEMY,
	END
}

@export var auto_advance := true

var current_phase: Phase = Phase.SETUP
var phase_order: Array[Phase] = [
	Phase.SETUP,
	Phase.PLAYER,
	Phase.ALLY,
	Phase.ENEMY,
	Phase.END
]

var active_units: Array[Node] = []

func _ready():
	start_phase(Phase.SETUP)


func start_phase(phase: Phase) -> void:
	current_phase = phase
	print("Starting phase:", phase_to_string(phase))
	emit_signal("phase_started", phase)

	match phase:
		Phase.SETUP:
			_on_setup_phase()
		Phase.PLAYER:
			_begin_team_turn("Player")
		Phase.ALLY:
			_begin_team_turn("Ally")
		Phase.ENEMY:
			_begin_team_turn("Enemy")
		Phase.END:
			_on_end_phase()


func end_phase() -> void:
	emit_signal("phase_ended", current_phase)

	if auto_advance:
		advance()


func advance() -> void:
		var next = _get_next_phase(current_phase)
		start_phase(next)


func _on_setup_phase():
	# var tiles := grid.get_deployment_tiles("Player")  # You define this per map
	# setup_manager.begin_setup(tiles)
	pass
	# setup_manager.connect("placement_complete", Callable(self, "_on_setup_finished"))


func _on_end_phase():
	# Show summary, transition to next map, etc.
	print("Turn cycle complete.")
	# Optionally loop:
	start_phase(Phase.PLAYER)


func _begin_team_turn(faction_name: String):
	active_units = _get_units_by_faction(faction_name)

	for unit in active_units:
		var turn = unit.get_node_or_null("TurnComponent")
		if turn:
			turn.reset()

	if active_units.is_empty():
		end_phase()


func notify_unit_done(unit: Node) -> void:
	active_units.erase(unit)
	if active_units.is_empty():
		end_phase()


func _get_units_by_faction(faction: String) -> Array[Node]:
	var result := []
	for unit in get_tree().get_nodes_in_group("Units"):
		var comp = unit.get_node_or_null("FactionComponent")
		if comp and comp.get_faction_name() == faction:
			result.append(unit)
	return result


func _get_next_phase(current: Phase) -> Phase:
	var index := phase_order.find(current)
	return phase_order[(index + 1) % phase_order.size()]


func phase_to_string(phase: Phase) -> String:
	match phase:
		Phase.SETUP:
			return "Setup"
		Phase.PLAYER:
			return "Player Phase"
		Phase.ALLY:
			return "Ally Phase"
		Phase.ENEMY:
			return "Enemy Phase"
		Phase.END:
			return "End Phase"
		_:
			return "Unknown"
