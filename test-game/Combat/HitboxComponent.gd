extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_body: CharacterBody2D
@export var damage_visual: CanvasItem
@export var hit_cooldown: float = 0.4
@export var flash_duration: float = 0.1

var can_be_hit: bool = true

func damage(attack: Attack):
	if not can_be_hit:
		return
	
	can_be_hit = false
	var should_apply_damage := true

	if knockback_body and knockback_body.has_method("handle_incoming_attack"):
		should_apply_damage = bool(knockback_body.handle_incoming_attack(attack))
	
	if should_apply_damage and health_component:
		health_component.damage(attack)
	if should_apply_damage and knockback_body and knockback_body.has_method("apply_knockback"):
		var direction := (
			knockback_body.global_position - attack.attack_position
		).normalized()

		knockback_body.apply_knockback(
			direction,
			attack.knockback_force
		)
		if knockback_body.has_method("apply_stun"):
			knockback_body.apply_stun(attack.stun_duration)
	
	if not attack.skip_default_hit_flash:
		flash_red()
	
	await get_tree().create_timer(hit_cooldown).timeout
	can_be_hit = true

func flash_red() -> void:
	if not damage_visual:
		return

	damage_visual.modulate = Color.RED

	await get_tree().create_timer(flash_duration).timeout

	if is_instance_valid(damage_visual):
		damage_visual.modulate = Color.WHITE
