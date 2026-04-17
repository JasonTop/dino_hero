class_name BattleHUD
extends CanvasLayer

## 戰鬥 HUD — 回合提示、單位資訊、地形資訊

@onready var turn_label: Label = $TurnLabel
@onready var unit_info_panel: PanelContainer = $UnitInfoPanel
@onready var unit_name_label: Label = $UnitInfoPanel/VBox/NameLabel
@onready var unit_hp_label: Label = $UnitInfoPanel/VBox/HPLabel
@onready var unit_atk_label: Label = $UnitInfoPanel/VBox/ATKLabel
@onready var unit_def_label: Label = $UnitInfoPanel/VBox/DEFLabel
@onready var unit_spd_label: Label = $UnitInfoPanel/VBox/SPDLabel
@onready var unit_mov_label: Label = $UnitInfoPanel/VBox/MOVLabel
@onready var terrain_label: Label = $TerrainLabel
@onready var battle_result_panel: PanelContainer = $BattleResultPanel
@onready var result_label: Label = $BattleResultPanel/ResultLabel

func _ready() -> void:
	unit_info_panel.visible = false
	battle_result_panel.visible = false

func show_turn_banner(text: String) -> void:
	turn_label.text = text
	turn_label.visible = true
	turn_label.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(turn_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): turn_label.visible = false)

func show_unit_info(unit: Unit) -> void:
	if not unit or not unit.stats:
		hide_unit_info()
		return
	unit_info_panel.visible = true
	unit_name_label.text = unit.stats.display_name + " Lv." + str(unit.stats.level)
	unit_hp_label.text = "HP: " + str(unit.stats.hp) + "/" + str(unit.stats.hp_max)
	unit_atk_label.text = "ATK: " + str(unit.stats.attack)
	unit_def_label.text = "DEF: " + str(unit.stats.defense)
	unit_spd_label.text = "SPD: " + str(unit.stats.speed)
	unit_mov_label.text = "MOV: " + str(unit.stats.movement)

func hide_unit_info() -> void:
	unit_info_panel.visible = false

func show_terrain_info(terrain_name: String, defense_bonus: float, evasion_bonus: float) -> void:
	var def_text := ("+" + str(roundi(defense_bonus * 100)) + "%%") if defense_bonus > 0 else "0%%"
	var eva_text := ("+" + str(roundi(evasion_bonus * 100)) + "%%") if evasion_bonus > 0 else "0%%"
	terrain_label.text = terrain_name + "  DEF:" + def_text + "  EVA:" + eva_text

func show_battle_result(is_victory: bool) -> void:
	battle_result_panel.visible = true
	if is_victory:
		result_label.text = "勝利！"
		result_label.modulate = Color.GOLD
	else:
		result_label.text = "敗北..."
		result_label.modulate = Color.RED
