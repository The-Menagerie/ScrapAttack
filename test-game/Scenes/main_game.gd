extends Node2D

@export var current_scene: Node
var loaded_main_scene
@export var load_anim: Node
@export var pause_menu: Control
var loading = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if current_scene != null:
		current_scene.process_mode = Node.PROCESS_MODE_PAUSABLE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit") and not event.is_echo():
		if pause_menu != null:
			pause_menu.toggle_menu()

func loading_start() -> void:
	load_anim.play_section("hide")
	loading = true

func loading_stop() -> void:
	load_anim.play_backwards("hide")
	loading = false
	
func preload_main_scene(path: String) -> void:
	loaded_main_scene = load(path)

func replace_scene_with_loaded() -> void:
	loading_start()
	var instantiated_scene = loaded_main_scene.instantiate()
	instantiated_scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(instantiated_scene)
	current_scene.queue_free()
	current_scene = instantiated_scene
	loading_stop()
	loaded_main_scene = null
	
	
