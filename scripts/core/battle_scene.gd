extends Node2D

## 戰鬥場景 — 初始化所有系統並佈置測試關卡

const UnitScene := preload("res://scenes/battle/unit.tscn")

@onready var battle_map: BattleMap = $BattleMap
@onready var cursor: CursorController = $Cursor
@onready var hud: BattleHUD = $BattleHUD
@onready var action_menu: ActionMenu = $UILayer/ActionMenu
@onready var skill_menu: SkillMenu = $UILayer/SkillMenu
@onready var item_menu: ItemMenu = $UILayer/ItemMenu
@onready var level_up_popup: LevelUpPopup = $UILayer/LevelUpPopup
@onready var battle_manager: BattleManager = $BattleManager
@onready var ai_controller: AIController = $AIController
@onready var camera: Camera2D = $Camera2D

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

func _ready() -> void:
	cursor.init(battle_map)

	battle_manager.init(battle_map, cursor, hud, action_menu, ai_controller,
		skill_menu, item_menu, level_up_popup)
	battle_manager.battle_ended.connect(_on_battle_ended)

	_setup_test_level()
	battle_manager.start_battle(player_units, enemy_units)

func _setup_test_level() -> void:
	# === 我方單位 ===
	# 銳牙（迅猛龍 Lv.3，裝備利齒項圈）
	var raptor1_stats := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "銳牙", 3)
	raptor1_stats.equipped_item_id = "sharp_claw_ring"
	var raptor1 := _spawn_unit(raptor1_stats, Unit.Team.PLAYER, Vector2i(2, 4))
	player_units.append(raptor1)

	# 疾風（恐爪龍 Lv.3）
	var raptor2_stats := UnitData.create_stats(UnitData.DinoType.DEINONYCHUS, "疾風", 3)
	var raptor2 := _spawn_unit(raptor2_stats, Unit.Team.PLAYER, Vector2i(2, 6))
	player_units.append(raptor2)

	# 鐵壁（三角龍 Lv.3，裝備堅鱗護甲）
	var trike_stats := UnitData.create_stats(UnitData.DinoType.TRICERATOPS, "鐵壁", 3)
	trike_stats.equipped_item_id = "hard_scale_armor"
	var trike := _spawn_unit(trike_stats, Unit.Team.PLAYER, Vector2i(1, 5))
	player_units.append(trike)

	# 春芽（慈母龍 Lv.2，支援）
	var support_stats := UnitData.create_stats(UnitData.DinoType.MAIASAURA, "春芽", 2)
	var support := _spawn_unit(support_stats, Unit.Team.PLAYER, Vector2i(0, 4))
	player_units.append(support)

	# === 敵方單位（套用難度修正）===
	_spawn_enemy(UnitData.DinoType.TREX, "暴龍兵", 4, Vector2i(12, 5))
	_spawn_enemy(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍A", 2, Vector2i(11, 3))
	_spawn_enemy(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍B", 2, Vector2i(11, 7))
	_spawn_enemy(UnitData.DinoType.DILOPHOSAURUS, "雙冠龍", 3, Vector2i(13, 2))

## 建立敵方單位（自動套用當前難度）
func _spawn_enemy(dino_type: int, dino_name: String, base_level: int, cell: Vector2i) -> Unit:
	var cfg := GameManager.get_difficulty_config()
	var level_bonus: int = cfg["level_bonus"]
	var final_level := maxi(base_level + level_bonus, 1)
	var stats := UnitData.create_stats(dino_type, dino_name, final_level)
	GameManager.apply_difficulty_to_enemy(stats)
	var unit := _spawn_unit(stats, Unit.Team.ENEMY, cell)
	enemy_units.append(unit)
	return unit

func _spawn_unit(stats: UnitStats, team: int, cell: Vector2i) -> Unit:
	var unit: Unit = UnitScene.instantiate()
	$Units.add_child(unit)
	unit.init(stats, team, cell)
	battle_map.place_unit(unit, cell)
	unit.unit_died.connect(_on_unit_died)
	return unit

func _on_unit_died(unit: Unit) -> void:
	battle_map.remove_unit(unit.cell)

func _on_battle_ended(is_victory: bool) -> void:
	# 若是由 ChapterFlow 管理（非根場景），由父節點接手處理
	if get_tree().current_scene != self:
		return
	await get_tree().create_timer(3.0).timeout
	GameManager.change_scene("res://scenes/ui/title_screen.tscn")
