extends Control

func open() -> void: ##This function is used to open the inventory scene and pause the game.
	visible = true
	get_tree().paused = true

func close() -> void: ##This function is used to close the inventory scene and unpause the game.
	visible = false
	get_tree().paused = false
