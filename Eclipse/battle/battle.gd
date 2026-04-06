extends Node2D


var battle_start_panel: PanelContainer
@onready var choices_dialog: PanelContainer = $UI/ChoicesDialog
@onready var win: bool = false
@onready var music: AudioStreamPlayer
@onready var victory_laugh = $VictoryLaugh
@onready var lose_battle_jingle = $LoseBattleJingle

# Map
@onready var current_map: TileMap = $Maps/PlainsMap

# Menu Layers
@onready var pause_menu: Control = $UI/PauseMenu
@onready var control_menu: Control = $UI/ControlMenu

const GAME_OVER_DIALOG_CHOICES = ["Continue"]

# transition scenes to or from battle
var main: Node2D
var win_cutscene: Node2D
var lose_cutscene: Node2D
# location where the battle take place, init by location during scene switch
var location: Area2D
var _minion_name: String
var _hero_name: String

var rng: RandomNumberGenerator
var mage_spawn_locs = [
		Vector2(182,214),
		Vector2(826,156),
		Vector2(1536,222),
		Vector2(1412,827),
		Vector2(775,840),
		Vector2(525,573),
		Vector2(814,464)
	]
var minion_spawn_locs = [
		Vector2(307,274),
		Vector2(559,58),
		Vector2(1361,94),
		Vector2(1253,905),
		Vector2(763,988),
		Vector2(264,773),
		Vector2(694,378)
	]


func _ready() -> void:
	music.play()
	get_tree().call_group("entity", "reset")

func initialize_battle(main_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	main = main_scene
	location = location_scene
	rng = RandomNumberGenerator.new()
	battle_start_panel = $UI/BattleStartPanel
	
	_hero_name = hero.name
	var i = rng.randi_range(0, 6)
	hero.position = mage_spawn_locs[i]
	hero.dead.connect(_on_hero_dead.unbind(1))
	add_child(hero)

	_minion_name = minion.name
	i = rng.randi_range(0, 6)
	minion.position = minion_spawn_locs[i]
	minion.dead.connect(_on_minion_dead.unbind(1))
	add_child(minion)
	# TODO: pause entities with a warmup timer
	
	$Camera2D.target = minion
	music = $Music
	
	minion.is_fighting = false
	hero.is_fighting = false
	battle_start_panel.set_label(minion, hero)
	battle_start_panel.show()

func set_map(map: Globals.BATTLE_MAP) -> void:
	current_map.set_visible(false)
	current_map.set_layer_enabled(0, false)
	current_map.set_layer_navigation_enabled(0, false)
	current_map.process_mode = Node.PROCESS_MODE_DISABLED
	
	match map:
		Globals.BATTLE_MAP.DESERT:
			current_map = $Maps/DesertMap
		Globals.BATTLE_MAP.MOUNTAIN:
			current_map = $Maps/MountainMap
		Globals.BATTLE_MAP.PLAINS:
			current_map = $Maps/PlainsMap
		_:
			current_map = $Maps/PlainsMap
	
	current_map.set_visible(true)
	current_map.set_layer_enabled(0, true)
	current_map.set_layer_navigation_enabled(0, false)
	current_map.process_mode = Node.PROCESS_MODE_INHERIT


func initialize_final_battle(win_scene: Node2D, lose_scene: Node2D, location_scene: Area2D, hero: CharacterBody2D, minion: CharacterBody2D):
	location = location_scene
	win_cutscene = win_scene
	lose_cutscene = lose_scene
	rng = RandomNumberGenerator.new()
	battle_start_panel = $UI/BattleStartPanel
	
	_hero_name = hero.name
	var i = rng.randi_range(0, 6)
	hero.position = mage_spawn_locs[i]
	hero.dead.connect(_on_hero_dead.unbind(1))
	add_child(hero)

	_minion_name = minion.name
	i = rng.randi_range(0, 6)
	minion.position = minion_spawn_locs[i]
	minion.dead.connect(_on_minion_dead.unbind(1))
	add_child(minion)
	
	$Camera2D.target = minion
	music = $MusicFinal
	
	minion.is_fighting = false
	hero.is_fighting = false
	battle_start_panel.set_label(minion, hero)
	battle_start_panel.show()


# When the player clicks "Fight!" on the battle_start_panel, start the battle.
func _on_start_battle_pressed():
	var minion = get_node("/root/Battle/"+_minion_name)
	minion.is_fighting = true
	var hero = get_node("/root/Battle/"+_hero_name)
	hero.is_fighting = true
	hero.is_moving = true


func _on_hero_dead():
	win = true
	victory_laugh.play()
	$Camera2D.target = null
	_game_over()
	
func _on_minion_dead():
	lose_battle_jingle.play()
	$Camera2D.target = null
	_game_over()
	
func _game_over():
	music.stop()
	get_tree().call_group("entity", "stop")
	if (win):
		var minion = get_node("/root/Battle/"+_minion_name)
		minion.level_up()
		remove_child(minion)
	else:
		var hero = get_node("/root/Battle/"+_hero_name)
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

func _on_choices_dialog_selected(_index: int):
	var tree = get_tree()
	var root = tree.get_root()
	var battle_scene = tree.get_current_scene()
	root.remove_child(battle_scene)
	
	if Globals.current_day < Globals.MAX_DAYS:
		root.add_child(main)
		tree.set_current_scene(main)
		location.emit_battle_end_signal()
	else:
		if win:
			root.add_child(win_cutscene)
			tree.set_current_scene(win_cutscene)
		else:
			# lose
			root.add_child(lose_cutscene)
			tree.set_current_scene(lose_cutscene)
	queue_free()

func _on_control_menu_close_menu():
	control_menu.hide()

func _on_pause_menu_open_controls():
	control_menu.show()


func _on_pause_menu_close_menu():
	pause_menu.hide()
	control_menu.hide()
	get_tree().paused = false


func _on_pause_receiver_unpause():
	pause_menu.hide()
	control_menu.hide()
	get_tree().paused = false


func _on_pause_menu_pause():
	pause_menu.show()

func _on_pause_menu_unpause():
	pause_menu.hide()
	control_menu.hide()


func _on_music_finished():
	music.play()
