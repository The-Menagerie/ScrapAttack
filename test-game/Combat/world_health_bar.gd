extends Node2D
class_name WorldHealthBar

@export var health_component: HealthComponent
@export var show_at_full_health: bool = true
@export var fade_delay: float = 0.75
@export var fade_duration: float = 1.0
@export var faded_alpha: float = 0.0

@onready var progress_bar: ProgressBar = $ProgressBar

var _fade_tween: Tween
var _last_health: float = -1.0

func _ready() -> void:
	z_as_relative = false
	z_index = 100
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if health_component == null:
		push_warning("WorldHealthBar has no HealthComponent.")
		return

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	var current_health: float = health_component.health

	if current_health <= 0.0:
		current_health = health_component.MAX_HEALTH

	_on_health_changed(current_health, health_component.MAX_HEALTH)

func configure(component: HealthComponent, offset: Vector2) -> void:
	health_component = component
	position = offset

func _on_health_changed(current_health: float, max_health: float) -> void:
	progress_bar.max_value = max_health
	progress_bar.value = current_health

	var took_damage := _last_health >= 0.0 and current_health < _last_health

	if took_damage:
		_show_full_then_fade(current_health, max_health)
	else:
		_apply_resting_visibility(current_health, max_health)

	_last_health = current_health

func _show_full_then_fade(current_health: float, max_health: float) -> void:
	_stop_fade_tween()
	visible = true
	modulate.a = 1.0

	var target_alpha := _get_target_alpha(current_health, max_health)

	_fade_tween = create_tween()
	_fade_tween.tween_interval(fade_delay)
	_fade_tween.tween_property(
		self,
		"modulate:a",
		target_alpha,
		fade_duration
	)
	_fade_tween.finished.connect(func() -> void:
		if is_equal_approx(target_alpha, 0.0):
			visible = false
	)

func _apply_resting_visibility(current_health: float, max_health: float) -> void:
	_stop_fade_tween()

	var target_alpha := _get_target_alpha(current_health, max_health)

	visible = target_alpha > 0.0
	modulate.a = target_alpha

func _get_target_alpha(current_health: float, max_health: float) -> float:
	if current_health <= 0.0:
		return 0.0

	if show_at_full_health or current_health < max_health:
		return faded_alpha

	return 0.0

func _stop_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = null
