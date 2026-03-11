extends Node2D

@onready var choices_dialog = $"BattleConfirmation"
@onready var next_day = $"Camera2D/NextDay"

@onready var battle_scene_preload = preload("res://battle/battle.tscn")
@onready var minion_scene_preload = preload("res://player/player.tscn")
@onready var location_array = [$"Castle1", $"Castle2"]

# Called when the node enters the scene tree for the first time.
func _ready():
	choices_dialog.choices = ["click this to change to battle scene"]
	choices_dialog.visible = false
	choices_dialog.process_mode = Node.PROCESS_MODE_DISABLED
	
	next_day.choices = ["Next day"]
	
	location_array[0].hero = minion_scene_preload.instantiate()
	location_array[1].hero = minion_scene_preload.instantiate()

func _on_battle_confirmed(index):
	var battle_scene = battle_scene_preload.instantiate()
	var tree = get_tree()
	var main_scene = tree.get_current_scene()
	battle_scene.main_scene = main_scene
	tree.get_root().add_child(battle_scene)
	tree.get_root().remove_child(main_scene)
	tree.set_current_scene(battle_scene)


func _on_next_day_selected(index):
	print("Castle1 event")
	print(location_array[0].generate_events())
	print("Castle2 event")
	print(location_array[1].generate_events())
