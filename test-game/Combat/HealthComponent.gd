extends Node2D
class_name HealthComponent

signal health_changed(current_health: float, max_health: float)

const WORLD_HEALTH_BAR_SCENE := preload("res://Combat/world_health_bar.tscn")

@export var MAX_HEALTH := 10.0
@export var show_world_health_bar: bool = true
@export var world_health_bar_offset: Vector2 = Vector2(0, -28)
var health : float

func _ready() -> void:
	health = MAX_HEALTH
	_spawn_world_health_bar()
	health_changed.emit(health, MAX_HEALTH)

func damage(attack: Attack) -> void:
	health = clampf(
		health - attack.attack_damage,
		0.0,
		MAX_HEALTH
	)
	health_changed.emit(health, MAX_HEALTH)
	
	if health <= 0:
		get_parent().queue_free()

func _spawn_world_health_bar() -> void:
	if not show_world_health_bar:
		return

	if get_parent() is HitboxComponent:
		return

	for child in get_children():
		if child is WorldHealthBar:
			return

	var world_health_bar := WORLD_HEALTH_BAR_SCENE.instantiate() as WorldHealthBar

	if world_health_bar == null:
		return

	for child in get_children():
		if child is WorldHealthBar:
			return

	add_child(world_health_bar)
	world_health_bar.configure(self, world_health_bar_offset)
