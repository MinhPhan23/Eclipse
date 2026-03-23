extends Area2D


@export var SPEED: float = 200.0

var damage: float = 10.0
var direction : Vector2
<<<<<<< mage_battle
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
=======
var spawn_pos : Vector2
var spawn_rot : float  # Used to orient a sprite with a head/tail.

signal hit_player(damage: float)

func _ready():
	global_position = spawn_pos
	global_rotation = spawn_rot

func _physics_process(_delta):
	velocity = direction.normalized() * SPEED
	
	move_and_slide()
	HandleCollisions()

func HandleCollisions():
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
	
		if collider == null:
			continue
		
		if collider.is_in_group("minion"):
			EventBus.player_hit.emit(damage)
		
		if collider.is_in_group("hero"):
			EventBus.hero_hit.emit(damage)
		
		queue_free()
>>>>>>> main


# Delete the firebolt object after it has traveled a set time.
func _on_expire_timer_timeout():
	queue_free()

