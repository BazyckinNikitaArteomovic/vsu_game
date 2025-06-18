class_name DirectedWindow extends RefCounted

var rect: Rect2
var direction: int
var start: float
var end: float

func _init(r: Rect2, dir: int, s: float, e: float):
	rect = r
	direction = dir
	start = s
	end = e

func is_horizontal() -> bool:
	return direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]

func get_cells():
	var global_start = rect.position + Vector2(start if not is_horizontal() else 0, start if is_horizontal() else 0)
	var global_end = rect.position + Vector2(end if not is_horizontal() else 0, end if is_horizontal() else 0)
	var cells = []
	for x in range(global_start.x, global_end.x + 1):
		for y in range(global_start.y, global_end.y + 1):
			cells.append(Vector2(x, y))
	return cells

func size() -> float:
	return end - start

func to_another_rect(new_rect: Rect2) -> DirectedWindow:
	var global_center = rect.position + Vector2(start + size()/2 if not is_horizontal() else 0, start + size()/2 if is_horizontal() else 0) + Vector2(rect.size.x if direction == DirectionHelper.Directions.RIGHT else 0, rect.size.y if direction == DirectionHelper.Directions.DOWN else 0)
	if not rect.has_point(global_center + Vector2(-1 if direction == DirectionHelper.Directions.RIGHT else 0, -1 if direction == DirectionHelper.Directions.DOWN else 0) + Vector2(1 if direction == DirectionHelper.Directions.LEFT else 0, 1 if direction == DirectionHelper.Directions.UP else 0)):
		printerr("Window center ", global_center, " outside old rect ", new_rect)
	
	var new_direction = DirectionHelper.Directions.UP
	if global_center.x == new_rect.position.x:
		new_direction = DirectionHelper.Directions.LEFT
	elif global_center.x == new_rect.position.x + new_rect.size.x:
		new_direction = DirectionHelper.Directions.RIGHT
	elif global_center.y == new_rect.position.y:
		new_direction = DirectionHelper.Directions.UP
	elif global_center.y == new_rect.position.y + new_rect.size.y:
		new_direction = DirectionHelper.Directions.DOWN
	if not new_rect.has_point(global_center + Vector2(-1 if new_direction == DirectionHelper.Directions.RIGHT else 0, -1 if new_direction == DirectionHelper.Directions.DOWN else 0) + Vector2(1 if new_direction == DirectionHelper.Directions.LEFT else 0, 1 if new_direction == DirectionHelper.Directions.UP else 0)):
		printerr("Window center ", global_center, " outside new rect ", new_rect)
	
	return DirectedWindow.new(
		new_rect,
		new_direction,
		start,
		end
	)
