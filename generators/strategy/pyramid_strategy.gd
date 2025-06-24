# pyramid_strategy.gd
class_name PyramidStrategy extends FillStrategy

const GRID_STEP := 1
const PLATFORM_HEIGHT := 1
const MAX_CLIMB := 3 * GRID_STEP

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
	var enter_point
	if region.enter_point.direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]:
		enter_point = region.enter_point.get_cords() + Vector2(2 * GRID_STEP, 3 * GRID_STEP)
	else:
		enter_point = region.enter_point.get_cords() + Vector2(0, 2 * GRID_STEP)
	var exit_center = region.exit_window.get_cells()[1] + Vector2(0, 2 * GRID_STEP)

	var x = enter_point.x
	var y = enter_point.y
	var target_x = exit_center.x
	var target_y = exit_center.y

	var dx = abs(target_x - x)
	var dy = abs(target_y - y)

	var steps_needed = ceil(float(dy) / MAX_CLIMB)
	var min_dx_required = steps_needed * GRID_STEP

	# ❌ Проверка: хватит ли горизонтального пространства для безопасного подъёма
	if dx < min_dx_required:
		print("[PyramidStrategy] Cannot build: not enough horizontal space for safe climb")
		return region.enter_point  # или просто return null

	# ✅ Построение: движемся змейкой с ограничением подъёма
	var platform_count := 0
	var dir_x = sign(target_x - x)
	var dir_y = sign(target_y - y)

	while true:
		if abs(x - target_x) <= GRID_STEP and abs(y - target_y) <= GRID_STEP:
			break

		var next_x = x + dir_x * GRID_STEP
		var next_y = y

		# Только если нужно подниматься или спускаться
		if abs(y - target_y) > 0:
			var delta_y = min(MAX_CLIMB, abs(y - target_y))
			next_y += dir_y * delta_y

		var platform := Rect2(Vector2(next_x, next_y), Vector2(GRID_STEP, PLATFORM_HEIGHT))

		# Граница безопасности
		if not rect.has_point(platform.position) or not rect.has_point(platform.position + platform.size):
			print("[PyramidStrategy] Out of bounds at: ", platform)
			break

		components.append(PlatformComponent.new(platform))
		x = next_x
		y = next_y
		platform_count += 1

	print("[PyramidStrategy] Finished. Total platforms: ", platform_count)

	return DirectedPoint.new(
		rect,
		region.exit_window.direction,
		region.exit_window.end - GRID_STEP
	)
