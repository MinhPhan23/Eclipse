extends Area2D


@export var SPEED = 200

var direction : Vector2
var spawnRot : float  # Used to orient a sprite with a head/tail.


func _ready():
	global_rotation = spawnRot


func _physics_process(delta):
	#velocity = direction * SPEED
	#move_and_slide()
	#HandleCollisions()

	global_position += direction * SPEED * delta


#func HandleCollisions():
#	for index in range(get_slide_collision_count()):
#		var collision = get_slide_collision(index)
#	
#		if collision.get_collider() == null:
#			continue
#	
#		queue_free()

# Projectile disappears when it hits the minion.
func _on_area_entered(area):
	#deal damage?
	queue_free()


# Projectile disappears when it hits a wall.
func _on_body_entered(body):
	queue_free()


# Delete the firebolt object after it has traveled a set time.
func _on_expire_timeout():
	queue_free()

