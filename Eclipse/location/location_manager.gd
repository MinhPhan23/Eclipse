extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var minion_choice = $"../UI/MinionList"
@onready var events: Array[String] = []
@onready var deploy_minion_sound = $DeployMinionSound

var _locations: Array[Node]
var _battle_triggered: bool
var _deployed_minion: int
var _animation_finished_count: int
var _all_minion_list: Array[Node]
var _deployable_minion_list: Array[Node]
var _close_button_index:int

var rand_num: RandomNumberGenerator
var _curr_loc: Area2D

signal minion_return
signal start_next_day
signal minion_lost
signal minion_win
signal minion_look_around
signal battle_trigger

# Called when the node enters the scene tree for the first time.
func _ready():
	rand_num = RandomNumberGenerator.new()
	for i in 3:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = "Minion " + str(i + 1)
		new_minion.dead.connect(remove_dead_minion)
		_all_minion_list.append(new_minion)
	_deployable_minion_list = _all_minion_list.duplicate()
	_deployed_minion = 0
	
	_locations = []
	for child in get_children():
		if child is Location:
			_locations.append(child)
	
	for i in _locations:
		minion_return.connect(i.callback_minion)
		i.battle_end.connect(_next_day_lock_battle)
		i.animation_end.connect(_next_day_lock_animation)
	
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED

func send_minion_dialog(location_name):
	for i in _locations:
		if i.name == location_name:
			_curr_loc = i
	if _curr_loc.minion != null:
		minion_choice.label_text = "Withdraw Minion?"
		minion_choice.choices = ["Yes", "No"]
		minion_choice.visible = true
		minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		minion_choice.label_text = "Send Minion?"
		minion_choice.choices = minion_arr()
		minion_choice.visible = true
		minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	
func minion_arr() -> Array[String]:
	var arr: Array[String] = []
	for i in _deployable_minion_list:
		arr.append("%s Lvl:%d" % [i.name, i.level])
	arr.append("Close Menu")
	_close_button_index = arr.size() - 1
	return arr
	
func remove_dead_minion(dead_minion):
	_all_minion_list.erase(dead_minion)
	dead_minion.dead.disconnect(remove_dead_minion)
		
func generate_hero():
	var index: int = rand_num.randi_range(0, _locations.size() - 1)
	if _locations[index].hero == null:
		_locations[index].add_hero(hero_scene_preload.instantiate())
	
func send_minion(index):
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	if _curr_loc.minion != null:
		if index == 0:
			_deployable_minion_list.append(_curr_loc.callback_minion())
			_deployable_minion_list.sort_custom(func(a, b): return a.name < b.name)
			_deployed_minion -= 1
	elif index != _close_button_index:
		_curr_loc.add_minion(_deployable_minion_list[index])
		_deployed_minion += 1
		_deployable_minion_list.erase(_deployable_minion_list[index])
	
func generate_event():
	events = []
	for i in _locations:
		if i.has_method("generate_events"):
			events.append(i.generate_events())
			
func simulate_battle():
	_battle_triggered = false
	_animation_finished_count = 0
	
	if (_deployed_minion != 0):
		for i in _locations:
			var result = i.simulate_battle()
			if (result == Globals.SIMULATION_BATTLE_RESULT.MINION_LOOK_AROUND):
				minion_look_around.emit(i.location_name)
			elif (result == Globals.SIMULATION_BATTLE_RESULT.MINION_LOST):
				minion_lost.emit(i.location_name)
			elif (result == Globals.SIMULATION_BATTLE_RESULT.MINION_WIN):
				minion_win.emit(i.location_name)
			elif (result == Globals.SIMULATION_BATTLE_RESULT.BATTLE_TRIGGER):
				_battle_triggered = true
				battle_trigger.emit(i.location_name)
	else:
		start_next_day.emit()
	
func _next_day_lock_battle():
	_battle_triggered = false
	for i in _locations:
		i.close_battle_confirmation_dialog()

	if (_animation_finished_count == _deployed_minion):
		start_next_day.emit()
		
func _next_day_lock_animation():	
	_animation_finished_count += 1
	if (!_battle_triggered and _animation_finished_count == _deployed_minion):
		start_next_day.emit()

func generate_next_day():
	
	if Globals.current_day <= Globals.MAX_DAYS:
		generate_hero()
		generate_event()
		# Calls back all the minion from assigned _location
		minion_return.emit()
		_deployable_minion_list = _all_minion_list.duplicate()
		_deployed_minion = 0

func start_final_battle():
	# Trigger final battle
	var top_min = minion_scene_preload.instantiate()
	for minion in _deployable_minion_list:
		if top_min == null or minion.level > top_min.level:
			top_min = minion
	
	var top_hero = hero_scene_preload.instantiate()
	var final_location = _locations[rand_num.randi_range(0, _locations.size()-1)]
	for location in _locations:
		if location.hero != null and (top_hero == null or location.hero.level > top_hero.level):
			top_hero = location.hero
			final_location = location
	
	top_hero.target = top_min
	final_location.add_minion(top_min)
	final_location.add_hero(top_hero)
	final_location.transition_to_battle_scene()
