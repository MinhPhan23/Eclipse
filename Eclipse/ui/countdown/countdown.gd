extends Node2D

@onready var sprite: Sprite2D = $EclipseSprite
@onready var label: Label = $Label

var current_day: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_ui()

func _set_ui() -> void:
	sprite.frame = current_day
	label.text = "Day %d" % (current_day + 1)

func next_day() -> void:
	current_day += 1
	_set_ui()
