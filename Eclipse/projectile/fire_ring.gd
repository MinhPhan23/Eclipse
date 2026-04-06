extends Area2D

@onready var cast_sound = $CastSound

@export var BASE_SPEED: float = 50.0
var acceleration: float = 60.0  # No acceleration: multiplied by delta = 1/60
var damage: float = 10.0

var speed: float = BASE_SPEED
var direction : Vector2
var spawn_pos : Vector2
var spawn_rot : float  # Used to orient a sprite with a head/tail.


func _ready():
	global_position = spawn_pos
	global_rotation = spawn_rot
	cast_sound.play()
	$AnimatedSprite2D.play()


func _process(delta):
	global_position += direction * speed * delta
	speed *= acceleration * delta


func _on_body_entered(body):
	if body.is_in_group("minion"):
		EventBus.player_hit.emit(damage)


# Delete the fire ring object after it has traveled a set time.
func _on_expire_timer_timeout():
	queue_free()
