extends Node

signal turn_complete(unit)

var has_moved := false
var has_acted := false

func reset():
    has_moved = false
    has_acted = false

func end_turn():
    has_moved = true
    has_acted = true
    turn_complete.emit(get_parent())
