extends Node2D

@onready var minion_scene_preload: PackedScene = preload("res://minion/minion.tscn")
@onready var hero_scene_preload: PackedScene = preload("res://mage/mage.tscn")

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
	Globals.next_day()
	var report_str: String
	
	if Globals.current_day <= Globals.MAX_DAYS:
		location_manager.generate_next_day()
		report_str = _generate_report_string()
		
		countdown.next_day()
		report.show_report(report_str)
		start_battle.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		# Trigger final battle
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
