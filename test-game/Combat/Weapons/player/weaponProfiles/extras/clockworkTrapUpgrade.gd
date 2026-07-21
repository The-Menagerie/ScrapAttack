extends ScrapUpgrade
class_name ClockworkTrapUpgrade

@export var projectile_scene: PackedScene
@export var trap_duration: float = 3.0
@export var trap_spawn_distance: float = 22.0
@export var trap_damage: float = 0.0
@export var trap_knockback_force: float = 0.0
@export var trap_stun_duration: float = 0.75
@export var trap_tick_interval: float = 0.35
@export var trap_scale: Vector2 = Vector2.ONE

func execute() -> bool:
	if weapon == null or not can_execute() or projectile_scene == null:
		return false

	var projectile := projectile_scene.instantiate()

	if not (projectile is Node2D):
		return false

	var projectile_node := projectile as Node2D
	var direction := weapon.aim_direction

	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	if projectile.has_method("configure"):
		projectile.configure(
			direction,
			0.0,
			trap_duration,
			trap_damage,
			trap_knockback_force,
			trap_stun_duration
		)

	if projectile.has_method("configure_damage_over_time"):
		projectile.configure_damage_over_time(trap_tick_interval)

	play_upgrade_audio()
	projectile_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_node.global_position = weapon.global_position + (direction * trap_spawn_distance)
	projectile_node.scale = trap_scale

	var scene_root := weapon.get_tree().current_scene
	if scene_root == null:
		scene_root = weapon.get_tree().root

	scene_root.add_child(projectile_node)

	is_action_active = true
	weapon.set_cooldown_override(cooldown)
	is_action_active = false
	weapon.finish_attack()
	return true
