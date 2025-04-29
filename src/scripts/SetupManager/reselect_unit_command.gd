# reselect_unit_command.gd
class_name ReselectUnitCommand
extends Command

var unit
var tile
var deployment_controller

var previous_tile

func _init(_unit, _tile, _deployment_controller):
	unit = _unit
	tile = _tile
	deployment_controller = _deployment_controller

func execute():
	# Cache previous state (for undo)
	previous_tile = unit.tile
	deployment_controller.reselect_unit(tile, unit)

func undo():
	# Units that are not deployed have position set to zero
	if unit.position != Vector2.ZERO:
		deployment_controller.deploy_unit(tile, unit)
