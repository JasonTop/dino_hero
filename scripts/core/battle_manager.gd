class_name BattleManager
extends Node

## 戰鬥總控制器 — 管理回合流程、玩家操作狀態機

signal battle_started()
signal battle_ended(is_victory: bool)
signal turn_changed(turn_number: int, phase: String)
signal unit_action_completed(unit: Unit)

enum Phase { BATTLE_START, PLAYER_TURN, ENEMY_TURN, TURN_END, BATTLE_OVER }
enum PlayerState { IDLE, UNIT_SELECTED, UNIT_MOVING, CHOOSING_ACTION, CHOOSING_TARGET, ATTACKING }

var current_phase: Phase = Phase.BATTLE_START
var player_state: PlayerState = PlayerState.IDLE
var turn_number: int = 0

var battle_map: BattleMap
var pathfinder: Pathfinder
var damage_calculator: DamageCalculator
var cursor: CursorController
var tile_highlighter: TileHighlighter
var ai_controller: AIController
var hud: BattleHUD
var action_menu: ActionMenu

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var selected_unit: Unit = null
var _reachable_cells: Array[Vector2i] = []
var _attack_cells: Array[Vector2i] = []

func init(map: BattleMap, cur: CursorController, hud_ref: BattleHUD, am: ActionMenu, ai: AIController) -> void:
	battle_map = map
	cursor = cur
	hud = hud_ref
	action_menu = am
	ai_controller = ai
	tile_highlighter = map.tile_highlighter
	pathfinder = Pathfinder.new(map)
	damage_calculator = DamageCalculator.new(map)

	ai_controller.init(map, pathfinder, damage_calculator)

	# 連接信號
	cursor.cell_selected.connect(_on_cell_selected)
	cursor.cell_hovered.connect(_on_cell_hovered)
	cursor.cancel_pressed.connect(_on_cancel_pressed)
	action_menu.action_selected.connect(_on_action_selected)
	ai_controller.ai_turn_completed.connect(_on_ai_turn_completed)

## 開始戰鬥
func start_battle(p_units: Array[Unit], e_units: Array[Unit]) -> void:
	player_units = p_units
	enemy_units = e_units
	turn_number = 0
	battle_started.emit()
	_start_player_turn()

## ========== 回合流程 ==========

func _start_player_turn() -> void:
	turn_number += 1
	current_phase = Phase.PLAYER_TURN
	player_state = PlayerState.IDLE

	for u in player_units:
		if u.is_alive():
			u.reset_turn()

	cursor.set_active(true)
	turn_changed.emit(turn_number, "player")
	hud.show_turn_banner("第 " + str(turn_number) + " 回合 — 我方行動")

func _start_enemy_turn() -> void:
	current_phase = Phase.ENEMY_TURN
	cursor.set_active(false)
	tile_highlighter.clear_all()
	hud.show_turn_banner("敵方行動")

	for u in enemy_units:
		if u.is_alive():
			u.reset_turn()

	# 延遲一下再開始 AI 行動
	await get_tree().create_timer(1.0).timeout

	var alive_enemies: Array[Unit] = []
	for u in enemy_units:
		if u.is_alive():
			alive_enemies.append(u)
	var alive_players: Array[Unit] = []
	for u in player_units:
		if u.is_alive():
			alive_players.append(u)

	ai_controller.start_ai_turn(alive_enemies, alive_players)

func _on_ai_turn_completed() -> void:
	_check_battle_end()
	if current_phase != Phase.BATTLE_OVER:
		_start_player_turn()

func _check_battle_end() -> void:
	var player_alive := false
	for u in player_units:
		if u.is_alive():
			player_alive = true
			break

	var enemy_alive := false
	for u in enemy_units:
		if u.is_alive():
			enemy_alive = true
			break

	if not enemy_alive:
		_end_battle(true)
	elif not player_alive:
		_end_battle(false)

func _end_battle(is_victory: bool) -> void:
	current_phase = Phase.BATTLE_OVER
	cursor.set_active(false)
	tile_highlighter.clear_all()
	hud.show_battle_result(is_victory)
	battle_ended.emit(is_victory)

## ========== 玩家操作狀態機 ==========

