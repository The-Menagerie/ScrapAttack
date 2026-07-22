extends Button

@onready var name_label: Label = %Name
@onready var quantity_label: Label = %Quantity

signal update_display()

var data: ItemData = null

func _ready() -> void:
	bar_data(data)

func bar_data(item_data: ItemData) -> void:
	name_label.text = item_data.name
	quantity_label.text = str(item_data.quantity)

func update_bar_data(item_data: ItemData) -> void:
	quantity_label.text = str(item_data.quantity)
