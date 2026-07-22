class_name WeaponEnemy
extends Node2D

@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.2

@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.35
@export var attack_distance_min: float = 0.0
@export var attack_distance_max: float = -1.0
@export var enemy: CanvasItem

@onready var weapon_sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var owner_visual: CanvasItem
var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	weapon_sprite.visible = false
	owner_visual = _resolve_owner_visual()

func attack(target_position: Vector2) -> void:
	if !can_attack or is_attacking:
		return

	can_attack = false
	is_attacking = true
	aim_at(target_position)

	flash_white()
	await get_tree().create_timer(attack_windup, false).timeout

	if !is_inside_tree():
		return

	weapon_sprite.visible = true
	_play_attack_audio()
	_play_attack_animation()

	_perform_attack(target_position)

	await _wait_for_attack_finish()

	weapon_sprite.visible = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown, false).timeout

	if !is_inside_tree():
		return

	can_attack = true

func flash_white() -> void:
	var shader_material := _get_enemy_shader_material()

	if shader_material == null:
		push_warning("Enemy sprite has no ShaderMaterial.")
		return

	var flash_count: int = 0
	if shader_material.has_meta("flash_request_count"):
		flash_count = int(shader_material.get_meta("flash_request_count"))
	flash_count += 1
	shader_material.set_meta("flash_request_count", flash_count)
	shader_material.set_shader_parameter(
		"flash_amount",
		1.0
	)

	await get_tree().create_timer(0.1, false).timeout

	if shader_material == null or not is_instance_valid(shader_material):
		return

	flash_count = 0
	if shader_material.has_meta("flash_request_count"):
		flash_count = int(shader_material.get_meta("flash_request_count"))

	flash_count = maxi(flash_count - 1, 0)
	shader_material.set_meta("flash_request_count", flash_count)

	if flash_count <= 0:
		shader_material.set_shader_parameter("flash_amount", 0.0)

func _get_enemy_shader_material() -> ShaderMaterial:
	if not is_instance_valid(owner_visual):
		owner_visual = _resolve_owner_visual()

	if not is_instance_valid(owner_visual):
		return null

	var current: CanvasItem = owner_visual

	while current != null:
		var shader_material := current.material as ShaderMaterial

		if shader_material != null:
			return shader_material

		current = current.get_parent() as CanvasItem

	return null

func deal_damage() -> void:
	for area in attack_area.get_overlapping_areas():
		if area is HitboxComponent:
			var attack_data := Attack.new()

			attack_data.attack_damage = attack_damage
			attack_data.knockback_force = knockback_force
			attack_data.stun_duration = stun_duration
			attack_data.attack_position = global_position
			var source_node := get_parent() as Node2D
			if is_instance_valid(source_node):
				attack_data.source_node = source_node

			area.damage(attack_data)

func _perform_attack(_target_position: Vector2) -> void:
	deal_damage()

func _play_attack_animation() -> void:
	if animation_player != null and animation_player.has_animation("Attack"):
		animation_player.play("Attack")

func _play_attack_audio() -> void:
	if audio_player != null and audio_player.stream != null:
		audio_player.play()

func _wait_for_attack_finish() -> void:
	if animation_player != null and animation_player.has_animation("Attack"):
		await animation_player.animation_finished
		return

	await get_tree().create_timer(attack_duration, false).timeout

func aim_at(target_position: Vector2) -> void:
	var direction := global_position.direction_to(target_position)
	var current_scale := scale

	if direction.x >= 0.0:
		current_scale.y = absf(current_scale.y)
	else:
		current_scale.y = -absf(current_scale.y)

	scale = current_scale
	rotation = direction.angle()

func get_attack_distance_min() -> float:
	return maxf(attack_distance_min, 0.0)

func get_attack_distance_max(default_attack_range: float) -> float:
	if attack_distance_max >= 0.0:
		return attack_distance_max

	return maxf(default_attack_range, 0.0)

func is_distance_in_attack_range(distance_to_target: float, default_attack_range: float) -> bool:
	var min_distance := get_attack_distance_min()
	var max_distance := get_attack_distance_max(default_attack_range)
	return distance_to_target >= min_distance and distance_to_target <= max_distance

func get_attack_distance_score(distance_to_target: float, default_attack_range: float) -> float:
	var min_distance := get_attack_distance_min()
	var max_distance := get_attack_distance_max(default_attack_range)

	if distance_to_target < min_distance:
		return min_distance - distance_to_target

	if distance_to_target > max_distance:
		return distance_to_target - max_distance

	return 0.0

func _resolve_owner_visual() -> CanvasItem:
	if is_instance_valid(enemy):
		return enemy

	var parent_node := get_parent()

	if parent_node == null:
		return null

	return parent_node.get_node_or_null("Sprite2D") as CanvasItem
