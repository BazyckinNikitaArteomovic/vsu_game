class_name Pathfinding

func is_level_connected(rooms: Array, tile_map: TileMap, player_size: Vector2i) -> bool:
	if rooms.is_empty():
		return false
	
	var visited = []
	var queue = [rooms[0]]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if visited.has(current):
			continue
		
		visited.append(current)
		
		for next_room in rooms:
			if next_room == current:
				continue
			
			if can_reach(current, next_room, tile_map, player_size):
				queue.append(next_room)
	
	return visited.size() == rooms.size()

func can_reach(room_a: Room, room_b: Room, tile_map: TileMap, player_size: Vector2i) -> bool:
	# Проверка, что между комнатами есть проход
	return true  # Упрощенная реализация
