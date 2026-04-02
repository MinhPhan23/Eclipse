extends Node2D

@export var dialog_text: Array[String]
@export var background: Resource
@export var next_scene: PackedScene

const TEXT_SPEED: float = 0.05
var current_line: int = 0 # indexing dialog_text

@onready var dialog: RichTextLabel = $DialogBox/DialogText
@onready var cutscene_background: Sprite2D = $Background
@onready var tween: Tween
@onready var music = $"../Music"
@onready var click_sound = $"../ClickSound"
@onready var textcrawl_sound = $"../TextcrawlSound"

func _ready():
	music.play()
	
	dialog.text = ""
	dialog.visible_characters = 0
	
	assert(background != null and background is Texture, "Cutscenes must have a background image.")
	var texture: Texture2D = load(background.resource_path)
	cutscene_background.set_texture(texture)
	
	_run_dialog()
	textcrawl_sound.play()

func _process(_delta):
	if Input.is_action_just_pressed("continue_dialog"):
		click_sound.play()
		if tween.is_running():
			# skip animation
			tween.pause()
			tween.custom_step(INF)
		elif !tween.is_running() and current_line < dialog_text.size():
			# next line
			_run_dialog()
			textcrawl_sound.play()
		else:
			# end dialog
			assert (next_scene != null, "Cutscenes must transition to another scene when finished.")
			get_tree().change_scene_to_packed(next_scene)
	
	if !tween.is_running():
		textcrawl_sound.stop()

func _run_dialog() -> void:
	assert(dialog_text.size() > 0, "Cutscenes must have at least one line of dialog text.")
	if current_line < dialog_text.size():
		dialog.text = dialog_text[current_line]
		dialog.visible_characters = 0
		
		var dialog_length = dialog.text.length()
		var duration = dialog_length * TEXT_SPEED
		
		tween = get_tree().create_tween()
		tween.set_loops(1)
		tween.tween_property(dialog, "visible_characters", dialog_length, duration)
		current_line += 1
