extends CharacterBody2D

@export var SPEED = 50
@export var MINION : Node2D
@export var SPELL_RANGE = 300
@export var FOLLOW_DISTANCE = 200
@export var MAX_HP = 10
@export var current_hp = 10
@export var DAMAGE = 1
@export var MAX_SPELL_ANGLE = 0.5  # Maximum angle away from slime that spell will be cast.

var facing : Vector2  # Direction the mage is facing (v_minion.normalized()).
var los : bool  # Line of sight.
var spell_ready = true  # Updated by SpellTimer
var spell_angle : float  # Angle offset for firebolt attack.
var swing_right = true  # Used to control the swing of the firebolt angle.

@onready var NAV_AGENT = $NavigationAgent2D
@onready var MAIN = get_tree().get_root().get_node("Main")
@onready var FIREBOLT = load("res://firebolt.tscn")

signal dead_mage  # Emitted at 0 hp.


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var v_minion = MINION.global_position - global_position
	facing = v_minion.normalized()
	
	if v_minion.length() < SPELL_RANGE and spell_ready:
		CastSpell(facing)
	
	# TODO: movement animations


func _physics_process(delta):
	# TODO: check for incoming damage.
	#if hit by player projectile:
		#get player projectile damage
		#TakeDamage(damage value)
	
	
	# Pathfinding.
	NAV_AGENT.target_position = MINION.global_position
	# v = vector from mage to MINION.
	var v_minion = MINION.global_position - global_position
	var direction = to_local(NAV_AGENT.get_next_path_position()).normalized()
	
	CheckLOS(MINION)
	
	# Move toward or away from MINION until reaching FOLLOW_DISTANCE.
	if v_minion.length() > FOLLOW_DISTANCE or !los:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()


# Called by _process() when in range.
func CastSpell(direction):
	var instance = FIREBOLT.instantiate()
	instance.direction = facing.rotated(spell_angle)
	instance.spawnPos = global_position
	instance.spawnRot = global_rotation #spell_angle?
	MAIN.add_child(instance)
	spell_ready = false


# Called by _physics_process() when a player projectile collides with the mage.
func TakeDamage(dmg):
	current_hp = current_hp - dmg
	if current_hp <= 0:
		# animation?
		dead_mage.emit()  # Battle scene handles end of battle protocols.


# Checks whether the mage has line of sight on the minion by doing a raycast
# to the minion and seeing whether any walls are hit by the ray.
func CheckLOS(minion: CharacterBody2D):
	var space_state = self.get_world_2d().direct_space_state
	
	# Establish raycast parameters.
	var raycast = PhysicsRayQueryParameters2D.create(
		self.global_position,
		minion.global_position
	)
	raycast.exclude = [self]  # Does not collide with self.
	raycast.collision_mask = 1  # Only collides with walls.
	
	# Check for collisions and update los accordingly.
	var wall_collision = space_state.intersect_ray(raycast)
<<<<<<< HEAD
	los = wall_collision.is_empty()
=======
	los = wall_collision.is_empty():		
>>>>>>> 86732688b07b7dc80e8d16ce4ef5ca80d0713c2c


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
