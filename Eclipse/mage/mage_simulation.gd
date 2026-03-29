extends CharacterBody2D

@onready var ANIMATION_TREE: AnimationTree = $AnimationTree

var _state_machine

func _ready():
	_state_machine = ANIMATION_TREE.get("parameters/StateMachine/MoveState/playback")

func attack():
	_state_machine.travel("attack_w")
	
func dead():
	_state_machine.travel("dead_w")
	
func reset():
	_state_machine.travel("IdleState")
	var facing_vector: Vector2 = Vector2(-1, 0).normalized()
	ANIMATION_TREE.set("parameters/StateMachine/MoveState/IdleState/blend_position", facing_vector)
