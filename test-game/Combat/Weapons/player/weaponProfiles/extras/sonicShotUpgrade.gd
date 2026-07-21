extends ScrapUpgrade
class_name ScrapShotUpgrade

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 260.0
@export var projectile_range: float = 110.0
@export var projectile_spawn_distance: float = 18.0
@export var projectile_damage: float = 4.0
@export var projectile_knockback_force: float = 150.0
@export var projectile_stun_duration: float = 0.0
@export var projectile_scale: Vector2 = Vector2(0.75, 0.75)
@export var sound_duration: float = 1.3

func execute() -> bool:
	if weapon == null or not can_execute() or projectile_scene == null:
		return false

	var projectile := projectile_scene.instantiate()

	if not (projectile is Node2D):
		return false

	var projectile_node := projectile as Node2D
	var direction := weapon.aim_direction

	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var projectile_lifetime := 0.0
	if projectile_speed > 0.0:
		projectile_lifetime = projectile_range / projectile_speed

	if projectile.has_method("configure"):
		projectile.configure(
			direction,
			projectile_speed,
			projectile_lifetime,
			projectile_damage,
			projectile_knockback_force,
			projectile_stun_duration
		)

	_play_upgrade_audio_for_duration()
	projectile_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_node.global_position = weapon.global_position + (direction * projectile_spawn_distance)
	projectile_node.rotation = direction.angle()
	projectile_node.scale = projectile_scale

	var scene_root := weapon.get_tree().current_scene
	if scene_root == null:
		scene_root = weapon.get_tree().root

	scene_root.add_child(projectile_node)

	is_action_active = true
	weapon.set_cooldown_override(cooldown)
	is_action_active = false
	weapon.finish_attack()
	return true

func _play_upgrade_audio_for_duration() -> void:
	if audio_player == null or audio_player.stream == null:
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	var temp_audio_player := AudioStreamPlayer.new()
	temp_audio_player.stream = audio_player.stream
	temp_audio_player.volume_db = audio_player.volume_db
	temp_audio_player.pitch_scale = audio_player.pitch_scale
	temp_audio_player.bus = audio_player.bus
	temp_audio_player.max_polyphony = 1
	temp_audio_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	scene_root.add_child(temp_audio_player)
	temp_audio_player.play()

	var timer := get_tree().create_timer(maxf(sound_duration, 0.0), false)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(temp_audio_player):
			temp_audio_player.stop()
			temp_audio_player.queue_free()
	)
