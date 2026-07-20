extends PanelContainer

@export var items: Array[ItemData] = [] ##Used to hold the item_data for every item in the inventory.
@export var inventory_item_scene: PackedScene ##Is the 2D Sprite used to display items in the inventory.
@onready var item_grid: GridContainer = %InventoryGrid ##Calls the inventory grid by an unique name.
@onready var weight_label: Label = %WeightLabel ##Calls the weight label by an unique name.

var current_weight: float ##Stores the current weight of every item in the inventory.

func _ready() -> void:
	var split_bool: bool = false
	for i in items:
		add_item(i, split_bool)
	##Adds any items that are in the inventory on start up.

func add_item(item_data: ItemData, split_bool: bool) -> void: ##This func adds items, item's data, and the item's weight to the inventory. Does not pickup from the world.
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	add_child(inventory_item)
	var success = item_grid.attempt_to_add_item_data(inventory_item)
	if split_bool == false:
		add_weight(inventory_item.data)

func remove_item(item_data: ItemData, item: Node) -> void: ##This func removes items, item's data, and the item's weight from the inventory. Does not drop into the world.
	subtract_weight(item_data)
	remove_child(item)

func add_weight(item_data: ItemData) -> void: ##This func adds the weight of a item in the inventory and calls func weight_label_append.
	current_weight += item_data.weight * item_data.quantity
	weight_label_append()

func subtract_weight(item_data: ItemData) -> void: ##This func subtracts the weight of a item in the inventory and calls func weight_label_append.
	current_weight -= item_data.weight * item_data.quantity
	weight_label_append()

func weight_label_append() -> void: ##This func takes the current weight and displays it on the label.
	weight_label.text = "Weight: " + str(current_weight) + "/100.0"
