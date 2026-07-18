extends RangedWeaponUpgrade
class_name LaserChargeUpgrade

@export var projectile_scene: PackedScene
@export var charge_effect_scene: PackedScene
@export var charge_time_max: float = 1.25
@export var charged_projectile_scale_min: float = 1.0
@export var charged_projectile_scale_max: float = 2.4
@export var charged_damage_multiplier_min: float = 1.25
@export var charged_damage_multiplier_max: float = 4.0
@export var charged_knockback_multiplier: float = 1.0
@export var charged_stun_bonus: float = 0.0
@export var max_charge_flash_duration: float = 0.1
@export var charge_effect_offset: Vector2 = Vector2.ZERO

var is_charging_alt: bool = false
var current_charge_time: float = 0.0
var did_flash_max_charge: bool = false
var active_charge_effect: Node2D

func uses_hold_alt_attack() -> bool:
	return true

func begin_alt_attack() -> void:
	if weapon == null or not weapon.can_attack or is_charging_alt:
		return

	weapon.can_attack = false
	weapon.is_attacking = true
	is_charging_alt = true
	current_charge_time = 0.0
	did_flash_max_charge = false
	_spawn_charge_effect()
	_update_charge_effect_progress(0.0)

func update_alt_attack(delta: float) -> void:
	if not is_charging_alt:
		return

	current_charge_time = minf(current_charge_time + delta, charge_time_max)
	var charge_ratio := 1.0

	if charge_time_max > 0.0:
		charge_ratio = clampf(current_charge_time / charge_time_max, 0.0, 1.0)

	_update_charge_effect_progress(charge_ratio)

	if not did_flash_max_charge and current_charge_time >= charge_time_max:
		did_flash_max_charge = true
		weapon.flash_owner_white(max_charge_flash_duration)

func release_alt_attack() -> void:
	if weapon == null or not is_charging_alt:
		return

	var charge_ratio := 1.0

	if charge_time_max > 0.0:
		charge_ratio = clampf(current_charge_time / charge_time_max, 0.0, 1.0)

	var projectile_scale_value := lerpf(
		charged_projectile_scale_min,
		charged_projectile_scale_max,
		charge_ratio
	)
	var damage_multiplier := lerpf(
		charged_damage_multiplier_min,
		charged_damage_multiplier_max,
		charge_ratio
	)
	var resolved_projectile_scene := projectile_scene
	if resolved_projectile_scene == null:
		resolved_projectile_scene = weapon.projectile_scene

	weapon._spawn_projectile(
		resolved_projectile_scene,
		weapon.projectile_speed,
		weapon.projectile_range,
		weapon.attack_damage * damage_multiplier,
		weapon.knockback_force * charged_knockback_multiplier,
		weapon.stun_duration + charged_stun_bonus,
		Vector2.ONE * projectile_scale_value
	)

	_reset_charge_state()
	weapon.set_cooldown_override(weapon.attack_cooldown)
	weapon.finish_attack()

func prevents_movement() -> bool:
	return is_charging_alt

func _exit_tree() -> void:
	_clear_charge_effect()

func _spawn_charge_effect() -> void:
	_clear_charge_effect()

	if weapon == null or charge_effect_scene == null:
		return

	var effect_instance := charge_effect_scene.instantiate()

	if not (effect_instance is Node2D):
		push_warning("Charge effect scene must inherit Node2D.")
		if effect_instance != null:
			effect_instance.queue_free()
		return

	var scene_root := weapon.get_tree().current_scene
	if scene_root == null:
		scene_root = weapon.get_tree().root

	active_charge_effect = effect_instance as Node2D
	active_charge_effect.global_position = (
		weapon.global_position
		+ (weapon.aim_direction * weapon.projectile_spawn_distance)
		+ charge_effect_offset
	)
	active_charge_effect.global_rotation = 0.0
	scene_root.add_child(active_charge_effect)

	if active_charge_effect.has_method("begin_charge"):
		active_charge_effect.call("begin_charge", charge_time_max)

func _update_charge_effect_progress(charge_ratio: float) -> void:
	if not is_instance_valid(active_charge_effect):
		return

	if active_charge_effect.has_method("set_charge_progress"):
		active_charge_effect.call("set_charge_progress", charge_ratio)

func _clear_charge_effect() -> void:
	if not is_instance_valid(active_charge_effect):
		active_charge_effect = null
		return

	if active_charge_effect.has_method("finish_charge"):
		active_charge_effect.call("finish_charge")
	else:
		active_charge_effect.queue_free()

	active_charge_effect = null

func _reset_charge_state() -> void:
	is_charging_alt = false
	current_charge_time = 0.0
	did_flash_max_charge = false
	_clear_charge_effect()
