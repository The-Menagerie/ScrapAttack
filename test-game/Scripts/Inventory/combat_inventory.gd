extends Control

signal opened
signal closed

var isOpen: bool = false

func _ready() -> void:
	close()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		if isOpen:
			close()
		else:
			open()

func open():
	visible = true
	isOpen = true
	get_tree().paused = true
	opened.emit()

func close():
	visible = false
	isOpen = false
	get_tree().paused = false
	closed.emit()
