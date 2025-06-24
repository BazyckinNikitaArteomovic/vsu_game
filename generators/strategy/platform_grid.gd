# platform_grid.gd
class_name PlatformGrid extends RefCounted


var _rect: Rect2
var _first_row_displaced: bool
var _left_shift: float
var _max_width: float
var _cells: Array = []
var _blocked_regions: Array[Rect2] = []
var _exit_cell: Cell = null
var _pre_exit_cell: Cell = null
var _need_exit_cell: bool = false

class Cell:
	var row: int
	var column: int
	var rect: Rect2
	var is_on_path: bool = false
	var is_disabled: bool = false
	
	func _init(r: int, c: int, r_rect: Rect2):
		row = r
		column = c
		rect = r_rect

# Конструктор
func _init(rect: Rect2, first_row_displaced: bool, left_shift: float, max_width: float):
	_rect = rect
	_first_row_displaced = first_row_displaced
	_left_shift = left_shift
	_max_width = max_width
	_create_grid()

# Основные методы
func is_valid() -> bool:
	var has_exit = _exit_cell != null
	var exit_reachable = has_exit and not _exit_cell.is_disabled and _exit_cell.is_on_path
	return not _need_exit_cell or (has_exit and exit_reachable)

func block_region(region: Rect2):
	# Преобразуем в локальные координаты сетки
	var local_region = Rect2(
		region.position - _rect.position,
		region.size
	)
	
	# Добавляем проверку на валидность региона
	if local_region.size.x <= 0 or local_region.size.y <= 0:
		return
		
	_blocked_regions.append(local_region)
	
	# Блокируем пересекающиеся ячейки
	for row in _cells:
		for cell in row:
			if local_region.intersects(cell.rect):
				cell.is_disabled = true

# Внутренние методы
func _create_grid():
	var platform_width = get_platform_width()
	var platform_height = get_platform_height()
	var v_step = get_vertical_step()
	var h_step = get_horizontal_step()
	var width = _rect.size.x
	var height = _rect.size.y
	var row_count = int((height - platform_height) / v_step) + 1
	
	for row in row_count:
		var row_cells = []
		var col_count = _get_column_count(row)
		var displacement = h_step if _row_has_displacement(row) else 0.0
		for col in col_count:
			var x = _rect.position.x + col * h_step + displacement
			var y = get_start_y_pos() + row * v_step
			var cell_rect = Rect2(x, y, platform_width, platform_height)
			var cell = Cell.new(row, col, cell_rect)
			if cell_rect.position.y + cell_rect.size.y > _rect.end.y || cell_rect.position.y < _rect.position.y || cell_rect.position.x + cell_rect.size.x > _rect.end.x || cell_rect.position.x < _rect.position.x:
				cell.is_disabled = true
			row_cells.append(cell)
		_cells.append(row_cells)

# Статические методы
static func get_max_shift(width: float) -> float:
	var platform_width = get_platform_width()
	var h_step = get_horizontal_step()
	return minf(
		fmod(width - platform_width, h_step * 2),
		fmod(width - platform_width - h_step, h_step * 2)
	)

func get_row_num_under(y_pos: float) -> int:
	return int((y_pos - get_start_y_pos()) / get_vertical_step()) + 1

static func get_platform_height() -> float:
	return 1

static func get_platform_width() -> float:
	return 2

func _get_column_count(row: int) -> int:
	return _displ_row_size() if _row_has_displacement(row) else _not_displ_row_size()

func _row_has_displacement(row: int) -> bool:
	return (row % 2 == 0) == _first_row_displaced

func _displ_row_size() -> int:
	return int((_max_width - get_platform_width() * 2) / (get_horizontal_step())) + 1

func _not_displ_row_size() -> int:
	return int((_max_width - get_platform_width()) / (get_horizontal_step())) + 1

func build(exit_point: DirectedPoint, exit_window: DirectedWindow, enter_point: DirectedPoint) -> DirectedPoint:
	_find_exit_near(exit_point, exit_window)
	_create_directed_path(enter_point, exit_point)
	#_create_control_points()
	#_create_paths()
	#_do_post_process()
	return _calculate_exit_point(exit_point)
	
