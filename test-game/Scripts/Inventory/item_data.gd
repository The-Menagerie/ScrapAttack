class_name ItemData extends Resource

@export var name: String ##Variable to hold name text for items.
@export var texture: Texture2D ##Variable to hold 2D texture for items.
@export var dimensions: Vector2i ##Variable to hold grid dimensions for items.
@export var weight: float ##Variable to hold the weight of items.
@export var quantity: int = 1 ##Variable to keep track of the current quantity of items in a stack.
@export var max_stack_size: int ##Variable to hold the max stack size of an item.
@export var category: String ##Variable to hold the category of an item.

var uID: String: ##This variable takes an items name, makes it lower case, replaces all " " with "_" and returns this new name as an ID.
	get():
		var res = name.to_lower().replace(" ", "_")
		return res

#Example: Scrap Sword becomes scrap_sword
