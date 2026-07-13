extends PanelContainer

@export var items: Array[ItemData] = []
@export var inventory_item_scene: PackedScene
@onready var item_grid: GridContainer = %InventoryGrid
@onready var weight_label: Label = %WeightLabel

var current_weight: float

func _ready() -> void:
	for i in items:
		add_item(i)

func add_item(item_data: ItemData) -> void:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	add_child(inventory_item)
	var success = item_grid.attempt_to_add_item_data(inventory_item)
	add_weight(inventory_item.data)

func remove_item(item_data: ItemData, item: Node) -> void:
	subtract_weight(item_data)
	remove_child(item)

func add_weight(item_data: ItemData) -> void:
	current_weight += item_data.weight * item_data.quantity
	weight_label_append()

func subtract_weight(item_data: ItemData) -> void:
	current_weight -= item_data.weight * item_data.quantity
	weight_label_append()

func weight_label_append() -> void:
	weight_label.text = "Weight: " + str(current_weight) + "/100.0"
