extends Node2D

@export var next_day : PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready():	
	next_day.choices = ["Next day"]
	next_day.label_text = ""
	
