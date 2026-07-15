extends MeleeWeapon
class_name SwordWeapon

@export_group("Special Block")
@export_range(0.0, 1.0, 0.05) var block_damage_reduction: float = 0.35
@export var block_duration: float = 1.0
@export var parry_window: float = 0.2
@export var special_cooldown: float = 0.9
@export var parry_knockback_force: float = 500.0
@export var parry_stun_duration: float = 0.75
@export var block_flash_duration: float = 1.0

@onready var owner_visual: CanvasItem = get_parent().get_node_or_null("Sprite2D") as CanvasItem

var is_blocking: bool = false
var is_parry_window_active: bool = false

func attack() -> void:
	if is_blocking:
		return

	super.attack()

func alt_attack() -> void:
	if is_blocking:
		return

	super.alt_attack()

func special_attack() -> void:
	if is_blocking:
		return

	can_attack = false
	is_attacking = true
	is_blocking = true
	is_parry_window_active = true
	set_cooldown_override(special_cooldown)
	flash_owner_white(block_flash_duration)
	_start_block_timers()

func handle_incoming_attack(attack: Attack) -> bool:
	if not is_blocking:
		return true

	attack.skip_default_hit_flash = true

	if is_parry_window_active and attack.can_be_parried:
		attack.attack_damage = 0.0
		attack.knockback_force = 0.0
		attack.stun_duration = 0.0
		_parry_source(attack.source_node)
		_end_block()
		return false

	attack.attack_damage *= maxf(0.0, 1.0 - block_damage_reduction)
	return true

func prevents_movement() -> bool:
	return is_blocking

func _start_block_timers() -> void:
	var parry_timer := get_tree().create_timer(parry_window)
	parry_timer.timeout.connect(_end_parry_window)

	var block_timer := get_tree().create_timer(block_duration)
	block_timer.timeout.connect(_end_block)

func _end_parry_window() -> void:
	is_parry_window_active = false

func _end_block() -> void:
	if not is_blocking:
		return

	is_blocking = false
	is_parry_window_active = false
	finish_attack()

func _parry_source(source_node: Node2D) -> void:
	if source_node == null:
		return

	var direction := global_position.direction_to(source_node.global_position)

	if source_node.has_method("apply_knockback"):
		source_node.apply_knockback(direction, parry_knockback_force)

	if source_node.has_method("apply_stun"):
		source_node.apply_stun(parry_stun_duration)

func flash_owner_white(duration: float) -> void:
	var shader_material := _get_owner_shader_material()

	if shader_material == null:
		return

	var original_flash_amount: float = float(
		shader_material.get_shader_parameter("flash_amount")
	)

	shader_material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(duration).timeout

	if not is_instance_valid(shader_material):
		return

	shader_material.set_shader_parameter("flash_amount", original_flash_amount)

func _get_owner_shader_material() -> ShaderMaterial:
	if not is_instance_valid(owner_visual):
		owner_visual = get_parent().get_node_or_null("Sprite2D") as CanvasItem

	if not is_instance_valid(owner_visual):
		return null

	var owner_node := owner_visual

	while owner_node != null:
		var shader_material := owner_node.material as ShaderMaterial

		if shader_material != null:
			return shader_material

		owner_node = owner_node.get_parent() as CanvasItem

	return null
