extends Control

@onready var name_label: Label = %NameLabel
@onready var item_weight_label: Label = %ItemWeightLabel
@onready var category_label: Label = %CategoryLabel
@onready var description_label: Label = %DescriptionLabel
@onready var item_scroll = $ItemScroll

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

func update_display(item_data: ItemData) -> void:
	name_label.text = "Item: " + item_data.name
	item_weight_label.text = "Weight per Item: " + str(item_data.weight)
	category_label.text = "Category: " +item_data.category

func move_item_c_to_t(item_data: ItemData) -> void:
	item_scroll.add_item(item_data)
