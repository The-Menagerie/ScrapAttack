class_name ItemData extends Resource

@export var name: String
@export var texture: Texture2D
@export var dimensions: Vector2i
@export var weight: float
@export var quantity: int = 1
@export var max_stack_size: int

@export var uID: String:
	get():
		var res = name.to_lower().replace(" ", "_")
		return res
