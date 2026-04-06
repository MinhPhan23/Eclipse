extends Control

@onready var sprite: Sprite2D = $EclipseSprite
@onready var label: Label = $Label

func _set_ui() -> void:
	sprite.frame = min(Globals.current_day / 2 - 1, sprite.hframes - 1)
	label.text = "Day %d" % (Globals.current_day)

func next_day() -> void:
	_set_ui()
