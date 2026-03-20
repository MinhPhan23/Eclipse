extends Node2D

@export var next_day : PanelContainer

@onready var location_manager : Node2D = $"LocationManager"

var day: int
# Called when the node enters the scene tree for the first time.
func _ready():	
	next_day.choices = ["Next day"]
	next_day.label_text = ""


func proceed_to_next_day(index):
	day += 1
	location_manager.update_game_world()
	
