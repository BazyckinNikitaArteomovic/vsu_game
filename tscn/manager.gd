extends Node

@onready var pause_menu = $"../Stats/PauseMenu"
var game_paused: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		game_paused = !game_paused
		
	if game_paused:
		get_parent().get_tree().paused = true
		pause_menu.show()
	else:
		get_parent().get_tree().paused = false
		pause_menu.hide()


func _on_resume_pressed() -> void:
	game_paused = !game_paused


func _on_quit_pressed() -> void:
	get_parent().get_tree().paused = false
	get_parent().get_tree().change_scene_to_file("res://tscn/start_screen.tscn")
