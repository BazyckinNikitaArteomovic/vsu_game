extends Node2D

@export var floor_tile: Vector2i = Vector2i(3, 0)
@export var wall_tile: Vector2i = Vector2i(3, 18)
@export var level_size: Vector2i = Vector2i(200, 80)
@export var min_region_size: Vector2i = Vector2i(10, 10)


var tile_map

var _split_fill_generator := SplitAndFillGenerator.new()

func generate_level(character, tilemap):
	_enter_tree()
	# Очистка предыдущего уровня
	print("=== LEVEL GENERATION STARTED ===")
	# Очистка
	print("Clearing tilemap...")
	tile_map = tilemap
	tile_map.clear()
	print("Creating initial region...")
	# Создание начального региона
	var start_rect := Rect2(Vector2.ZERO, level_size)
	var exit_window := DirectedWindow.new(
		start_rect,
		DirectionHelper.Directions.RIGHT,
		float(level_size.y * 0.1 - 1),
		float(level_size.y * 0.1 + 1)
	)
	print("Exit window created: ", exit_window.start, "  ", exit_window.end)
	var enter_point := DirectedPoint.new(
		start_rect,
		DirectionHelper.Directions.LEFT,
		float(level_size.y * 0.8),
	)
	print("Enter point created: ", enter_point.position)
	var start_region := DirectedRegion.new(
		start_rect,
		enter_point,
		exit_window
	)
	print("Region created: ", start_region)
	print("Generating components...")
	# Генерация компонентов уровня
	var components := _split_fill_generator.generate_region(start_region, exit_window)
	print("Generated components count: ", components.size())
	# Отрисовка компонентов
	print("Drawing components...")
	for i in components.size():
		var comp = components[i]
		if comp is PlatformComponent:
			#print("Drawing platform at: ", comp.rect)
			_draw_platform(comp.rect)
		elif comp is DebugRegionComponent:
			print("Drawing debug region: ", comp.region.rect)
			_draw_debug_region(comp.region)
	

	# Спавн игрока
	print("Spawning player...")
	_spawn_player(components, enter_point.get_cords(), character)
	print("Player spawn position: ", character.position)
	print("=== LEVEL GENERATION COMPLETED ===")

func _draw_platform(rect: Rect2):
	#print("Drawing platform from ", rect.position, " to ", rect.end)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			tile_map.set_cell(0, Vector2i(x, y), 3, wall_tile)
			#_add_wall_collision(x, y)

func _draw_debug_region(region: DirectedRegion):
	# Отрисовка границ для отладки
	var rect := region.rect
	for x in range(rect.position.x, rect.end.x):
		tile_map.set_cell(0, Vector2i(x, rect.position.y), 3, wall_tile)
		tile_map.set_cell(0, Vector2i(x, rect.end.y - 1), 3, wall_tile)
	
	for y in range(rect.position.y, rect.end.y):
		tile_map.set_cell(0, Vector2i(rect.position.x, y), 3, wall_tile)
		tile_map.set_cell(0, Vector2i(rect.end.x - 1, y), 3, wall_tile)
	for cell in region.exit_window.get_cells():
		tile_map.set_cell(0, Vector2i(cell.x, cell.y), 3, floor_tile)
	'''tile_map.set_cell(0, Vector2i(region.enter_point.position, rect.end.y), 3, floor_tile)
	print(region.enter_point.direction)'''

func _add_wall_collision(x: int, y: int):
	var wall_pos := Vector2i(x, y)
	if tile_map.get_cell_source_id(0, wall_pos) == -1:
		tile_map.set_cell(0, wall_pos, 3, wall_tile)

func _spawn_player(components: Array, spawn_pos: Vector2, character: CharacterBody2D):
	var tile_size = Vector2i(32, 32)  # Ваш размер тайла
	var level_rect = Rect2(Vector2.ZERO, level_size * tile_size)  # Переводим в пиксельные координаты
	
	# Дебаг лог
	print("Raw spawn pos: ", spawn_pos)
	print("Level rect (pixels): ", level_rect)
	
	# 1. Проверяем, находится ли точка спавна внутри уровня в пикселях
	if not level_rect.has_point(spawn_pos):
		printerr("Spawn position outside level! Adjusting...")
		
		# Принудительно ограничиваем позицию
		spawn_pos.x = clamp(spawn_pos.x, 0, level_rect.end.x)
		spawn_pos.y = clamp(spawn_pos.y, 0, level_rect.end.y)
	
	# 2. Ищем ближайшую платформу
	var closest_platform = null
	var min_distance = INF
	
	for comp in components:
		if comp is PlatformComponent:
			var platform_center = comp.rect.position + comp.rect.size/2
			var distance = spawn_pos.distance_to(platform_center)
			
			if distance < min_distance:
				min_distance = distance
				closest_platform = comp.rect
	
	# 3. Устанавливаем позицию
	if closest_platform:
		character.position = Vector2(
			(closest_platform.position.x + closest_platform.size.x/2) * 32,
			closest_platform.position.y * 32 - 50  # 20px выше платформы
		)
		print("Spawned on closest platform at: ", character.position)
	else:
		# Fallback - центр уровня
		character.position = level_rect.size / 2
		printerr("No platforms found! Spawning at center: ", character.position)

# Инициализация параметров мира
func _enter_tree():
	WorldProperties.initialize({
		"GRID_STEP": 1,
		"PLAYER_WIDTH": 1,
		"JUMP_HEIGHT": 5,
		"BORDER_SIZE": 0,
		"GRAVITY": 5,
		"RUN_SPEED": 5,
		"TOP_PLATFORM_POS": 50
	})
