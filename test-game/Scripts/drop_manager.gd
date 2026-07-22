extends Node
#signal drop_item(item_database_entry, placement_pos, parent_node, stack_size)

var drop_item_base

func _ready() -> void:
	drop_item_base = preload("res://Scenes/utility_scenes/dropped_item.tscn")

func drop_item(item_database_entry, placement_pos, parent_node, stack_size = 1):
	var dropped_item = drop_item_base.instantiate()
	dropped_item.initialize(item_database_entry,placement_pos,stack_size)
	parent_node.add_child(dropped_item)


	
	
