extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_body: CharacterBody2D
@export var damage_visual: CanvasItem
@export var hit_cooldown: float = 0.4
@export var flash_duration: float = 0.1
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
@export var hit_sound_volume_db: float = 0.0
@export var death_sound_volume_db: float = 0.0

var can_be_hit: bool = true

func damage(attack: Attack):
	if not can_be_hit:
		return
	
	can_be_hit = false
	var should_apply_damage := true
	var did_die := false

	if knockback_body and knockback_body.has_method("handle_incoming_attack"):
		should_apply_damage = bool(knockback_body.handle_incoming_attack(attack))
	
	if should_apply_damage and health_component:
		var previous_health := health_component.health
		health_component.damage(attack)
		did_die = previous_health > 0.0 and health_component.health <= 0.0

	if should_apply_damage:
		if did_die:
			_play_sound(death_sound, death_sound_volume_db)
		else:
			_play_sound(hit_sound, hit_sound_volume_db)

	if should_apply_damage and knockback_body and knockback_body.has_method("apply_knockback"):
		var direction := (
			knockback_body.global_position - attack.attack_position
		).normalized()

		knockback_body.apply_knockback(
			direction,
			attack.knockback_force
		)
		if knockback_body.has_method("apply_stun"):
			knockback_body.apply_stun(attack.stun_duration)
	
	if not attack.skip_default_hit_flash:
		flash_red()
	
	await get_tree().create_timer(hit_cooldown, false).timeout
	can_be_hit = true

func flash_red() -> void:
	if not damage_visual:
		return

	damage_visual.modulate = Color.RED

	await get_tree().create_timer(flash_duration, false).timeout

	if is_instance_valid(damage_visual):
		damage_visual.modulate = Color.WHITE

func _play_sound(stream: AudioStream, volume_db: float) -> void:
	if stream == null or not is_inside_tree():
		return

	var audio_player := AudioStreamPlayer2D.new()
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.global_position = global_position

	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	scene_root.add_child(audio_player)
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()
