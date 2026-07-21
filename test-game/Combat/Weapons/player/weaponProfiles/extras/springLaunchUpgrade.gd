extends ScrapUpgrade
class_name springLaunchUpgrade

@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.06
@export var attack_duration: float = 0.08
@export var dash_multiplier: float = 3.2
@export var dash_duration: float = 0.1

@onready var left_sprite: Sprite2D = $SpecialAttackLeft
@onready var right_sprite: Sprite2D = $SpecialAttackRight
@onready var left_area: Area2D = $SpecialAttackAreaLeft
@onready var right_area: Area2D = $SpecialAttackAreaRight
@onready var left_shape: CollisionShape2D = $SpecialAttackAreaLeft/CollisionShape2D
@onready var right_shape: CollisionShape2D = $SpecialAttackAreaRight/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	left_shape.disabled = true
	right_shape.disabled = true
	left_sprite.visible = false
	right_sprite.visible = false
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	left_area.area_entered.connect(_on_left_area_entered)
	right_area.area_entered.connect(_on_right_area_entered)

func execute() -> bool:
	if weapon == null or not can_execute():
		return false

	is_action_active = true
	weapon.set_cooldown_override(cooldown)
	weapon.play_attack_audio()
	var dash_direction := _get_dash_direction()
	_set_attack_pose(dash_direction)
	left_shape.set_deferred("disabled", false)
	right_shape.set_deferred("disabled", false)
	left_sprite.visible = true
	right_sprite.visible = true
	left_sprite.frame = 0
	right_sprite.frame = 0
	animation_player.play("Attack")
	attack_timer.start(attack_duration)
	var owner_player := weapon.get_parent()
	if owner_player != null and owner_player.has_method("dash"):
		owner_player.dash(dash_direction, dash_multiplier, dash_duration)
	return true

func _on_attack_timer_timeout() -> void:
	left_shape.set_deferred("disabled", true)
	right_shape.set_deferred("disabled", true)
	left_sprite.visible = false
	right_sprite.visible = false
	animation_player.stop()
	is_action_active = false

	if weapon != null:
		weapon.finish_attack()

func _on_left_area_entered(area: Area2D) -> void:
	_apply_hit(area, left_area.global_position)

func _on_right_area_entered(area: Area2D) -> void:
	_apply_hit(area, right_area.global_position)

func _apply_hit(area: Area2D, attack_position: Vector2) -> void:
	if weapon == null:
		return

	weapon.apply_attack_to_hitbox(
		area,
		attack_damage,
		knockback_force,
		stun_duration,
		attack_position
	)

func _get_dash_direction() -> Vector2:
	if weapon == null:
		return Vector2.RIGHT

	var owner_player := weapon.get_parent()

	if owner_player != null:
		var movement_direction_value: Variant = owner_player.get("last_move_direction")
		if movement_direction_value is Vector2:
			var movement_direction: Vector2 = movement_direction_value
			if movement_direction.length_squared() > 0.0:
				return movement_direction.normalized()

	return weapon.aim_direction

func _set_attack_pose(dash_direction: Vector2) -> void:
	var base_angle := dash_direction.angle()
	var clockwise_direction := dash_direction.rotated(PI * 0.5)
	var counter_clockwise_direction := dash_direction.rotated(-PI * 0.5)

	left_sprite.rotation = clockwise_direction.angle() - base_angle
	right_sprite.rotation = counter_clockwise_direction.angle() - base_angle
	left_area.rotation = clockwise_direction.angle() - base_angle
	right_area.rotation = counter_clockwise_direction.angle() - base_angle
	weapon.set_aim_direction(dash_direction)
