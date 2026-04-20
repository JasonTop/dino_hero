class_name PauseMenu
extends CanvasLayer

## 戰鬥中暫停選單

signal save_requested()
signal quit_to_map_requested()
signal resume_requested()

@onready var panel: PanelContainer = $Panel
@onready var save_btn: Button = $Panel/VBox/SaveButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton
@onready var resume_btn: Button = $Panel/VBox/ResumeButton

func _ready() -> void:
	visible = false
	save_btn.pressed.connect(func(): save_requested.emit())
	quit_btn.pressed.connect(func(): quit_to_map_requested.emit())
	resume_btn.pressed.connect(func(): close())

func open() -> void:
	visible = true
	resume_btn.grab_focus()

func close() -> void:
	visible = false
	resume_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		close()
