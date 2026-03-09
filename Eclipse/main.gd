extends Node2D

@onready var choicesDialog = $"ChoicesDiaglog"

var battle_scene_preload = preload("res://battle/battle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	choicesDialog.choices = ["click this to change to battle scene"]
	choicesDialog.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_choices_diaglog_selected(index):
	var battle_scene = battle_scene_preload.instantiate()
	var tree = get_tree()
	var main_scene = tree.get_current_scene()
	battle_scene.main_scene = main_scene
	tree.get_root().add_child(battle_scene)
	tree.get_root().remove_child(main_scene)
	tree.set_current_scene(battle_scene)
