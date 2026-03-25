extends Control

const TEXT_SPEED: float = 0.05

@onready var report_text: RichTextLabel = $ReportText
@onready var continue_button: Button = $ContinueButton

# Called when the node enters the scene tree for the first time.
func _ready():
	report_text.text = ""
	report_text.visible_characters = 0

func show_report(text: String) -> void:
	report_text.text = text
	var report_length = report_text.text.length()
	var duration = report_length * TEXT_SPEED
	var tween = get_tree().create_tween()
	tween.set_loops(1)

	report_text.text = text
	
	# Display report with crawling text
	# Will automatically call _report_done on finished
	show()
	tween.tween_property(report_text, "visible_characters", report_length, duration)
	tween.tween_callback(_report_done)

func _report_done() -> void:
	continue_button.disabled = false

func _on_continue_button_pressed():
	hide()
	report_text.text = ""
	report_text.visible_characters = 0
