extends Area2D

@export var parent_building: Node

func transmit_interaction(player: Node) -> void:
	parent_building.interaction(player)
