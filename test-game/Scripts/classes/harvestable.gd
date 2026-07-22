class_name harvestable extends Node2D

func interaction(player: Node) -> void:
	DropManager.drop_item({
				"name": "concrete",
				"description": "Durable, lasts well despite magic contamination. Will be useful for building structures",
				"category": "resources",
				"rarity": "Common",
				"sprite": "concrete.png",
				"weight": 2,
				"dimensions": {
					"width": 1,
					"height": 1
				}},self.position,get_parent(),1)
	self.queue_free()
