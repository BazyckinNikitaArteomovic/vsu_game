class_name DirectedPoint extends RefCounted

var rect: Rect2
var direction: int
var position: float

func _init(r: Rect2, dir: int, pos: float):
	rect = r
	direction = dir
	position = pos

func get_cords():
	var wall_x = rect.position.x
	var wall_y = rect.position.y
	if direction == DirectionHelper.Directions.UP:
		wall_x += position
	elif direction == DirectionHelper.Directions.LEFT:
		wall_y += position
	elif direction == DirectionHelper.Directions.RIGHT:
		wall_y += position
		wall_x = rect.position.x + rect.size.x
	elif direction == DirectionHelper.Directions.DOWN:
		wall_y = rect.position.y + rect.size.y
		wall_x += position
	return Vector2(wall_x, wall_y)
	
func to_another_rect(new_rect: Rect2):
	var cords = get_cords()
	if new_rect.position.x > cords.x or new_rect.position.y > cords.y or new_rect.end.x < cords.x or new_rect.end.y < cords.y:
		printerr("Point ", cords, " outside new rect ", new_rect)
		return false
	# Конвертируем позицию в новый Rect
	var new_direction = DirectionHelper.Directions.UP
	var new_position = 0
	if cords.x == new_rect.position.x:
		new_direction = DirectionHelper.Directions.LEFT
		new_position = cords.y - new_rect.position.y
	elif cords.x == new_rect.position.x + new_rect.size.x:
		new_direction = DirectionHelper.Directions.RIGHT
		new_position = cords.y - new_rect.position.y
	elif cords.y == new_rect.position.y:
		new_direction = DirectionHelper.Directions.UP
		new_position = cords.x - new_rect.position.x
	elif cords.y == new_rect.position.y + new_rect.size.y:
		new_direction = DirectionHelper.Directions.DOWN
		new_position = cords.x - new_rect.position.x
	
	return DirectedPoint.new(
		new_rect,
		new_direction,
		new_position
	)
