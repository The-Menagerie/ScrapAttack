extends Control

const MASTER_BUS_NAME := "Master"

@onready var menu_title: Label = $PanelContainer/MarginContainer/VBoxContainer/Title
@onready var main_button_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/MainButtons
@onready var options_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MainButtons/OptionsButton
@onready var quit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MainButtons/QuitButton
@onready var options_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/OptionsContainer
@onready var volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/VolumeSlider
@onready var volume_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/VolumeValue
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/BackButton

var master_bus_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	_show_main_buttons()
	_sync_volume_slider()

func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	visible = true
	_show_main_buttons()
	_sync_volume_slider()
	get_tree().paused = true

func close_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_options_button_pressed() -> void:
	menu_title.text = "Options"
	main_button_container.visible = false
	options_container.visible = true

func _on_back_button_pressed() -> void:
	_show_main_buttons()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

func _on_volume_slider_value_changed(value: float) -> void:
	_update_volume_label(value)

	if master_bus_index == -1:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus_index, true)
		return

	AudioServer.set_bus_mute(master_bus_index, false)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

func _show_main_buttons() -> void:
	menu_title.text = "Pause Menu"
	main_button_container.visible = true
	options_container.visible = false

func _sync_volume_slider() -> void:
	if master_bus_index == -1:
		volume_slider.set_value_no_signal(1.0)
		_update_volume_label(1.0)
		return

	if AudioServer.is_bus_mute(master_bus_index):
		volume_slider.set_value_no_signal(0.0)
		_update_volume_label(0.0)
		return

	var current_db := AudioServer.get_bus_volume_db(master_bus_index)
	var slider_value := db_to_linear(current_db)

	slider_value = clampf(slider_value, 0.0, 1.0)
	volume_slider.set_value_no_signal(slider_value)
	_update_volume_label(slider_value)

func _update_volume_label(value: float) -> void:
	volume_value_label.text = "Volume: %d%%" % int(round(value * 100.0))
