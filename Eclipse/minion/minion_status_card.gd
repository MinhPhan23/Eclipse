extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	#$VBoxContainer/Name.text = ""
	#$VBoxContainer/Level.text = ""
	#$VBoxContainer/Status.text = ""
	pass


func set_minion(minion: CharacterBody2D):
	if minion != null:
		$VBoxContainer/Name.text = minion.name
		$VBoxContainer/Level.text = "Level %d" % minion.level
		$VBoxContainer/Status.text = minion.get_status()
	else:
		$VBoxContainer/Name.text = "EMPTY"
		$VBoxContainer/Level.text = ""
		$VBoxContainer/Status.text = ""
