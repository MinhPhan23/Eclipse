class_name Location
extends Area2D

@onready var battle_scene_preload = preload("res://battle/battle.tscn")
@onready var lose_scene_load = load("res://cutscenes/lose_cutscene.tscn")
@onready var win_scene_load = load("res://cutscenes/win_cutscene.tscn")
@onready var battle_confirmation_dialog = $"BattleConfirmation"
@onready var deployed_minion_label = $"DeployedMinionPanel/VBoxContainer/DeployedMinionLabel"
@onready var deployed_minion_icon = $"DeployedMinionPanel/VBoxContainer/DeployedMinionIcon"
@onready var deployed_minion_panel = $"DeployedMinionPanel"
@onready var location_name_label = $"LocationName"
@onready var tile_map = $"TileMap"
@onready var simulation_animation = $"SimulationAnimation"
@onready var minion_animation_tree = $"SimulationAnimation/Minion/AnimationTree"
@onready var deploy_minion_sound = $"../DeployMinionSound"

@export var location_name: String
@export var name_short: String
@export var events: Array[String]
@export var hero_events: Array[String]
@export var location_events: Array[String]
@export var pattern_index: int
@export var minion_bonus: int = 2
@export var battle_trigger_range: int = 6

var hero: CharacterBody2D
var minion: CharacterBody2D
var rng: RandomNumberGenerator

# Minion Selection
signal selection(select)
# To end battle_trigger
signal battle_end
signal animation_end

func _ready():
	rng = RandomNumberGenerator.new()
	hero = null
	minion = null
	location_name_label.text = location_name
	
	battle_confirmation_dialog.choices = ["Yes", "No"]
	battle_confirmation_dialog.label_text = "Take over the minion?"
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED
	
	simulation_animation.visible = false
	deployed_minion_panel.visible = true
	
	minion_animation_tree.animation_finished.connect(emit_animation_end_signal)

	_load_tile_map_pattern()
	
func _load_tile_map_pattern():
	var pattern = tile_map.tile_set.get_pattern(pattern_index)
	tile_map.set_pattern(0, Vector2i(0, 0), pattern)
	
func emit_animation_end_signal(anim_name: String):
	if (anim_name == "attack_e" or anim_name == "dead_e" or anim_name == "look_around"):
		animation_end.emit()


# 80% chance to generate an event at a location if a hero is present.
# 20% chance to generate an event at a location if a hero is not present.
func generate_events() -> String:
	var random_number = rng.randf();
	if (hero != null && random_number < 0.8):
		return hero_events[rng.randi_range(0, hero_events.size() - 1)]
	elif (hero == null && random_number < 0.5):
		return location_events[rng.randi_range(0, location_events.size() - 1)]
	return ""


func add_hero(new_hero):
	hero = new_hero
	hero.dead.connect(_remove_hero)

func move_hero(new_location):
	if (new_location.hero == null):
		new_location.add_hero(hero)
	hero = null

func _remove_hero(removed_hero):
	if hero == null or hero != removed_hero:
		return
	hero.dead.disconnect(_remove_hero)
	hero.queue_free()
	hero = null


# Adds a minion selected for deployment to this location.
# Called by send_minion() in location_manager.gd.
func add_minion(new_minion):
	deploy_minion_sound.play()
	minion = new_minion
	minion.dead.connect(_remove_minion)
	if hero != null:
		hero.target = new_minion
	deployed_minion_label.text = minion.name
	deployed_minion_icon.visible = true
	simulation_animation.visible  = false


func callback_minion() -> CharacterBody2D:
	# If location has no minion return null.
	if (minion == null):
		return null
	
	# If location has a minion return it.
	deployed_minion_label.text = "No deployed minion"
	deployed_minion_icon.visible = false
	simulation_animation.visible = false
	minion.dead.disconnect(_remove_minion)
	var withdrawn_minion = minion
	minion = null
	return withdrawn_minion


func _remove_minion(removed_minion):
	if minion == null or minion != removed_minion:
		return
	deployed_minion_label.text = "No deployed minion"
	deployed_minion_icon.visible = false
	minion.dead.disconnect(_remove_minion)
	if hero != null:
		hero.target = null
	minion.queue_free()
	minion = null


# Registers that this location has been clicked on and signals
# location_manager.gd to open a minion deployment menu.
func _input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("left_mouse_click"):
		emit_signal("selection", self.name)


func simulate_battle() -> Globals.SIMULATION_BATTLE_RESULT:
	if minion == null:
		return Globals.SIMULATION_BATTLE_RESULT.NO_DEPLOYED_MINION
	
	deployed_minion_icon.visible = false
	simulation_animation.visible  = true
	
	if hero == null:
		simulation_animation.minion_look_around()
		return Globals.SIMULATION_BATTLE_RESULT.MINION_LOOK_AROUND
		
	var minion_level = minion.level
	var hero_level = hero.level

	var minion_dice_roll = rng.randi_range(1, 12) + minion_bonus + minion_level
	var hero_dice_roll = rng.randi_range(1, 12) + hero_level
	if (minion_dice_roll < hero_dice_roll):
		simulation_animation.hero_win()
		if (hero_dice_roll - minion_dice_roll <= battle_trigger_range):
			_open_battle_confirmation_dialog()
			return Globals.SIMULATION_BATTLE_RESULT.BATTLE_TRIGGER
		else:
			#hero win and level up
			hero.level_up()
			minion.emit_dead_signal()
			return Globals.SIMULATION_BATTLE_RESULT.MINION_LOST
	else:
		#minion win and level up
		simulation_animation.minion_win()
		minion.level_up()
		hero.emit_dead_signal()
		return Globals.SIMULATION_BATTLE_RESULT.MINION_WIN

func emit_battle_end_signal():
	battle_end.emit()

func _open_battle_confirmation_dialog():
	battle_confirmation_dialog.visible = true
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_INHERIT

func close_battle_confirmation_dialog():
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED

func transition_to_battle_scene():
	var battle_scene = battle_scene_preload.instantiate()
	var tree = get_tree()
	var root = tree.get_root()
	var main_scene = tree.get_current_scene()
	
	if Globals.current_day < Globals.MAX_DAYS:
		battle_scene.initialize_battle(main_scene, self, hero, minion)
	else:
		var lose_scene = lose_scene_load.instantiate()
		var win_scene = win_scene_load.instantiate()
		battle_scene.initialize_final_battle(win_scene, lose_scene, self, hero, minion)
	root.add_child(battle_scene)
	root.remove_child(main_scene)
	tree.set_current_scene(battle_scene)
	
func _on_battle_confirmation_selected(index):
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED
	if (index == 0):
		transition_to_battle_scene()
	else:
		hero.level_up()
		minion.emit_dead_signal()
		battle_end.emit()
