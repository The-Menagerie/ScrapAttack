extends Node2D

@export var enemy_list: Array[PackedScene]
@export var spawn_chance: float = 25
@export var random_seed: int = 0

var _rng := RandomNumberGenerator.new()
var scene_parent
var self_parent

func _ready() -> void:
	self_parent = get_parent()
	
	for i in get_tree().current_scene.get_children():
		if i is ProceduralRoomGenerator:
			scene_parent = i
			_setup_rng()
			break
	
	if scene_parent != null:
		if _rng.randf() <= spawn_chance/100:
			var chosen_enemy = enemy_list.pick_random()
			var enemy_node = chosen_enemy.instantiate()
			self_parent.add_child.call_deferred(enemy_node)
			enemy_node.position = position
			self.queue_free()
			


func _setup_rng() -> void:
	if random_seed == 0:
		_rng.randomize()
		return

	_rng.seed = random_seed

	
