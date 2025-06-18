class_name WorldProperties

static var _properties: Dictionary = {
	"GRID_STEP": 1.0  # Значение по умолчанию
}

static func initialize(params: Dictionary):
	_properties.merge(params, true)  # Объединяем с переданными параметрами

static func bind_to_grid(value: float) -> float:
	var step = _properties.get("GRID_STEP", 32.0)
	return floor(value / step) * step

static func get_property(name: String) -> float:
	return _properties.get(name, 0.0)

static func has_property(name: String) -> bool:
	return name in _properties  # Предполагая, что свойства хранятся в _properties
