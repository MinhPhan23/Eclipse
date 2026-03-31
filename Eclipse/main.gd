extends Node2D

@export var next_day: PanelContainer

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")
@onready var location_manager: Node2D = $"LocationManager"
@onready var report: Control = $UI/Report
@onready var countdown: Node2D = $UI/Countdown

# Called when the node enters the scene tree for the first time.
func _ready():
	location_manager.start_next_day.connect(_generate_next_day_events)
	
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	_generate_next_day_events()

func start_simulation_battle(_index):
	next_day.process_mode = Node.PROCESS_MODE_DISABLED
	location_manager.simulate_battle()
	
func _generate_next_day_events():
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
