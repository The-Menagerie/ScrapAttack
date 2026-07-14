extends Node2D
class_name Weapon

@export var attack_cooldown: float = 0.35
@onready var cooldown_timer: Timer = $CooldownTimer

var can_attack := true
var is_attacking := false

func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func attack() -> void:
	if not can_attack:
		return

	can_attack = false
	is_attacking = true
	_begin_attack()

func _on_cooldown_timer_timeout() -> void:
	can_attack = true

func finish_attack() -> void:
	is_attacking = false
	cooldown_timer.start(attack_cooldown)

func _begin_attack() -> void:
	finish_attack()

func set_aim_direction(direction: Vector2, rotation_offset: float = 0.0) -> void:
	if direction.length_squared() <= 0.0:
		return

	var normalized_direction := direction.normalized()

	if normalized_direction.x >= 0.0:
		scale.y = 1.0
	else:
		scale.y = -1.0

	rotation = normalized_direction.angle() + rotation_offset
