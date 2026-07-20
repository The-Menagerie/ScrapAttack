extends Control

signal tc_inventory_open
signal tc_inventory_close

var isCombatOpen: bool = false

func _input(event) -> void:
	if event.is_action_pressed("switch_inventory"):
		if isCombatOpen:
			isCombatOpen = false
			tc_inventory_close.emit()
			open()
		elif !isCombatOpen:
			isCombatOpen = true
			close()
			tc_inventory_open.emit()

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false
