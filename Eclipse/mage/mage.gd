extends CharacterBody2D


signal dead  # Emitted at 0 hp.

@onready var ANIMATION_TREE: AnimationTree = $AnimationTree
@onready var NAV_AGENT = $NavigationAgent2D
@onready var RETICLE = $Reticle
@onready var impact_sound = $ImpactSound

# BATTLE VARIABLES
@export var RETICLE_DIST: float = 25.0    # distance from model center, pixels
@export var BASE_FOLLOW_DISTANCE: int = 200
@export var CLOSE_RANGE: int = 400
var is_fighting: bool = false
var target: CharacterBody2D
var facing: Vector2  # Direction the mage is facing (v_minion.normalized()).
var distance: float  # Distance from mage to minion
var los: bool  # Line of sight.
var dead_emit_flag: bool = false

# HERO VARIABLES
@export var LVLUP_RATE: int = 2  # Number of days it takes a hero to level up.
@export var BASE_HP: float = 100.0
@export var HP_GROWTH_RATE: int = 50
@export var BASE_SPEED: int = 50
@export var SPEED_GROWTH_RATE: int = 10
# lvlup_countdown is decremented and reset in generate_next_day() in
# location_manager.gd, hero level is incremented when it hits 0.
var lvlup_countdown: int  
var level: int = 1
var current_max_hp: float = BASE_HP
var current_hp: float = current_max_hp
var current_speed: int = BASE_SPEED


# SPELLCASTING VARIABLES
@onready var casting_timer = $CastingTimer  # No spellcasting while this timer is running.
var ready_to_cast: bool = true  # Toggle false after casting spell, toggle true _on_casting_timer_timeout().

# BURN
@onready var BULLET = preload("res://projectile/firebolt.tscn")
@onready var BURN_TIMER = $BurnTimer
@export var BURN_UNLOCK_LVL: int = 1
@export var BASE_BURN_COOLDOWN: float = 0.4     # seconds
@export var MIN_BURN_COOLDOWN: float = 0.1
@export var BURN_COOLDOWN_REDUCTION_RATE: float = 0.03
@export var BASE_BURN_ANGLE: float = 0.5  # Maximum angle away from player that spell will be cast, radians.
var bullet_spawn_node: Node
var burn_cooldown: float = BASE_BURN_COOLDOWN
var burn_ready = true  # Updated by BurnTimer
var burn_angle : float  # Angle offset for Burn spell.
var swing_right = true  # Used to control the swing of the Burn angle.



func _ready():
	var v_minion = target.global_position - global_position
	facing = v_minion.normalized()
	distance = v_minion.length()
	
	BURN_TIMER.wait_time = burn_cooldown
	
	# Set HealthBar to full.
	$HealthBar.value = current_hp * 100 / current_max_hp
	
	# wait for physics frame to be ready for navigation
	set_physics_process(false)
	call_deferred("_navigation_setup")


func _process(_delta):
	var v_minion = target.global_position - global_position
	facing = v_minion.normalized()
	distance = v_minion.length()
	RETICLE.position = facing * RETICLE_DIST
	
	if is_fighting and ready_to_cast:
		_cast_spell()
	
	# Update HealthBar
	$HealthBar.value = current_hp * 100.0 / current_max_hp


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
	if is_fighting and (!los or v_minion.length() > BASE_FOLLOW_DISTANCE):
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/idle"] = false
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/running"] = true
		velocity = direction * current_speed
	else:
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/idle"] = true
		ANIMATION_TREE["parameters/StateMachine/MoveState/conditions/running"] = false
		velocity = Vector2.ZERO
	
	move_and_slide()


# Called on _ready() to enable physics after first frame
# Prevents navigation map from searching for path before it can synchronize
func _navigation_setup():
	await get_tree().physics_frame
	set_physics_process(true)
	

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


func _on_casting_timer_timeout():
	ready_to_cast = true


# Choose a spell to cast from available unlocked spells then cast it.
func _cast_spell():	
	# New choose spell logic
	#if level >= SHIELD_UNLOCK_LVL and distance > CLOSE_RANGE and !shielded:
	#	cast shield spell
	#elif level >= GLPYH_UNLOCK_LVL and glyph_ready:
	#	cast glyph spell  #TODO: implement mage strafing
	#elif level >= FIREBALL_UNLOCK_LVL and distance <= CLOSE_RANGE and fireball_ready:
	#	cast fireball spell
	if level >= BURN_UNLOCK_LVL and distance <= CLOSE_RANGE and burn_ready:
		_cast_burn()
	#elif level >= LIGHTNING_UNLOCK_LVL and distance > CLOSE_RANGE and lightning_ready:
	#	cast lightning spell


# Burn spell.
func _cast_burn() -> void:
	var instance: CharacterBody2D = BULLET.instantiate()
	instance.direction = facing.rotated(burn_angle)
	instance.spawn_pos = RETICLE.global_position
	instance.spawn_rot = facing.rotated(burn_angle).angle() - PI/2
	
	instance.set_collision_layer_value(5, true) # hero bullet
	instance.set_collision_mask_value(2, true)  # player
	
	bullet_spawn_node.add_child(instance)
	burn_ready = false
	BURN_TIMER.start()
	
	ready_to_cast = false
	casting_timer.wait_time = burn_cooldown
	casting_timer.start()

func _on_burn_timer_timeout():
	burn_ready = true
	
	# Update burn_angle.
	if swing_right:
		if burn_angle > BASE_BURN_ANGLE:
			swing_right = false
			burn_angle -= 0.1
		else:
			burn_angle += 0.1
	else:
		if burn_angle < -BASE_BURN_ANGLE:
			swing_right = true
			burn_angle += 0.1
		else:
			burn_angle -= 0.1


# Called by _physics_process() when a player projectile collides with the mage.
func _on_hit(dmg: int):
	impact_sound.play()
	
	current_hp -= dmg
	if current_hp <= 0.0 and !dead_emit_flag:
		# animation?
		dead_emit_flag = true
		dead.emit(self)  # Battle scene handles end of battle protocols.


# Level up the mage.
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
	
	# Update mage stats.
	current_max_hp = BASE_HP + HP_GROWTH_RATE * (level - 1)
	current_hp = current_max_hp
	current_speed = BASE_SPEED + SPEED_GROWTH_RATE * (level - 1)
	
	# Update Burn spell.
	if burn_cooldown > MIN_BURN_COOLDOWN:
		burn_cooldown = BASE_BURN_COOLDOWN - BURN_COOLDOWN_REDUCTION_RATE * (level - 1)
	BURN_TIMER.wait_time = burn_cooldown
	process_mode = Node.PROCESS_MODE_INHERIT