func _create_directed_path(entry_point: DirectedPoint, exit_point: DirectedPoint):
	var new_enter_point
	if exit_point.direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]:
		new_enter_point = entry_point.get_cords() + Vector2(2, 3)
	else:
		new_enter_point = entry_point.get_cords() + Vector2(0, 2)
	var entry_cell := _find_closest_cell(new_enter_point)
	var exit_cell := _exit_cell

	if !entry_cell or !exit_cell:
		return

	var bottom_cells := _cells[_cells.size() - 1].filter(func(c): return not c.is_disabled) as Array
	bottom_cells.shuffle()
	var flag = false
	for i in range(20):
		if flag:
			break
		for start_cell in bottom_cells:
			var success_to_entry := _bfs_path_to(start_cell, entry_cell)
			var success_to_exit := _bfs_path_to(start_cell, _pre_exit_cell)
			if success_to_entry and success_to_exit:
				flag = true
				break

func _bfs_path_to(start: Cell, goal: Cell) -> bool:
	var came_from = {}
	var queue = [start]
	var visited = {}

	while not queue.is_empty():
		var current = queue.pop_front()
		if current == goal:
			# Пометить путь
			var cell = current
			while cell in came_from:
				cell.is_on_path = true
				cell = came_from[cell]
			start.is_on_path = true
			goal.is_on_path = true
			return true

		visited[current] = true

		for neighbor in _get_valid_neighbors(current):
			if neighbor in visited or neighbor in queue:
				continue
			came_from[neighbor] = current
			queue.append(neighbor)

	return false
	
func _find_closest_cell(target_pos: Vector2) -> Cell:
	var min_dist := INF
	var result: Cell = null
	for row in _cells:
		for cell in row:
			"""if cell.is_disabled:
				continue"""
			var center = cell.rect.position + cell.rect.size / 2
			var dist = center.distance_to(target_pos)
			if dist < min_dist:
				min_dist = dist
				result = cell
	return result
	
func _count_path_cells() -> int:
	var count = 0
	for row in _cells:
		for cell in row:
			if cell.is_on_path: count += 1
	return count

func get_platforms() -> Array:
	var platforms := []
	for row in _cells:
		for cell in row:
			if cell.is_on_path && !cell.is_disabled:
				platforms.append(cell.rect)
	
	return platforms

func get_bottom_platforms() -> Array:
	var platforms := []
	var last_row = _cells[-1]
	for cell in last_row:
		if cell.is_on_path:
			platforms.append(cell.rect)
	return platforms

# Внутренние методы реализации
func _find_exit_near(exit_point: DirectedPoint, exit_window: DirectedWindow):
	var exit_pos = exit_point.get_cords()
	if exit_point.direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]:
		exit_pos = exit_point.get_cords() + Vector2(2, 3)
	else:
		exit_pos = exit_point.get_cords() + Vector2(0, 2)
	var min_dist := INF
	var exit_row := _calculate_exit_row(exit_pos.y)
	
	if exit_row >= _cells.size():
		return
	
	for col in _cells[exit_row].size():
		var cell = _cells[exit_row][col]
		var dist = abs(cell.rect.position.x + cell.rect.size.x/2 - exit_pos.x)
		var valid = _is_cell_valid(cell, exit_window)
		
		if dist < min_dist:
			min_dist = dist
			_exit_cell = cell
			_pre_exit_cell = _find_pre_exit_cell(cell, exit_point)

func _create_control_points():
	var control_cells := []
	for row in range(1, _cells.size()):
		for cell in _cells[row]:
			if !cell.is_disabled && randf() < 0.1:
				control_cells.append(cell)
	
	control_cells.shuffle()
	control_cells = control_cells.slice(0, min(5, control_cells.size()))
	
	for control in control_cells:
		_bfs_search(control)

