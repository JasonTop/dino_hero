class_name PartyScreen
extends CanvasLayer

## 隊伍管理介面 — 查看屬性、換裝、進化

signal closed()

static var _active: PartyScreen = null

const EquipSelectRes := preload("res://scenes/ui/equip_select_popup.tscn")
const EvolutionRes := preload("res://scenes/ui/evolution_popup.tscn")

@onready var member_list: VBoxContainer = $Root/HBox/LeftPanel/VBox/Scroll/MemberList
@onready var close_btn: Button = $Root/HBox/LeftPanel/VBox/CloseButton

@onready var name_label: Label = $Root/HBox/RightPanel/VBox/Header/NameLabel
@onready var class_label: Label = $Root/HBox/RightPanel/VBox/Header/ClassLabel
@onready var stats_label: RichTextLabel = $Root/HBox/RightPanel/VBox/StatsLabel
@onready var equip_label: Label = $Root/HBox/RightPanel/VBox/EquipRow/EquipLabel
@onready var equip_change_btn: Button = $Root/HBox/RightPanel/VBox/EquipRow/ChangeButton
@onready var equip_unequip_btn: Button = $Root/HBox/RightPanel/VBox/EquipRow/UnequipButton
@onready var active_list: VBoxContainer = $Root/HBox/RightPanel/VBox/ActiveSkills
@onready var passive_list: VBoxContainer = $Root/HBox/RightPanel/VBox/PassiveSkills
@onready var evolve_btn: Button = $Root/HBox/RightPanel/VBox/EvolveButton
@onready var evolve_info: Label = $Root/HBox/RightPanel/VBox/EvolveInfo

var _selected_index: int = 0

static func open_singleton(parent: Node, scene: PackedScene) -> PartyScreen:
	if _active != null and is_instance_valid(_active):
		return _active
	var inst: PartyScreen = scene.instantiate()
	parent.add_child(inst)
	return inst

static func is_open() -> bool:
	return _active != null and is_instance_valid(_active)

func _ready() -> void:
	_active = self
	close_btn.pressed.connect(_on_close)
	equip_change_btn.pressed.connect(_on_change_equip)
	equip_unequip_btn.pressed.connect(_on_unequip)
	evolve_btn.pressed.connect(_on_evolve)
	_rebuild()

func _exit_tree() -> void:
	if _active == self:
		_active = null

func _rebuild() -> void:
	_build_member_list()
	if PartyManager.members.is_empty():
		_clear_detail()
	else:
		_selected_index = clampi(_selected_index, 0, PartyManager.members.size() - 1)
		_show_detail(PartyManager.members[_selected_index])

func _build_member_list() -> void:
	for c in member_list.get_children():
		c.queue_free()

	for i in range(PartyManager.members.size()):
		var stats := PartyManager.members[i]
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_pressed = (i == _selected_index)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 15)
		btn.text = "%s  Lv.%d\n  HP %d/%d  MP %d/%d" % [
			stats.display_name, stats.level,
			stats.hp, stats.hp_max, stats.mp, stats.mp_max,
		]
		btn.custom_minimum_size = Vector2(200, 60)
		var idx := i
		btn.pressed.connect(func(): _on_member_selected(idx))
		member_list.add_child(btn)

func _on_member_selected(index: int) -> void:
	_selected_index = index
	_show_detail(PartyManager.members[index])
	# 更新清單按鈕 toggled 狀態
	for i in range(member_list.get_child_count()):
		var btn := member_list.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == _selected_index)

func _clear_detail() -> void:
	name_label.text = "—"
	class_label.text = ""
	stats_label.text = ""
	equip_label.text = ""
	evolve_btn.disabled = true

func _show_detail(stats: UnitStats) -> void:
	name_label.text = stats.display_name + "  Lv." + str(stats.level)
	class_label.text = _class_display(stats.class_type)

	var exp_next := UnitStats.exp_required_for_level(stats.level)
	var bbcode := "[color=#cccccc]HP[/color] %d / %d    [color=#aaddff]MP[/color] %d / %d\n" % [
		stats.hp, stats.hp_max, stats.mp, stats.mp_max,
	]
	bbcode += _stat_line("ATK", stats.attack, stats.get_effective_attack())
	bbcode += _stat_line("DEF", stats.defense, stats.get_effective_defense())
	bbcode += _stat_line("MATK", stats.magic_attack, stats.get_effective_magic_attack())
	bbcode += _stat_line("MDEF", stats.magic_defense, stats.get_effective_magic_defense())
	bbcode += _stat_line("SPD", stats.speed, stats.get_effective_speed())
	bbcode += _stat_line("MOV", stats.movement, stats.get_effective_movement())
	bbcode += "[color=#ffcc66]EXP[/color]  %d / %d\n" % [stats.exp, exp_next]
	bbcode += "[color=#aaaaaa]進化階段：%d[/color]" % stats.evolution_stage
	stats_label.text = bbcode

	# 裝備顯示
	_refresh_equip_row(stats)

	# 技能顯示
	_build_skill_rows(active_list, stats.active_skill_ids, 4, true)
	_build_skill_rows(passive_list, stats.passive_skill_ids, 2, false)

	# 進化按鈕
	_refresh_evolve_button(stats)

