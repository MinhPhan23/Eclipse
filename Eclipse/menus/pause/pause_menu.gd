extends Control

signal pause
signal unpause
signal close_menu
signal open_controls

func _input(event):
	if event.is_action_pressed("menu"):
		if !get_tree().paused:
			pause.emit()
			get_tree().paused = true
		else:
			get_tree().paused = false
			unpause.emit()

func _on_new_game_pressed():
	var new_game: PackedScene = load("res://cutscenes/intro_cutscene.tscn")
	Globals.new_game()
	get_tree().paused = false
	get_tree().change_scene_to_packed(new_game)

func _on_controls_pressed():
	open_controls.emit()

func _on_game_pressed():
	close_menu.emit()

func _on_main_pressed():
	var menu: PackedScene = load("res://menus/main/main_menu.tscn")
	get_tree().paused = false
	get_tree().change_scene_to_packed(menu)
