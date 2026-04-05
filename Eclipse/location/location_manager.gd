extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var minion_choice = $"../UI/MinionList"  # Deployable minion menu.
@onready var events: Array[String] = []
@onready var deploy_minion_sound = $DeployMinionSound
@onready var minion_manager = $"../MinionManager"

var _locations: Array[Node]
var _battle_triggered: bool
var _animation_finished_count: int
var _close_button_index:int

var rand_num: RandomNumberGenerator
var _curr_loc: Area2D

signal start_next_day
signal minion_lost
signal minion_win
signal minion_look_around
signal battle_trigger

const HERO_NAMES_LIST: Array[String] = [
	"Velarian","Nestor","Lanxas","Hestia","Amalia","Kazius","Robyn","Ford",
	"Draven","Sylthas","Belmont","Tyrgen","Ruwin","Sullivan","Smogus","Hefnd",
	"Viusu","Thaddeus","Cassius","Toyota","Arcus","Hunter","Eirrik","Digit",
	"Valentine","Zemirah","Orthorien","Ren","Chaos","Sidra","Gabbro","Feldspar",
	"Blare","Viho","Geet","Dr Uncle","Lethe","Othree","Natki","Arag","Paren",
	"Chess","Ali","Gorath","Asteria","Vael","Kaad","Birgir","Manneo","Yoda",
	"Valeri","Percival","Gerald","Leolin","Rhae'gon","Volvo","Slate","Faelyn",
	"Harry"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	rand_num = RandomNumberGenerator.new()
	
	_locations = []
	for child in get_children():
		if child is Location:
			_locations.append(child)
	
	for i in _locations:
		minion_manager.minion_return.connect(i.callback_minion)
		i.battle_end.connect(_next_day_lock_battle)
		i.animation_end.connect(_next_day_lock_animation)
	
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED


# Open a minion deployment menu for the selected location.
# Called by _input_event() in location.gd emitting its "selection" signal.
# Gets passed the name of the location from which the signal was sent.
func transfer_minion_dialog(location_name):
	# Identify the location being selected.
	for i in _locations:
		if i.name == location_name:
			_curr_loc = i
	
	# If a minion is in the current location open the Withdraw Minion menu.
	if _curr_loc.minion != null:
		minion_choice.label_text = "Withdraw Minion?"
		minion_choice.choices = ["Yes", "No"]
		minion_choice.visible = true
		minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	
	# If no minion is in the current location open the Send Minion menu.
	else:
		minion_choice.label_text = "Send Minion?"
		var arr: Array[String] = []
		arr = minion_manager.minion_arr()
		arr.append("Close Menu")
		_close_button_index = arr.size() - 1
		minion_choice.choices = arr
		minion_choice.visible = true
		minion_choice.process_mode = Node.PROCESS_MODE_INHERIT


# Randomly select a location and generate a hero there if none is present.
func generate_hero():
	var index: int = rand_num.randi_range(0, _locations.size() - 1)
	if _locations[index].hero == null:
		var new_hero = hero_scene_preload.instantiate()
		var name_num = rand_num.randi_range(0, HERO_NAMES_LIST.size()-1)
		new_hero.name = HERO_NAMES_LIST[name_num]
		_locations[index].add_hero(new_hero)


# Called when a selection is made in a minion deployment menu.
func transfer_minion(index):
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	
	# If a minion is already at the location, withdraw it and return it to the
	# deployable minions list.
	if _curr_loc.minion != null:
		if index == 0:  # "Yes" option is selected in Withdraw Minion menu.
			minion_manager.retrieve_minion(_curr_loc)
	
	# If a minion has been selected for deployment, send it to the selected
	# location and remove it from the list of deployable minions.
	elif index != _close_button_index:
		minion_manager.deploy_minion(_curr_loc, index)


# Generate the report by calling generate_events() at each location.
func generate_event():
	events = []
	for i in _locations:
		if i.has_method("generate_events"):
			events.append(i.generate_events())


# Call simulate_battle() in all locations and process the result, then start
# the next day.
func simulate_battle():
	_battle_triggered = false
	_animation_finished_count = 0
	
	if (minion_manager.deployed_minion != 0):
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
	
	if (_animation_finished_count == minion_manager.deployed_minion):
		start_next_day.emit()


func _next_day_lock_animation():
	_animation_finished_count += 1
	if (!_battle_triggered and _animation_finished_count == minion_manager.deployed_minion):
		start_next_day.emit()


func generate_next_day():
	# Level up every alive hero.
	for i in _locations:
		if i.hero != null:
			i.hero.level_up()
	
	if Globals.current_day <= Globals.MAX_DAYS:
		generate_hero()
		generate_event()
		minion_manager.new_day()


func start_final_battle():
	# Trigger final battle
	var top_min = minion_scene_preload.instantiate()
	for minion in minion_manager.deployable_minion_list:
		if top_min == null or minion.level > top_min.level:
			top_min = minion
	
	var top_hero = hero_scene_preload.instantiate()
	var final_location = _locations[rand_num.randi_range(0, _locations.size()-1)]
	for location in _locations:
		if location.hero != null and (top_hero == null or location.hero.level >= top_hero.level):
			top_hero = location.hero
			final_location = location
	
	top_hero.target = top_min
	final_location.add_minion(top_min)
	final_location.transition_to_battle_scene()
