extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://minion/minion.tscn")

var day: int
var location: Array[Node];
var rand_num:RandomNumberGenerator; 

# Called when the node enters the scene tree for the first time.
func _ready():
	day = 0
	rand_num = RandomNumberGenerator.new()
	location = get_children()
	print("NOW")
	generate_hero()
	select_location()

func proceed_to_next_day():
	day += 1
func generate_hero():
	var index:int = rand_num.randi_range(0, location.size() - 1)
	location[0].hero = hero_scene_preload.instantiate()
	# remove later
	location[0].minion = minion_scene_preload.instantiate()

func select_location():
	var index:int = rand_num.randi_range(0, location.size() - 1)
	if location[index].has_method("generate_events"):
		location[index].generate_events()
		
func _on_next_day_selected(index):
	location[0]._open_battle_confirmation_dialog()
	
