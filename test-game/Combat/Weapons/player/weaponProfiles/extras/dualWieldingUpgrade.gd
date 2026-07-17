extends ScrapUpgrade
class_name DualWieldingUpgrade

@export var attack_damage: float = 10.0
@export var knockback_force: float = 50.0
@export var attack_duration: float = 0.08
@export var stun_duration: float = 0.04

@onready var attack_sprite: Sprite2D = $AttackSprite
@onready var hit_area: Area2D = $HitArea
@onready var hit_shape: CollisionShape2D = $HitArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var default_sprite_scale: Vector2 = Vector2.ONE
var default_hitbox_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	attack_sprite.visible = false
	hit_shape.disabled = true
	default_sprite_scale = attack_sprite.scale
	default_hitbox_scale = hit_shape.scale
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hit_area.area_entered.connect(_on_hitbox_area_entered)

func execute() -> bool:
	if weapon == null or not can_execute():
		return false

	is_action_active = true
	weapon.set_cooldown_override(cooldown)
	attack_sprite.visible = true
	attack_sprite.frame = 0
	attack_sprite.scale = default_sprite_scale
	hit_shape.scale = default_hitbox_scale
	hit_shape.set_deferred("disabled", false)
	animation_player.play("Attack")
	attack_timer.start(attack_duration)
	return true

func _on_attack_timer_timeout() -> void:
	hit_shape.set_deferred("disabled", true)
	attack_sprite.visible = false
	attack_sprite.scale = default_sprite_scale
	hit_shape.scale = default_hitbox_scale
	animation_player.stop()
	is_action_active = false

	if weapon != null:
		weapon.finish_attack()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if weapon == null:
		return

	weapon.apply_attack_to_hitbox(
		area,
		attack_damage,
		knockback_force,
		stun_duration,
		hit_area.global_position
	)
