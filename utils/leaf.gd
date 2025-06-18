class_name Leaf
extends RefCounted

var x: int
var y: int
var width: int
var height: int
var left_child: Leaf = null
var right_child: Leaf = null
var room: Rect2i
var split_vertical: bool = false

func _init(X: int, Y: int, Width: int, Height: int):
	x = X
	y = Y
	width = Width
	height = Height

func is_leaf() -> bool:
	return left_child == null and right_child == null

func split(min_size: int, max_size: int) -> bool:
	if not is_leaf():
		return false
	
	var split_horizontal = randf() < 0.5
	if width > height and float(width) / height >= 1.25:
		split_horizontal = false
	elif height > width and float(height) / width >= 1.25:
		split_horizontal = true
	
	var max_split = (height if split_horizontal else width) - min_size
	if max_split < min_size:
		return false
	
	var split_val = randi_range(min_size, max_split)
	
	if split_horizontal:
		left_child = Leaf.new(x, y, width, split_val)
		right_child = Leaf.new(x, y + split_val, width, height - split_val)
	else:
		left_child = Leaf.new(x, y, split_val, height)
		right_child = Leaf.new(x + split_val, y, width - split_val, height)
	
	split_vertical = not split_horizontal
	return true

func get_some_room() -> Rect2i:
	if is_leaf():
		return room
	var left_room = left_child.get_some_room()
	if left_room.size != Vector2i.ZERO:
		return left_room
	return right_child.get_some_room()

func create_rooms():
	if is_leaf():
		var min_room_size = 5
		var room_width = randi_range(min_room_size, width)
		var room_height = randi_range(min_room_size, height)
		var room_x = x + randi_range(0, width - room_width)
		var room_y = y + randi_range(0, height - room_height)
		room = Rect2i(room_x, room_y, room_width, room_height)
		print("Room created at: ", room)
	else:
		left_child.create_rooms()
		right_child.create_rooms()
