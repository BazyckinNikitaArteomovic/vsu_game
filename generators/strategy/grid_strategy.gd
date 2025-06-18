class_name GridStrategy extends FillStrategy

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	# Получаем необходимые данные из региона
	var exit_point = region.get_exit_point()  # Получаем DirectedPoint
	var exit_window = region.exit_window      # Получаем DirectedWindow

	# Создаем PlatformGrid с корректными параметрами
	var grid := PlatformGrid.new(
		region.rect,
		false,
		0.0,
		region.rect.size.x
	)
	
	# Блокировка областей вокруг ключевых точек
	#grid.block_region_around_point(region.enter_point)
	#grid.block_region_around_point(exit_point)

	# Вызываем build() с обоими аргументами
	var final_exit_point = grid.build(exit_point, exit_window, region.enter_point)
	print(2)
	var tile_size = WorldProperties.get_property("GRID_STEP")

	for platform_rect in grid.get_platforms():
		var tile_pos = (platform_rect.position).floor()
		var tile_size_rect = (platform_rect.size).ceil()
		var tile_rect = Rect2(tile_pos, tile_size_rect)
		print("Creating component with rect: ", tile_rect)
		components.append(PlatformComponent.new(tile_rect))

	return DirectedPoint.new(
		region.rect,
		exit_window.direction,
		final_exit_point.position
	)
	
func get_min_width() -> float:
	return PlatformGrid.get_platform_width() * 3

func get_min_height() -> float:
	return PlatformGrid.get_vertical_step() * 3
	
# Возвращает массив точек входа по всем сторонам rect
func _generate_wall_points(rect: Rect2) -> Array:
	var points := []
	var step = PlatformGrid.get_horizontal_step() / 2
	var platform_width = 2
	var platform_height = 1

	for dir in DirectionHelper.Directions:
		match dir:
			"UP":
				var x = rect.position.x + platform_width
				while x < rect.end.x - step:
					points.append(DirectedPoint.new(rect, DirectionHelper.Directions.UP, x))
					x += step

			"DOWN":
				var x = rect.position.x + platform_width
				while x < rect.end.x - step:
					points.append(DirectedPoint.new(rect, DirectionHelper.Directions.DOWN, x))
					x += step

			"LEFT":
				var y = rect.position.y + platform_height
				while y < rect.end.y - step:
					points.append(DirectedPoint.new(rect, DirectionHelper.Directions.LEFT, y))
					y += step

			"RIGHT":
				var y = rect.position.y + platform_height
				while y < rect.end.y - step:
					points.append(DirectedPoint.new(rect, DirectionHelper.Directions.RIGHT, y))
					y += step

	return points

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var entrances := []

	# Получаем точку выхода
	var exit_point = DirectedPoint.new(rect, exit_window.direction, exit_window.start + exit_window.size()/2)

	# Генерируем точки по периметру комнаты
	var entrance_points = _generate_wall_points(rect)

	for point in entrance_points:
		# Создаём временную точку входа
		var entrance_point = DirectedPoint.new(rect, point.direction, WorldProperties.bind_to_grid(point.position))

		# Проверяем, чтобы вход и выход не пересекались
		'''if entrance_point.direction == exit_window.direction:
			if abs(entrance_point.position - exit_point.position) < 4.0:
				continue

		# Создаём сетку
		var grid = PlatformGrid.new(rect, false, 0, rect.size.x)

		# Блокируем область вокруг входа и выхода
		grid.block_region_around_point(entrance_point, 1.0)
		grid.block_region_around_point(exit_point, 1.0)

		# Строим путь от входа к выходу
		grid.build(entrance_point, exit_window)'''

		# Проверяем валидность
		#if grid.is_valid():
			# Добавляем новое входное окно
		var entrance_window = DirectedWindow.new(
			rect,
			entrance_point.direction,
			exit_window.size()/2 - 1 + entrance_point.position,
			exit_window.size()/2 + 1 + entrance_point.position
		)
		entrances.append(entrance_window)

	return entrances
