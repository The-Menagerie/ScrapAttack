extends MeleeWeapon
class_name DualDaggersWeapon

@onready var primary_animation_player: AnimationPlayer = $PrimaryAnimationPlayer

var can_primary_attack: bool = true

func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	cooldown_timer.timeout.connect(_on_primary_cooldown_timeout)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_primary_attack_timer_timeout)
	special_attack_action = _instantiate_action_scene(special_attack_scene)
	_apply_upgrades()
	attack_shape.disabled = true
	weapon_sprite.visible = false
	default_sprite_scale = weapon_sprite.scale
	default_hitbox_scale = attack_shape.scale
	attack_area.area_entered.connect(_on_primary_hitbox_area_entered)

func attack() -> void:
	if not can_primary_attack:
		return

	can_primary_attack = false
	is_attacking = true
	weapon_sprite.visible = true
	weapon_sprite.frame = 0
	attack_shape.set_deferred("disabled", false)
	primary_animation_player.play("Attack")
	attack_timer.start(attack_duration)

func _on_primary_attack_timer_timeout() -> void:
	attack_shape.set_deferred("disabled", true)
	weapon_sprite.visible = false
	primary_animation_player.stop()
	finish_attack()

func _on_primary_cooldown_timeout() -> void:
	can_primary_attack = true

func _on_primary_hitbox_area_entered(area: Area2D) -> void:
	apply_attack_to_hitbox(
		area,
		attack_damage,
		knockback_force,
		stun_duration,
		global_position
	)
