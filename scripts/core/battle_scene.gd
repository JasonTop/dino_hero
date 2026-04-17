extends Node2D

## 戰鬥場景 — 初始化所有系統並佈置測試關卡

const UnitScene := preload("res://scenes/battle/unit.tscn")

@onready var battle_map: BattleMap = $BattleMap
@onready var cursor: CursorController = $Cursor
@onready var hud: BattleHUD = $BattleHUD
@onready var action_menu: ActionMenu = $UILayer/ActionMenu
@onready var battle_manager: BattleManager = $BattleManager
@onready var ai_controller: AIController = $AIController
@onready var camera: Camera2D = $Camera2D

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

func _ready() -> void:
	# 初始化游標
	cursor.init(battle_map)

	# 初始化 BattleManager
	battle_manager.init(battle_map, cursor, hud, action_menu, ai_controller)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# 佈置測試關卡
	_setup_test_level()

	# 開始戰鬥
	battle_manager.start_battle(player_units, enemy_units)

func _setup_test_level() -> void:
	# === 我方單位 ===
	# 迅猛龍・銳牙（主角）
	var raptor1_stats := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "銳牙", 3)
	var raptor1 := _spawn_unit(raptor1_stats, Unit.Team.PLAYER, Vector2i(2, 4))
	player_units.append(raptor1)

	# 迅猛龍・疾風
	var raptor2_stats := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "疾風", 2)
	var raptor2 := _spawn_unit(raptor2_stats, Unit.Team.PLAYER, Vector2i(2, 6))
	player_units.append(raptor2)

	# 三角龍・鐵壁
	var trike_stats := UnitData.create_stats(UnitData.DinoType.TRICERATOPS, "鐵壁", 3)
	var trike := _spawn_unit(trike_stats, Unit.Team.PLAYER, Vector2i(1, 5))
	player_units.append(trike)

	# === 敵方單位 ===
	# 暴龍
	var trex_stats := UnitData.create_stats(UnitData.DinoType.TREX, "暴龍兵", 3)
	var trex := _spawn_unit(trex_stats, Unit.Team.ENEMY, Vector2i(12, 5))
	enemy_units.append(trex)

	# 敵方迅猛龍 x2
	var e_raptor1_stats := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍A", 2)
	var e_raptor1 := _spawn_unit(e_raptor1_stats, Unit.Team.ENEMY, Vector2i(11, 3))
	enemy_units.append(e_raptor1)

	var e_raptor2_stats := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍B", 2)
	var e_raptor2 := _spawn_unit(e_raptor2_stats, Unit.Team.ENEMY, Vector2i(11, 7))
	enemy_units.append(e_raptor2)

func _spawn_unit(stats: UnitStats, team: int, cell: Vector2i) -> Unit:
	var unit: Unit = UnitScene.instantiate()
	$Units.add_child(unit)
	unit.init(stats, team, cell)
	battle_map.place_unit(unit, cell)

	# 連接死亡信號以清除地圖位置
	unit.unit_died.connect(_on_unit_died)
	return unit

func _on_unit_died(unit: Unit) -> void:
	battle_map.remove_unit(unit.cell)

func _on_battle_ended(is_victory: bool) -> void:
	# 延遲後回到標題
	await get_tree().create_timer(3.0).timeout
	GameManager.change_scene("res://scenes/ui/title_screen.tscn")
