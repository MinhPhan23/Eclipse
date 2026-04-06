extends Control

const TEXT_SPEED: float = 0.05
var tween: Tween
var is_running: bool
var crawling_enabled: bool = true

@export var button_text: String
@export var report_title: String

@onready var report_text: RichTextLabel = $Margins/VBox/BodyMargins/ReportText
@onready var continue_button: Button = $Margins/VBox/ContinueButton
@onready var title_label: Label = $Margins/VBox/Label

# sounds
@onready var open_report = $OpenReport
@onready var close_report = $CloseReport
@onready var click_sound = $ClickSound
@onready var textcrawl_sound = $TextcrawlSound

signal report_done

# Called when the node enters the scene tree for the first time.
func _ready():
	is_running = false
	continue_button.text = button_text
	title_label.text = report_title
	report_text.text = ""
	report_text.visible_characters = 0
	
	# Prevents conflicting dialogue actions
	process_mode = Node.PROCESS_MODE_DISABLED


func _input(event):
	if crawling_enabled and event.is_action_pressed("continue_dialog"):
		click_sound.play()
		if tween.is_running():
			# skip animation
			tween.pause()
			tween.custom_step(INF)
			_report_done()

func toggle_report(toggle_on: bool) -> void:
	if toggle_on:
		show()
		open_report.play()
	else:
		hide()
		close_report.play()

func disable_crawling():
	crawling_enabled = false

func show_report(text: String) -> void:
	report_text.text = text
	report_text.visible_characters = 0
	continue_button.hide()
	
	process_mode = Node.PROCESS_MODE_INHERIT
	open_report.play()
	show()

	var report_length = report_text.text.length()
	if crawling_enabled:
		var duration = report_length * TEXT_SPEED
		tween = get_tree().create_tween()
		tween.set_loops(1)
		is_running = true
		# Display report with crawling text
		# Will automatically call _report_done on finished
		
		textcrawl_sound.play()
		tween.tween_property(report_text, "visible_characters", report_length, duration)
		tween.tween_callback(_report_done)
	else:
		report_text.visible_characters = report_length
		continue_button.show()

func _report_done() -> void:
	is_running = false
	continue_button.show()
	textcrawl_sound.stop()

func _on_continue_button_pressed():
	close_report.play()
	hide()
	report_done.emit()
