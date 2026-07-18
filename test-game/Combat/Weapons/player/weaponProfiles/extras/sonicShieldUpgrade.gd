extends ScrapUpgrade
class_name SonicShieldUpgrade

@export_range(0.0, 1.0, 0.05) var block_damage_reduction: float = 0.7
@export var block_duration: float = 1.0
@export var parry_window: float = 0.2
@export var parry_knockback_force: float = 400.0
@export var parry_stun_duration: float = 0.75
@export var block_flash_duration: float = 0.2
@export var block_animation_name: StringName = &"Block"
@export var reset_animation_name: StringName = &"RESET"

var is_parry_window_active: bool = false
var owner_visual: CanvasItem

@onready var block_sprite: Sprite2D = $BlockSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if is_instance_valid(block_sprite):
		block_sprite.visible = false

func execute() -> bool:
	if weapon == null or not can_execute():
		return false

	is_action_active = true
	is_parry_window_active = true
	weapon.set_cooldown_override(cooldown)
	flash_owner_white(block_flash_duration)
	_play_block_animation()
	_start_block_timers()
	return true

func handle_incoming_attack(attack: Attack) -> bool:
	if not is_action_active:
		return true

	attack.skip_default_hit_flash = true

	if is_parry_window_active and attack.can_be_parried:
		attack.attack_damage = 0.0
		attack.knockback_force = 0.0
		attack.stun_duration = 0.0
		_parry_source(attack.source_node)
		_end_parry_window()
		return false

	attack.attack_damage *= maxf(0.0, 1.0 - block_damage_reduction)
	return true

func prevents_movement() -> bool:
	return is_action_active

func _start_block_timers() -> void:
	var parry_timer := get_tree().create_timer(parry_window)
	parry_timer.timeout.connect(_end_parry_window)

	var block_timer := get_tree().create_timer(block_duration)
	block_timer.timeout.connect(_end_block)

func _end_parry_window() -> void:
	is_parry_window_active = false

func _end_block() -> void:
	if not is_action_active:
		return

	is_action_active = false
	is_parry_window_active = false
	_stop_block_animation()

	if weapon != null:
		weapon.finish_attack()

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
	if weapon == null:
		return null

	if not is_instance_valid(owner_visual):
		owner_visual = weapon.get_parent().get_node_or_null("Sprite2D") as CanvasItem

	if not is_instance_valid(owner_visual):
		return null

	var owner_node := owner_visual

	while owner_node != null:
		var shader_material := owner_node.material as ShaderMaterial

		if shader_material != null:
			return shader_material

		owner_node = owner_node.get_parent() as CanvasItem

	return null

func _play_block_animation() -> void:
	if is_instance_valid(block_sprite):
		block_sprite.visible = true

	if not is_instance_valid(animation_player):
		return

	if animation_player.has_animation(reset_animation_name):
		animation_player.play(reset_animation_name)
		animation_player.seek(0.0, true)
		animation_player.stop()

	if not animation_player.has_animation(block_animation_name):
		return

	var block_animation := animation_player.get_animation(block_animation_name)

	if block_animation == null:
		return

	var animation_length := maxf(block_animation.length, 0.001)
	var target_duration := maxf(block_duration, 0.001)

	animation_player.speed_scale = animation_length / target_duration
	animation_player.play(block_animation_name)

func _stop_block_animation() -> void:
	if is_instance_valid(animation_player):
		animation_player.stop()
		animation_player.speed_scale = 1.0

		if animation_player.has_animation(reset_animation_name):
			animation_player.play(reset_animation_name)
			animation_player.seek(0.0, true)
			animation_player.stop()

	if is_instance_valid(block_sprite):
		block_sprite.visible = false
