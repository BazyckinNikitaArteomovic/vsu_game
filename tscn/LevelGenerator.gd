extends Node2D

@onready var level_generator = preload("res://generators/bsp_generator.gd").new()
@onready var tile_map = $TileMap
@onready var Character = $Character

func _ready():
	level_generator.generate_level(Character, tile_map)
