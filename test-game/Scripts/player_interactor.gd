extends Node2D

var player_dir = Vector2(0,1)
var player: Node

func _ready() -> void:
	self.rotation = player_dir.angle()
	player = get_parent()
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right") || Input.is_action_pressed("move_up") || Input.is_action_pressed("move_down"):
		player_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.25)
		self.rotation = player_dir.angle()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && event.is_action_pressed("interact_1"):
			var interacted = $Area2D.get_overlapping_areas()
			if interacted:
				interacted[0].transmit_interaction(player)
	
	
