extends Area2D

var current_day: int
var events: Array[String]
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
	
func simulate_battle():
	var minion_level = minion.level
	var hero_level = hero.level
	
	var minion_dice_roll = rng.randi_range(1, 12) + MINION_BONUS + minion_level
	var hero_dice_roll = rng.randi_range(1, 12) + hero_level
	
	if (minion_dice_roll < hero_dice_roll):
		if (hero_dice_roll - minion_dice_roll <= BATTLE_TRIGGER_RANGE):
			#trigger active battle
			pass
		else:
			#hero win and level up
			hero.level = hero_level + 1
	else:
		#minion win and level up
		minion.level = minion_level + 1
