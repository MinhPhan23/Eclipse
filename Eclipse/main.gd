extends Node2D

@export var next_day: PanelContainer

const FIRST_DEPLOYMENT: String = "These heroes are popping up everywhere according to the reports. Need to figure out where they are coming from and deal with them before they get too strong."
const FIRST_SIMULATION_WIN: String = "These minions can still do some work I guess."
const FIRST_SIMULATION_LOST: String = "Useless, can't even win a fight against some random hero."
const FIRST_SIMULATION_NO_HERO: String = "What? No hero? Can't even write a proper report."
const FIRST_BATTLE_TRIGGER: String = "Pathetic, letting the hero turn the tables on you like that. Need to deal with everything myself"

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")
@onready var location_manager: Node2D = $"LocationManager"
@onready var report: Control = $UI/Report
@onready var countdown: Node2D = $UI/Countdown
@onready var demon_lord_dialog: Control = $UI/LordDialog
@onready var demon_lord_dialog_queue: Array[String] = [FIRST_DEPLOYMENT]
@onready var battle_trigger: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	location_manager.start_next_day.connect(_generate_next_day_events)
	location_manager.minion_win.connect(_on_minion_win_first_time)
	location_manager.minion_lost.connect(_on_minion_lost_first_time)
	location_manager.minion_look_around.connect(_on_minion_look_around_first_time)
	location_manager.battle_trigger.connect(_on_battle_trigger_first_time)
	
	demon_lord_dialog.demon_lord_dialog_done.connect(_on_demon_lord_dialog_done)
	
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	_generate_next_day_events()

func start_simulation_battle(_index):
	next_day.process_mode = Node.PROCESS_MODE_DISABLED
	location_manager.simulate_battle()
	
func _generate_next_day_events():
	if !demon_lord_dialog_queue.is_empty():
		var next_dialog = demon_lord_dialog_queue.pop_front()
		demon_lord_dialog.show_dialog(next_dialog)
	else:
		Globals.next_day()
		location_manager.generate_next_day()
		var report_str: String = _generate_report_string()
		
		countdown.next_day()
		report.show_report(report_str)
		next_day.process_mode = Node.PROCESS_MODE_INHERIT

func _generate_report_string() -> String:
	var events: Array[String] = location_manager.events
	
	var report_str = ""
	for event in events:
		if !event.is_empty():
			report_str += event + '\n'
	
	if report_str.is_empty():
		return "The day passes uneventfully."
	
	return report_str

func _on_demon_lord_dialog_done():
	if battle_trigger:
		# If battle is triggered, do not generate next day events.
		battle_trigger = false
	else:
		_generate_next_day_events()

func _on_minion_win_first_time():
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_WIN)
	location_manager.minion_win.disconnect(_on_minion_win_first_time)

func _on_minion_lost_first_time():
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_LOST)
	location_manager.minion_lost.disconnect(_on_minion_lost_first_time)

func _on_minion_look_around_first_time():
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_NO_HERO)
	location_manager.minion_look_around.disconnect(_on_minion_look_around_first_time)

func _on_battle_trigger_first_time():
	battle_trigger = true
	demon_lord_dialog.show_dialog(FIRST_BATTLE_TRIGGER)
	location_manager.battle_trigger.disconnect(_on_battle_trigger_first_time)
