extends Camera2D

@export var target: Node2D

var viewport_size
var camera_size
var camera_min_x
var camera_max_x
var camera_min_y
var camera_max_y

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport_size = get_viewport_rect().size
	camera_size = viewport_size / zoom
	camera_min_x = camera_size.x / 2
	camera_max_x = viewport_size.x - camera_min_x
	camera_min_y = camera_size.y / 2
	camera_max_y = viewport_size.y - camera_min_y
	
	if target:
		position.x = clamp(target.position.x, camera_min_x, camera_max_x)
		position.y = clamp(target.position.y, camera_min_y, camera_max_y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if target:
		position.x = clamp(target.position.x, camera_min_x, camera_max_x)
		position.y = clamp(target.position.y, camera_min_y, camera_max_y)
