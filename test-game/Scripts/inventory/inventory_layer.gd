extends CanvasLayer

signal combat_inventory_open
signal comabt_inventory_close
signal town_inventory_open
signal town_inventory_close

var isOpen: bool = false

func _ready() -> void:
	comabt_inventory_close.emit()
	town_inventory_close.emit()

func _input(event) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if BuildEnv.enabled == true && isOpen:
			isOpen = false
			town_inventory_close.emit()
		elif BuildEnv.enabled == true && !isOpen:
			isOpen = true
			town_inventory_open.emit()
		elif BuildEnv.enabled == false && isOpen:
			isOpen = false
			comabt_inventory_close.emit()
		elif BuildEnv.enabled == false && !isOpen:
			isOpen = true
			combat_inventory_open.emit()
