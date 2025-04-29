# command_manager.gd
extends Node

var command_stack := []
var undo_stack := []

# on input event
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		undo()
	elif event.is_action_pressed("redo"):
		redo()


func run(command: Command):
	command.execute()
	command_stack.append(command)
	undo_stack.clear()  # Redo becomes invalid

func undo():
	print("undo", command_stack)
	if command_stack.size() > 0:
		var command: Command = command_stack.pop_back()
		command.undo()
		print("undo", command.unit, command.tile, command.unit.name)
		undo_stack.append(command)

func redo():
	print("Redo", undo_stack)
	if undo_stack.size() > 0:
		var command: Command = undo_stack.pop_back()
		command.execute()
		command_stack.append(command)