func _bfs_search(start_cell: Cell):
	var queue = [start_cell]
	var visited = {}
	var steps = 0
	var max_depth = 3  # Максимальная глубина поиска
	while !queue.is_empty() and steps < max_depth:
		var cell = queue.pop_front()
		if visited.has(cell):
			continue
			
		visited[cell] = true
		cell.is_on_path = true
		
		# Получаем только валидных соседей
		var neighbors = _get_valid_neighbors(cell).filter(
			func(n): return !visited.has(n)
		)
		
		# Добавляем случайность
		neighbors.shuffle()
		queue += neighbors.slice(0, 2)  # Не более 2 соседей на шаг
		
		steps += 1

func _do_post_process():
	for row in _cells:
		for cell in row:
			if cell.is_on_path:
				_expand_platform(cell)
				_adjust_borders(cell)

func _expand_platform(cell: Cell):
	var max_expansion = get_horizontal_step()
	var left = cell.rect.position.x
	var right = cell.rect.end.x
	
	# Расширение влево
	while left > 0 && _can_expand(cell, -1):
		left -= max_expansion
		cell.rect.position.x = left
		cell.rect.size.x += max_expansion
	
	# Расширение вправо
	while right < _max_width && _can_expand(cell, 1):
		right += max_expansion
		cell.rect.size.x += max_expansion

func _calculate_exit_point(original_exit: DirectedPoint) -> DirectedPoint:
	'''if _exit_cell && _pre_exit_cell:
		var x_pos = (_exit_cell.rect.position.x + _pre_exit_cell.rect.end.x) / 2
		var point = DirectedPoint.new(
			_rect,
			original_exit.direction,
			x_pos
		)
		printerr("Корды выхода которые считаются в calculate_exit_point")
		printerr(point.get_cords())
		return point'''
	return original_exit

# Вспомогательные методы
func _get_valid_neighbors(cell: Cell) -> Array:
	var neighbors := []
	var directions = [
		{ "row": -1, "col": 0 },  # Вверх
		{ "row": 1, "col": 0 },   # Вниз
		{ "row": 0, "col": -1 },  # Влево
		{ "row": 0, "col": 1 }    # Вправо
	]
	
	for dir in directions:
		var new_row = cell.row + dir["row"]
		var new_col = cell.column + dir["col"]
		
		if new_row >= 0 && new_row < _cells.size():
			if new_col >= 0 && new_col < _cells[new_row].size():
				var neighbor = _cells[new_row][new_col]
				if !neighbor.is_disabled:
					neighbors.append(neighbor)
	
	return neighbors

func _is_cell_valid(cell: Cell, exit_window: DirectedWindow) -> bool:
	var cell_center = cell.rect.position + cell.rect.size/2
	return exit_window.rect.has_point(cell_center)

static func get_horizontal_step() -> float:
	return get_platform_width() + _calc_horizontal_distance()

static func get_vertical_step() -> float:
	return get_platform_height() + _calc_vertical_distance()

static func _calc_horizontal_distance() -> float:
	var g = WorldProperties.get_property("GRAVITY")
	var h = get_vertical_step()
	var v = sqrt(2 * g * h)
	return (v * WorldProperties.get_property("RUN_SPEED")) / g

static func _calc_vertical_distance() -> float:
	return WorldProperties.get_property("JUMP_HEIGHT") - get_platform_height()

func get_start_y_pos() -> float:
	return _rect.position.y

func _create_paths():
	# Создание основных путей через BFS
	for cell in _get_start_cells():
		_bfs_path(cell)
	
	# Добавление случайных ответвлений
	_add_random_branches()

func _calculate_exit_row(y_pos: float) -> int:
	var relative_y = y_pos - get_start_y_pos()
	return clamp(int(relative_y / get_vertical_step()), 0, _cells.size() - 1)

