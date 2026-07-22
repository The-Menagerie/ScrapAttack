extends Control

@onready var inventory = $%Inventory

signal add_to_tinv(item_data: ItemData)

func open() -> void: ##This function is used to open the inventory scene and pause the game.
	visible = true
	get_tree().paused = true

func close() -> void: ##This function is used to close the inventory scene and unpause the game.
	visible = false
	get_tree().paused = false

func move_item(item_data: ItemData) -> void:
	add_to_tinv.emit(item_data)

func move_item_t_to_c(item_data: ItemData, split: bool = false) -> void:
	inventory.add_item(item_data, split)
