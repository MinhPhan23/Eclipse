extends Node2D

@onready var choices_dialog: PanelContainer = $CanvasLayer/ChoicesDiaglog
@onready var win: bool = false
@onready var victory_laugh = $VictoryLaugh
@onready var lose_battle_jingle = $LoseBattleJingle

const GAME_OVER_DIALOG_CHOICES = ["Continue"]

# transition scenes to or from battle
var main: Node2D
var win_cutscene: Node2D
var lose_cutscene: Node2D
# location where the battle take place, init by location during scene switch
var location: Area2D
var _minion_name: String

func _ready() -> void:
	get_tree().call_group("entity", "reset")

func initialize_battle(main_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	main = main_scene
	location = location_scene

	hero.name = "Hero"
	hero.position = location.hero_spawn_pos
	hero.dead.connect(_on_hero_dead.unbind(1))
	add_child(hero)

	_minion_name = minion.name
	minion.position = location.minion_spawn_pos
	minion.dead.connect(_on_minion_dead.unbind(1))
	add_child(minion)
	# TODO: pause entities with a warmup timer

func initialize_final_battle(win_scene: Node2D, lose_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	location = location_scene
	win_cutscene = win_scene
	lose_cutscene = lose_scene
	
	hero.name = "Hero"
	hero.position = location.hero_spawn_pos
	hero.dead.connect(_on_hero_dead.unbind(1))
	add_child(hero)

	_minion_name = minion.name
	minion.position = location.minion_spawn_pos
	minion.dead.connect(_on_minion_dead.unbind(1))
	add_child(minion)

func _on_hero_dead():
	win = true
	victory_laugh.play()
	_game_over()
	
func _on_minion_dead():
	lose_battle_jingle.play()
	_game_over()
	
func _game_over():
	get_tree().call_group("entity", "stop")
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
	root.remove_child(battle_scene)
	
	if Globals.current_day >= Globals.MAX_DAYS:
		if win:
			root.add_child(win_cutscene)
			tree.set_current_scene(win_cutscene)
		else:
			# lose
			root.add_child(lose_cutscene)
			tree.set_current_scene(lose_cutscene)
	else:
		root.add_child(main)
		tree.set_current_scene(main)
		location.emit_battle_end_signal()
	queue_free()
