extends Node

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var hero_scene_preload = preload("res://minion/minion.tscn")
@onready var minion_choice = $"MinionList"
var day: int
var location: Array[Node];
var minion_list: Array[Node];
var rand_num:RandomNumberGenerator; 
var curr_loc:String;
# Called when the node enters the scene tree for the first time.
func _ready():
	day = 0
	rand_num = RandomNumberGenerator.new()
	for i in 3:
		var goon = minion_scene_preload.instantiate()
		goon.name = "Minion " + str(i + 1)
		minion_list.append(goon)
	location = get_children()
	# To remove MininonList for our array
	location.remove_at(location.size() - 1)
	
	minion_choice.label_text = "Send Minion?"
	set_minion_choice()
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	

func proceed_to_next_day():
	day += 1
	
func send_minion_dialog(location):
	print(location)
	minion_choice.visible = true
	minion_choice.process_mode = Node.PROCESS_MODE_INHERIT
	curr_loc = location

func set_minion_choice():
	minion_choice.choices = [
		"Minion %d Atk:%d Lvl:%d Health:%d/%d"%[1 ,minion_list[0].strength,minion_list[0].level, minion_list[0].current_health,minion_list[0].MAX_HEALTH],
		"Minion %d Atk:%d Lvl:%d Health:%d/%d"%[2 ,minion_list[1].strength,minion_list[1].level, minion_list[1].current_health,minion_list[1].MAX_HEALTH],
		"Minion %d Atk:%d Lvl:%d Health:%d/%d"%[3 ,minion_list[2].strength,minion_list[2].level, minion_list[2].current_health,minion_list[2].MAX_HEALTH]
	]
	#Might need to implement it using for loop later on
	#for i in 3:
	#	minion_choice.choices.append("YES")
	#print(minion_choice.choices)
	
func generate_hero():
	var index:int = rand_num.randi_range(0, location.size() - 1)
	if location[index].hero == null:
		location[index].hero_add(hero_scene_preload.instantiate())
	
func send_minion(index):
	
	minion_choice.visible = false
	minion_choice.process_mode = Node.PROCESS_MODE_DISABLED
	for i in location:
		if i.name == curr_loc and i.minion == null:
			i.minion_add(minion_list[index])
	

func generate_event():
	var index:int = rand_num.randi_range(0, location.size() - 1)
	if location[index].has_method("generate_events"):
		location[index].generate_events()
		
func _on_next_day_selected(index):
	start_battle()
	proceed_to_next_day()
	generate_hero()
	generate_event()
	
func start_battle():
	for i in location :
		if i.hero != null and i.minion != null:
			i._open_battle_confirmation_dialog()
			break
	
