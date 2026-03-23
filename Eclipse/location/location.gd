extends Area2D

@onready var battle_scene_preload = preload("res://battle/battle.tscn")
@onready var battle_confirmation_dialog = $"BattleConfirmation"
@onready var deployed_minion_label = $"DeployedMinionPanel/VBoxContainer/DeployedMinionLabel"
@onready var deployed_minion_icon = $"DeployedMinionPanel/VBoxContainer/DeployedMinionIcon"
@onready var deployed_minion_panel = $"DeployedMinionPanel"
@onready var location_name = $"LocationName"
@onready var tile_map = $"TileMap"

@export var events: Array[String]
@export var pattern_index: int
@export var minion_bonus: int = 2
@export var battle_trigger_range: int = 3
@export var minion_spawn_pos: Vector2 = Vector2(30, 30)
@export var hero_spawn_pos: Vector2 = Vector2(50, 50)

var hero: CharacterBody2D
var minion: CharacterBody2D
var rng: RandomNumberGenerator

# Minion Selection
signal selection(select)
# To end battle_trigger
signal end_battle
# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	hero = null
	minion = null
	
	battle_confirmation_dialog.choices = ["Yes", "No"]
	battle_confirmation_dialog.label_text = "Take over the minion?"
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED

	_load_tile_map_pattern()
	
func _load_tile_map_pattern():
	var pattern = tile_map.tile_set.get_pattern(pattern_index)
	tile_map.set_pattern(0, Vector2i(0, 0), pattern)

func generate_events() -> String:
	var random_number = rng.randf();
	if (hero != null && random_number < 0.8) || (hero == null && random_number < 0.2):
		return events[rng.randi_range(0, events.size() - 1)]
	return ""

func hero_add(new_hero):
	hero = new_hero

func move_hero(new_location):
	if (new_location.hero == null):
		new_location.hero = hero
	hero = null

func hero_remove():
	hero.queue_free()
	hero = null
	
func minion_add(new_minion):
	minion = new_minion
	minion.dead.connect(minion_remove.unbind(1)) # unbind to ignore passed argument
	if hero != null:
		hero.TARGET = new_minion
	deployed_minion_label.text = "Minion level " + str(minion.level)
	deployed_minion_icon.visible = true
	
func callback_minion():
	if (minion == null):
		return
	deployed_minion_label.text = "No deployed minion"
	deployed_minion_icon.visible = false
	minion.dead.disconnect(Callable(self, "minion_remove"))
	minion = null
	
func minion_remove():
	if minion == null:
		return
	deployed_minion_label.text = "No deployed minion"
	deployed_minion_icon.visible = false
	minion.dead.disconnect(Callable(self, "minion_remove"))
	if hero != null:
		hero.TARGET = null
	minion.queue_free()
	minion = null

func _input_event(viewport, event, shape_idx):
	if event.is_action_pressed("left_mouse_click") and minion == null:
		emit_signal("selection", self.name)
	
func simulate_battle() -> bool:
	if minion == null or hero == null:
		return false
	
	var minion_level = minion.level
	var hero_level = hero.level

	var minion_dice_roll = rng.randi_range(1, 12) + minion_bonus + minion_level
	var hero_dice_roll = rng.randi_range(1, 12) + hero_level
	if (minion_dice_roll < hero_dice_roll):
		if (hero_dice_roll - minion_dice_roll <= battle_trigger_range):
			_open_battle_confirmation_dialog()
			return true
		else:
			#hero win and level up
			hero.level = hero_level + 1
			minion.dead.emit(minion)
	else:
		#minion win and level up
		minion.level = minion_level + 1
	return false

func _open_battle_confirmation_dialog():
	battle_confirmation_dialog.visible = true
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_INHERIT

func _transition_to_battle_scene():
	var battle_scene = battle_scene_preload.instantiate()
	var tree = get_tree()
	var root = tree.get_root()
	var main_scene = tree.get_current_scene()
	
	battle_scene.initialize_battle(main_scene, self, hero, minion)
	root.add_child(battle_scene)
	root.remove_child(main_scene)
	tree.set_current_scene(battle_scene)
	

func _on_battle_confirmation_selected(index):
	battle_confirmation_dialog.visible = false
	battle_confirmation_dialog.process_mode = Node.PROCESS_MODE_DISABLED
	if (index == 0):
		_transition_to_battle_scene()
