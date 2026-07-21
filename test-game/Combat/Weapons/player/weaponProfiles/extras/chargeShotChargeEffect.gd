extends Node2D
class_name ChargeShotChargeEffect

@export var charge_animation_name: StringName = &"Charge"
@export var reset_animation_name: StringName = &"RESET"
@export var charge_volume_min_db: float = -18.0
@export var charge_volume_max_db: float = 0.0

var _is_active: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

func _ready() -> void:
	visible = false
	if is_instance_valid(sprite):
		sprite.frame = 0
	if is_instance_valid(audio_player) and not audio_player.finished.is_connected(_on_audio_finished):
		audio_player.finished.connect(_on_audio_finished)

func begin_charge(duration: float) -> void:
	_is_active = true
	visible = true
	_set_charge_volume(0.0)
	_play_charge_audio()
	_play_charge_animation(duration)

func set_charge_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	_set_charge_volume(clamped_progress)

	if not _is_active or not is_instance_valid(animation_player):
		return

	var animation := animation_player.get_animation(charge_animation_name)

	if animation == null:
		return

	var animation_length := maxf(animation.length, 0.001)
	animation_player.seek(clamped_progress * animation_length, true)

func finish_charge() -> void:
	_is_active = false
	visible = false

	if is_instance_valid(animation_player):
		animation_player.stop()
	if is_instance_valid(audio_player):
		audio_player.stop()

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

func _play_charge_audio() -> void:
	if not is_instance_valid(audio_player) or audio_player.stream == null:
		return

	audio_player.play()

func _on_audio_finished() -> void:
	if not _is_active or not is_instance_valid(audio_player) or audio_player.stream == null:
		return

	audio_player.play()

func _set_charge_volume(progress: float) -> void:
	if not is_instance_valid(audio_player):
		return

	audio_player.volume_db = lerpf(
		charge_volume_min_db,
		charge_volume_max_db,
		clampf(progress, 0.0, 1.0)
	)
