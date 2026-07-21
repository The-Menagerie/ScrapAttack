@tool
extends Resource
class_name ProceduralRoomDoor

@export var cell: Vector2i = Vector2i.ZERO
@export var direction: Vector2i = Vector2i.RIGHT

func get_cardinal_direction() -> Vector2i:
	if direction == Vector2i.ZERO:
		return Vector2i.RIGHT

	if abs(direction.x) >= abs(direction.y):
		return Vector2i(_sign_int(direction.x), 0)

	return Vector2i(0, _sign_int(direction.y))

func _sign_int(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0
