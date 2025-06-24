# split_and_fill_generator.gd
class_name SplitAndFillGenerator extends RefCounted

const MIN_REGION_SQUARE := 20.0
const BORDER_SIZE := 0.0
const SPLIT_DEVIATION_RATE := 0.382

var _strategies := {}
var _current_components := []
var _min_strategy_width := 20.0
var _min_strategy_height := 20.0

func _init():
	_strategies = {
		"Pyramid": PyramidStrategy.new(),
		"Grid": GridStrategy.new()
	}
	#_calculate_min_sizes()

func generate_region(region: DirectedRegion, enter_window: DirectedWindow) -> Array:
	print("[Generator] Starting generation for region: ", region.enter_point.position, "  ", region._exit_point.position)
	_current_components = []
	var root = RegionTree.new(region)
	_process_region(root, 0)
	_add_outer_borders(region, root, enter_window)
	print("[Generator] Generation completed. Components count: ", _current_components.size())
	return _current_components.duplicate()

class RegionTree:
	var region: DirectedRegion
	var left: RegionTree
	var right: RegionTree
	
	func _init(r: DirectedRegion):
		region = r

class SplitVariant:
	var enter_rect: Rect2
	var exit_rect: Rect2
	var traverse_dir: int
	
	func _init(enter_r: Rect2, exit_r: Rect2, dir: int):
		enter_rect = enter_r
		exit_rect = exit_r
		traverse_dir = dir

func _process_region(node: RegionTree, depth: int):
	print("Processing region: ", node.region.rect, " Depth: ", depth)
	if depth > 50:  # Добавляем ограничение глубины рекурсии
		print("Max recursion depth reached, applying fallback strategy")
		_apply_strategy(_strategies.values()[0], node.region)
		return
	
	# Если регион слишком мал для разделения, пробуем применить стратегию
	if node.region.rect.size.x < _min_strategy_width * 2 || node.region.rect.size.y < _min_strategy_height * 2:
		print("Region too small for splitting, trying strategies")
		var strategy = _select_strategy(node.region)
		if strategy:
			_apply_strategy(strategy, node.region)
		return
	
	if _try_split(node, depth):
		return
	"""if _try_cut(node):
		return"""
	var strategy = _select_strategy(node.region)
	if strategy:
		print("Applying strategy: ", strategy.get_name())
		_apply_strategy(strategy, node.region)
		return
	else:
		print("No suitable strategy found for region: ", node.region.rect)

func _try_split(node: RegionTree, depth: int) -> bool:
	print("Trying split for region: ", node.region.rect)
	var variants = _get_split_variant(node.region)
	for variant in variants:
		if _try_split_variant(node, variant, depth):
			return true
	return false

func _region_is_valid_for_strategy(rect: Rect2, window: DirectedWindow, strategy: FillStrategy) -> bool:
	return (
		rect.size.x >= (strategy.get_min_width())  && 
		rect.size.y >= (strategy.get_min_height())
	)

func _can_apply_strategy_to_cut(region: DirectedRegion) -> bool:
	for strategy in _strategies.values():
		if _can_apply_strategy(strategy, region):
			return true
	return false
	
func _get_split_variant(region: DirectedRegion):
	var variants = []
	if region.enter_point.direction in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]:
		var v_window_size = 4
		_add_split_in_range(variants, region, 0, region.enter_point.position - v_window_size, false, true)
		_add_split_in_range(variants, region, region.enter_point.position, region.rect.size.y, false, false)
	else:
		_add_split_in_range(variants, region, 0, region.rect.size.y, false, region.enter_point.direction == DirectionHelper.Directions.UP)
	
	if region.enter_point.direction in [DirectionHelper.Directions.UP, DirectionHelper.Directions.DOWN]:
		var h_window_size = 3
		_add_split_in_range(variants, region, 0, region.enter_point.position - h_window_size, true, true)
		_add_split_in_range(variants, region, region.enter_point.position + h_window_size, region.rect.size.x, true, false)
	else:
		_add_split_in_range(variants, region, 0, region.rect.size.x, true, region.enter_point.direction == DirectionHelper.Directions.LEFT)
	
	var horizontal_weight = region.rect.size.x / region.rect.size.y
	var vertical_weight = region.rect.size.y / region.rect.size.x
	horizontal_weight *= horizontal_weight
	vertical_weight *= vertical_weight
	var weights = []
	for variant in variants:
		if variant.traverse_dir in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]:
			weights.append(horizontal_weight)
		else:
			weights.append(vertical_weight)
	_do_random_weights_sort(variants, weights)
	return variants
	
