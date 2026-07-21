extends WeaponEnemy
class_name RangedWeaponEnemy

enum AttackPattern {
	AIMED,
	RADIAL
}

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 200.0
@export var projectile_range: float = 180.0
@export var projectile_spawn_distance: float = 12.0
@export var attack_pattern: AttackPattern = AttackPattern.AIMED
@export_range(1, 32, 1) var radial_projectile_count: int = 6
@export_range(0.0, 360.0, 1.0) var radial_angle_offset_degrees: float = 0.0
@export var radial_offset_tracks_target: bool = true

func _perform_attack(target_position: Vector2) -> void:
	match attack_pattern:
		AttackPattern.RADIAL:
			_spawn_radial_projectiles(target_position)
		_:
			var direction := global_position.direction_to(target_position)
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT

			_spawn_projectile_in_direction(direction)

func _spawn_radial_projectiles(target_position: Vector2) -> void:
	var projectile_count: int = maxi(radial_projectile_count, 1)
	var angle_step: float = TAU / float(projectile_count)
	var start_angle: float = deg_to_rad(radial_angle_offset_degrees)

	if radial_offset_tracks_target:
		var target_direction: Vector2 = global_position.direction_to(target_position)
		if target_direction != Vector2.ZERO:
			start_angle += target_direction.angle()

	for projectile_index in projectile_count:
		var angle: float = start_angle + (angle_step * float(projectile_index))
		_spawn_projectile_in_direction(Vector2.RIGHT.rotated(angle))

func _spawn_projectile_in_direction(direction: Vector2) -> Node2D:
	if projectile_scene == null:
		return null

	var projectile := projectile_scene.instantiate()
	if not (projectile is Node2D):
		return null

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var projectile_lifetime := 0.0
	if projectile_speed > 0.0:
		projectile_lifetime = projectile_range / projectile_speed

	if projectile.has_method("configure"):
		projectile.configure(
			direction,
			projectile_speed,
			projectile_lifetime,
			attack_damage,
			knockback_force,
			stun_duration,
			get_parent() as Node2D
		)

	var projectile_node := projectile as Node2D
	projectile_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_node.global_position = global_position + (direction * projectile_spawn_distance)
	projectile_node.rotation = direction.angle()

	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	scene_root.add_child(projectile_node)
	return projectile_node
