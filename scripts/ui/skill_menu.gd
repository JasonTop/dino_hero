class_name SkillMenu
extends PanelContainer

## 技能選擇選單

signal skill_selected(skill: Skill)
signal cancelled()

@onready var list: VBoxContainer = $VBox/SkillList
@onready var title: Label = $VBox/Title

var _current_unit: Unit = null

func _ready() -> void:
	visible = false

func show_menu(unit: Unit) -> void:
	_current_unit = unit
	title.text = unit.stats.display_name + " 的技能"
	_refresh_list()
	visible = true
	if list.get_child_count() > 0:
		list.get_child(0).grab_focus()

func hide_menu() -> void:
	visible = false

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()

	for skill_id in _current_unit.stats.active_skill_ids:
		var skill := SkillDatabase.get_skill(skill_id)
		if skill == null:
			continue
		var btn := Button.new()
		var can_use := _current_unit.stats.mp >= skill.mp_cost
		var label: String = "%s  (MP %d)  %s" % [skill.display_name, skill.mp_cost, skill.description]
		btn.text = label
		btn.disabled = not can_use
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_skill_picked.bind(skill))
		list.add_child(btn)

	if list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "（沒有可用技能）"
		list.add_child(empty)

func _on_skill_picked(skill: Skill) -> void:
	hide_menu()
	skill_selected.emit(skill)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		hide_menu()
		cancelled.emit()
