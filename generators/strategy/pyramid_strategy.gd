# pyramid_strategy.gd
class_name PyramidStrategy extends FillStrategy

const GRID_STEP := 1
const PLATFORM_HEIGHT := 1

func get_name() -> String: return "Pyramid"

func get_min_width() -> float:
	return GRID_STEP * 4

func get_min_height() -> float:
	return GRID_STEP * 4
	
func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array[DirectedWindow]:
	if rect.size.x >= get_min_width() and rect.size.y >= get_min_height():
		return [DirectedWindow.new(rect, DirectionHelper.Directions.UP, 0, rect.size.x)]
	return []

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	print("[PyramidStrategy] Starting fill for region: ", region.rect)
	
	var rect := region.rect
	var wall_x = region.rect.position.x
	var wall_y = region.rect.position.y
	if region.enter_point.direction == DirectionHelper.Directions.UP:
		wall_x = region.enter_point.position
	elif region.enter_point.direction == DirectionHelper.Directions.LEFT:
		wall_y = region.enter_point.position
	elif region.enter_point.direction == DirectionHelper.Directions.RIGHT:
		wall_y = region.enter_point.position
		wall_x = region.rect.position.x + region.rect.size.x
	else:
		wall_y = region.rect.position.y + region.rect.size.y
		wall_x = region.enter_point.position
	var enter_point := Vector2(wall_x, wall_y)
	var exit_window := region.exit_window
	wall_x = region.rect.position.x
	wall_y = region.rect.position.y
	if exit_window.direction == DirectionHelper.Directions.UP:
		wall_x = exit_window.start + exit_window.size()/2
	elif exit_window.direction == DirectionHelper.Directions.LEFT:
		wall_y = exit_window.start + exit_window.size()/2
	elif exit_window.direction == DirectionHelper.Directions.RIGHT:
		wall_y = exit_window.start + exit_window.size()/2
		wall_x = region.rect.position.x + region.rect.size.x
	var exit_center := Vector2(wall_x, wall_y)
	
	print("[PyramidStrategy] Enter point: ", enter_point)
	print("[PyramidStrategy] Exit window direction: ", exit_window.direction)
	print("[PyramidStrategy] Exit center: ", exit_center)

	# Шаги по X и Y
	var step_x := GRID_STEP
	var step_y := GRID_STEP
	
	# Начальные координаты
	var x := enter_point.x
	var y := enter_point.y
	
	var target_x := exit_center.x
	var target_y := exit_center.y
	
	# Направление по X
	var dir_x: int = sign(target_x - x) as int
	if dir_x == 0:
		dir_x = 1  # чтобы лестница не зациклилась

	var platform_count := 0
	var max_y := rect.position.y + rect.size.y
	
	while y < max_y:
		if abs(x - target_x) <= step_x and abs(y - target_y) <= step_y:
			print("[PyramidStrategy] Target reached at (", x, ", ", y, ")")
			break

		var width := step_x
		var height := PLATFORM_HEIGHT
		
		var platform := Rect2(x, y, width, height)
		components.append(PlatformComponent.new(platform))
		print("  → Platform #", platform_count, ": ", platform)

		platform_count += 1
		x += dir_x * step_x
		y += step_y

		# Проверка выхода за границы
		if x < rect.position.x or x + step_x > rect.end.x:
			print("[PyramidStrategy] Staircase hit horizontal wall at x=", x)
			break
		if y > rect.end.y:
			print("[PyramidStrategy] Staircase exceeded vertical space at y=", y)
			break

	print("[PyramidStrategy] Finished. Total platforms: ", platform_count)
	
	return DirectedPoint.new(
		rect,
		region.exit_window.direction,
		region.exit_window.end - GRID_STEP
	)
