extends Node2D

@export var next_day : PanelContainer

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://minion/minion.tscn")
@onready var location_array = [$"Castle"]

# Called when the node enters the scene tree for the first time.
func _ready():	
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	
	location_array[0].hero = hero_scene_preload.instantiate()
	location_array[0].minion = minion_scene_preload.instantiate()

func _on_next_day_selected(index):
	location_array[0]._open_battle_confirmation_dialog()
