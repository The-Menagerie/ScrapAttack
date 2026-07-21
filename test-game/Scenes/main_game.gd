extends Node2D

@export var current_scene: Node
var loaded_main_scene
@export var load_anim: Node
var loading = false
#func _ready() -> void:

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
	add_child(instantiated_scene)
	current_scene.queue_free()
	current_scene = instantiated_scene
	loading_stop()
	loaded_main_scene = null
	
	
