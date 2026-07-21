extends Area2D
class_name PlayerProjectile

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 450.0
@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.0
@export var lingers: bool = false
@export var damage_tick_interval: float = 0.2
@export var rotate_to_direction: bool = true

const FADE_OUT_DURATION: float = 0.15

var lifetime: float = 0.0
var is_fading_out: bool = false
var damage_tick_elapsed: float = 0.0

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var audio_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_play_spawn_animation()
	_play_looping_audio()
	damage_tick_elapsed = damage_tick_interval

	if lifetime > 0.0:
		var timer := get_tree().create_timer(lifetime, false)
		timer.timeout.connect(_begin_fade_out)

func _physics_process(delta: float) -> void:
	if is_fading_out:
		return

	global_position += direction * speed * delta

	if not lingers:
		return

	damage_tick_elapsed += delta

	if damage_tick_elapsed >= damage_tick_interval:
		damage_tick_elapsed = 0.0
		_damage_overlapping_hitboxes()

func configure(
	new_direction: Vector2,
	new_speed: float,
	new_lifetime: float,
	new_attack_damage: float,
	new_knockback_force: float,
	new_stun_duration: float
) -> void:
	if new_direction.length_squared() > 0.0:
		direction = new_direction.normalized()
		if rotate_to_direction:
			rotation = direction.angle()

	speed = new_speed
	lifetime = new_lifetime
	attack_damage = new_attack_damage
	knockback_force = new_knockback_force
	stun_duration = new_stun_duration

func configure_damage_over_time(new_tick_interval: float) -> void:
	lingers = true
	damage_tick_interval = maxf(new_tick_interval, 0.01)
	damage_tick_elapsed = damage_tick_interval

func _begin_fade_out() -> void:
	if is_fading_out:
		return

	is_fading_out = true
	monitoring = false
	monitorable = false

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if is_instance_valid(audio_player):
		audio_player.stop()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	tween.finished.connect(queue_free)

func _play_spawn_animation() -> void:
	if animation_player != null:
		if animation_player.has_animation("Attack"):
			animation_player.play("Attack")
			return
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")
			return

	if animated_sprite != null:
		if animated_sprite.sprite_frames == null:
			return
		if animated_sprite.sprite_frames.has_animation("Attack"):
			animated_sprite.play("Attack")
			return
		if animated_sprite.sprite_frames.has_animation("default"):
			animated_sprite.play("default")

func _damage_overlapping_hitboxes() -> void:
	for area in get_overlapping_areas():
		if not area is HitboxComponent:
			continue

		var hitbox := area as HitboxComponent
		var attack := Attack.new()
		attack.attack_damage = attack_damage
		attack.knockback_force = knockback_force
		attack.attack_position = global_position
		attack.stun_duration = stun_duration
		hitbox.damage(attack)

func _on_area_entered(area: Area2D) -> void:
	if is_fading_out:
		return

	if lingers:
		return

	if !(area is HitboxComponent):
		return

	var hitbox := area as HitboxComponent
	var attack := Attack.new()
	attack.attack_damage = attack_damage
	attack.knockback_force = knockback_force
	attack.attack_position = global_position
	attack.stun_duration = stun_duration
	hitbox.damage(attack)
	if is_instance_valid(audio_player):
		audio_player.stop()
	queue_free()

func _play_looping_audio() -> void:
	if not is_instance_valid(audio_player) or audio_player.stream == null:
		return

	if not audio_player.finished.is_connected(_on_audio_finished):
		audio_player.finished.connect(_on_audio_finished)

	audio_player.play()

func _on_audio_finished() -> void:
	if is_fading_out or not is_inside_tree():
		return

	if not is_instance_valid(audio_player) or audio_player.stream == null:
		return

	audio_player.play()
