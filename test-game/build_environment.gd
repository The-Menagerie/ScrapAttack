extends Node

var enabled = true

func enter_build_environment() -> void:
	enabled = true
	
func exit_build_environment() -> void:
	enabled = false
