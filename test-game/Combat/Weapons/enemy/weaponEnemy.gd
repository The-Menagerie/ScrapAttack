class_name WeaponEnemy
extends Node2D

@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.2

@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.35
@export var enemy: CanvasItem

@onready var weapon_sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer


var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	weapon_sprite.visible = false

func attack(target_position: Vector2) -> void:
	if !can_attack or is_attacking:
		return

	can_attack = false
	is_attacking = true
	aim_at(target_position)

	flash_white()
	await get_tree().create_timer(attack_windup).timeout

	if !is_inside_tree():
		return

	weapon_sprite.visible = true
	animation_player.play("Attack")

	deal_damage()

	await animation_player.animation_finished

	weapon_sprite.visible = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	if !is_inside_tree():
		return

	can_attack = true

func flash_white() -> void:
	var shader_material := _get_enemy_shader_material()

	if shader_material == null:
		push_warning("Enemy sprite has no ShaderMaterial.")
		return

	var original_flash_amount: float = float(
		shader_material.get_shader_parameter("flash_amount")
	)

	shader_material.set_shader_parameter(
		"flash_amount",
		1.0
	)

	await get_tree().create_timer(0.1).timeout

	if shader_material == null or not is_instance_valid(shader_material):
		return

	shader_material.set_shader_parameter("flash_amount", original_flash_amount)

func _get_enemy_shader_material() -> ShaderMaterial:
	if not is_instance_valid(enemy):
		return null

	var current: CanvasItem = enemy

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
			attack_data.source_node = get_parent() as Node2D

			area.damage(attack_data)

func aim_at(target_position: Vector2) -> void:
	var direction := global_position.direction_to(target_position)
	var current_scale := scale

	if direction.x >= 0.0:
		current_scale.y = absf(current_scale.y)
	else:
		current_scale.y = -absf(current_scale.y)

	scale = current_scale
	rotation = direction.angle()
