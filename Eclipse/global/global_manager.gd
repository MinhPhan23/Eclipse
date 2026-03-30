extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var minion_choice = $"MinionList"
@onready var events: Array[String] = []

var _location: Array[Node]
var _battle_finished_count: int
var _deployed_minion: int
var _animation_finished_count: int
var _all_minion_list: Array[Node]
var minion_list: Array[Node]
var rand_num: RandomNumberGenerator
var curr_loc: String

signal minion_return
signal start_next_day
# Called when the node enters the scene tree for the first time.
func _ready():
	rand_num = RandomNumberGenerator.new()
	for i in 3:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = "Minion " + str(i + 1)
		new_minion.dead.connect(remove_dead_minion)
		_all_minion_list.append(new_minion)
	_deployed_minion = 0
		
	_location = get_children()
	# To remove MininonList for our array
	_location.remove_at(_location.size() - 1)
	for i in _location:
		minion_return.connect(i.callback_minion)
		i.battle_end.connect(_next_day_lock_battle)
		i.animation_end.connect(_next_day_lock_animation)
	
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
		arr.append("%s Atk:%d Lvl:%d Health:%d" % [i.name, i.strength, i.level, i.MAX_HEALTH])
	return arr
	
func remove_dead_minion(dead_minion):
	_all_minion_list.erase(dead_minion)
	dead_minion.dead.disconnect(remove_dead_minion)
		
func generate_hero():
	var index: int = rand_num.randi_range(0, _location.size() - 1)
	if _location[index].hero == null:
		_location[index].add_hero(hero_scene_preload.instantiate())
	
func send_minion(index):
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	for i in _location:
		if i.name == curr_loc:
			i.add_minion(minion_list[index])
			_deployed_minion += 1
			minion_list.erase(minion_list[index])
	
func generate_event():
	events = []
	for i in _location:
		if i.has_method("generate_events"):
			events.append(i.generate_events())
			
func simulate_battle():
	if (_deployed_minion != 0):
		_battle_finished_count = 0
		_animation_finished_count = 0
		for i in _location:
			i.simulate_battle()
	else:
		start_next_day.emit()
	
func _next_day_lock_battle():
	_battle_finished_count += 1
	if (_battle_finished_count == _deployed_minion and _animation_finished_count == _deployed_minion):
		start_next_day.emit()
		
func _next_day_lock_animation():
	_animation_finished_count += 1
	if (_battle_finished_count == _deployed_minion and _animation_finished_count == _deployed_minion):
		start_next_day.emit()

func generate_next_day():
	generate_hero()
	generate_event()
	# Calls back all the minion from assigned _location
	minion_return.emit()
	minion_list = _all_minion_list.duplicate()
	_deployed_minion = 0
