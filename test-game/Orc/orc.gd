extends CharacterBody2D

enum ORC_STATE {IDLE, WALK }

@export var move_speed : float = 20
@export var idle_time : float = 5
@export var walk_time : float = 2
@export var detectionRadius : float = 100
@export var agroRadius : float = 200

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var player = get_tree().get_first_node_in_group("Player")

var is_agro: bool = false
var move_direction : Vector2 = Vector2.ZERO
var current_state : ORC_STATE = ORC_STATE.IDLE

func _ready():
	pick_new_state()

func _physics_process(_delta):
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if !is_agro and distance_to_player <= detectionRadius:
			is_agro = true
		if is_agro and distance_to_player > agroRadius:
			is_agro = false
			pick_new_state()
		if is_agro:
			var to_player = player.global_position - global_position
			move_direction = to_player.normalized()
			current_state = ORC_STATE.WALK
			state_machine.travel("Walk")
			velocity = move_direction * move_speed
			animation_tree.set("parameters/Walk/blend_position", move_direction)
			animation_tree.set("parameters/Idle/blend_position", move_direction)
			move_and_slide()
			return
			
	if(current_state == ORC_STATE.WALK):
		velocity = move_direction * move_speed
		move_and_slide()

func select_new_direction():
	move_direction = Vector2(
		randi_range(-1,1),
		randi_range(-1,1)
	)
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	animation_tree.set("parameters/Walk/blend_position", move_direction)
	animation_tree.set("parameters/Idle/blend_position", move_direction)

func pick_new_state():
	if is_agro:
		return
			
	if(current_state == ORC_STATE.IDLE):
		state_machine.travel("Walk")
		current_state = ORC_STATE.WALK
		select_new_direction()
		timer.start(walk_time)
	elif(current_state == ORC_STATE.WALK):
		velocity = Vector2.ZERO
		state_machine.travel("Idle")
		current_state = ORC_STATE.IDLE
		timer.start(idle_time)


func _on_timer_timeout() -> void:
	pick_new_state()
