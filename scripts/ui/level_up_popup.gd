class_name LevelUpPopup
extends Control

## 升級彈窗 — 顯示等級與屬性成長

signal closed()

@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var info: Label = $Panel/VBox/Info
@onready var close_btn: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)

func show_level_up(unit: Unit, level_ups: Array) -> void:
	if level_ups.is_empty():
		return
	visible = true

	var text_lines: Array[String] = []
	text_lines.append(unit.stats.display_name + " 升級了！")
	text_lines.append("")
	for lu: Dictionary in level_ups:
		var lv: int = lu["new_level"]
		var gains: Dictionary = lu["gains"]
		text_lines.append("Lv." + str(lv - 1) + " → Lv." + str(lv))
		text_lines.append("  HP +" + str(gains["hp"]) + "  MP +" + str(gains["mp"]))
		text_lines.append("  ATK +" + str(gains["atk"]) + "  DEF +" + str(gains["def"]))
		text_lines.append("  MATK +" + str(gains["matk"]) + "  MDEF +" + str(gains["mdef"]))
		text_lines.append("  SPD +" + str(gains["spd"]))
		var learned: Array = lu.get("learned_skills", [])
		if not learned.is_empty():
			for sid in learned:
				var skill := SkillDatabase.get_skill(sid)
				if skill:
					text_lines.append("  學會新技能：" + skill.display_name + "！")
		text_lines.append("")

	title.text = "等級提升！"
	info.text = "\n".join(text_lines)
	close_btn.grab_focus()

func _on_close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_on_close()
