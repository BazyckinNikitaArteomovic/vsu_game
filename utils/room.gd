class_name Room

var rect: Rect2i
var entrance: Vector2i
var exit_window: Rect2i
var spawn_regions: Array[Rect2i] = []

func _init(rect: Rect2i, entrance: Vector2i, exit_window: Rect2i):
	self.rect = rect
	self.entrance = entrance
	self.exit_window = exit_window
	generate_spawn_regions()

func generate_spawn_regions():
	# Генерация безопасных зон для спавна
	var region_size = Vector2i(2, 2)
	for i in range(3):
		var x = randi_range(rect.position.x + 2, rect.end.x - 4)
		var y = randi_range(rect.position.y + 2, rect.end.y - 4)
		spawn_regions.append(Rect2i(x, y, region_size.x, region_size.y))
