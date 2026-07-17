extends Weapon
class_name RangedWeapon

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 450.0
@export var projectile_range: float = 675.0
@export var projectile_spawn_distance: float = 16.0
@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.0

func _begin_attack() -> void:
	_spawn_projectile(
		projectile_scene,
		projectile_speed,
		projectile_range,
		attack_damage,
		knockback_force,
		stun_duration
	)
	finish_attack()

func _spawn_projectile(
	scene: PackedScene,
	speed: float,
	range: float,
	damage: float,
	knockback: float,
	stun: float,
	projectile_scale: Vector2 = Vector2.ONE
) -> Node2D:
	if scene == null:
		return null

	var projectile := scene.instantiate()

	if projectile == null:
		return null

	var projectile_lifetime := 0.0

	if speed > 0.0:
		projectile_lifetime = range / speed

	if projectile.has_method("configure"):
		projectile.configure(
			aim_direction,
			speed,
			projectile_lifetime,
			damage,
			knockback,
			stun
		)

	if projectile is Node2D:
		var projectile_node := projectile as Node2D
		projectile_node.global_position = global_position + (aim_direction * projectile_spawn_distance)
		projectile_node.rotation = aim_direction.angle()
		projectile_node.scale = projectile_scale

	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	scene_root.add_child(projectile)

	return projectile as Node2D
