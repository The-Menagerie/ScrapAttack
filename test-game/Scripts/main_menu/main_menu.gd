extends Node

@onready var smile_button = $MenuContainer/VboxContainer/SmileButton
var kitty = TextureRect.new()
var dimensions = 0
var window_dimensions = DisplayServer.screen_get_size()
var kitty_timer = Timer.new()


func _ready():
	smile_button.pressed.connect(_Kitty_Time)
	kitty.texture = load("res://Resources/Temp_Assets/cat.jpg")
	dimensions = kitty.texture.get_size()
	kitty.position.x = window_dimensions[0]/2 - dimensions[0]/2
	kitty.position.y = window_dimensions[1]/2 - dimensions[1]/2
	kitty_timer.timeout.connect(_kitty_time_over)
	add_child(kitty_timer)
	
	
	
func _Kitty_Time():
	add_child(kitty)
	kitty_timer.start(2)
	
func _kitty_time_over():
	remove_child(kitty)
	kitty_timer.stop()
	
