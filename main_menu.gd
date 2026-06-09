extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Сигналы кнопок должны быть подключены через редактор
	# (PlayButton, ClearButton, EndlessButton, QuitButton)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://survival.tscn")

func _on_clear_button_pressed():
	get_tree().change_scene_to_file("res://clear.tscn")

func _on_endless_button_pressed():
	get_tree().change_scene_to_file("res://endless.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
