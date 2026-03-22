extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var minion_choice = $"MinionList"

var _location: Array[Node];
var minion_list: Array[Node];
var rand_num: RandomNumberGenerator;
var curr_loc: String;

signal minion_return 
# Called when the node enters the scene tree for the first time.
func _ready():
	rand_num = RandomNumberGenerator.new()
	for i in 3:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = "Minion " + str(i + 1)
		new_minion.dead.connect(remove_minion)
		minion_list.append(new_minion)
		
	_location = get_children()
	# To remove MininonList for our array
	_location.remove_at(_location.size() - 1)
	for i in _location:
		minion_return.connect(i.callback_minion)
	
	minion_choice.label_text = "Send Minion?"
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	
func send_minion_dialog(location):
	if !minion_list.is_empty():
		minion_choice.choices = minion_arr()
		minion_choice.visible = true
		minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	curr_loc = location
	
func minion_arr() -> Array[String]:
	var arr: Array[String] = []
	for i in minion_list:
		arr.append("%s Atk:%d Lvl:%d Health:%d/%d" % [i.name, i.strength, i.level, i.current_health, i.MAX_HEALTH])
	return arr
	
func remove_minion(dead_minion):
	minion_list.erase(dead_minion)
	dead_minion.dead.disconnect(remove_minion)
		
func generate_hero():
	var index: int = rand_num.randi_range(0, _location.size() - 1)
	if _location[index].hero == null:
		_location[index].hero_add(hero_scene_preload.instantiate())
	
func send_minion(index):
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	for i in _location:
		if i.name == curr_loc:
			i.minion_add(minion_list[index])
	
func generate_event():
	var index: int = rand_num.randi_range(0, _location.size() - 1)
	for i in _location:
		if i.has_method("generate_events"):
			i.generate_events()
		
func update_game_world():
	for i in _location:
		var battle_trigger:bool = i.simulate_battle()
		if (battle_trigger):
			await i.end_battle
	generate_hero()
	generate_event()
	# Calls back all the minion from assigned _location
	minion_return.emit()
