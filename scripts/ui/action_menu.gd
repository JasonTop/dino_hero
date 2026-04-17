class_name ActionMenu
extends PanelContainer

## 行動選單 — 攻擊/待機

signal action_selected(action: String)

@onready var attack_btn: Button = $VBox/AttackButton
@onready var wait_btn: Button = $VBox/WaitButton

func _ready() -> void:
	attack_btn.pressed.connect(_on_attack_pressed)
	wait_btn.pressed.connect(_on_wait_pressed)
	visible = false

func show_menu(can_attack: bool = true) -> void:
	attack_btn.disabled = not can_attack
	visible = true
	# 聚焦到第一個可用按鈕
	if can_attack:
		attack_btn.grab_focus()
	else:
		wait_btn.grab_focus()

func hide_menu() -> void:
	visible = false

func _on_attack_pressed() -> void:
	hide_menu()
	action_selected.emit("attack")

func _on_wait_pressed() -> void:
	hide_menu()
	action_selected.emit("wait")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		hide_menu()
		action_selected.emit("cancel")
		get_viewport().set_input_as_handled()
