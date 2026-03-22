extends Node2D

@onready var choices_dialog: PanelContainer = $CanvasLayer/ChoicesDiaglog
@onready var win: bool = false

const GAME_OVER_DIALOG_CHOICES = ["Continue"]

# the scene that initialize scene switch to battle
var main: Node2D
# location where the battle take place, init by location during scene switch
var location: Area2D
var _minion_name: String

func initialize_battle(main_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	main = main_scene
	location = location_scene

	hero.name = "Hero"
	hero.position = location.hero_spawn_pos
	hero.dead.connect(_on_hero_dead)
	hero.run()
	add_child(hero)

	_minion_name = minion.name
	minion.position = location.minion_spawn_pos
	minion.dead.connect(_on_minion_dead.unbind(1))
	minion.run()
	add_child(minion)
	
	# TODO: pause entities with a warmup timer

func _on_hero_dead():
	win = true
	_game_over()
	
func _on_minion_dead():
	_game_over()
	
func _game_over():
	get_tree().call_group("entity", "reset")
	if (win):
		var minion = get_node("/root/Battle/"+_minion_name)
		minion.level_up()
		remove_child(minion)
	else:
		var hero = $"Hero"
		hero.level_up()
		remove_child(hero)
	
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
	var tree = get_tree()
	var root = tree.get_root()
	var battle_scene = tree.get_current_scene()
	
	root.add_child(main)
	root.remove_child(battle_scene)
	tree.set_current_scene(main)
	location.end_battle.emit()
	queue_free()