func _on_cell_hovered(cell: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return

	# 顯示懸停格子的單位資訊和地形資訊
	var unit = battle_map.get_unit_at(cell)
	if unit:
		hud.show_unit_info(unit)
	else:
		hud.hide_unit_info()

	var terrain_info := battle_map.get_terrain_info(cell)
	hud.show_terrain_info(terrain_info["name"], terrain_info["def"], terrain_info["eva"])

	# 在 UNIT_SELECTED 狀態下顯示路徑預覽
	if player_state == PlayerState.UNIT_SELECTED and selected_unit:
		if cell in _reachable_cells:
			var path := pathfinder.get_path(selected_unit.cell, cell, selected_unit.team)
			tile_highlighter.show_path(path)
		else:
			tile_highlighter.clear_path()

func _on_cell_selected(cell: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return

	match player_state:
		PlayerState.IDLE:
			_handle_idle_select(cell)
		PlayerState.UNIT_SELECTED:
			_handle_unit_selected_select(cell)
		PlayerState.CHOOSING_TARGET:
			_handle_target_select(cell)

func _on_cancel_pressed() -> void:
	if current_phase != Phase.PLAYER_TURN:
		return

	match player_state:
		PlayerState.UNIT_SELECTED:
			_deselect_unit()
		PlayerState.CHOOSING_ACTION:
			# ActionMenu 自己處理 cancel
			pass
		PlayerState.CHOOSING_TARGET:
			# 回到行動選單
			tile_highlighter.clear_attack_range()
			player_state = PlayerState.CHOOSING_ACTION
			action_menu.show_menu(true)

## IDLE 狀態下點擊
func _handle_idle_select(cell: Vector2i) -> void:
	var unit = battle_map.get_unit_at(cell)
	if unit and unit is Unit:
		if unit.team == Unit.Team.PLAYER and not unit.has_acted and unit.is_alive():
			_select_unit(unit)
		else:
			# 點到敵人或已行動的單位 → 僅顯示資訊
			hud.show_unit_info(unit)

## UNIT_SELECTED 狀態下點擊
func _handle_unit_selected_select(cell: Vector2i) -> void:
	if cell in _reachable_cells:
		# 移動到該格
		_move_selected_unit(cell)
	elif cell == selected_unit.cell:
		# 點擊自身 = 原地不動，直接進入行動選單
		_show_action_menu()
	else:
		# 點到範圍外
		var unit = battle_map.get_unit_at(cell)
		if unit and unit.team == Unit.Team.PLAYER and not unit.has_acted and unit.is_alive():
			_deselect_unit()
			_select_unit(unit)
		else:
			_deselect_unit()

## CHOOSING_TARGET 狀態下點擊
func _handle_target_select(cell: Vector2i) -> void:
	if cell in _attack_cells:
		var target = battle_map.get_unit_at(cell)
		if target and target.team != selected_unit.team and target.is_alive():
			_execute_attack(selected_unit, target)
			return
	# 無效目標
	pass

## ========== 操作實作 ==========

func _select_unit(unit: Unit) -> void:
	selected_unit = unit
	selected_unit.set_selected(true)
	player_state = PlayerState.UNIT_SELECTED

	# 計算並顯示移動範圍
	_reachable_cells = pathfinder.get_reachable_cells(unit.cell, unit.stats.movement, unit.team)
	tile_highlighter.show_move_range(_reachable_cells)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
	selected_unit = null
	player_state = PlayerState.IDLE
	_reachable_cells.clear()
	_attack_cells.clear()
	tile_highlighter.clear_all()

func _move_selected_unit(target_cell: Vector2i) -> void:
	player_state = PlayerState.UNIT_MOVING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	var path := pathfinder.get_path(selected_unit.cell, target_cell, selected_unit.team)
	battle_map.move_unit(selected_unit.cell, target_cell)
	selected_unit.move_along_path(path)
	await selected_unit.move_finished

	cursor.set_active(true)
	_show_action_menu()

func _show_action_menu() -> void:
	player_state = PlayerState.CHOOSING_ACTION
	cursor.set_active(false)

	# 檢查是否有可攻擊目標
	_attack_cells = pathfinder.get_attack_range(
		selected_unit.cell,
		selected_unit.stats.attack_range_min,
		selected_unit.stats.attack_range_max
	)
	var can_attack := false
	for cell in _attack_cells:
		var target = battle_map.get_unit_at(cell)
		if target and target.team != selected_unit.team and target.is_alive():
			can_attack = true
			break

	action_menu.show_menu(can_attack)

func _on_action_selected(action: String) -> void:
	match action:
		"attack":
			player_state = PlayerState.CHOOSING_TARGET
			cursor.set_active(true)
			tile_highlighter.show_attack_range(_attack_cells)
		"wait":
			selected_unit.end_action()
			_deselect_unit()
			_check_player_turn_end()
		"cancel":
			# 如果已移動過，不能取消（簡化版：允許取消回到 IDLE）
			cursor.set_active(true)
			_deselect_unit()

func _execute_attack(attacker: Unit, target: Unit) -> void:
	player_state = PlayerState.ATTACKING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	# 計算傷害
	var result := damage_calculator.calculate_damage(attacker, target)

	# 生成傷害數字
	var popup_scene := preload("res://scenes/battle/damage_popup.tscn")
	var popup: DamagePopup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = target.global_position + Vector2(0, -20)
	popup.show_damage(result["damage"], result["is_crit"], not result["is_hit"])

	# 套用傷害
	if result["is_hit"]:
		target.take_damage(result["damage"])

	await get_tree().create_timer(0.5).timeout

	attacker.end_action()

	# 更新 HUD
	hud.show_unit_info(target)

	_deselect_unit()
	_check_battle_end()

	if current_phase != Phase.BATTLE_OVER:
		_check_player_turn_end()

func _check_player_turn_end() -> void:
	# 檢查是否所有我方單位都已行動
	var all_acted := true
	for u in player_units:
		if u.is_alive() and not u.has_acted:
			all_acted = false
			break

	if all_acted:
		_start_enemy_turn()
	else:
		cursor.set_active(true)
		player_state = PlayerState.IDLE

## 按空白鍵手動結束回合
func _unhandled_input(event: InputEvent) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if player_state != PlayerState.IDLE:
		return
	if event.is_action_pressed("end_turn"):
		_start_enemy_turn()
