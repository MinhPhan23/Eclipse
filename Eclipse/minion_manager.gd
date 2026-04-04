extends Node2D

@onready var minion_scene_preload = preload("res://minion/minion.tscn")
@onready var location_manager = $"../LocationManager"

const MAX_MINIONS: int = 3

var rng: RandomNumberGenerator
var minion_names_list: Array[String]
var _all_minion_list: Array[Node]
var _deployable_minion_list: Array[Node]
var _deployed_minion: int

signal minion_return


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	
	minion_names_list = [
		"Keith","Terry","Mark","Lisa","Helen","Megan","Wraith","Blackjack",
		"Musket","Wraith","Mince","Sparrow","Mongrel","Twitch","Veil","Haze",
		"Thistle","Fox","Raven","Umber","Ratchet","Dash","Sprite","Sage",
		"Fluke","Pyro","Splinter","Crow","Mirage","Coyote","Storm","Kiss",
		"Blink","Faze","Vaic","Ghrusk","Xenk","Cric","Riarg","Kreng","Xig",
		"Ghrim","Scul","Scaadi","Thriax","Kheinzah","Rigrein","Rirgaan",
		"Crod","Dhung","Khrech","Ghos","Kegma","Eguhn","Elgri","Shezsru","Bonk",
		"Velarian","Nestor","Lanxas","Hestia","Amalia","Kazius","Robyn","Ford",
		"Draven","Sylthas","Belmont","Tyrgen","Ruwin","Sullivan","Smogus",
		"Hefnd","Viusu","Thaddeus","Cassius","Toyota","Arcus","Hunter","Eirrik",
		"Digit","Valentine","Zemirah","Orthorien","Ren","Chaos","Sidra",
		"Gabbro","Feldspar","Blare","Viho","Geet","Dr. Uncle","Lethe","Othree",
		"Natki","Arag","Paren","Chess"
	]
	
	# Initialize the player's minions.
	for i in 3:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = generate_minion_name()
		new_minion.dead.connect(remove_dead_minion)
		_all_minion_list.append(new_minion)
	_deployable_minion_list = _all_minion_list.duplicate()
	_deployed_minion = 0


# Generate a name for a new minion.
func generate_minion_name() -> String:
	var rand = rng.randi_range(0, 99)
	return minion_names_list[rand]


# At the start of a new day, return all minions from their assigned locations
# to the _deployable_minion_list and generate a new minion if the player's
# minion roster is not full.
# Called by generate_next_day() in location_manager.gd.
func new_day() -> void:
	minion_return.emit()  # Signal all locations to return deployed minions.
	
	# Add one new minion to the player's roster if there are fewer than max.
	if _all_minion_list.size() < MAX_MINIONS:
		var new_minion = minion_scene_preload.instantiate()
		new_minion.name = generate_minion_name()
		new_minion.dead.connect(remove_dead_minion)
		_all_minion_list.append(new_minion)
	
	_deployable_minion_list = _all_minion_list.duplicate()
	_deployed_minion = 0
	
	# Rest minions that were deployed in the previous day and remove them from
	# the list of deployable minions for today.
	for i in _deployable_minion_list.duplicate():
		if i.needs_rest:
			i.rest()
			_deployable_minion_list.erase(i)


# Create an array of the deployable minions.
# Called by transfer_minion_dialog() in location_manager.gd to create a minion
# deployment menu.
func minion_arr() -> Array[String]:
	var arr: Array[String] = []
	for i in _deployable_minion_list:
		arr.append("%s Lvl:%d" % [i.name, i.level])
	return arr


# Deploy a minion to a specified location.
# Called by transfer_minion() in location_manager.gd.
func deploy_minion(loc: Location, index: int) -> void:
	if loc.minion == null:
		var mini = _deployable_minion_list[index]
		loc.add_minion(mini)
		_deployed_minion += 1
		_deployable_minion_list.erase(mini)
		mini.exhaust()


# Return a deployed minion to the deployable minions list from a specified
# location.
# Called by transfer_minion() in location_manager.gd.
func retrieve_minion(loc: Location) -> void:
	if loc.minion != null:
		var mini = loc.callback_minion()
		_deployable_minion_list.append(mini)
		_deployable_minion_list.sort_custom(func(a, b): return a.name < b.name)
		_deployed_minion -= 1
		mini.rest()


# Remove a defeated minion from the player's roster.
# Called by a minion's dead signal in _on_hit() or by simulation.gd if the
# minion loses a simulated battle.
func remove_dead_minion(dead_minion) -> void:
	_all_minion_list.erase(dead_minion)
	dead_minion.dead.disconnect(remove_dead_minion)