func _do_random_weights_sort(array: Array, weights: Array):
	var copy = array.duplicate()
	var copy_weights = weights.duplicate()
	array.clear()
	var total = 0
	
	for weight in copy_weights:
		total += weight
	while (!copy.is_empty()):
		var value = randf() * total
		var number = 0
		if value > 0:
			var sum = 0
			while (sum < value):
				sum += copy_weights[number]
				number += 1
			number -= 1
		total -= copy_weights[number]
		array.append(copy[number])
		copy.remove_at(number)
		copy_weights.remove_at(number)

func _add_split_in_range(variants: Array, region: DirectedRegion, range_start: float, range_end: float, is_horizontal_split: bool, exit_is_first: bool):
	var min_side_size = (_min_strategy_width if is_horizontal_split else _min_strategy_height)
	var side_size = (region.rect.size.x if is_horizontal_split else region.rect.size.y)
	range_start = max(range_start, min_side_size)
	range_end = min(range_end, side_size - min_side_size)
	var another_side_size = (region.rect.size.x if not is_horizontal_split else region.rect.size.y)
	var min_side_size_by_square = MIN_REGION_SQUARE / another_side_size
	range_start = max(range_start, min_side_size_by_square)
	range_end = min(range_end, side_size - min_side_size_by_square)
	var exit_is_horizontal = not region.exit_window.is_horizontal()
	if exit_is_horizontal == is_horizontal_split:
		var exit_start = region.exit_window.start
		var exit_end = region.exit_window.end
		var v_window_size = 4
		var h_window_size = 3
		var min_exit_size = (h_window_size if exit_is_horizontal else v_window_size)
		if exit_is_first:
			range_start = max(range_start, exit_start + min_exit_size)
		else:
			range_end = min(range_end, exit_end - min_exit_size)
	if range_end - range_start >= 0:
		var variant = _make_split_in_range(region, range_start, range_end, is_horizontal_split)
		if variant != null:
			variants.append(variant)
	
