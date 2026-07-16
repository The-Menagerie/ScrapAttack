extends RangedWeaponUpgrade
class_name LaserSpecialUpgrade

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 90.0
@export var projectile_range: float = 260.0
@export var projectile_damage_per_tick: float = 2.0
@export var projectile_knockback_force: float = 0.0
@export var projectile_stun_duration: float = 0.0
@export var projectile_scale: Vector2 = Vector2(2.0, 2.0)
@export var projectile_tick_interval: float = 0.25
@export var cooldown: float = 1.4

func special_attack() -> void:
	if weapon == null or not weapon.can_attack:
		return

	weapon.can_attack = false
	weapon.is_attacking = true

	var projectile := weapon._spawn_projectile(
		projectile_scene,
		projectile_speed,
		projectile_range,
		projectile_damage_per_tick,
		projectile_knockback_force,
		projectile_stun_duration,
		projectile_scale
	)

	if projectile != null and projectile.has_method("configure_damage_over_time"):
		projectile.configure_damage_over_time(projectile_tick_interval)

	weapon.set_cooldown_override(cooldown)
	weapon.finish_attack()
