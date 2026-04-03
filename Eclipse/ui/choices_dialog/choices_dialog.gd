extends PanelContainer

signal SELECTED(index)

@onready var choices_list = $"MarginContainer/Choices"
@onready var choice_prefab = $"MarginContainer/Choices/Button"
@onready var label = $"Label"
@onready var margin_container = $"MarginContainer"

var choices:
	set(value):
		choices = value
		init_buttons()
		
var label_text:String :
	set(text):
		label_text = text
		init_label()
		
# Called when the node enters the scene tree for the first time.
func _ready():
	choices_list.get_child(0).pressed.connect(on_choice.bind(0))

func init_label():
	label.text = label_text
	if (label_text == null || label_text ==""):
		label.visible = false
	else:	
		margin_container.add_theme_constant_override("margin_top", label.size.y)

func init_buttons():
	var button
	
	while choices_list.get_child_count() > 1:
		button = choices_list.get_child(choices_list.get_child_count() - 1)
		choices_list.remove_child((button))
		button.queue_free()
		
	for choice_index in range(choices.size()):
		if (choice_index == 0):
			choices_list.get_child(0).text = choices[choice_index]
		else:
			choices_list.add_child(choice_prefab.duplicate())
			choices_list.get_child(choice_index).text = choices[choice_index]
			choices_list.get_child(choice_index).pressed.connect(on_choice.bind(choice_index))

func on_choice(choice_index):
	SELECTED.emit(choice_index)
