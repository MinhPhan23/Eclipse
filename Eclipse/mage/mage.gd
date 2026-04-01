extends CharacterBody2D

@export var BASE_FIRING_COOLDOWN: float = 0.5     # seconds
@export var BASE_FOLLOW_DISTANCE: int = 200
@export var BASE_HP: float = 100.0
@export var BASE_SPELL_ANGLE: float = 0.5  # Maximum angle away from player that spell will be cast.
@export var BASE_SPEED: int = 50
@export var BASE_SPELL_RANGE: int = 300

@export var RETICLE_DIST: float = 25.0    # distance from model center, pixels

@export var HP_GROWTH_RATE: int = 50
@export var SPEED_GROWTH_RATE: int = 10
@export var FIRING_COOLDOWN_REDUCTION_RATE: float = 0.05

var level: int = 1

var current_firing_cooldown: float = BASE_FIRING_COOLDOWN
var current_hp: float = BASE_HP
var current_speed: int = BASE_SPEED

var target: CharacterBody2D
var facing : Vector2  # Direction the mage is facing (v_minion.normalized()).
var los : bool  # Line of sight.
var spell_ready = true  # Updated by SpellTimer
var spell_angle : float  # Angle offset for firebolt attack.
var swing_right = true  # Used to control the swing of the firebolt angle.
var dead_emit_flag: bool = false
var bullet_spawn_node: Node

@onready var BULLET = preload("res://projectile/firebolt.tscn")
@onready var ANIMATION_TREE: AnimationTree = $AnimationTree
@onready var NAV_AGENT = $NavigationAgent2D
@onready var RETICLE = $Reticle
@onready var SPELL_TIMER = $SpellTimer

signal dead  # Emitted at 0 hp.

func _ready():
	SPELL_TIMER.wait_time = current_firing_cooldown
	
	# Set HealthBar to full.
	$HealthBar.value = current_hp * 100 / BASE_HP
	
	# wait for physics frame to be ready for navigation
	set_physics_process(false)
	call_deferred("_navigation_setup")

func _process(_delta):
	var v_minion = target.global_position - global_position
	facing = v_minion.normalized()
	
	if v_minion.length() < BASE_SPELL_RANGE and spell_ready and los:
		RETICLE.position = facing * RETICLE_DIST
		_cast_spell(facing)


func _physics_process(_delta):
	# Pathfinding.
	NAV_AGENT.target_position = target.global_position
	# v = vector from mage to MINION.
	var v_minion = target.global_position - global_position
	var next_pos = NAV_AGENT.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	_check_los()
	
	# Animation
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/RunState/blend_position", v_minion.normalized())
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/IdleState/blend_position", v_minion.normalized())
	
	# Move toward or away from MINION until reaching FOLLOW_DISTANCE.
	if !los or v_minion.length() > BASE_FOLLOW_DISTANCE:
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/idle"] = false
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/running"] = true
		velocity = direction * current_speed
	else:
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/idle"] = true
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/running"] = false
		velocity = Vector2.ZERO
	
	move_and_slide()

# Called on _read() to enable physics after first frame
# Prevents navigation map from searching for path before it can synchronize
func _navigation_setup():
	await get_tree().physics_frame
	set_physics_process(true)

# Called by _process() when in range.
func _cast_spell(direction: Vector2):
	var instance: CharacterBody2D = BULLET.instantiate()
	instance.direction = facing.rotated(spell_angle)
	instance.spawn_pos = RETICLE.global_position
	instance.spawn_rot = facing.rotated(spell_angle).angle() - PI/2
	
	instance.set_collision_layer_value(5, true) # hero bullet
	instance.set_collision_mask_value(2, true)  # player
	
	bullet_spawn_node.add_child(instance)
	spell_ready = false
	SPELL_TIMER.start()


# Called by _physics_process() when a player projectile collides with the mage.
func _on_hit(dmg: int):
	current_hp -= dmg
	$HealthBar.value = current_hp * 100 / BASE_HP
	
	if current_hp <= 0.0 and !dead_emit_flag:
		# animation?
		dead_emit_flag = true
		dead.emit(self)  # Battle scene handles end of battle protocols.

# Checks whether the mage has line of sight on the minion by doing a raycast
# to the minion and seeing whether any walls are hit by the ray.
func _check_los():
	var space_state = get_world_2d().direct_space_state
	
	# Establish raycast parameters.
	var raycast = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position
	)
	raycast.exclude = [self, target]  # Does not collide with self or target.
	raycast.collision_mask = 1        # Only collides with walls.
	
	# Check for collisions and update los accordingly.
	var wall_collision = space_state.intersect_ray(raycast)
	los = wall_collision.is_empty()


func _on_spell_timer_timeout():
	spell_ready = true
	
	# Update spell_angle.
	if swing_right:
		if spell_angle > BASE_SPELL_ANGLE:
			swing_right = false
			spell_angle -= 0.1
		else:
			spell_angle += 0.1
	else:
		if spell_angle < -BASE_SPELL_ANGLE:
			swing_right = true
			spell_angle += 0.1
		else:
			spell_angle -= 0.1

func level_up():
	level += 1
	
func emit_dead_signal():
	dead.emit(self)

func stop():
	EventBus.hero_hit.disconnect(_on_hit)
	process_mode = Node.PROCESS_MODE_DISABLED	

func reset():
	bullet_spawn_node = get_parent()
	EventBus.hero_hit.connect(_on_hit)
	current_hp = BASE_HP + HP_GROWTH_RATE * (level - 1)
	current_speed = BASE_SPEED + SPEED_GROWTH_RATE * (level - 1)
	current_firing_cooldown = BASE_FIRING_COOLDOWN - FIRING_COOLDOWN_REDUCTION_RATE * (level - 1)
	SPELL_TIMER.wait_time = current_firing_cooldown
	process_mode = Node.PROCESS_MODE_INHERIT
