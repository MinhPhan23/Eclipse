extends Node2D

@export var next_day: PanelContainer

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")
@onready var location_manager: Node2D = $"LocationManager"
@onready var report: Control = $UI/Report
@onready var countdown: Node2D = $UI/Countdown

var day: int = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	location_manager.update_game_world()
	var report_str: String = _generate_report_string()
	report.show_report(report_str)

func proceed_to_next_day(_index):
	day += 1
	location_manager.update_game_world()
	var report_str: String = _generate_report_string()
	
	countdown.next_day()
	
	report.show_report(report_str)

func _generate_report_string() -> String:
	var events: Array[String] = location_manager.events
	
	var report_str = ""
	for event in events:
		if !event.is_empty():
			report_str += event + '\n'
	
	if report_str.is_empty():
		return "The day passes uneventfully."
	
	return report_str
