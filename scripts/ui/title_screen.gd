extends Control

## 標題畫面

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$VBoxContainer/StartButton.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
