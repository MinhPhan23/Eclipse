extends Node2D

const FIRST_DEPLOYMENT: String = "These heroes are popping up everywhere according to the reports. Need to figure out where they are coming from and deal with them before they get too strong."
const FIRST_SIMULATION_WIN: String = "Seems like those deployed to %s can still do some work I guess."
const FIRST_SIMULATION_LOST: String = "Useless, wasted at %s can't even win a fight against some random hero."
const FIRST_SIMULATION_NO_HERO: String = "What? No hero found at %s? Can't even write a proper report."
const FIRST_BATTLE_TRIGGER: String = "Pathetic, letting the hero turn the tables on you like that. All the way at %s. Need to deal with everything myself"

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")

@onready var demon_lord_dialog: Control = $UI/LordDialog
@onready var demon_lord_dialog_queue: Array[String] = [FIRST_DEPLOYMENT]
@onready var battle_trigger: bool = false
@onready var ui_layer: CanvasLayer = $UI
@onready var countdown: Control = $UI/Countdown
@onready var start_battle: PanelContainer = $UI/StartBattle
@onready var report: Control = $UI/Report
@onready var location_manager: Node2D = $LocationManager
@onready var music = $Music

# Menu Layers
@onready var pause_menu: Control = $Pause/PauseMenu
@onready var control_menu: Control = $Pause/ControlMenu

# Called when the node enters the scene tree for the first time.
func _ready():	
	location_manager.start_next_day.connect(_generate_next_day_events)
	location_manager.minion_win.connect(_on_minion_win_first_time)
	location_manager.minion_lost.connect(_on_minion_lost_first_time)
	location_manager.minion_look_around.connect(_on_minion_look_around_first_time)
	location_manager.battle_trigger.connect(_on_battle_trigger_first_time)
	
	demon_lord_dialog.demon_lord_dialog_done.connect(_on_demon_lord_dialog_done)
	
	start_battle.choices = ["Start Battle"]
	start_battle.label_text = ""
	_generate_next_day_events()

func _input(event):
	if event.is_action_pressed("menu"):
		if !get_tree().paused:
			get_tree().paused = true
			pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
			pause_menu.show()
		else:
			pause_menu.hide()
			control_menu.hide()
			get_tree().paused = false
	

func start_simulation_battle(_index):
	start_battle.process_mode = Node.PROCESS_MODE_DISABLED
	location_manager.simulate_battle()

func _generate_next_day_events():
	var report_str: String
	if Globals.current_day < Globals.MAX_DAYS:
		if !demon_lord_dialog_queue.is_empty():
			var next_dialog = demon_lord_dialog_queue.pop_front()
			demon_lord_dialog.show_dialog(next_dialog)
		else:
			Globals.next_day()
			location_manager.generate_next_day()
			report_str = _generate_report_string()
			
			countdown.next_day()
			report.show_report(report_str)
			start_battle.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		# Trigger final battle
		location_manager.generate_next_day()
		report_str = "The hour of the eclipse is upon us. The final battle begins."
		var final_battle_dialog: Control = load("res://ui/accept_dialog/accept_dialog.tscn").instantiate()
		final_battle_dialog.dialog_content = report_str
		final_battle_dialog.accept_text = "Begin final battle"
		final_battle_dialog.alignment = HORIZONTAL_ALIGNMENT_LEFT
		final_battle_dialog.accept.connect(_start_final_battle)
		
		ui_layer.add_child(final_battle_dialog)

func _start_final_battle() -> void:
	location_manager.start_final_battle()

func _generate_report_string() -> String:
	var events: Array[String] = location_manager.events
	
	var report_str = ""
	for event in events:
		if !event.is_empty():
			report_str += event + '\n'
	
	if report_str.is_empty():
		return "The day passes uneventfully."
	
	return report_str

func _on_demon_lord_dialog_done():
	if battle_trigger:
		# If battle is triggered, do not generate next day events.
		battle_trigger = false
	else:
		_generate_next_day_events()

func _on_minion_win_first_time(location_name: String):
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_WIN % location_name)
	location_manager.minion_win.disconnect(_on_minion_win_first_time)

func _on_minion_lost_first_time(location_name: String):
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_LOST % location_name)
	location_manager.minion_lost.disconnect(_on_minion_lost_first_time)

func _on_minion_look_around_first_time(location_name: String):
	demon_lord_dialog_queue.push_back(FIRST_SIMULATION_NO_HERO % location_name)
	location_manager.minion_look_around.disconnect(_on_minion_look_around_first_time)

func _on_battle_trigger_first_time(location_name: String):
	battle_trigger = true
	demon_lord_dialog.show_dialog(FIRST_BATTLE_TRIGGER % location_name)
	location_manager.battle_trigger.disconnect(_on_battle_trigger_first_time)

# Loop background music.
func _on_music_finished():
	music.play()

func _on_control_menu_close_menu():
	control_menu.hide()

func _on_pause_menu_open_controls():
	control_menu.show()


func _on_pause_menu_close_menu():
	pause_menu.hide()
	control_menu.hide()
	get_tree().paused = false
