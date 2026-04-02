extends CharacterBody2D

@onready var impact_sound = $ImpactSound

signal dead

const BASE_FIRING_COOLDOWN: float = 0.65   # seconds
const BASE_HP: int = 100
const BASE_SPEED: int = 150

const RETICLE_DIST: float = 25.0  # pixels

@export var HP_GROWTH_RATE: int = 50
@export var SPEED_GROWTH_RATE: int = 10
@export var FIRING_COOLDOWN_REDUCTION_RATE: float = 0.05

var current_firing_cooldown: float = BASE_FIRING_COOLDOWN
var current_hp: int = BASE_HP
var current_speed: int = BASE_SPEED

var strength: int = 10
var level: int = 1
var dead_emit_flag: bool = false

var input_vector: Vector2
var mouse_pos: Vector2
var aim_dir: Vector2
var bullet_spawn_node: Node


@onready var BULLET = preload("res://projectile/firebolt.tscn")
@onready var ANIMATION_TREE: AnimationTree = $AnimationTree
@onready var COOLDOWN: Timer = $BulletCooldownTimer
@onready var RETICLE: Node2D = $Reticle

func _ready() -> void:
	input_vector = Vector2.ZERO
	mouse_pos = Vector2(position.x, position.y)
	COOLDOWN.wait_time = current_firing_cooldown
	
	# Set HealthBar to full.
	$HealthBar.value = current_hp * 100.0 / BASE_HP


func _physics_process(_delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_pos = get_global_mouse_position()
	
	velocity = input_vector * current_speed
	
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
	impact_sound.play()
	
	current_hp -= damage
	# Update HealthBar
	$HealthBar.value = current_hp * 100.0 / BASE_HP
	
	if current_hp <= 0.0 and !dead_emit_flag:
		# TODO death animation
		dead_emit_flag = true
		dead.emit(self)

func _shoot(direction: Vector2) -> void:
	var instance: CharacterBody2D = BULLET.instantiate()
	instance.direction = direction
	instance.spawn_pos = RETICLE.global_position
	instance.spawn_rot = direction.angle() - PI/2
	instance.set_collision_layer_value(4, true)  # player bullet
	instance.set_collision_mask_value(3, true)   # hero
	
	bullet_spawn_node.add_child(instance)

func level_up():
	level += 1
	# Increase other stats if needed
	
func emit_dead_signal():
	dead.emit(self)

func stop():
	EventBus.player_hit.disconnect(_on_hit)
	process_mode = Node.PROCESS_MODE_DISABLED

func reset():
	EventBus.player_hit.connect(_on_hit)
	bullet_spawn_node = get_parent()
	current_hp = BASE_HP + HP_GROWTH_RATE * (level - 1)
	current_speed = BASE_SPEED + SPEED_GROWTH_RATE * (level - 1)
	current_firing_cooldown = BASE_FIRING_COOLDOWN - FIRING_COOLDOWN_REDUCTION_RATE * (level - 1)
	COOLDOWN.wait_time = current_firing_cooldown
	process_mode = Node.PROCESS_MODE_INHERIT
