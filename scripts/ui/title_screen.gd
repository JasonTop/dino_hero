extends Control

## 標題畫面 — 含難度選擇

@onready var start_btn: Button = $VBoxContainer/StartButton
@onready var difficulty_btn: Button = $VBoxContainer/DifficultyButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	difficulty_btn.pressed.connect(_on_difficulty_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	start_btn.grab_focus()
	_update_difficulty_label()

func _on_start_pressed() -> void:
	# 新遊戲：重置劇情、進入世界地圖
	StoryManager.reset()
	get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")

func _on_difficulty_pressed() -> void:
	GameManager.cycle_difficulty()
	_update_difficulty_label()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _update_difficulty_label() -> void:
	difficulty_btn.text = "難度：" + GameManager.get_difficulty_name()