func _find_pre_exit_cell(exit_cell: Cell, exit_point: DirectedPoint) -> Cell:
	var exit_dir = exit_point.direction
	var candidates = []
	
	# Проверяем ячейки в направлении выхода
	if exit_dir == 2:  # Влево
		if exit_cell.column < _cells[exit_cell.row].size() - 1:
			candidates.append(_cells[exit_cell.row][exit_cell.column + 1])
	elif exit_dir == 3:  # Вправо
		if exit_cell.column > 0:
			candidates.append(_cells[exit_cell.row][exit_cell.column - 1])
	elif exit_dir == 0: # Вверх
		if exit_cell.row < _cells.size() - 1:
			candidates.append(_cells[exit_cell.row + 1][exit_cell.column if _cells[exit_cell.row + 1].size() > exit_cell.column else -1])
	elif exit_dir == 1: # Вниз
		if exit_cell.row > 0:
			candidates.append(_cells[exit_cell.row - 1][exit_cell.column if _cells[exit_cell.row - 1].size() > exit_cell.column else -1])
	
	# Если нет кандидатов, ищем любых соседей
	if candidates.is_empty():
		candidates = _get_valid_neighbors(exit_cell)
	
	return candidates[0] if !candidates.is_empty() else null

func _adjust_borders(cell: Cell):
	# Проверка и корректировка границ с соседями
	var neighbors = _get_all_neighbors(cell)
	for neighbor in neighbors:
		if neighbor.is_on_path:
			_align_borders(cell, neighbor)

func _can_expand(cell: Cell, direction: int) -> bool:
	var test_rect = cell.rect.grow_individual(
		abs(direction) * get_horizontal_step() if direction in [-1, 1] else 0,
		0,
		abs(direction) * get_horizontal_step() if direction in [-1, 1] else 0,
		0
	)
	
	# Проверка столкновений
	for blocked in _blocked_regions:
		if test_rect.intersects(blocked, true):
			return false
	
	# Проверка других платформ
	for row in _cells:
		for other in row:
			if other != cell && test_rect.intersects(other.rect, true):
				return false
	
	return true

# Вспомогательные методы
func _get_start_cells() -> Array:
	var starters := []
	for cell in _cells[0]:
		if !cell.is_disabled && randf() < 0.7:
			starters.append(cell)
	return starters

func _bfs_path(start_cell: Cell):
	var queue = [start_cell]
	var visited = {}
	
	while !queue.is_empty():
		var cell = queue.pop_front()
		visited[cell] = true
		cell.is_on_path = true
		
		var neighbors = _get_valid_neighbors(cell)
		neighbors.shuffle()
		
		for neighbor in neighbors:
			if !visited.get(neighbor, false) && randf() < 0.85:
				queue.append(neighbor)

func _add_random_branches():
	for i in range(3):
		var j = randi() % _cells.size()
		var random_cell = _cells[j][randi() % _cells[j].size()]
		if !random_cell.is_disabled:
			_bfs_path(random_cell)

func _get_all_neighbors(cell: Cell) -> Array:
	var neighbors := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 && dy == 0:
				continue
			var neighbor = _get_cell(cell.row + dy, cell.column + dx)
			if neighbor:
				neighbors.append(neighbor)
	return neighbors

func _align_borders(cell: Cell, neighbor: Cell):
	var axis = "x" if cell.rect.position.y == neighbor.rect.position.y else "y"
	var min_pos = min(cell.rect.position[axis], neighbor.rect.position[axis])
	var max_end = max(cell.rect.end[axis], neighbor.rect.end[axis])
	
	cell.rect.position[axis] = min_pos
	cell.rect.size[axis] = max_end - min_pos
	neighbor.rect = cell.rect

func _get_cell(row: int, column: int) -> Cell:
	if row < 0 || row >= _cells.size():
		return null
	if column < 0 || column >= _cells[row].size():
		return null
	return _cells[row][column]
	
func block_region_around_point(point: DirectedPoint, margin: float = 1.0) -> void:
	var point_pos = point.get_cords()
	var blocked_rect = Rect2(
		point_pos.x - margin,
		point_pos.y - margin,
		margin * 2,
		margin * 2
	)
	block_region(blocked_rect)
