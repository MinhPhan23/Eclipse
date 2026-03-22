extends CharacterBody2D

@export var SPEED: int = 50
@export var TARGET : Node2D
@export var SPELL_RANGE: int = 300
@export var FOLLOW_DISTANCE: int = 200
@export var MAX_HP: int = 10
@export var current_hp: int  = MAX_HP
@export var DAMAGE: int = 1
@export var MAX_SPELL_ANGLE: float = 0.5  # Maximum angle away from player that spell will be cast.
@export var FIRING_RATE: float = 0.25     # seconds
@export var RETICLE_DIST: float = 25.0    # distance from model center, pixels

var level: int = 1
var facing : Vector2  # Direction the mage is facing (v_minion.normalized()).
var los : bool  # Line of sight.
var spell_ready = true  # Updated by SpellTimer
var spell_angle : float  # Angle offset for firebolt attack.
var swing_right = true  # Used to control the swing of the firebolt angle.
var dead_emit_flag: bool = false

@onready var BULLET = preload("res://projectile/firebolt.tscn")
@onready var ANIMATION_TREE: AnimationTree = $AnimationTree
@onready var BULLET_SPAWN_NODE: Node = get_parent()
@onready var NAV_AGENT = $NavigationAgent2D
@onready var RETICLE = $Reticle
@onready var SPELL_TIMER = $SpellTimer

signal dead  # Emitted at 0 hp.

func _ready():
	EventBus.hero_hit.connect(_on_hit)
	SPELL_TIMER.wait_time = FIRING_RATE
	
	# wait for physics frame to be ready for navigation
	set_physics_process(false)
	call_deferred("_navigation_setup")

func _process(_delta):
	var v_minion = TARGET.global_position - global_position
	facing = v_minion.normalized()
	
	if v_minion.length() < SPELL_RANGE and spell_ready:
		RETICLE.position = facing * RETICLE_DIST
		_cast_spell(facing)
	
	# TODO: movement animations


func _physics_process(_delta):
	# Pathfinding.
	NAV_AGENT.target_position = TARGET.global_position
	# v = vector from mage to MINION.
	var v_minion = TARGET.global_position - global_position
	var direction = to_local(NAV_AGENT.get_next_path_position()).normalized()
	
	_check_los(TARGET)
	
	# Animation
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/RunState/blend_position", v_minion.normalized())
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/IdleState/blend_position", v_minion.normalized())
	
	# Move toward or away from MINION until reaching FOLLOW_DISTANCE.
	if v_minion.length() > FOLLOW_DISTANCE or !los:
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/idle"] = false
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/running"] = true
		velocity = direction * SPEED
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
	
	instance.set_collision_layer_value(5, true) # hero bullet
	instance.set_collision_mask_value(2, true)  # player
	
	BULLET_SPAWN_NODE.add_child(instance)
	spell_ready = false
	SPELL_TIMER.start()


# Called by _physics_process() when a player projectile collides with the mage.
func _on_hit(dmg: int):
	current_hp -= dmg
	if current_hp <= 0.0 and !dead_emit_flag:
		# animation?
		dead_emit_flag = true
		dead.emit()  # Battle scene handles end of battle protocols.

# Checks whether the mage has line of sight on the minion by doing a raycast
# to the minion and seeing whether any walls are hit by the ray.
func _check_los(target: CharacterBody2D):
	var space_state = get_world_2d().direct_space_state
	
	# Establish raycast parameters.
	var raycast = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position
	)
	raycast.exclude = [self]  # Does not collide with self.
	raycast.collision_mask = 1  # Only collides with walls.
	
	# Check for collisions and update los accordingly.
	var wall_collision = space_state.intersect_ray(raycast)
	los = wall_collision.is_empty()


func _on_spell_timer_timeout():
	spell_ready = true
	
	# Update spell_angle.
	if swing_right:
		if spell_angle > MAX_SPELL_ANGLE:
			swing_right = false
			spell_angle -= 0.1
		else:
			spell_angle += 0.1
	else:
		if spell_angle < -MAX_SPELL_ANGLE:
			swing_right = true
			spell_angle += 0.1
		else:
			spell_angle -= 0.1

func level_up():
	level += 1

func stop():
	process_mode = Node.PROCESS_MODE_DISABLED

func run():
	process_mode = Node.PROCESS_MODE_INHERIT

func reset():
	current_hp = MAX_HP
