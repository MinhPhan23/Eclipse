extends Node2D

@onready var minion = $"Minion"
@onready var mage = $"Mage"

func minion_win():
	minion.reset()
	minion.attack()
	mage.reset()
	mage.dead()
	
func hero_win():
	minion.reset()
	minion.dead()
	mage.reset()
	mage.attack()
	
func minion_look_around():
	mage.reset()
	mage.visible = false
	minion.reset()
	minion.look_around()
	
