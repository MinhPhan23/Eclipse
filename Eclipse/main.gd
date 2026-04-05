extends Node2D

const FIRST_DEPLOYMENT: String = "These heroes are popping up everywhere according to the reports. Need to figure out where they are coming from and deal with them before they get too strong."
const FIRST_SIMULATION_WIN: String = "Seems like those deployed to %s can still do some work I guess."
const FIRST_SIMULATION_LOST: String = "Useless, wasted at %s can't even win a fight against some random hero."
const FIRST_SIMULATION_NO_HERO: String = "What? No hero found at %s? Can't even write a proper report."
const FIRST_BATTLE_TRIGGER: String = "Pathetic, letting the hero turn the tables on you like that. All the way at %s. Need to deal with everything myself"

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")

@onready var battle_reports: Array[String] = []
@onready var demon_lord_dialog_queue: Array[String] = [FIRST_DEPLOYMENT]
@onready var minion_win_first_time: bool = true
@onready var minion_lost_first_time: bool = true
@onready var minion_look_around_first_time: bool = true
@onready var battle_trigger_first_time: bool = true
@onready var first_day: bool = true
@onready var battle_trigger: bool = false

@onready var music = $Music

# UI Nodes
@onready var ui_layer: CanvasLayer = $UI
@onready var demon_lord_dialog: Control = $UI/LordDialog
@onready var countdown: Control = $UI/Countdown
@onready var start_battle: PanelContainer = $UI/StartBattle
@onready var event_report: Control = $UI/EventReport
@onready var battle_report: Control = $UI/BattleReport
@onready var report_button: TextureButton = $UI/ReportButton

@onready var location_manager: Node2D = $LocationManager

# Menu Layers
@onready var pause_menu: Control = $Pause/PauseMenu
@onready var control_menu: Control = $Pause/ControlMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	location_manager.battles_done.connect(_generate_battle_report)
	location_manager.minion_win.connect(_on_minion_win)
	location_manager.minion_lost.connect(_on_minion_lost)
	location_manager.minion_look_around.connect(_on_minion_look_around)
	location_manager.battle_trigger.connect(_on_battle_trigger)
	
	demon_lord_dialog.demon_lord_dialog_done.connect(_on_demon_lord_dialog_done)
	
	event_report.report_done.connect(_on_event_report_done)
	battle_report.report_done.connect(_on_battle_report_done)
	battle_report.disable_crawling()
	
	start_battle.choices = ["Deploy minion"]
	start_battle.label_text = ""
	demon_lord_dialog.show_dialog(demon_lord_dialog_queue.pop_front())

func _input(event):
	# toggle the report if it is finished running and there is not another dialog visible (i.e. tutorial)
	if event.is_action_pressed("toggle_report") and !event_report.is_running and !demon_lord_dialog.visible:
		event_report.toggle_report(!event_report.visible)

func start_simulation_battle(_index):
	start_battle.process_mode = Node.PROCESS_MODE_DISABLED
	location_manager.simulate_battle()

func _generate_next_day_events():
	var report_str: String
	if Globals.current_day < Globals.MAX_DAYS:
		report_button.set_disabled(true)
		Globals.next_day()  # Increment the day counter.
		location_manager.generate_next_day()
			
		report_str = _generate_event_report_string()
		
		countdown.next_day()
		event_report.show_report(report_str)
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

func _generate_battle_report():
	start_battle.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.75).timeout

	if !demon_lord_dialog_queue.is_empty():  # Demon lord yaps.
		demon_lord_dialog.show_dialog(demon_lord_dialog_queue.pop_front())

	var report_str = ""
	for report in battle_reports:
		report_str += report + '\n\n'
	if report_str.is_empty():
		report_str = "No minions were deployed."

	battle_report.show_report(report_str)
	battle_reports.clear()

func _start_final_battle() -> void:
	location_manager.start_final_battle()

func _generate_event_report_string() -> String:
	var events: Array[String] = location_manager.events

	var report_str = ""
	for event in events:
		if !event.is_empty():
			report_str += event + '\n\n'
	
	if report_str.is_empty():
		return "The day passes uneventfully."
	
	return report_str


# Demon lord tutorial dialogues.
func _on_demon_lord_dialog_done():
	if battle_trigger:
		# If battle is triggered, do not generate next day events.
		battle_trigger = false
	elif first_day:
		first_day = false
		_generate_next_day_events()
	
	if !demon_lord_dialog_queue.is_empty():  # Demon lord yaps.
		demon_lord_dialog.show_dialog(demon_lord_dialog_queue.pop_front())

func _on_minion_win(location_name: String):
	if (minion_win_first_time):
		minion_win_first_time = false
		demon_lord_dialog_queue.push_back(FIRST_SIMULATION_WIN % location_name)
	battle_reports.append("Minion won at %s." % location_name)

func _on_minion_lost(location_name: String):
	if (minion_lost_first_time):
		minion_lost_first_time = false
		demon_lord_dialog_queue.push_back(FIRST_SIMULATION_LOST % location_name)
	battle_reports.append("Minion lost at %s." % location_name)


func _on_minion_look_around(location_name: String):
	if (minion_look_around_first_time):
		minion_look_around_first_time = false
		demon_lord_dialog_queue.push_back(FIRST_SIMULATION_NO_HERO % location_name)
	battle_reports.append("No hero found at %s." % location_name)

func _on_battle_trigger(location_name: String):
	if (battle_trigger_first_time):
		battle_trigger_first_time = false
		demon_lord_dialog.show_dialog(FIRST_BATTLE_TRIGGER % location_name)
		battle_trigger = true
	battle_reports.append("Battle triggered at %s." % location_name)


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

func _on_pause_menu_pause():
	pause_menu.show()

func _on_pause_menu_unpause():
	pause_menu.hide()
	control_menu.hide()

func _on_event_report_done():
	report_button.set_disabled(false)
	report_button.set_pressed_no_signal(false)
	start_battle.process_mode = Node.PROCESS_MODE_INHERIT

func _on_battle_report_done():
	start_battle.process_mode = Node.PROCESS_MODE_INHERIT
	_generate_next_day_events()
