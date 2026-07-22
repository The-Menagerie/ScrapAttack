extends VBoxContainer

@export var inventory_bar_scene: PackedScene

var bar_data: Array[Node] = []

func create_bar(item_data: ItemData) -> void:
	var inventory_bar = inventory_bar_scene.instantiate()
	inventory_bar.data = item_data
	add_child(inventory_bar)
	bar_data.append(inventory_bar)

##func update_bar(item_data: ItemData) -> void:
##	for i in bar_data:
##		if  == item_data.uID:
##			bar_data[i].update_bar_data(item_data)