func _make_split_in_range(region: DirectedRegion, range_start: float, range_end: float, is_horizontal_split: bool):
	var side_size = (region.rect.size.x if is_horizontal_split else region.rect.size.y)
	var split_pos = side_size / 2 * (1 + randf_range(-SPLIT_DEVIATION_RATE, SPLIT_DEVIATION_RATE))
	split_pos = max(split_pos, range_start)
	split_pos = min(split_pos, range_end)
	split_pos = WorldProperties.bind_to_grid(split_pos)
	
	var first_rect: Rect2
	var second_rect: Rect2
	
	if is_horizontal_split:
		first_rect = Rect2(region.rect.position, Vector2(split_pos, region.rect.size.y))
		second_rect = Rect2(region.rect.position + Vector2(split_pos, 0), 
						  Vector2(region.rect.size.x - split_pos, region.rect.size.y))
	else:
		first_rect = Rect2(region.rect.position, Vector2(region.rect.size.x, split_pos))
		second_rect = Rect2(region.rect.position + Vector2(0, split_pos), 
						  Vector2(region.rect.size.x, region.rect.size.y - split_pos))
	
	var enter_rect
	var exit_rect
	var enter_part_is_first
	var enter_dir = region.enter_point.direction
	var enter_pos = region.enter_point.get_cords()
	var is_horizontal_enter = enter_dir in [DirectionHelper.Directions.LEFT, DirectionHelper.Directions.RIGHT]
	
	if is_horizontal_enter != is_horizontal_split:
		if is_horizontal_split:
			enter_part_is_first = enter_pos.x < region.rect.position.x + split_pos
		else:
			enter_part_is_first = enter_pos.y < region.rect.position.y + split_pos
	else:
		enter_part_is_first = enter_dir == DirectionHelper.Directions.LEFT || enter_dir == DirectionHelper.Directions.UP
	
	if enter_part_is_first:
		enter_rect = first_rect
		exit_rect = second_rect
	else:
		enter_rect = second_rect
		exit_rect = first_rect
	
	var traverse_direction = ((DirectionHelper.Directions.LEFT if enter_part_is_first else DirectionHelper.Directions.RIGHT) 
	if is_horizontal_split else (DirectionHelper.Directions.UP if enter_part_is_first else DirectionHelper.Directions.DOWN))
	if not enter_rect.has_point(enter_pos + Vector2(-1 if enter_dir == DirectionHelper.Directions.RIGHT else 0, -1 if enter_dir == DirectionHelper.Directions.DOWN else 0) + Vector2(1 if enter_dir == DirectionHelper.Directions.LEFT else 0, 1 if enter_dir == DirectionHelper.Directions.UP else 0)):
		printerr("Enter point not in enter_rect after split!", enter_rect, "  ", enter_pos)
		printerr("Enter rect: ", enter_rect.position, enter_rect.size)
		printerr("Enter point: ", enter_pos)
		return null
	if not exit_rect.has_point(region.exit_window.get_cells()[0] + Vector2(-1 if region.exit_window.direction == DirectionHelper.Directions.RIGHT else 0, -1 if region.exit_window.direction == DirectionHelper.Directions.DOWN else 0) + Vector2(1 if region.exit_window.direction == DirectionHelper.Directions.LEFT else 0, 1 if region.exit_window.direction == DirectionHelper.Directions.UP else 0)):
		printerr("Exit point not in exit_rect after split, is it in enter_rect: ", enter_rect.has_point(region.exit_window.get_cells()[0]))
		printerr("Exit rect: ", exit_rect.position, exit_rect.size)
		printerr("Exit window: ", region.exit_window.get_cells()[0])
		return null
	return SplitVariant.new(enter_rect, exit_rect, traverse_direction)
	

func _try_split_variant(node: RegionTree, variant: SplitVariant, depth: int) -> bool:
	print("Trying split variant: enter_rect = ", variant.enter_rect, ", exit_rect = ", variant.exit_rect)
	var exit_rect_window = node.region.exit_window.to_another_rect(variant.exit_rect)
	if exit_rect_window == null:
		print("exit_rect_window is null for exit_rect: ", variant.exit_rect)
		return false
	if variant.enter_rect.size.x < _min_strategy_width || variant.enter_rect.size.y < _min_strategy_height || variant.exit_rect.size.x < _min_strategy_width || variant.exit_rect.size.y < _min_strategy_height:
		return false
	
	var valid_pairs = []
	for exit_strategy in _strategies.values():
		if !_region_is_valid_for_strategy(variant.exit_rect, exit_rect_window, exit_strategy):
			print(2)
			continue
		if exit_strategy.get_name() == "Pyramid":
			continue
		var enter_windows = exit_strategy.try_fill(variant.exit_rect, exit_rect_window)
		for enter_window in enter_windows:
			if enter_window.direction != variant.traverse_dir:
				continue
			var traverse_window = enter_window.to_another_rect(variant.enter_rect)
			var enter_subregion = DirectedRegion.new(
				variant.enter_rect,
				node.region.enter_point.to_another_rect(variant.enter_rect),
				traverse_window
			)
			
			for enter_strategy in _strategies.values():
				if _can_apply_strategy(enter_strategy, enter_subregion):
					valid_pairs.append({
						"enter_strategy": enter_strategy,
						"exit_strategy": exit_strategy,
						"traverse_window": traverse_window
					})
	
	if valid_pairs.is_empty():
		print("No valid strategy pairs found for variant")
		return false
	var selected_pair = valid_pairs[randi() % valid_pairs.size()]
	node.left = RegionTree.new(DirectedRegion.new(
		variant.enter_rect,
		node.region.enter_point.to_another_rect(variant.enter_rect),
		selected_pair.traverse_window
	))
	
	node.right = RegionTree.new(DirectedRegion.new(
		variant.exit_rect,
		node.left.region.get_exit_point().to_another_rect(variant.exit_rect),
		exit_rect_window
	))
	
	_process_region(node.left, depth + 1)
	_process_region(node.right, depth + 1)
	#_add_borders(node, selected_pair.traverse_window)
	return true

