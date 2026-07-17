extends Node2D
class_name Weapon

enum HudCooldownSlot {
	PRIMARY,
	ALT,
	SPECIAL
}

@export var display_name: String = ""
@export var hud_icon: Texture2D
@export var attack_cooldown: float = 0.35
@onready var cooldown_timer: Timer = $CooldownTimer

var can_attack := true
var is_attacking := false
var aim_direction: Vector2 = Vector2.RIGHT
var _cooldown_override: float = -1.0
var _pending_hud_cooldown_slot: HudCooldownSlot = HudCooldownSlot.PRIMARY
var _active_hud_cooldown_slot: HudCooldownSlot = HudCooldownSlot.PRIMARY
var _active_hud_cooldown_duration: float = 0.0

func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func attack() -> void:
	if not can_attack:
		return

	_pending_hud_cooldown_slot = HudCooldownSlot.PRIMARY
	can_attack = false
	is_attacking = true
	_begin_attack()

func alt_attack() -> void:
	attack()

func uses_hold_alt_attack() -> bool:
	return false

func begin_alt_attack() -> void:
	alt_attack()

func update_alt_attack(_delta: float) -> void:
	return

func release_alt_attack() -> void:
	return

func special_attack() -> void:
	return

func handle_incoming_attack(_attack: Attack) -> bool:
	return true

func prevents_movement() -> bool:
	return false

func _on_cooldown_timer_timeout() -> void:
	can_attack = true
	_active_hud_cooldown_duration = 0.0

func finish_attack() -> void:
	is_attacking = false
	var cooldown := attack_cooldown

	if _cooldown_override >= 0.0:
		cooldown = _cooldown_override
		_cooldown_override = -1.0

	_active_hud_cooldown_slot = _pending_hud_cooldown_slot
	_active_hud_cooldown_duration = maxf(cooldown, 0.001)
	cooldown_timer.start(cooldown)

func _begin_attack() -> void:
	finish_attack()

func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name

	return name

func get_hud_icon() -> Texture2D:
	return hud_icon

func get_upgrade_hud_icons() -> Array[Texture2D]:
	return []

func get_hud_cooldown_progress() -> float:
	if cooldown_timer == null or cooldown_timer.is_stopped():
		return 0.0

	if _active_hud_cooldown_duration <= 0.0:
		return 0.0

	return clampf(cooldown_timer.time_left / _active_hud_cooldown_duration, 0.0, 1.0)

func get_upgrade_hud_cooldown_progresses() -> Array[float]:
	return []

func get_slot_hud_cooldown_progress(slot: HudCooldownSlot) -> float:
	if _active_hud_cooldown_slot != slot:
		return 0.0

	return get_hud_cooldown_progress()

func set_cooldown_override(cooldown: float) -> void:
	_cooldown_override = cooldown

func set_pending_hud_cooldown_slot(slot: HudCooldownSlot) -> void:
	_pending_hud_cooldown_slot = slot

func set_aim_direction(direction: Vector2, rotation_offset: float = 0.0) -> void:
	if direction.length_squared() <= 0.0:
		return

	var normalized_direction := direction.normalized()
	aim_direction = normalized_direction

	if normalized_direction.x >= 0.0:
		scale.y = 1.0
	else:
		scale.y = -1.0

	rotation = normalized_direction.angle() + rotation_offset
