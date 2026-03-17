extends Node2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var player_coord: Vector2 = $Player.position
	$Camera2D.position = player_coord
