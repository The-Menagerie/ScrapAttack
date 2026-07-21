extends ScrapUpgrade
class_name SonicBoomUpgrade

@export var attack_damage: float = 0.0
@export var knockback_force: float = 450.0
@export var stun_duration: float = 0.15
@export var attack_duration: float = 0.2

@onready var hit_area: Area2D = $HitArea
@onready var hit_shape: CollisionShape2D = $HitArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var fallback_visual: CanvasItem = get_node_or_null("Sprite2D") as CanvasItem

func _ready() -> void:
	hit_shape.disabled = true
	_set_visual_visible(false)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hit_area.area_entered.connect(_on_hitbox_area_entered)

func execute() -> bool:
	if weapon == null or not can_execute():
		return false

	is_action_active = true
	weapon.set_cooldown_override(cooldown)
	play_upgrade_audio()
	_set_visual_visible(true)
	hit_shape.set_deferred("disabled", false)
	animation_player.play("Attack")
	attack_timer.start(attack_duration)
	return true

func _on_attack_timer_timeout() -> void:
	hit_shape.set_deferred("disabled", true)
	_set_visual_visible(false)
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

func _set_visual_visible(is_visible: bool) -> void:
	if visual != null:
		visual.visible = is_visible

	if fallback_visual != null:
		fallback_visual.visible = is_visible
