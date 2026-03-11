extends Camera2D

@export var move_speed: float = 300.0
@export var border_margin: float = 10.0
var viewport_size 
var camera_size
var camera_min_x
var camera_max_x
var camera_min_y
var camera_max_y

func _ready():
	viewport_size = get_viewport_rect().size
	camera_size = viewport_size / zoom
	camera_min_x = camera_size.x / 2
	camera_max_x = viewport_size.x - camera_min_x
	camera_min_y = camera_size.y / 2
	camera_max_y = viewport_size.y - camera_min_y

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var move_vec = Vector2.ZERO
	# Check horizontal borders
	if mouse_pos.x < border_margin:
		move_vec.x -= 1
	elif mouse_pos.x > viewport_size.x - border_margin:
		move_vec.x += 1

	# Check vertical borders
	if mouse_pos.y < border_margin:
		move_vec.y -= 1
	elif mouse_pos.y > viewport_size.y - border_margin:
		move_vec.y += 1

	# Move camera
	position += move_vec.normalized() * move_speed * delta
	
	# Clamp
	position.x = clamp(position.x, camera_min_x, camera_max_x)
	position.y = clamp(position.y, camera_min_y, camera_max_y)
