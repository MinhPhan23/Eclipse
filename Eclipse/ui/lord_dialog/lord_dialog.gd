extends Control

const TEXT_SPEED: float = 0.05

var tween: Tween
var current_dialog_index: int = 0
var dialog_texts: Array[String] = []

@onready var dialog: RichTextLabel = $PanelContainer/HBoxContainer/Label
@onready var continue_button: Button = $"PanelContainer/Button"

signal demon_lord_dialog_done

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	dialog.text = ""
	dialog.visible_characters = 0

func show_dialog(text: Array[String]) -> void:
	dialog_texts = text
	current_dialog_index = 0
	_show_dialog(dialog_texts[current_dialog_index])

func _show_dialog(text: String) -> void:
	continue_button.hide()

	dialog.text = text
	var dialog_length = dialog.text.length()
	var duration = dialog_length * TEXT_SPEED
	tween = get_tree().create_tween()
	tween.set_loops(1)

	# Display report with crawling text
	# Will automatically call _report_done on finished
	show()
	tween.tween_property(dialog, "visible_characters", dialog_length, duration)
	tween.tween_callback(_dialog_done)
	
func _dialog_done():
	continue_button.show()
	
func _on_continue_button_pressed():
	dialog.text = ""
	dialog.visible_characters = 0
	if (current_dialog_index < dialog_texts.size() - 1):
		current_dialog_index += 1
		_show_dialog(dialog_texts[current_dialog_index])
	else:
		hide()
		demon_lord_dialog_done.emit()
		
	continue_button.hide()
