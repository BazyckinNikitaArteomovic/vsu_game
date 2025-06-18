class_name DirectedRegion extends RefCounted

var rect: Rect2
var enter_point: DirectedPoint
var exit_window: DirectedWindow
var _exit_point: DirectedPoint  # Добавляем приватное поле

func _init(r: Rect2, ep: DirectedPoint, ew: DirectedWindow):
	rect = r
	enter_point = ep
	exit_window = ew
	# Рассчитываем exit_point на основе exit_window
	_exit_point = DirectedPoint.new(
		rect,
		exit_window.direction,
		(exit_window.start + exit_window.end) / 2.0  # Центр окна
	)

# Метод для получения точки выхода
func get_exit_point() -> DirectedPoint:
	return _exit_point

# Метод для обновления точки выхода (если потребуется)
func set_exit_point(point: DirectedPoint):
	_exit_point = point
