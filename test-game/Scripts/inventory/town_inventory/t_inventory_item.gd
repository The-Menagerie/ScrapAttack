extends Sprite2D

var data: ItemData = null

func _ready() -> void:
	if data:
		texture = data.texture
