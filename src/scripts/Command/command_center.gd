extends Node
class_name CommandCenster

var history: Array[Command] = []
var undo_stack: Array[Command] = []

func execute_command(command: Command):
	command.execute()
	history.append(command)
	undo_stack.clear()


func undo():
	if history.size() > 0:
		var command = history.pop_back()
		command.undo()
		undo_stack.append(command)


func redo():
	if undo_stack.size() > 0:
		var command = undo_stack.pop_back()
		command.execute()
		history.append(command)
