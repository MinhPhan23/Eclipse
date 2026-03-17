extends CharacterBody2D


@export var SPEED = 200

var direction : Vector2
var spawnPos : Vector2
var spawnRot : float  # Used to orient a sprite with a head/tail.

signal hit_player

func _physics_process(_delta):
	velocity = direction * SPEED
	move_and_slide()
	HandleCollisions()

func HandleCollisions():
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
	
		if collision.get_collider() == null:
			continue
		
		if collision.get_collider().is_in_group("slimy"):  # TODO: set to minion group
			hit_player.emit()
	
		queue_free()


# Delete the firebolt object after it has traveled a set time.
func _on_expire_timeout():
	queue_free()
