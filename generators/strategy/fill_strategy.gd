# fill_strategy.gd
class_name FillStrategy extends RefCounted

# Абстрактный класс, требует реализации в наследниках
func get_name() -> String:
	push_error("FillStrategy.get_name() must be overridden")
	return ""

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array[DirectedWindow]:
	push_error("FillStrategy.try_fill() must be overridden")
	return []

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	push_error("FillStrategy.fill() must be overridden")
	return DirectedPoint.new(Rect2(), DirectionHelper.Directions.UP, 0.0)

func get_min_width() -> float:
	push_error("FillStrategy.get_min_width() must be overridden")
	return 0.0

func get_min_height() -> float:
	push_error("FillStrategy.get_min_height() must be overridden")
	return 0.0
