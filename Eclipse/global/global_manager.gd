extends Node

var day: int

# Called when the node enters the scene tree for the first time.
func _ready():
	day = 0

func proceed_to_next_day():
	day += 1
