extends WeaponEnemy
class_name TeleportWeaponEnemy

@export var teleport_disappear_time: float = 0.25
@export var teleport_reappear_delay: float = 0.05
@export var teleport_reappear_damage_delay: float = 0.05
@export var teleport_offset_distance: float = 0.0
@export var teleport_reappear_stun_duration: float = 0.3

var _cached_collision_shapes: Array[CollisionShape2D] = []
var _cached_visual_nodes: Array[CanvasItem] = []

func _ready() -> void:
	super()
	_cache_owner_nodes()

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

	weapon_sprite.visible = false
	_play_attack_audio()
	_play_attack_animation()

	await _perform_teleport_attack(target_position)

	weapon_sprite.visible = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown, false).timeout

	if !is_inside_tree():
		return

	can_attack = true

func _perform_teleport_attack(target_position: Vector2) -> void:
	var owner_enemy := get_parent() as Node2D
	if owner_enemy == null:
		return

	_set_owner_active(false)

	if teleport_disappear_time > 0.0:
		await get_tree().create_timer(teleport_disappear_time, false).timeout

	if not is_inside_tree() or not is_instance_valid(owner_enemy):
		return

	var teleport_target: Vector2 = target_position
	var teleport_direction: Vector2 = owner_enemy.global_position.direction_to(target_position)
	if teleport_direction == Vector2.ZERO:
		teleport_direction = Vector2.RIGHT

	if teleport_offset_distance != 0.0:
		teleport_target -= teleport_direction.normalized() * teleport_offset_distance

	owner_enemy.global_position = teleport_target
	aim_at(target_position)

	if teleport_reappear_delay > 0.0:
		await get_tree().create_timer(teleport_reappear_delay, false).timeout

	if not is_inside_tree():
		return

	_set_owner_active(true)

	if teleport_reappear_damage_delay > 0.0:
		await get_tree().create_timer(teleport_reappear_damage_delay, false).timeout

	if not is_inside_tree():
		return

	deal_damage()

	var owner_enemy_body := owner_enemy as Enemy
	if owner_enemy_body != null and teleport_reappear_stun_duration > 0.0:
		owner_enemy_body.apply_stun(teleport_reappear_stun_duration)

func _cache_owner_nodes() -> void:
	var owner_enemy: Node = get_parent()
	if owner_enemy == null:
		return

	_cached_collision_shapes.clear()
	_cached_visual_nodes.clear()

	for child in owner_enemy.get_children():
		if child is CollisionShape2D:
			_cached_collision_shapes.append(child as CollisionShape2D)
		elif child is CanvasItem and child != self:
			_cached_visual_nodes.append(child as CanvasItem)

		if child is CollisionObject2D:
			for grandchild in child.get_children():
				if grandchild is CollisionShape2D:
					_cached_collision_shapes.append(grandchild as CollisionShape2D)

func _set_owner_active(is_active: bool) -> void:
	for shape in _cached_collision_shapes:
		if shape != null and is_instance_valid(shape):
			shape.set_deferred("disabled", !is_active)

	for visual_node in _cached_visual_nodes:
		if visual_node != null and is_instance_valid(visual_node):
			visual_node.visible = is_active
