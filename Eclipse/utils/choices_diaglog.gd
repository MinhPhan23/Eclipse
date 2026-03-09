extends PanelContainer

signal SELECTED(index)

@onready var choices_list = $"MarginContainer/Choices"
@onready var choice_prefab = $"MarginContainer/Choices/Button"

var choices:
	set(value):
		choices = value
		init_buttons()
		
# Called when the node enters the scene tree for the first time.
func _ready():
	choices_list.get_child(0).pressed.connect(on_choice.bind(0))

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
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_choice(choice_index):
	SELECTED.emit(choice_index)
