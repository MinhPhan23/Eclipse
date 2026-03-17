extends Area2D

@onready var battle_scene_preload = preload("res://battle/battle.tscn")
@onready var battle_confirmation_dialog = $"BattleConfirmation"

@export var events: Array[String]

# Minion Selection
signal selection(select)

var current_day: int
var hero: CharacterBody2D
var minion: CharacterBody2D
var rng: RandomNumberGenerator
var MINION_BONUS = 2
var BATTLE_TRIGGER_RANGE = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	current_day = 0
	events = ["Secret meeting", "Smoke is spotted from a corner of the castle", "Strange lights flash within the castle tower"]
	rng = RandomNumberGenerator.new()
	hero = null
	minion = null
	
	battle_confirmation_dialog.choices = ["Yes", "No"]
	battle_confirmation_dialog.label_text = "Take over the minion?"
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED

func generate_events() -> String:
	var random_number = rng.randf();
	if (hero != null && random_number < 0.8) || (hero == null && random_number < 0.2):
		return events[rng.randi_range(0, 2)]
	return ""

func hero_add(new_hero):
	hero = new_hero

func move_hero(new_location):
	if (new_location.hero == null) :
		new_location.hero = hero
	hero = null

func hero_remove():
	hero.queue_free()
	hero = null
	
func minion_add(new_minion):
	minion = new_minion
	
func move_minion(new_location):
	if (new_location.minion == null):
		new_location.minion = minion
	minion = null
	
func minion_remove():
	minion.queue_free()
	minion = null
	
func _input_event(viewport, event, shape_idx):
	if event.is_action_pressed("left_mouse_click"):
		emit_signal("selection", self.name)
		
func simulate_battle():
	var minion_level = minion.level
	var hero_level = hero.level
	
	var minion_dice_roll = rng.randi_range(1, 12) + MINION_BONUS + minion_level
	var hero_dice_roll = rng.randi_range(1, 12) + hero_level
	
	if (minion_dice_roll < hero_dice_roll):
		if (hero_dice_roll - minion_dice_roll <= BATTLE_TRIGGER_RANGE):
			_open_battle_confirmation_dialog()
		else:
			#hero win and level up
			hero.level = hero_level + 1
	else:
		#minion win and level up
		minion.level = minion_level + 1

func _open_battle_confirmation_dialog():
	print(hero)
	if hero == null || minion == null:
		return
	battle_confirmation_dialog.visible = true
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_INHERIT

func _transition_to_battle_scene():
	var battle_scene = battle_scene_preload.instantiate()
	var tree = get_tree()
	var root = tree.get_root()
	var main_scene = tree.get_current_scene()
	
	battle_scene.main_scene = main_scene
	battle_scene.location = self
	battle_scene.add_hero_and_minion(hero, minion)
	
	root.add_child(battle_scene)
	root.remove_child(main_scene)
	tree.set_current_scene(battle_scene)

func _on_battle_confirmation_selected(index):
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED
	if (index == 0):
		_transition_to_battle_scene()
