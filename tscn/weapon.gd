class_name Weapon
static var modifires = ["poison", "nothing", "blood"]
static var weapons = {}
static var modifire = "nothing"
static var modifire_damage = 0
static var modifire_duration = 0
static var weapon_damage = 0


static func new_weapon(level: int):
	var id = weapons.size()
	modifire = modifires.pick_random()
	modifire_damage = randi_range(0, level) / 2
	modifire_duration = randi_range(0, 3)
	weapon_damage = level * 2
	weapons[id] = [modifire, modifire_damage, modifire_duration, weapon_damage]
	return id

static func get_modifire(id: int):
	return weapons[id][0]

static func get_modifire_damage(id: int):
	return weapons[id][1]

static func get_modifire_duration(id: int):
	return weapons[id][2]

static func get_weapon_damage(id: int):
	return weapons[id][3]

static func get_icon():
	return preload("res://assets/weapons/8.png")
