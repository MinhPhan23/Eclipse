extends CharacterBody2D

signal dead

const MAX_HEALTH: int = 100
const SPEED: int = 150
const RETICLE_DIST: float = 25.0  # pixels
const FIRING_RATE: float = 0.25   # seconds
var current_health: int = MAX_HEALTH
var strength: int = 10
var level: int = 1

var input_vector: Vector2
var mouse_pos: Vector2
var aim_dir: Vector2


@onready var ROOT = get_tree().current_scene
@onready var BULLET = preload("res://projectile/firebolt.tscn")
@onready var ANIMATION_TREE: AnimationTree = $AnimationTree
@onready var COOLDOWN: Timer = $BulletColldownTimer
@onready var RETICLE: Node2D = $Reticle

func _ready() -> void:
	input_vector = Vector2.ZERO
	mouse_pos = Vector2(position.x, position.y)
	COOLDOWN.wait_time = FIRING_RATE
	
	# Listen for bullet hits
	EventBus.player_hit.connect(_on_hit)

func _physics_process(_delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_pos = get_global_mouse_position()
	
	velocity = input_vector * SPEED
	
	# Sprite will face the mouse
	aim_dir = position.direction_to(mouse_pos)
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/RunState/blend_position", aim_dir)
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/IdleState/blend_position", aim_dir)
	
	# Rotate the reticle about player
	RETICLE.position = aim_dir * RETICLE_DIST
	
	# Shoot in direction of mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if COOLDOWN.is_stopped():
			_shoot(aim_dir)
			COOLDOWN.start()

	move_and_slide()

func _on_hit(damage: int):
	current_health -= damage
	if current_health <= 0.0:
		# TODO death animation
		dead.emit()
		print("player dead") # TODO: remove

func _shoot(direction: Vector2) -> void:
	var instance: CharacterBody2D = BULLET.instantiate()
	instance.direction = direction
	instance.spawn_pos = RETICLE.global_position
	instance.set_collision_layer_value(4, true)  # player bullet
	instance.set_collision_mask_value(3, true)   # hero
	
	ROOT.add_child(instance)

func level_up() -> void:
	level += 1
	# Increase other stats if needed
