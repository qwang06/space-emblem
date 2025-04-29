# return_unit_command.gd
class_name ReturnUnitCommand
extends Command

var unit
var tile
var deployment_controller

func _init(_unit, _tile, _deployment_controller):
	unit = _unit
	tile = _tile
	deployment_controller = _deployment_controller

func execute():
	deployment_controller.return_unit(tile, unit)

func undo():
	if unit.position == Vector2.ZERO:
		deployment_controller.deploy_unit(tile, unit)
