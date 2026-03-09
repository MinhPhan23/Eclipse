extends Node2D

@onready var choicesDialog = $"ChoicesDiaglog"
var main_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	choicesDialog.choices = ["click this to change back to main"]
	choicesDialog.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_choices_diaglog_selected(index):
	var tree = get_tree()
	var battle_scene = tree.get_current_scene()
	tree.get_root().add_child(main_scene)
	tree.get_root().remove_child(battle_scene)
	tree.set_current_scene(main_scene)
