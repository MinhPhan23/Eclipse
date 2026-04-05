extends Control

const TEXT_SPEED: float = 0.05

var tween: Tween

@onready var dialog: RichTextLabel = $PanelContainer/HBoxContainer/Label
@onready var continue_button: Button = $"PanelContainer/Button"

signal demon_lord_dialog_done

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	dialog.text = ""
	dialog.visible_characters = 0
	
func _input(event):
	if event.is_action_pressed("continue_dialog"):
		if tween.is_running():
			# skip animation
			tween.pause()
			tween.custom_step(INF)
			_dialog_done()

func show_dialog(text: String) -> void:
	continue_button.hide()

	dialog.text = text
	var dialog_length = dialog.text.length()
	var duration = dialog_length * TEXT_SPEED
	tween = get_tree().create_tween()
	tween.set_loops(1)

	# Display report with crawling text
	# Will automatically call _dialog_done on finished
	show()
	tween.tween_property(dialog, "visible_characters", dialog_length, duration)
	tween.tween_callback(_dialog_done)
	
func _dialog_done():
	continue_button.show()
	
func _on_continue_button_pressed():
	dialog.text = ""
	dialog.visible_characters = 0
	hide()
	demon_lord_dialog_done.emit()
	continue_button.hide()
