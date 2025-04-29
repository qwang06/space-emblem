# deploy_unit_command.gd
class_name DeployUnitCommand
extends Command

var unit
var tile
var deployment_controller

func _init(_unit, _tile, _deployment_controller):
	unit = _unit
	tile = _tile
	deployment_controller = _deployment_controller

func execute():
	print("execute deployment of unit: ", unit.name, unit.position)
	# Cache previous state (for undo)
	deployment_controller.deploy_unit(tile, unit)

func undo():
	print("Undoing deployment of unit: ", unit.name)
  # Units that are not deployed have position set to zero
	if unit.position != Vector2.ZERO:
		deployment_controller.return_unit(tile, unit)
