extends MeleeWeapon
class_name DualDaggersWeapon

@export_group("Special Dash")
@export var special_attack_damage: float = 3.0
@export var special_knockback_force: float = 12.0
@export var special_attack_stun_duration: float = 0.05
@export var special_attack_duration: float = 0.08
@export var special_attack_cooldown: float = 0.45
@export var special_dash_multiplier: float = 3.2
@export var special_dash_duration: float = 0.1

@onready var alt_cooldown_timer: Timer = $AltCooldownTimer
@onready var alt_attack_timer: Timer = $AltAttackTimer
@onready var special_attack_left_sprite: Sprite2D = $SpecialAttackLeft
@onready var special_attack_right_sprite: Sprite2D = $SpecialAttackRight
@onready var special_attack_left_area: Area2D = $SpecialAttackAreaLeft
@onready var special_attack_right_area: Area2D = $SpecialAttackAreaRight
@onready var special_attack_left_shape: CollisionShape2D = $SpecialAttackAreaLeft/CollisionShape2D
@onready var special_attack_right_shape: CollisionShape2D = $SpecialAttackAreaRight/CollisionShape2D
@onready var special_attack_timer: Timer = $SpecialAttackTimer
@onready var special_cooldown_timer: Timer = $SpecialCooldownTimer
@onready var primary_animation_player: AnimationPlayer = $PrimaryAnimationPlayer
@onready var alt_animation_player: AnimationPlayer = $AltAnimationPlayer
@onready var special_animation_player: AnimationPlayer = $SpecialAnimationPlayer

var can_primary_attack: bool = true
var can_alt_attack_independent: bool = true
var can_special_attack: bool = true
var active_action_count: int = 0

func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_primary_cooldown_timeout)
	alt_cooldown_timer.one_shot = true
	alt_cooldown_timer.timeout.connect(_on_alt_cooldown_timeout)
	alt_attack_timer.one_shot = true
	alt_attack_timer.timeout.connect(_on_alt_attack_timer_timeout)
	special_attack_timer.one_shot = true
	special_attack_timer.timeout.connect(_on_special_attack_timer_timeout)
	special_cooldown_timer.one_shot = true
	special_cooldown_timer.timeout.connect(_on_special_cooldown_timeout)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_primary_attack_timer_timeout)
	attack_shape.disabled = true
	weapon_sprite.visible = false
	default_sprite_scale = weapon_sprite.scale
	default_hitbox_scale = attack_shape.scale
	if alt_attack_sprite != null:
		alt_attack_sprite.visible = false
		default_alt_sprite_scale = alt_attack_sprite.scale
	if alt_attack_shape != null:
		alt_attack_shape.disabled = true
		default_alt_hitbox_scale = alt_attack_shape.scale
	special_attack_left_shape.disabled = true
	special_attack_right_shape.disabled = true
	special_attack_left_sprite.visible = false
	special_attack_right_sprite.visible = false
	attack_area.area_entered.connect(
		_on_custom_hitbox_area_entered.bind(
			attack_damage,
			knockback_force,
			stun_duration,
			attack_area
		)
	)
	if alt_attack_area != null:
		alt_attack_area.area_entered.connect(
			_on_custom_hitbox_area_entered.bind(
				alt_attack_damage,
				alt_attack_knockback_force,
				alt_attack_stun_duration,
				alt_attack_area
			)
		)
	special_attack_left_area.area_entered.connect(
		_on_custom_hitbox_area_entered.bind(
			special_attack_damage,
			special_knockback_force,
			special_attack_stun_duration,
			special_attack_left_area
		)
	)
	special_attack_right_area.area_entered.connect(
		_on_custom_hitbox_area_entered.bind(
			special_attack_damage,
			special_knockback_force,
			special_attack_stun_duration,
			special_attack_right_area
		)
	)

func attack() -> void:
	if not can_primary_attack:
		return

	can_primary_attack = false
	_begin_action()
	weapon_sprite.visible = true
	weapon_sprite.frame = 0
	attack_shape.set_deferred("disabled", false)
	primary_animation_player.play("Attack")
	attack_timer.start(attack_duration)

