extends Control
class_name PlayerHealthBar

@export_node_path("HealthComponent") var health_component_path: NodePath

var health_component: HealthComponent

@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel

func _ready() -> void:
	health_component = get_node_or_null(health_component_path) as HealthComponent

	if health_component == null:
		push_warning("PlayerHealthBar has no HealthComponent.")
		return

	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	var current_health := health_component.health
	if current_health <= 0.0:
		current_health = health_component.MAX_HEALTH

	_on_health_changed(current_health, health_component.MAX_HEALTH)

func _on_health_changed(current_health: float, max_health: float) -> void:
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	health_label.text = "HP: %d / %d" % [int(round(current_health)), int(round(max_health))]
