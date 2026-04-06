extends Control

#dates stored in log
const LOG_MAX_SIZE = 3

@onready var report_text_entry: RichTextLabel = $Margins/VBoxContainer/ScrollContainer/VBox/ReportText
@onready var report_entry_list: VBoxContainer = $Margins/VBoxContainer/ScrollContainer/VBox

# sounds
@onready var open_report = $OpenReport
@onready var close_report = $CloseReport

var _log_size

signal report_done

# Called when the node enters the scene tree for the first time.
func _ready():
	_log_size = 0

func toggle_report(toggle_on: bool) -> void:
	if toggle_on:
		show()
	else:
		hide()
		
func push_report_entry(text: String):
	if (_log_size == 0):
		report_text_entry.text = text
	else:
		if (_log_size == LOG_MAX_SIZE):
			var entry_to_be_removed: RichTextLabel = report_entry_list.get_child(_log_size - 1)
			report_entry_list.remove_child(entry_to_be_removed)
		var entry_to_be_pushed: RichTextLabel = report_text_entry.duplicate()
		entry_to_be_pushed.text = text
		report_entry_list.add_child(entry_to_be_pushed)
		report_entry_list.move_child(entry_to_be_pushed, 0)
	_log_size += 1

func _on_continue_button_pressed():
	close_report.play()
	hide()
