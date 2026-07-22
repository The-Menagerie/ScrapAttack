extends Node2D

var player_on_item = false
@export var item_image: Node
@export var anim_player: Node
var item_data = {
				"name": "concrete",
				"description": "Durable, lasts well despite magic contamination. Will be useful for building structures",
				"category": "resources",
				"rarity": "Common",
				"sprite": "concrete.png",
				"weight": 2,
				"dimensions": {
					"width": 1,
					"height": 1
				}}
var current_stack = 1

func _ready() -> void:
	anim_player.play_section("idle")

func initialize(item_database_entry, placement_pos, stack_size = 1) -> void:
	self.position = placement_pos
	item_data = item_database_entry
	current_stack = stack_size
	
	var sprite = "res://Resources/Utility_Assets/item_images/"+item_data["sprite"]
	item_image.texture = load(sprite)
	item_image.scale = 16/item_image.texture.get_width()
	pass
	
func player_entered(body) -> void:
	if body is CharacterBody2D:
		print("player is in")
		player_on_item = true

func player_exited(body) -> void:
	if body is CharacterBody2D:
		print("player is out")
		player_on_item = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && event.is_action_pressed("interact_1"):
			print("player_attempted to nab")
			if player_on_item == true:
				self.queue_free()
	
