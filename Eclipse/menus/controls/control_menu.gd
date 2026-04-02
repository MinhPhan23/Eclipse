extends Control

signal close_menu


func _on_close_pressed():
	close_menu.emit()
