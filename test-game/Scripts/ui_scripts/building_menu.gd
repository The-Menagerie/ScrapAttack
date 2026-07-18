extends Control

@export var scroll_container: Node
@export var animation_player: Node

func _ready() -> void:
	BuildEnv.start_buildin.connect(_start_building)
	BuildEnv.stop_buildin.connect(_stop_building)
	

func _start_building(building: Dictionary) -> void:
	scroll_container.mouse_filter = MOUSE_FILTER_IGNORE
	animation_player.play_section("Hide Menu")
	pass
	
func _stop_building() -> void:
	scroll_container.mouse_filter = MOUSE_FILTER_STOP
	animation_player.play_section("Reveal Menu")
	pass
	
