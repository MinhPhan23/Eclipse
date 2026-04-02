extends Control

signal accept

@export var dialog_content: String
@export var accept_text: String
@export var alignment: HorizontalAlignment

@onready var button: Button = $Button
@onready var dialog_content_box: Label = $Label

func _ready():
	button.text = accept_text
	dialog_content_box.text = dialog_content
	dialog_content_box.horizontal_alignment = alignment

func _on_button_pressed():
	accept.emit()
