class_name building_option extends Control

@export var name_label: Node ## Where the name of the building should be
@export var blueprint_image: Node ##Where the sprite will be shown
@export var tile_print_grid: Node ##Where the tile layout for the building is shown

var grid_tile = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Temp_Assets/build_ui_grid.png"))

func _craft_tile(type: int) -> Node:
	var tile
	if type == 1:
		tile = TextureRect.new()
		tile.set_texture(grid_tile)
		tile.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		tile.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	else:
		tile = ColorRect.new()
		tile.color = Color(1,1,1,0)
		tile.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		tile.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	return tile

func initialize(building: Dictionary) -> void:
	print("initialized "+building["name"])
	var building_name = building["name"]
	var sprite = "res://Resources/Sprout Lands - Sprites - Basic pack/Objects/"+building["sprite"]
	var gridspace = building["gridspace"]
	
	name_label.text = building_name
	blueprint_image.texture = ImageTexture.create_from_image(Image.load_from_file(sprite))
	tile_print_grid.columns = gridspace.size()
	print(tile_print_grid.columns)
	for i in gridspace:
		print(i)
		for k in i:
			var tile = _craft_tile(int(k))
			tile_print_grid.add_child(tile)
			
			
			
	
