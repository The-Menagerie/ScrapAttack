extends ScrollContainer

@export var items: Array[ItemData] = []
@onready var item_container: VBoxContainer = %ItemContainer

signal create_bar(item_data: ItemData)
signal update_bar(item_data: ItemData)

var storage: Array[ItemData] = []

func _ready() -> void:
	for i in items:
		add_item(i)
		storage.append(i)

func add_item(item_data: ItemData) -> void:
	for i in storage:
		if i.uID == item_data.uID:
			i.quantity += item_data.quantity
			##update_bar.emit(item_data)
			return
	create_bar.emit(item_data)
