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
		wall_x = position
	elif direction == DirectionHelper.Directions.LEFT:
		wall_y = position
	elif direction == DirectionHelper.Directions.RIGHT:
		wall_y = position
		wall_x = rect.position.x + rect.size.x
	elif direction == DirectionHelper.Directions.DOWN:
		wall_y = rect.position.y + rect.size.y
		wall_x = position
	return Vector2(wall_x, wall_y)
	
func to_another_rect(new_rect: Rect2) -> DirectedPoint:
	var cords = get_cords()
	if not new_rect.has_point(cords):
		printerr("Point ", cords, " outside new rect ", new_rect)
	# Конвертируем позицию в новый Rect
	var new_direction = DirectionHelper.Directions.UP
	if cords.x == new_rect.position.x:
		new_direction = DirectionHelper.Directions.LEFT
	elif cords.x == new_rect.position.x + new_rect.size.x:
		new_direction = DirectionHelper.Directions.RIGHT
	elif cords.y == new_rect.position.y:
		new_direction = DirectionHelper.Directions.UP
	elif cords.y == new_rect.position.y + new_rect.size.y:
		new_direction = DirectionHelper.Directions.DOWN
	
	return DirectedPoint.new(
		new_rect,
		new_direction,
		cords.y if new_direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT] else cords.x
	)
