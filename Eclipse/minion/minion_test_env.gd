extends Node2D

@onready var FIREBOLT = load("res://projectile/firebolt.tscn")

func _physics_process(_delta):
	var mouse_pos = get_global_mouse_position()
	
	# On right click, shoot a bullet at the player
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and $Minion != null:
		var instance: CharacterBody2D = FIREBOLT.instantiate()
		instance.direction = mouse_pos.direction_to($Minion.position)
		instance.spawn_pos = mouse_pos
		instance.set_collision_layer_value(5, true)  # hero bullet
		instance.set_collision_mask_value(2, true)   # player
	
		add_child(instance)
