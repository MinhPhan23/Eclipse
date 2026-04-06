extends Control

@onready var sprite: Sprite2D = $EclipseSprite
@onready var label: Label = $Label

func _ready():
	sprite.frame = 0

func _set_ui() -> void:
	sprite.frame = max(Globals.current_day / 2 - 1, 0)
	label.text = "Day %d" % (Globals.current_day)

func next_day() -> void:
	_set_ui()
