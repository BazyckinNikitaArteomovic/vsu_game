class_name Corridor

var points: Array[Vector2i] = []

func _init(start: Vector2i, end: Vector2i):
	generate_path(start, end)

func generate_path(start: Vector2i, end: Vector2i):
	var current = start
	var iterations = 0
	var max_iterations = 1000  # Защита от бесконечного цикла
	
	while current != end and iterations < max_iterations:
		iterations += 1
		
		# Получаем приоритетные направления
		var dir = get_next_direction(current, end)
		current += dir
		
		# Добавляем боковые тайлы для ширины коридора
		for offset in [-1, 0, 1]:
			var side_pos = current + Vector2i(offset * dir.y, offset * dir.x)
			if is_valid_corridor_tile(side_pos):
				points.append(side_pos)
	
	if iterations >= max_iterations:
		printerr("Ошибка: Превышено максимальное количество итераций при генерации коридора!")

# ✅ Новая функция: возвращает направление к цели
func get_next_direction(current: Vector2i, target: Vector2i) -> Vector2i:
	var delta = target - current
	var directions = []
	
	# Приоритет по направлению к цели
	if delta.x > 0:
		directions.append(Vector2i(1, 0))  # Вправо
	elif delta.x < 0:
		directions.append(Vector2i(-1, 0))  # Влево
	
	if delta.y > 0:
		directions.append(Vector2i(0, 1))  # Вниз
	elif delta.y < 0:
		directions.append(Vector2i(0, -1))  # Вверх
	
	# Если нет явного направления, выбираем случайное
	if directions.is_empty():
		return Vector2i(1, 0)  # По умолчанию — вправо
	
	return directions[randi() % directions.size()]

func is_valid_corridor_tile(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x <= 100 and pos.y <= 50
