extends TextureProgressBar

@export var minion: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	value = minion.current_hp * 100 / minion.BASE_HP


func _on_minion_lose_health():
	value = minion.current_hp * 100 / minion.BASE_HP
