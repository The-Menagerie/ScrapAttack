extends Area2D
class_name EnemyProjectile

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 250.0
@export var attack_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var stun_duration: float = 0.0
@export var rotate_to_direction: bool = true

var lifetime: float = 0.0
var source_node: Node2D

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_play_spawn_animation()

	if lifetime > 0.0:
		var timer := get_tree().create_timer(lifetime, false)
		timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func configure(
	new_direction: Vector2,
	new_speed: float,
	new_lifetime: float,
	new_attack_damage: float,
	new_knockback_force: float,
	new_stun_duration: float,
	new_source_node: Node2D
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
	source_node = new_source_node

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

func _on_area_entered(area: Area2D) -> void:
	if !(area is HitboxComponent):
		return

	var hitbox := area as HitboxComponent
	var attack := Attack.new()
	attack.attack_damage = attack_damage
	attack.knockback_force = knockback_force
	attack.attack_position = global_position
	attack.stun_duration = stun_duration
	if is_instance_valid(source_node):
		attack.source_node = source_node
	hitbox.damage(attack)
	queue_free()
