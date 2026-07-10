extends Node2D

@export var map_width = 120
@export var map_height = 64
@export var tile_size = 16
@export var noise_scale = 0.05 # Adjust for terrain chunkiness
@export var seed = 0

@onready var tilemap = $TileMapTest  # Assuming your TileMap is a direct child

func _ready():
	if seed == 0:
		seed = randi() # Assign a random seed on game start
	generate_map()

func generate_map():
	var noise = FastNoiseLite.new()
	noise.seed = seed # set the seed to the generated seed
	noise.frequency = noise_scale

	for x in map_width:
		for y in map_height:
			var noise_value = noise.get_noise_2d(x, y)
			# Scale noise_value to a usable range (0-1)
			noise_value = remap(noise_value, -1, 1, 0, 1)

			var tile_id = determine_tile(noise_value) # Select the right tile based on noise
			tilemap.set_cell(Vector2i(x, y), 0, tile_id)

func determine_tile(noise_value):
	if noise_value < 0.4:
		return Vector2i(0,0) # Water
	elif noise_value < 0.6:
		return Vector2i(1,1) # Sand
	elif noise_value < 0.8:
		return Vector2i(2,2) # Grass
	else:
		return Vector2i(3,3) # Stone
