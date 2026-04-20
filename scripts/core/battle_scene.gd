extends Node2D

## 戰鬥場景 — 初始化所有系統並佈置測試關卡

const UnitScene := preload("res://scenes/battle/unit.tscn")
const SaveLoadScene := preload("res://scenes/ui/save_load_screen.tscn")

@onready var battle_map: BattleMap = $BattleMap
@onready var cursor: CursorController = $Cursor
@onready var hud: BattleHUD = $BattleHUD
@onready var action_menu: ActionMenu = $UILayer/ActionMenu
@onready var skill_menu: SkillMenu = $UILayer/SkillMenu
@onready var item_menu: ItemMenu = $UILayer/ItemMenu
@onready var level_up_popup: LevelUpPopup = $UILayer/LevelUpPopup
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var battle_manager: BattleManager = $BattleManager
@onready var ai_controller: AIController = $AIController
@onready var camera: Camera2D = $Camera2D

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

# 當前章節 ID（由 ChapterFlow 或 world map 透過 StoryManager 傳入）
var chapter_id: String = ""

func _ready() -> void:
	cursor.init(battle_map)

	battle_manager.init(battle_map, cursor, hud, action_menu, ai_controller,
		skill_menu, item_menu, level_up_popup)
	battle_manager.battle_ended.connect(_on_battle_ended)

	pause_menu.save_requested.connect(_on_save_requested)
	pause_menu.quit_to_map_requested.connect(_on_quit_to_map)
	pause_menu.resume_requested.connect(_on_resume)

	# 左上角選單按鈕
	var menu_btn := $UILayer/MenuButton
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_button_pressed)

	# 開發模式：顯示跳過戰鬥按鈕
	var skip_btn := $DevLayer/SkipButton
	skip_btn.visible = GameManager.is_dev_mode_active()
	skip_btn.pressed.connect(_on_skip_pressed)

	chapter_id = StoryManager.current_chapter

	# 若有戰鬥快照，還原戰鬥；否則正常佈置
	var snapshot: Dictionary = StoryManager.get_flag("pending_battle_snapshot", {})
	if snapshot is Dictionary and not snapshot.is_empty():
		StoryManager.set_flag("pending_battle_snapshot", {})
		_setup_from_snapshot(snapshot)
	else:
		_setup_test_level()

	battle_manager.start_battle(player_units, enemy_units)

