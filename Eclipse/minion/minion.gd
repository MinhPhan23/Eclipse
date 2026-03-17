extends CharacterBody2D

signal dead

const MAX_HEALTH: float = 100.0
const SPEED: float = 150.0
const RETICLE_DIST: float = 25.0
var current_health: float = MAX_HEALTH
var strength: int = 10
var level: int = 1

var input_vector: Vector2
var mouse_pos: Vector2
var aim_dir: Vector2

# Wait until we have access to animation tree before calling
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var FIREBOLT = load("res://projectile/firebolt.tscn")

func _ready() -> void:
	input_vector = Vector2.ZERO
	mouse_pos = Vector2(position.x, position.y)

func _physics_process(_delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_pos = get_global_mouse_position()
	
	velocity = input_vector * SPEED
	
	# Sprite will face the mouse
	aim_dir = position.direction_to(mouse_pos)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", aim_dir)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", aim_dir)
	
	# rotate the reticle
	$Reticle.position = aim_dir * RETICLE_DIST
	
	# Shoot in direction of mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print("hold")
		_shoot(aim_dir)
	
	move_and_slide()
	
	if current_health <= 0.0:
		_on_death()
	# TODO: take damage when hitbox area2d entered

func _shoot(direction: Vector2) -> void:
	var instance: CharacterBody2D = FIREBOLT.instantiate()
	instance.direction = direction
	instance.position = $Reticle.position
	instance.set_collision_layer_value(4, true) # sits as player bullet
	instance.set_collision_mask_value(3, true)  # sees hero
	
	
	print("reticle dir: %s" % [aim_dir])
	print("fire dir: %s" % [instance.direction])
	
	add_child(instance)

func _on_death() -> void:
	# TODO death animation
	# TODO emit signal to trigger end of battle
	queue_free()

func level_up() -> void:
	level += 1
	# Increase other stats if needed
