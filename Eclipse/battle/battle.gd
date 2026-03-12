extends Node2D

@onready var choicesDialog = $"ChoicesDiaglog"
@onready var win = false

var main_scene: Node2D
var location: Area2D
var minion_spawn_coord = Vector2(30, 30)
var hero_spawn_coord = Vector2(50, 50)

# Called when the node enters the scene tree for the first time.
func _ready():
	choicesDialog.choices = ["click this to change back to main"]
	choicesDialog.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_hero_and_minion(hero, minion):
	hero.name = "Hero"
	hero.position = hero_spawn_coord
	add_child(hero)
	minion.name = "Minion"
	minion_spawn_coord = minion_spawn_coord
	add_child(minion)

func _on_choices_diaglog_selected(index):
	var hero = $"Hero"
	var minion = $"Minion"
	
	var tree = get_tree()
	var root = tree.get_root()
	var battle_scene = tree.get_current_scene()
	
	if (win):
		minion.level += 1
		location.hero = null
	else:
		hero.level += 1
		location.minion = null
	
	remove_child(hero)
	remove_child(minion)
	
	root.add_child(main_scene)
	root.remove_child(battle_scene)
	tree.set_current_scene(main_scene)
	queue_free()