func _setup_test_level() -> void:
	# === 我方單位 ===
	if PartyManager.members.is_empty():
		PartyManager.reset_to_default()

	var spawn_cells: Array[Vector2i] = [Vector2i(2, 4), Vector2i(2, 6), Vector2i(1, 5), Vector2i(0, 4),
		Vector2i(0, 3), Vector2i(0, 6), Vector2i(1, 3), Vector2i(1, 7)]
	for i in range(PartyManager.members.size()):
		var stats := PartyManager.members[i]
		var cell: Vector2i = spawn_cells[i] if i < spawn_cells.size() else Vector2i(0, i)
		var unit := _spawn_unit(stats, Unit.Team.PLAYER, cell)
		player_units.append(unit)

	# === 敵方單位（套用難度修正）===
	_spawn_enemy(UnitData.DinoType.TREX, "暴龍兵", 4, Vector2i(12, 5))
	_spawn_enemy(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍A", 2, Vector2i(11, 3))
	_spawn_enemy(UnitData.DinoType.VELOCIRAPTOR, "敵迅猛龍B", 2, Vector2i(11, 7))
	_spawn_enemy(UnitData.DinoType.DILOPHOSAURUS, "雙冠龍", 3, Vector2i(13, 2))

## 從戰鬥快照還原
func _setup_from_snapshot(snap: Dictionary) -> void:
	# 我方從 PartyManager 還原 stats（因為 PartyManager 已經由 SaveManager 還原過）
	# snapshot 只記錄位置與 has_acted 狀態
	var players: Array = snap.get("player_units", [])
	for entry: Dictionary in players:
		var idx: int = int(entry.get("party_index", -1))
		if idx < 0 or idx >= PartyManager.members.size():
			continue
		var stats := PartyManager.members[idx]
		var cell := Vector2i(int(entry.get("cell_x", 0)), int(entry.get("cell_y", 0)))
		var unit := _spawn_unit(stats, Unit.Team.PLAYER, cell)
		unit.has_acted = bool(entry.get("has_acted", false))
		if unit.has_acted:
			unit.modulate = Color(0.5, 0.5, 0.5, 1.0)
		player_units.append(unit)

	# 敵方 stats 從 snapshot 還原（不存在於 PartyManager）
	var enemies: Array = snap.get("enemy_units", [])
	for entry: Dictionary in enemies:
		var stats := UnitStats.from_dict(entry.get("stats", {}))
		var cell := Vector2i(int(entry.get("cell_x", 0)), int(entry.get("cell_y", 0)))
		var unit := _spawn_unit(stats, Unit.Team.ENEMY, cell)
		unit.has_acted = bool(entry.get("has_acted", false))
		if unit.has_acted:
			unit.modulate = Color(0.5, 0.5, 0.5, 1.0)
		enemy_units.append(unit)

## 產生當前戰鬥快照
func make_snapshot() -> Dictionary:
	var players: Array = []
	for i in range(player_units.size()):
		var u := player_units[i]
		if not u.is_alive():
			continue
		players.append({
			"party_index": i,
			"cell_x": u.cell.x, "cell_y": u.cell.y,
			"has_acted": u.has_acted,
		})
	var enemies: Array = []
	for u in enemy_units:
		if not u.is_alive():
			continue
		enemies.append({
			"cell_x": u.cell.x, "cell_y": u.cell.y,
			"has_acted": u.has_acted,
			"stats": u.stats.to_dict(),
		})
	return {
		"chapter_id": chapter_id,
		"turn_number": battle_manager.turn_number,
		"player_units": players,
		"enemy_units": enemies,
	}

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

## ===== 選單按鈕 =====
func _on_menu_button_pressed() -> void:
	if pause_menu.visible:
		return
	# 僅允許在玩家回合的 IDLE 狀態打開
	if battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN \
			and battle_manager.player_state == BattleManager.PlayerState.IDLE:
		cursor.set_active(false)
		pause_menu.open()

func _on_save_requested() -> void:
	if SaveLoadScreen.is_open():
		return
	var snap := make_snapshot()
	SaveLoadScreen.open_singleton(self, SaveLoadScene, SaveLoadScreen.Mode.SAVE, snap)

func _on_quit_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")

func _on_resume() -> void:
	cursor.set_active(true)

## ===== 開發模式 =====
func _on_skip_pressed() -> void:
	# 計算該場敵方總經驗值，發給每位出場的我方單位
	_grant_skip_exp_to_party()
	battle_manager.force_victory()

## 模擬整場戰鬥擊殺所有敵人所能獲得的總經驗
## 基準：以隊伍平均等級作為攻擊方等級（用於等級差補正）
func _grant_skip_exp_to_party() -> void:
	var party_lv_sum := 0
	var party_count := 0
	for p in player_units:
		if p.is_alive():
			party_lv_sum += p.stats.level
			party_count += 1
	if party_count == 0:
		return
	var avg_party_lv: int = int(round(float(party_lv_sum) / float(party_count)))

	var total_exp := 0
	for e in enemy_units:
		if not e.is_alive():
			continue
		# 沿用 ExpSystem 公式：base(10) + level_diff*5 + kill_bonus(20)
		var level_diff: int = e.stats.level - avg_party_lv
		var level_bonus: int = clampi(level_diff * 5, -10, 30)
		total_exp += maxi(10 + level_bonus + 20, 1)

	if total_exp <= 0:
		return

	# 給每位活著的我方單位相同的總經驗
	print("[DEV] 跳過戰鬥：發放 %d EXP 給每位我方成員" % total_exp)
	for p in player_units:
		if not p.is_alive():
			continue
		var level_ups := ExpSystem.grant_exp(p, total_exp)
		_show_floating_exp_text(p, total_exp)
		if not level_ups.is_empty():
			var lv_list: Array = []
			for lu: Dictionary in level_ups:
				lv_list.append(str(lu["new_level"]))
			print("[DEV]   %s 升到 Lv.%s" % [p.stats.display_name, ",".join(lv_list)])

func _show_floating_exp_text(unit: Unit, amount: int) -> void:
	var popup_scene := preload("res://scenes/battle/damage_popup.tscn")
	var popup: DamagePopup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = unit.global_position + Vector2(0, -30)
	popup.show_text("+%d EXP" % amount)
