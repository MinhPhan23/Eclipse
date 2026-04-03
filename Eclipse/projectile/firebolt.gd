extends CharacterBody2D

@onready var cast_sound = $CastSound

@export var SPEED: float = 200.0

var damage: float = 10.0
var direction : Vector2
var spawn_pos : Vector2
var spawn_rot : float  # Used to orient a sprite with a head/tail.

signal hit_player(damage: float)

func _ready():
	global_position = spawn_pos
	global_rotation = spawn_rot
	cast_sound.play()

func _physics_process(_delta):
	velocity = direction.normalized() * SPEED
	
	var collision = move_and_collide(direction.normalized() * SPEED * _delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("minion"):
			EventBus.player_hit.emit(damage)
		if collider.is_in_group("hero"):
			EventBus.hero_hit.emit(damage)
		queue_free()


# Delete the firebolt object after it has traveled a set time.
func _on_expire_timer_timeout():
	queue_free()

