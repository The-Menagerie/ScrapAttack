extends RangedWeaponUpgrade
class_name LaserChargeUpgrade

@export var charge_time_max: float = 1.25
@export var charged_projectile_scale_min: float = 1.0
@export var charged_projectile_scale_max: float = 2.4
@export var charged_damage_multiplier_min: float = 1.25
@export var charged_damage_multiplier_max: float = 4.0
@export var charged_knockback_multiplier: float = 1.0
@export var charged_stun_bonus: float = 0.0
@export var max_charge_flash_duration: float = 0.1

var is_charging_alt: bool = false
var current_charge_time: float = 0.0
var did_flash_max_charge: bool = false

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

func update_alt_attack(delta: float) -> void:
	if not is_charging_alt:
		return

	current_charge_time = minf(current_charge_time + delta, charge_time_max)

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

	weapon._spawn_projectile(
		weapon.projectile_scene,
		weapon.projectile_speed,
		weapon.projectile_range,
		weapon.attack_damage * damage_multiplier,
		weapon.knockback_force * charged_knockback_multiplier,
		weapon.stun_duration + charged_stun_bonus,
		Vector2.ONE * projectile_scale_value
	)

	is_charging_alt = false
	current_charge_time = 0.0
	did_flash_max_charge = false
	weapon.set_cooldown_override(weapon.attack_cooldown)
	weapon.finish_attack()

func prevents_movement() -> bool:
	return is_charging_alt
