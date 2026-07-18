extends Node2D
class_name ChargeShotChargeEffect

@export var charge_animation_name: StringName = &"Charge"
@export var reset_animation_name: StringName = &"RESET"

var _is_active: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	visible = false
	if is_instance_valid(sprite):
		sprite.frame = 0

func begin_charge(duration: float) -> void:
	_is_active = true
	visible = true
	_play_charge_animation(duration)

func set_charge_progress(progress: float) -> void:
	if not _is_active or not is_instance_valid(animation_player):
		return

	var animation := animation_player.get_animation(charge_animation_name)

	if animation == null:
		return

	var animation_length := maxf(animation.length, 0.001)
	animation_player.seek(clampf(progress, 0.0, 1.0) * animation_length, true)

func finish_charge() -> void:
	_is_active = false
	visible = false

	if is_instance_valid(animation_player):
		animation_player.stop()

	queue_free()

func _play_charge_animation(duration: float) -> void:
	if not is_instance_valid(animation_player):
		return

	if animation_player.has_animation(reset_animation_name):
		animation_player.play(reset_animation_name)
		animation_player.seek(0.0, true)
		animation_player.stop()
	elif is_instance_valid(sprite):
		sprite.frame = 0

	if not animation_player.has_animation(charge_animation_name):
		return

	var charge_animation := animation_player.get_animation(charge_animation_name)
	var animation_length := maxf(charge_animation.length, 0.001)
	var charge_duration := maxf(duration, 0.001)

	animation_player.speed_scale = animation_length / charge_duration
	animation_player.play(charge_animation_name)
