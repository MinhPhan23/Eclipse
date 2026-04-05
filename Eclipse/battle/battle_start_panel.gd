extends PanelContainer


signal start_battle

@onready var start_button = $MarginContainer/VBoxContainer/StartButton


# Called when the node enters the scene tree for the first time.
func _ready():
	start_button.pressed.connect(_on_start_pressed)


func set_label(minion: CharacterBody2D, hero: CharacterBody2D) -> void:
	var battle_label = $MarginContainer/VBoxContainer/MinionVsHeroLabel
	battle_label.text = "MINION: %s, lvl %d\nVS\nHERO: %s, lvl %d" % [
		minion.name,
		minion.level,
		hero.name,
		hero.level
	]


func _on_start_pressed() -> void:
	emit_signal("start_battle")
	hide()
