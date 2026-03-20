extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var minion_choice = $"MinionList"

var location: Array[Node];
var minion_list: Array[Node];
var rand_num: RandomNumberGenerator;
var curr_loc: String;
# Called when the node enters the scene tree for the first time.
func _ready():
	rand_num = RandomNumberGenerator.new()
	for i in 3:
		var goon = minion_scene_preload.instantiate()
		goon.name = "Minion " + str(i + 1)
		minion_list.append(goon)
	location = get_children()
	# To remove MininonList for our array
	location.remove_at(location.size() - 1)
	
	minion_choice.label_text = "Send Minion?"
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func send_minion_dialog(location):
	minion_choice.choices = minion_arr()
	minion_choice.visible = true
	minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	curr_loc = location
	
func minion_arr() -> Array[String]:
	var arr: Array[String] = []
	for i in 3:
		arr.append("Minion %d Atk:%d Lvl:%d Health:%d/%d" % [i + 1, minion_list[i].strength, minion_list[i].level, minion_list[i].current_health, minion_list[i].MAX_HEALTH])
	return arr

func generate_hero():
	var index: int = rand_num.randi_range(0, location.size() - 1)
	if location[index].hero == null:
		location[index].hero_add(hero_scene_preload.instantiate())
	
func send_minion(index):
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	for i in location:
		if i.name == curr_loc and i.minion == null:
			i.minion_add(minion_list[index])
	

func generate_event():
	var index: int = rand_num.randi_range(0, location.size() - 1)
	for i in location:
		if i.has_method("generate_events"):
			i.generate_events()
		
func update_game_world():
	generate_hero()
	generate_event()
