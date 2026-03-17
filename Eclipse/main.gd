extends Node2D

@onready var next_day = $"Camera2D/NextDay"

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://minion/minion.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():	
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	

