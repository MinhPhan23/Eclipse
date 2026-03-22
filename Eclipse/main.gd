extends Node2D

@export var next_day : PanelContainer

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://mage/mage.tscn")
@onready var location_manager : Node2D = $"LocationManager"
@onready var location_array = [$LocationManager/Castle]

var day: int
# Called when the node enters the scene tree for the first time.
func _ready():
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	
	for location in location_array:
		location.hero = hero_scene_preload.instantiate()
		location.minion = minion_scene_preload.instantiate()

func _on_next_day_selected(_index):
	location_array[0]._open_battle_confirmation_dialog()


func proceed_to_next_day(_index):
	day += 1
	location_manager.update_game_world()
	
