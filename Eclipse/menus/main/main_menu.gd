extends Control

@onready var controls: CanvasLayer = $Controls

func _on_start_pressed():
	# Starts a new game
	var game_scene = load("res://cutscenes/intro_cutscene.tscn")
	Globals.new_game()
	get_tree().change_scene_to_packed(game_scene)

func _on_controls_pressed():
	# Opens control menu
	controls.show()

func _on_control_menu_close_menu():
	controls.hide()

func _on_quit_pressed():
	get_tree().quit()
