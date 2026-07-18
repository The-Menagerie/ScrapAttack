extends Node

var enabled = true

signal start_buildin(build_dict)
signal stop_buildin

signal valid_blueprint
signal remove_blueprint

signal build_done

func enter_build_environment() -> void:
	enabled = true
	
func exit_build_environment() -> void:
	enabled = false
	
func build_bus(building) -> void:
	start_buildin.emit(building)
	