func alt_attack() -> void:
	if not can_alt_attack_independent or alt_attack_sprite == null or alt_attack_shape == null:
		return

	can_alt_attack_independent = false
	_begin_action()
	alt_attack_sprite.visible = true
	alt_attack_sprite.frame = 0
	alt_attack_shape.set_deferred("disabled", false)
	alt_animation_player.play("AltAttack")
	alt_attack_timer.start(alt_attack_duration)
	alt_cooldown_timer.start(alt_attack_cooldown)

func special_attack() -> void:
	if not can_special_attack:
		return

	can_special_attack = false
	_begin_action()
	var dash_direction := _get_dash_direction()
	_set_special_attack_pose(dash_direction)
	special_attack_left_shape.set_deferred("disabled", false)
	special_attack_right_shape.set_deferred("disabled", false)
	special_attack_left_sprite.visible = true
	special_attack_right_sprite.visible = true
	special_attack_left_sprite.frame = 0
	special_attack_right_sprite.frame = 0
	special_animation_player.play("SpecialAttack")
	special_attack_timer.start(special_attack_duration)
	special_cooldown_timer.start(special_attack_cooldown)
	var owner_player := get_parent()
	if owner_player != null and owner_player.has_method("dash"):
		owner_player.dash(dash_direction, special_dash_multiplier, special_dash_duration)

func _on_primary_attack_timer_timeout() -> void:
	attack_shape.set_deferred("disabled", true)
	weapon_sprite.visible = false
	primary_animation_player.stop()
	_end_action()
	cooldown_timer.start(attack_cooldown)

func _on_primary_cooldown_timeout() -> void:
	can_primary_attack = true

func _on_alt_cooldown_timeout() -> void:
	can_alt_attack_independent = true

func _on_special_attack_timer_timeout() -> void:
	special_attack_left_shape.set_deferred("disabled", true)
	special_attack_right_shape.set_deferred("disabled", true)
	special_attack_left_sprite.visible = false
	special_attack_right_sprite.visible = false
	special_animation_player.stop()
	_end_action()

func _on_special_cooldown_timeout() -> void:
	can_special_attack = true

func _on_attack_timer_timeout() -> void:
	_on_alt_attack_timer_timeout()

func _on_alt_attack_timer_timeout() -> void:
	if alt_attack_shape == null:
		return

	alt_attack_shape.set_deferred("disabled", true)
	alt_attack_sprite.visible = false
	alt_animation_player.stop()
	_end_action()

func _on_custom_hitbox_area_entered(
	area: Area2D,
	damage_amount: float,
	knockback_amount: float,
	stun_amount: float,
	attack_origin: Area2D
) -> void:
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		var outgoing_attack := Attack.new()
		outgoing_attack.attack_damage = damage_amount
		outgoing_attack.knockback_force = knockback_amount
		outgoing_attack.attack_position = attack_origin.global_position
		outgoing_attack.stun_duration = stun_amount
		outgoing_attack.source_node = get_parent() as Node2D
		hitbox.damage(outgoing_attack)

func _begin_action() -> void:
	active_action_count += 1
	is_attacking = true

func _end_action() -> void:
	active_action_count = maxi(active_action_count - 1, 0)
	is_attacking = active_action_count > 0

func _get_dash_direction() -> Vector2:
	var owner_player := get_parent()

	if owner_player != null:
		var movement_direction_value: Variant = owner_player.get("last_move_direction")
		if movement_direction_value is Vector2:
			var movement_direction: Vector2 = movement_direction_value
			if movement_direction.length_squared() > 0.0:
				return movement_direction.normalized()

	return aim_direction

func _set_special_attack_pose(dash_direction: Vector2) -> void:
	var base_angle := dash_direction.angle()
	var clockwise_direction := dash_direction.rotated(PI * 0.5)
	var counter_clockwise_direction := dash_direction.rotated(-PI * 0.5)

	special_attack_left_sprite.rotation = clockwise_direction.angle() - base_angle
	special_attack_right_sprite.rotation = counter_clockwise_direction.angle() - base_angle
	special_attack_left_area.rotation = clockwise_direction.angle() - base_angle
	special_attack_right_area.rotation = counter_clockwise_direction.angle() - base_angle
	set_aim_direction(dash_direction)
