extends Node2D

var SceneManager: Node


func _ready() -> void:
	SceneManager = get_tree().current_scene
	

func interaction(player: Node) -> void:
	if SceneManager != null:
		BuildEnv.exit_build_environment()
		SceneManager.replace_scene_with_loaded()
	
