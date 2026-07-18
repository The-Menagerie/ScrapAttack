class_name building_option extends Control

@export var name_label: Node ## Where the name of the building should be
@export var blueprint_image: Node ##Where the sprite will be shown
@export var tile_print_grid: Node ##Where the tile layout for the building is shown

var building_dat= {"name":"pizza"}
var initialized = false
var grid_tile = load("res://Resources/Utility_Assets/build_ui_grid.png")
var bad_grid_tile = load("res://Resources/Utility_Assets/build_ui_grid_bad.png")
#var grid_tile = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Temp_Assets/build_ui_grid.png"))

func _craft_tile(type: int) -> Node:
	var tile
	if type == 1:
		tile = TextureRect.new()
		tile.set_texture(grid_tile)
		tile.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		tile.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	else:
		#tile = ColorRect.new()
		#tile.color = Color(1,1,1,0)
		
		tile = TextureRect.new()
		tile.set_texture(bad_grid_tile)
		tile.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		tile.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	return tile

func initialize(building: Dictionary) -> void:
	name_label.text = building["name"]
	
	var sprite = "res://Resources/Sprout Lands - Sprites - Basic pack/Objects/"+building["sprite"]
	blueprint_image.texture = load(sprite)
		
	var gridspace = building["gridspace"]
	tile_print_grid.columns = gridspace.size()
	for i in gridspace:
		for k in i:
			var tile = _craft_tile(int(k))
			tile_print_grid.add_child(tile)
	
	building_dat = building
	initialized = true
	
	BuildEnv.start_buildin.connect(deactivate)
	BuildEnv.stop_buildin.connect(reactivate)

	
	
			
			
func _gui_input(event: InputEvent) -> void:
	if initialized:
		if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 1:
			BuildEnv.start_buildin.emit(building_dat)
			
	else:
		if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 1:
			print("This element has not been initialized")
		
func deactivate(_building:Dictionary) -> void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func reactivate() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_STOP
