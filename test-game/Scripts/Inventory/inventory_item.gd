extends Sprite2D

@onready var quantity_label: Label = %QuantityLabel

var data: ItemData = null
var is_picked: bool = false
var size: Vector2:
	get():
		return Vector2(data.dimensions.x, data.dimensions.y) * 64

var anchor_point: Vector2:
	get():
		return global_position - size / 2

func _ready() -> void:
	if data:
		texture = data.texture
		update_quantity_label()

func _process(delta: float) -> void:
	if is_picked:
		global_position = get_global_mouse_position()

func set_init_position(pos: Vector2) -> void:
	global_position = pos + size / 2
	anchor_point = global_position - size / 2

func get_picked_up() -> void:
	add_to_group("held_item")
	is_picked = true
	z_index = 10
	anchor_point = global_position - size /2

func get_placed(pos: Vector2i) -> void:
	is_picked = false
	global_position = pos + Vector2i(size / 2)
	z_index = 0
	anchor_point = global_position - size / 2
	remove_from_group("held_item")

func update_quantity_label() -> void:
	if data.quantity > 1:
		quantity_label.text = str(data.quantity)
		quantity_label.show()
	else:
		quantity_label.hide()

func stack(item_stack: int) -> void:
	data.quantity += item_stack
	update_quantity_label()
	
