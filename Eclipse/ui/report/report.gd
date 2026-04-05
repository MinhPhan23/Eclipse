extends Control

const TEXT_SPEED: float = 0.05
var tween: Tween
var is_running: bool

@onready var report_text: RichTextLabel = $Margins/VBox/BodyMargins/ReportText
@onready var continue_button: Button = $Margins/VBox/ContinueButton

# sounds
@onready var open_report = $OpenReport
@onready var close_report = $CloseReport
@onready var click_sound = $ClickSound
@onready var textcrawl_sound = $TextcrawlSound

signal report_done

# Called when the node enters the scene tree for the first time.
func _ready():
	is_running = false
	report_text.text = ""
	report_text.visible_characters = 0
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta):
	if Input.is_action_just_pressed("continue_dialog"):
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

func show_report(text: String) -> void:
	report_text.text = text
	report_text.visible_characters = 0
	continue_button.hide()
	
	process_mode = Node.PROCESS_MODE_INHERIT
	open_report.play()
	
	var report_length = report_text.text.length()
	var duration = report_length * TEXT_SPEED
	tween = get_tree().create_tween()
	tween.set_loops(1)

	# Display report with crawling text
	# Will automatically call _report_done on finished
	is_running = true
	show()
	textcrawl_sound.play()
	tween.tween_property(report_text, "visible_characters", report_length, duration)
	tween.tween_callback(_report_done)

func _report_done() -> void:
	continue_button.show()
	textcrawl_sound.stop()
	is_running = false

func _on_continue_button_pressed():
	close_report.play()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	report_done.emit()
