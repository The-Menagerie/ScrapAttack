extends Node2D

@export var leave_path = "res://Scenes/procedural_room_generation/overgrowth_generation.tscn"
var SceneManager: Node
var sent_scene = false

func _ready() -> void:
	
	SceneManager = get_tree().current_scene

func player_nears(body) -> void:
	if body is CharacterBody2D:
		print("player wants to go to "+leave_path)
		if not sent_scene:
			SceneManager.preload_main_scene(leave_path)
			sent_scene = true
	