func _try_cut(node: RegionTree) -> bool:
	print("Trying cut for region: ", node.region.rect)
	var cut_variants = _get_cut_variants(node.region)
	for variant in cut_variants:
		if _try_cut_variant(node, variant):
			print(1)
			return true
	return false

func _try_cut_variant(node: RegionTree, variant: CutVariant) -> bool:
	# Проверяем, что регион действительно изменится
	if variant.main_rect == node.region.rect:
		printerr("ERROR: Cut variant doesn't change region size!")
		return false
	
	# Добавляем вырезанную часть
	_current_components.append(PlatformComponent.new(variant.cut_rect))
	
	# Создаем новый регион с обновленными параметрами
	var new_enter_point = node.region.enter_point.to_another_rect(variant.main_rect)
	var new_exit_window = node.region.exit_window.to_another_rect(variant.main_rect)
	if (not new_exit_window) or (not new_enter_point):
		return false
	# Явно проверяем преобразование точек
	if new_enter_point.rect != variant.main_rect or new_exit_window.rect != variant.main_rect:
		printerr("ERROR: Point conversion failed!")
		return false
	
	node.region = DirectedRegion.new(
		variant.main_rect,
		new_enter_point,
		new_exit_window
	)
	
	# Пропускаем обработку если регион слишком мал
	if variant.main_rect.size.x < 7 or variant.main_rect.size.y < 7:
		return true
		
	_process_region(node, 0)
	return true

func _apply_strategy(strategy: FillStrategy, region: DirectedRegion):
	var exit_point = strategy.fill(region, _current_components)
	_current_components.append(DebugRegionComponent.new(region, strategy.get_name()))

func _get_split_variants(region: DirectedRegion) -> Array:
	var variants = []
	var rect = region.rect
	
	# Vertical split
	var vertical_split = _calculate_split(rect, false)
	if vertical_split:
		variants.append(vertical_split)
	
	# Horizontal split
	var horizontal_split = _calculate_split(rect, true)
	if horizontal_split:
		variants.append(horizontal_split)
	
	variants.shuffle()
	return variants

func _calculate_split(rect: Rect2, is_horizontal: bool) -> SplitVariant:
	var split_pos = rect.size.x / 2 if is_horizontal else rect.size.y / 2
	split_pos = WorldProperties.bind_to_grid(split_pos * (1 + randf_range(-SPLIT_DEVIATION_RATE, SPLIT_DEVIATION_RATE)))
	
	var first_rect: Rect2
	var second_rect: Rect2
	
	if is_horizontal:
		first_rect = Rect2(rect.position, Vector2(split_pos, rect.size.y))
		second_rect = Rect2(rect.position + Vector2(split_pos + BORDER_SIZE, 0), 
						  Vector2(rect.size.x - split_pos - BORDER_SIZE, rect.size.y))
	else:
		first_rect = Rect2(rect.position, Vector2(rect.size.x, split_pos))
		second_rect = Rect2(rect.position + Vector2(0, split_pos + BORDER_SIZE), 
						  Vector2(rect.size.x, rect.size.y - split_pos - BORDER_SIZE))
	
	return SplitVariant.new(first_rect, second_rect, 
						  DirectionHelper.Directions.LEFT if is_horizontal else DirectionHelper.Directions.UP)

