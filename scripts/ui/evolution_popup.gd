class_name EvolutionPopup
extends CanvasLayer

## 進化選項彈窗

signal evolved()

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var desc_label: Label = $Root/Panel/VBox/Description
@onready var options_container: VBoxContainer = $Root/Panel/VBox/OptionsContainer
@onready var cancel_btn: Button = $Root/Panel/VBox/CancelButton

var _current_stats: UnitStats

func _ready() -> void:
	cancel_btn.pressed.connect(queue_free)

func open(stats: UnitStats) -> void:
	_current_stats = stats
	title_label.text = stats.display_name + " 的進化"
	var info := EvolutionSystem.get_evolution_info(stats)
	if not info.get("available", false):
		desc_label.text = "無法進化：" + str(info.get("reason", "—"))
		return

	desc_label.text = "請選擇進化方向，選擇後將消耗一個進化化石："
	var options: Array = info["options"]
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 16)
		btn.text = "%s\n  %s" % [opt.get("name", "—"), _bonus_str(opt.get("stat_bonus", {}))]
		btn.custom_minimum_size = Vector2(400, 60)
		var idx := i
		btn.pressed.connect(func(): _on_choice(idx))
		options_container.add_child(btn)

func _bonus_str(bonus: Dictionary) -> String:
	var parts: Array[String] = []
	for k in bonus:
		parts.append("%s+%d" % [k.to_upper(), int(bonus[k])])
	if parts.is_empty():
		return ""
	return "加成：" + "  ".join(parts)

func _on_choice(option_index: int) -> void:
	if EvolutionSystem.evolve(_current_stats, option_index):
		evolved.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		queue_free()
