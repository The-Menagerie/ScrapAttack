extends WeaponEnemy
class_name SummonWeaponEnemy

@export var summon_pool: Array[PackedScene] = []
@export var summon_cooldown: float = 5.0
@export_range(1, 8, 1) var summon_count: int = 1
@export_range(0, 32, 1) var max_active_summons: int = 3
@export var summon_spawn_radius_min: float = 32.0
@export var summon_spawn_radius_max: float = 72.0

var active_summons: Array[Node2D] = []

func _ready() -> void:
	attack_cooldown = summon_cooldown
	super()

func _perform_attack(_target_position: Vector2) -> void:
	_cleanup_active_summons()

	if summon_pool.is_empty():
		return

	var spawn_total: int = mini(summon_count, _get_available_summon_slots())
	if spawn_total <= 0:
		return

	for summon_index in spawn_total:
		var summon_scene: PackedScene = _get_random_summon_scene()
		if summon_scene == null:
			continue

		var summon_instance: Node = summon_scene.instantiate()
		if not (summon_instance is Node2D):
			if summon_instance != null:
				summon_instance.queue_free()
			continue

		var summon_node: Node2D = summon_instance as Node2D
		summon_node.global_position = _get_summon_position(float(summon_index), float(spawn_total))

		var scene_root: Node = get_tree().current_scene
		if scene_root == null:
			scene_root = get_tree().root

		summon_node.process_mode = Node.PROCESS_MODE_PAUSABLE
		scene_root.add_child(summon_node)
		active_summons.append(summon_node)

	attack_cooldown = summon_cooldown

func _get_available_summon_slots() -> int:
	if max_active_summons <= 0:
		return summon_count

	return maxi(max_active_summons - active_summons.size(), 0)

func _get_random_summon_scene() -> PackedScene:
	var valid_scenes: Array[PackedScene] = []

	for candidate in summon_pool:
		if candidate != null:
			valid_scenes.append(candidate)

	if valid_scenes.is_empty():
		return null

	var random_index: int = randi_range(0, valid_scenes.size() - 1)
	return valid_scenes[random_index]

func _get_summon_position(summon_index: float, summon_total: float) -> Vector2:
	var min_radius: float = maxf(summon_spawn_radius_min, 0.0)
	var max_radius: float = maxf(summon_spawn_radius_max, min_radius)
	var base_angle: float = randf() * TAU

	if summon_total > 1.0:
		base_angle += (TAU / summon_total) * summon_index

	var radius: float = randf_range(min_radius, max_radius)
	return global_position + Vector2.RIGHT.rotated(base_angle) * radius

func _cleanup_active_summons() -> void:
	var valid_summons: Array[Node2D] = []

	for summon in active_summons:
		if summon != null and is_instance_valid(summon) and summon.is_inside_tree():
			valid_summons.append(summon)

	active_summons = valid_summons
