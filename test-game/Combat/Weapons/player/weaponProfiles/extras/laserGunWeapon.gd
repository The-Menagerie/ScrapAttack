extends RangedWeapon
class_name LaserGunWeapon

@export_group("Charge Shot")
@export var charge_time_max: float = 1.25
@export var charged_projectile_scale_min: float = 1.0
@export var charged_projectile_scale_max: float = 2.4
@export var charged_damage_multiplier_min: float = 1.25
@export var charged_damage_multiplier_max: float = 4.0
@export var charged_knockback_multiplier: float = 1.0
@export var charged_stun_bonus: float = 0.0
@export var max_charge_flash_duration: float = 0.1

@export_group("Special Attack")
@export var special_projectile_scene: PackedScene
@export var special_projectile_speed: float = 90.0
@export var special_projectile_range: float = 260.0
@export var special_projectile_damage_per_tick: float = 2.0
@export var special_projectile_knockback_force: float = 0.0
@export var special_projectile_stun_duration: float = 0.0
@export var special_projectile_scale: Vector2 = Vector2(2.0, 2.0)
@export var special_projectile_tick_interval: float = 0.25
@export var special_attack_cooldown: float = 1.4

var is_charging_alt: bool = false
var current_charge_time: float = 0.0
var did_flash_max_charge: bool = false

@onready var owner_visual: CanvasItem = get_parent().get_node_or_null("Sprite2D") as CanvasItem

func uses_hold_alt_attack() -> bool:
	return true

func begin_alt_attack() -> void:
	if not can_attack or is_charging_alt:
		return

	can_attack = false
	is_attacking = true
	is_charging_alt = true
	current_charge_time = 0.0
	did_flash_max_charge = false

func update_alt_attack(delta: float) -> void:
	if not is_charging_alt:
		return

	current_charge_time = minf(current_charge_time + delta, charge_time_max)

	if not did_flash_max_charge and current_charge_time >= charge_time_max:
		did_flash_max_charge = true
		flash_owner_white(max_charge_flash_duration)

func release_alt_attack() -> void:
	if not is_charging_alt:
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

	_spawn_projectile(
		projectile_scene,
		projectile_speed,
		projectile_range,
		attack_damage * damage_multiplier,
		knockback_force * charged_knockback_multiplier,
		stun_duration + charged_stun_bonus,
		Vector2.ONE * projectile_scale_value
	)

	is_charging_alt = false
	current_charge_time = 0.0
	did_flash_max_charge = false
	set_cooldown_override(attack_cooldown)
	finish_attack()

func prevents_movement() -> bool:
	return is_charging_alt

func special_attack() -> void:
	if not can_attack or is_charging_alt:
		return

	can_attack = false
	is_attacking = true

	var projectile := _spawn_projectile(
		special_projectile_scene,
		special_projectile_speed,
		special_projectile_range,
		special_projectile_damage_per_tick,
		special_projectile_knockback_force,
		special_projectile_stun_duration,
		special_projectile_scale
	)

	if projectile != null and projectile.has_method("configure_damage_over_time"):
		projectile.configure_damage_over_time(special_projectile_tick_interval)

	set_cooldown_override(special_attack_cooldown)
	finish_attack()

func flash_owner_white(duration: float) -> void:
	var shader_material := _get_owner_shader_material()

	if shader_material == null:
		return

	var original_flash_amount: float = float(
		shader_material.get_shader_parameter("flash_amount")
	)

	shader_material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(duration).timeout

	if not is_instance_valid(shader_material):
		return

	shader_material.set_shader_parameter("flash_amount", original_flash_amount)

func _get_owner_shader_material() -> ShaderMaterial:
	if not is_instance_valid(owner_visual):
		owner_visual = get_parent().get_node_or_null("Sprite2D") as CanvasItem

	if not is_instance_valid(owner_visual):
		return null

	var owner_node := owner_visual

	while owner_node != null:
		var shader_material := owner_node.material as ShaderMaterial

		if shader_material != null:
			return shader_material

		owner_node = owner_node.get_parent() as CanvasItem

	return null