func _get_cut_variants(region: DirectedRegion) -> Array:
	var variants = []
	var rect = region.rect
	
	# Вертикальный разрез (сверху)
	var cut_height = min(7, rect.size.y * 0.3)  # Макс 224px или 30% высоты
	if cut_height > 0:
		variants.append(CutVariant.new(
			Rect2(rect.position + Vector2(0, cut_height), Vector2(rect.size.x, rect.size.y - cut_height)), # Основной регион
			Rect2(rect.position, Vector2(rect.size.x, cut_height)), # Вырезанная часть
			DirectionHelper.Directions.UP
		))
	
	# Горизонтальный разрез (слева)
	var cut_width = min(7, rect.size.x * 0.3)  # Макс 224px или 30% ширины
	if cut_width > 0:
		variants.append(CutVariant.new(
			Rect2(rect.position + Vector2(cut_width, 0), Vector2(rect.size.x - cut_width, rect.size.y)), # Основной регион
			Rect2(rect.position, Vector2(cut_width, rect.size.y)), # Вырезанная часть
			DirectionHelper.Directions.LEFT
		))
	
	return variants

func _calculate_cut_rect(rect: Rect2, dir: DirectionHelper.Directions, size: float) -> Rect2:
	match dir:
		DirectionHelper.Directions.LEFT:
			return Rect2(rect.position, Vector2(size, rect.size.y))
		DirectionHelper.Directions.RIGHT:
			return Rect2(rect.position + Vector2(rect.size.x - size, 0), Vector2(size, rect.size.y))
		DirectionHelper.Directions.UP:
			return Rect2(rect.position, Vector2(rect.size.x, size))
		DirectionHelper.Directions.DOWN:
			return Rect2(rect.position + Vector2(0, rect.size.y - size), Vector2(rect.size.x, size))
	return Rect2()

func _add_borders(node: RegionTree, window: DirectedWindow):
	var border_rect = Rect2(
		window.rect.position - Vector2.ONE * BORDER_SIZE,
		window.rect.size + Vector2.ONE * BORDER_SIZE * 2
	)
	_current_components.append(PlatformComponent.new(border_rect))

func _calculate_min_sizes():
	var min_widths = []
	var min_heights = []
	for strategy in _strategies.values():
		min_widths.append(strategy.get_min_width())
		min_heights.append(strategy.get_min_height())
	_min_strategy_width = min_widths.min()
	_min_strategy_height = min_heights.min()

func _select_strategy(region: DirectedRegion) -> FillStrategy:
	var valid_strategies = []
	for strategy in _strategies.values():
		if _can_apply_strategy(strategy, region):
			valid_strategies.append(strategy)
	if valid_strategies.is_empty() and _strategies.size() > 0:
		# Fallback - используем простую стратегию для больших регионов
		print("No standard strategies found, using fallback")
		return _strategies.values()[0]
	
	return valid_strategies[randi() % valid_strategies.size()] if valid_strategies else null

func _can_apply_strategy(strategy: FillStrategy, region: DirectedRegion) -> bool:
	
	var try_fill_result = strategy.try_fill(region.rect, region.exit_window)
	
	return (region.rect.size.x >= (strategy.get_min_width())  && 
			region.rect.size.y >= (strategy.get_min_height()) &&
			!try_fill_result.is_empty())

func _add_outer_borders(region: DirectedRegion, root: RegionTree, enter_window: DirectedWindow):
	var border_size = WorldProperties.get_property("BORDER_SIZE")
	var corners = [
		Rect2(region.rect.position - Vector2.ONE * border_size, Vector2.ONE * border_size),
		Rect2(region.rect.position + Vector2(region.rect.size.x, -border_size), Vector2.ONE * border_size),
		Rect2(region.rect.position + Vector2(-border_size, region.rect.size.y), Vector2.ONE * border_size),
		Rect2(region.rect.position + region.rect.size, Vector2.ONE * border_size)
	]
	
	for corner in corners:
		if corner.size.x > 0 and corner.size.y > 0:
			_current_components.append(PlatformComponent.new(corner))

class CutVariant:
	var main_rect: Rect2
	var cut_rect: Rect2
	var direction: int
	
	func _init(m_r: Rect2, c_r: Rect2, dir: int):
		main_rect = m_r
		cut_rect = c_r
		direction = dir
