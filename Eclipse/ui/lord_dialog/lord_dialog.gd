extends Control

const TEXT_SPEED: float = 0.05

var tween: Tween

@onready var dialog: RichTextLabel = $PanelContainer/HBoxContainer/Label
@onready var close_button: Button = $"PanelContainer/Button"

# Called when the node enters the scene tree for the first time.
func _ready():
	dialog.text = ""
	dialog.visible_characters = 0

func show_dialog(text: String) -> void:
	dialog.text = text
	var dialog_length = dialog.text.length()
	var duration = dialog_length * TEXT_SPEED
	tween = get_tree().create_tween()
	tween.set_loops(1)

	# Display report with crawling text
	# Will automatically call _report_done on finished
	show()
	tween.tween_property(dialog, "visible_characters", dialog_length, duration)

func _on_close_button_pressed():
	close_button.hide()
	hide()
	dialog.text = ""
	dialog.visible_characters = 0