func _stat_line(label: String, base: int, effective: int) -> String:
	var diff := effective - base
	if diff > 0:
		return "[color=#cccccc]%s[/color] %d [color=#88ff88](+%d)[/color]\n" % [label, base, diff]
	elif diff < 0:
		return "[color=#cccccc]%s[/color] %d [color=#ff8888](%d)[/color]\n" % [label, base, diff]
	else:
		return "[color=#cccccc]%s[/color] %d\n" % [label, base]

func _class_display(class_type: String) -> String:
	match class_type:
		"striker": return "突擊型"
		"tank": return "坦克型"
		"heavy": return "重砲型"
		"ranged": return "遠程型"
		"flyer": return "飛行型"
		"support": return "支援型"
		"aquatic": return "水棲型"
	return class_type

func _refresh_equip_row(stats: UnitStats) -> void:
	if stats.equipped_item_id == "":
		equip_label.text = "（未裝備）"
		equip_unequip_btn.disabled = true
	else:
		var item := ItemDatabase.get_item(stats.equipped_item_id)
		if item:
			var bonuses_str := _bonuses_to_str(item.stat_bonuses)
			equip_label.text = "%s  %s" % [item.display_name, bonuses_str]
		else:
			equip_label.text = stats.equipped_item_id
		equip_unequip_btn.disabled = false

func _bonuses_to_str(bonuses: Dictionary) -> String:
	var parts: Array[String] = []
	for k in bonuses:
		parts.append("%s+%d" % [k.to_upper(), int(bonuses[k])])
	return "(" + "  ".join(parts) + ")"

func _build_skill_rows(container: VBoxContainer, skill_ids: Array, max_slots: int, is_active: bool) -> void:
	for c in container.get_children():
		c.queue_free()

	for i in range(max_slots):
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 14)
		if i < skill_ids.size():
			var skill := SkillDatabase.get_skill(skill_ids[i])
			if skill:
				var mp_text: String = ""
				if is_active and skill.mp_cost > 0:
					mp_text = "  (MP %d)" % skill.mp_cost
				row.text = "%d. %s%s — %s" % [i + 1, skill.display_name, mp_text, skill.description]
			else:
				row.text = "%d. %s" % [i + 1, skill_ids[i]]
		else:
			row.text = "%d. —" % (i + 1)
			row.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(row)

func _refresh_evolve_button(stats: UnitStats) -> void:
	var info := EvolutionSystem.get_evolution_info(stats)
	if info.get("available", false):
		evolve_btn.disabled = false
		evolve_btn.text = "進化！"
		evolve_info.text = "符合進化條件"
		evolve_info.modulate = Color(0.6, 1, 0.6)
	else:
		evolve_btn.disabled = true
		evolve_btn.text = "進化"
		var reason: String = info.get("reason", "暫無可用進化路線")
		evolve_info.text = reason
		evolve_info.modulate = Color(0.8, 0.8, 0.8)

## ===== 裝備變更 =====
func _on_change_equip() -> void:
	if PartyManager.members.is_empty():
		return
	var popup: EquipSelectPopup = EquipSelectRes.instantiate()
	add_child(popup)
	popup.open(PartyManager.members[_selected_index])
	popup.equip_selected.connect(_on_equip_selected)

func _on_unequip() -> void:
	var stats := PartyManager.members[_selected_index]
	if stats.equipped_item_id == "":
		return
	# 把裝備回存到背包
	Inventory.add_item(stats.equipped_item_id, 1)
	stats.equipped_item_id = ""
	_show_detail(stats)

func _on_equip_selected(item_id: String) -> void:
	var stats := PartyManager.members[_selected_index]
	# 卸下舊裝備回到背包
	if stats.equipped_item_id != "":
		Inventory.add_item(stats.equipped_item_id, 1)
	# 從背包扣除新裝備
	if Inventory.remove_item(item_id, 1):
		stats.equipped_item_id = item_id
	_show_detail(stats)

## ===== 進化 =====
func _on_evolve() -> void:
	var stats := PartyManager.members[_selected_index]
	var popup: EvolutionPopup = EvolutionRes.instantiate()
	add_child(popup)
	popup.open(stats)
	popup.evolved.connect(_on_evolved)

func _on_evolved() -> void:
	_rebuild()

## ===== 關閉 =====
func _on_close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_on_close()
