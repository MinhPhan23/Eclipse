extends Node2D

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var location_manager = $"../LocationManager"
@onready var minion_status_panel = $"../UI/MinionStatusPanel/GridContainer"
@onready var status_card_preload = preload("res://minion/minion_status_card.tscn")

const MAX_MINIONS: int = 3

var rng: RandomNumberGenerator
var all_minion_list: Array[Node]
var deployable_minion_list: Array[Node]
var deployed_minion: int

signal minion_return


const MINION_NAMES_LIST: Array[String] = [
	"Keith","Terry","Mark","Lisa","Helen","Megan","Wraith","Blackjack",
	"Musket","Grog","Mince","Sparrow","Mongrel","Twitch","Veil","Haze",
	"Thistle","Fox","Raven","Umber","Ratchet","Dash","Sprite","Sage","Fluke",
	"Pyro","Splinter","Crow","Mirage","Coyote","Storm","Kiss","Blink","Faze",
	"Vaic","Ghrusk","Xenk","Cric","Riarg","Kreng","Xig","Ghrim","Scul","Scaadi",
	"Thriax","Kheinzah","Rigrein","Rirgaan","Crod","Dhung","Khrech","Ghos",
	"Kegma","Eguhn","Elgri","Shezsru","Bonk"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	
	# Initialize the player's minions.
	for i in 3:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = generate_minion_name()
		new_minion.dead.connect(remove_dead_minion)
		all_minion_list.append(new_minion)
	deployable_minion_list = all_minion_list.duplicate()
	deployed_minion = 0
	
	# Initialize the minion status panel.
	update_minion_panel()


# Generate a name for a new minion.
func generate_minion_name() -> String:
	var rand = rng.randi_range(0, MINION_NAMES_LIST.size()-1)
	return MINION_NAMES_LIST[rand]


# At the start of a new day, return all minions from their assigned locations
# to the _deployable_minion_list and generate a new minion if the player's
# minion roster is not full.
# Called by generate_next_day() in location_manager.gd.
func new_day() -> void:
	minion_return.emit()  # Signal all locations to return deployed minions.
	
	# Add one new minion to the player's roster if there are fewer than max.
	if all_minion_list.size() < MAX_MINIONS:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = generate_minion_name()
		new_minion.dead.connect(remove_dead_minion)
		all_minion_list.append(new_minion)
	
	deployable_minion_list = all_minion_list.duplicate()
	deployed_minion = 0
	
	# Rest minions that were deployed in the previous day and remove them from
	# the list of deployable minions for today.
	for i in deployable_minion_list.duplicate():
		if i.needs_rest:
			i.rest()
			i.set_status("Resting")
			deployable_minion_list.erase(i)
		else:
			i.set_status("Ready")
	
	update_minion_panel()


# Create an array of the deployable minions.
# Called by transfer_minion_dialog() in location_manager.gd to create a minion
# deployment menu.
func minion_arr() -> Array[String]:
	var arr: Array[String] = []
	for i in deployable_minion_list:
		arr.append("%s Lvl:%d" % [i.name, i.level])
	return arr


# Deploy a minion to a specified location.
# Called by transfer_minion() in location_manager.gd.
func deploy_minion(loc: Location, index: int) -> void:
	if loc.minion == null:
		var mini = deployable_minion_list[index]
		loc.add_minion(mini)
		deployed_minion += 1
		deployable_minion_list.erase(mini)
		var status_str: String = "Deployed to\n%s" % loc.name_short
		#print("Setting ", mini.name, "'s status to ", status_str) #testing
		mini.set_status(status_str)
		update_minion_panel()
		mini.exhaust()


# Return a deployed minion to the deployable minions list from a specified
# location.
# Called by transfer_minion() in location_manager.gd.
func retrieve_minion(loc: Location) -> void:
	if loc.minion != null:
		var mini = loc.callback_minion()
		deployable_minion_list.append(mini)
		deployable_minion_list.sort_custom(func(a, b): return a.name < b.name)
		deployed_minion -= 1
		mini.set_status("Ready")
		update_minion_panel()
		mini.rest()


# Update the displayed statuses of the current minions.
# Called by ready(), deploy_minion(), retrieve_minion()
func update_minion_panel() -> void:
	# Clear the current panel.
	for child in minion_status_panel.get_children():
		child.queue_free()
	
	# Get minion cards and display in the status panel.
	# Null minions do not generate a status card.
	for i in all_minion_list:
		var status_card = status_card_preload.instantiate()
		status_card.set_minion(i)
		minion_status_panel.add_child(status_card)


# Remove a defeated minion from the player's roster.
# Called by a minion's dead signal in _on_hit() or by simulation.gd if the
# minion loses a simulated battle.
func remove_dead_minion(dead_minion) -> void:
	all_minion_list.erase(dead_minion)
	dead_minion.dead.disconnect(remove_dead_minion)
