class_name ActionMenu
extends PanelContainer

## 行動選單 — 攻擊/技能/道具/待機

signal action_selected(action: String)

@onready var attack_btn: Button = $VBox/AttackButton
@onready var skill_btn: Button = $VBox/SkillButton
@onready var item_btn: Button = $VBox/ItemButton
@onready var wait_btn: Button = $VBox/WaitButton

func _ready() -> void:
	attack_btn.pressed.connect(func(): _emit("attack"))
	skill_btn.pressed.connect(func(): _emit("skill"))
	item_btn.pressed.connect(func(): _emit("item"))
	wait_btn.pressed.connect(func(): _emit("wait"))
	visible = false

## can_attack = 是否有敵人在攻擊範圍內
## can_skill = 是否有可用技能（MP 足夠）
## can_item = 是否有消耗品
func show_menu(can_attack: bool = true, can_skill: bool = true, can_item: bool = true) -> void:
	attack_btn.disabled = not can_attack
	skill_btn.disabled = not can_skill
	item_btn.disabled = not can_item
	visible = true
	# 聚焦到第一個可用按鈕
	for btn in [attack_btn, skill_btn, item_btn, wait_btn]:
		if not btn.disabled:
			btn.grab_focus()
			return

func hide_menu() -> void:
	visible = false

func _emit(action: String) -> void:
	hide_menu()
	action_selected.emit(action)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		hide_menu()
		action_selected.emit("cancel")
