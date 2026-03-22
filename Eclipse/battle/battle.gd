extends Node2D

@onready var choices_dialog: PanelContainer = $CanvasLayer/ChoicesDiaglog
@onready var win: bool = false

const GAME_OVER_DIALOG_CHOICES = ["Continue"]

# the scene that initialize scene switch to battle
var main: Node2D
# location where the battle take place, init by location during scene switch
var location: Area2D

func initialize_battle(main_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	main = main_scene
	location = location_scene

	hero.name = "Hero"
	hero.position = location.hero_spawn_pos
	hero.dead.connect(_on_hero_dead)
	hero.TARGET = minion # TODO extract this to location
	add_child(hero)

	minion.name = "Minion"
	minion.position = location.minion_spawn_pos
	minion.dead.connect(_on_minion_dead)
	
	# TODO: pause entities with a warmup timer
	
	add_child(minion)

func _on_hero_dead():
	win = true
	_game_over()
	
func _on_minion_dead():
	_game_over()
	
func _game_over():
	var hero = $Hero
	var minion = $Minion
	
	# Stop movement
	get_tree().call_group("entity", "stop")
	
	# Compute battle statistics
	if (win):
		minion.level_up()
	else:
		hero.level_up()
	
	# Show game over dialog
	_display_dialog()

func _display_dialog():
	var win_status_msg: String
	
	if (win):
		win_status_msg = "Victory"
	else:
		win_status_msg = "Defeat"
	choices_dialog.label_text = win_status_msg
	choices_dialog.choices = GAME_OVER_DIALOG_CHOICES
	choices_dialog.show()

func _on_choices_diaglog_selected(_index: int):
	var hero = $"Hero"
	var minion = $"Minion"
	
	var tree = get_tree()
	var root = tree.get_root()
	var battle_scene = tree.get_current_scene()
	
	remove_child(hero)
	remove_child(minion)
	
	if (win):
		location.hero_remove()
	else:
		hero.level += 1
		minion.dead.emit(minion)
	
	
	root.add_child(main)
	root.remove_child(battle_scene)
	tree.set_current_scene(main)
	queue_free()
