extends CharacterBody2D

signal dead

var HERO: CharacterBody2D
const MAX_HEALTH: float = 100.0
const SPEED: float = 150.0
var current_health: float = MAX_HEALTH
var strength: int = 10
var level: int = 1

var input_vector: Vector2
var mouse_pos: Vector2

# Wait until we have access to animation tree before calling
@onready var animation_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	input_vector = Vector2.ZERO
	mouse_pos = Vector2(position.x, position.y)


func _physics_process(_delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_pos = get_global_mouse_position()
	
	velocity = input_vector * SPEED
	
	# Sprite will face the mouse
	var direction: Vector2 = position.direction_to(mouse_pos)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction)
	
	move_and_slide()
	HandleCollisions()
	
	if current_health <= 0.0:
		_on_death()

# TODO: take damage when hitbox area2d entered

func _on_death() -> void:
	# TODO death animation
	# TODO emit signal to trigger end of battle
	queue_free()

func level_up() -> void:
	level += 1
	# Increase other stats if needed


func HandleCollisions() -> void:
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
	
		if collision.get_collider() == null:
			continue
		
		if collision.get_collider().is_in_group("mage_bolt"):
			current_health -= HERO.DAMAGE
			print("Minion hit! HP = %d" % current_health)
