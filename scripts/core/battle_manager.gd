class_name BattleManager
extends Node

## 戰鬥總控制器 — 管理回合流程、玩家操作狀態機
## Phase 2：加入技能/道具/經驗結算

signal battle_started()
signal battle_ended(is_victory: bool)
signal turn_changed(turn_number: int, phase: String)
signal unit_action_completed(unit: Unit)

enum Phase { BATTLE_START, PLAYER_TURN, ENEMY_TURN, TURN_END, BATTLE_OVER }
enum PlayerState {
	IDLE, UNIT_SELECTED, UNIT_MOVING,
	CHOOSING_ACTION, CHOOSING_TARGET,
	CHOOSING_SKILL, CHOOSING_SKILL_TARGET,
	CHOOSING_ITEM, CHOOSING_ITEM_TARGET,
	ATTACKING, LEVEL_UP,
}

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
var skill_menu: SkillMenu
var item_menu: ItemMenu
var level_up_popup: LevelUpPopup

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var selected_unit: Unit = null
var _reachable_cells: Array[Vector2i] = []
var _attack_cells: Array[Vector2i] = []

# 移動前的位置（供 CHOOSING_ACTION 階段取消移動用）
var _pre_move_cell: Vector2i = Vector2i.ZERO
var _has_moved_this_action: bool = false

# 當前正在施放的技能/道具
var _pending_skill: Skill = null
var _pending_item: Item = null

# 暫存等待升級彈窗的佇列
var _pending_level_ups: Array = []  # [{unit, level_ups}]

func init(map: BattleMap, cur: CursorController, hud_ref: BattleHUD,
		am: ActionMenu, ai: AIController,
		sm: SkillMenu = null, im: ItemMenu = null, lup: LevelUpPopup = null) -> void:
	battle_map = map
	cursor = cur
	hud = hud_ref
	action_menu = am
	ai_controller = ai
	skill_menu = sm
	item_menu = im
	level_up_popup = lup
	tile_highlighter = map.tile_highlighter
	pathfinder = Pathfinder.new(map)
	damage_calculator = DamageCalculator.new(map)

	ai_controller.init(map, pathfinder, damage_calculator)

	cursor.cell_selected.connect(_on_cell_selected)
	cursor.cell_hovered.connect(_on_cell_hovered)
	cursor.cancel_pressed.connect(_on_cancel_pressed)
	action_menu.action_selected.connect(_on_action_selected)
	ai_controller.ai_turn_completed.connect(_on_ai_turn_completed)

	if skill_menu:
		skill_menu.skill_selected.connect(_on_skill_selected)
		skill_menu.cancelled.connect(_on_submenu_cancelled)
	if item_menu:
		item_menu.item_selected.connect(_on_item_selected)
		item_menu.cancelled.connect(_on_submenu_cancelled)
	if level_up_popup:
		level_up_popup.closed.connect(_on_level_up_closed)

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

## 開發模式：強制勝利
func force_victory() -> void:
	if current_phase == Phase.BATTLE_OVER:
		return
	_end_battle(true)

## ========== 游標事件 ==========

func _on_cell_hovered(cell: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return

	var unit = battle_map.get_unit_at(cell)
	if unit:
		hud.show_unit_info(unit)
	else:
		hud.hide_unit_info()

	var terrain_info := battle_map.get_terrain_info(cell)
	hud.show_terrain_info(terrain_info["name"], terrain_info["def"], terrain_info["eva"])

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
		PlayerState.CHOOSING_SKILL_TARGET:
			_handle_skill_target_select(cell)
		PlayerState.CHOOSING_ITEM_TARGET:
			_handle_item_target_select(cell)

func _on_cancel_pressed() -> void:
	if current_phase != Phase.PLAYER_TURN:
		return

	match player_state:
		PlayerState.UNIT_SELECTED:
			_deselect_unit()
		PlayerState.CHOOSING_TARGET, PlayerState.CHOOSING_SKILL_TARGET, PlayerState.CHOOSING_ITEM_TARGET:
			tile_highlighter.clear_attack_range()
			player_state = PlayerState.CHOOSING_ACTION
			_show_action_menu()

## ========== IDLE/UNIT_SELECTED ==========

func _handle_idle_select(cell: Vector2i) -> void:
	var unit = battle_map.get_unit_at(cell)
	if unit and unit is Unit:
		if unit.team == Unit.Team.PLAYER and not unit.has_acted and unit.is_alive():
			tile_highlighter.clear_threat_range()
			_select_unit(unit)
		elif unit.is_alive():
			# 敵方或已行動的單位 → 預覽威脅範圍
			_show_threat_preview(unit)
			hud.show_unit_info(unit)
	else:
		# 點擊空地 → 清除預覽
		tile_highlighter.clear_threat_range()

## 顯示敵方/已行動單位的威脅範圍（移動+攻擊）
func _show_threat_preview(unit: Unit) -> void:
	var move_range := pathfinder.get_reachable_cells(
		unit.cell, unit.stats.get_effective_movement(), unit.team
	)
	# 攻擊範圍 = 從每個可到達格（含自身）算出所有可攻擊格
	var attack_set: Dictionary = {}
	var origins := move_range.duplicate()
	origins.append(unit.cell)
	for origin: Vector2i in origins:
		var atk_cells := pathfinder.get_attack_range(
			origin, unit.stats.attack_range_min, unit.stats.attack_range_max
		)
		for ac in atk_cells:
			attack_set[ac] = true
	# 攻擊範圍扣掉移動範圍本身（避免重疊混淆）
	var attack_only: Array[Vector2i] = []
	for ac in attack_set.keys():
		if not (ac in move_range) and ac != unit.cell:
			attack_only.append(ac)

	tile_highlighter.show_threat_range(move_range, attack_only)

func _handle_unit_selected_select(cell: Vector2i) -> void:
	if cell in _reachable_cells:
		_move_selected_unit(cell)
	elif cell == selected_unit.cell:
		_show_action_menu()
	else:
		var unit = battle_map.get_unit_at(cell)
		if unit and unit.team == Unit.Team.PLAYER and not unit.has_acted and unit.is_alive():
			_deselect_unit()
			_select_unit(unit)
		else:
			_deselect_unit()

func _select_unit(unit: Unit) -> void:
	selected_unit = unit
	selected_unit.set_selected(true)
	player_state = PlayerState.UNIT_SELECTED
	_reachable_cells = pathfinder.get_reachable_cells(unit.cell, unit.stats.get_effective_movement(), unit.team)
	tile_highlighter.clear_threat_range()
	tile_highlighter.show_move_range(_reachable_cells)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
	selected_unit = null
	player_state = PlayerState.IDLE
	_reachable_cells.clear()
	_attack_cells.clear()
	_pending_skill = null
	_pending_item = null
	_has_moved_this_action = false
	tile_highlighter.clear_all()

func _move_selected_unit(target_cell: Vector2i) -> void:
	player_state = PlayerState.UNIT_MOVING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	# 記錄移動前位置，供 ESC 取消還原
	_pre_move_cell = selected_unit.cell
	_has_moved_this_action = true

	var path := pathfinder.get_path(selected_unit.cell, target_cell, selected_unit.team)
	battle_map.move_unit(selected_unit.cell, target_cell)
	selected_unit.move_along_path(path)
	await selected_unit.move_finished

	cursor.set_active(true)
	_show_action_menu()

## 還原移動（把單位送回移動前位置）
func _undo_move() -> void:
	if not _has_moved_this_action or selected_unit == null:
		return
	var from := selected_unit.cell
	battle_map.move_unit(from, _pre_move_cell)
	selected_unit.cell = _pre_move_cell
	selected_unit.position = Vector2(_pre_move_cell) * Unit.CELL_SIZE + Vector2(Unit.CELL_SIZE / 2, Unit.CELL_SIZE / 2)
	selected_unit.has_moved = false
	_has_moved_this_action = false

## ========== 行動選單 ==========

func _show_action_menu() -> void:
	player_state = PlayerState.CHOOSING_ACTION
	cursor.set_active(false)

	# 檢查可攻擊目標
	_attack_cells = pathfinder.get_attack_range(
		selected_unit.cell,
		selected_unit.stats.attack_range_min,
		selected_unit.stats.attack_range_max
	)
	var can_attack := false
	for c in _attack_cells:
		var t = battle_map.get_unit_at(c)
		if t and t.team != selected_unit.team and t.is_alive():
			can_attack = true
			break

	# 檢查可用技能（至少有一個 MP 足夠）
	var can_skill := false
	for sid in selected_unit.stats.active_skill_ids:
		var sk := SkillDatabase.get_skill(sid)
		if sk and selected_unit.stats.mp >= sk.mp_cost:
			can_skill = true
			break

	# 檢查背包
	var can_item := not Inventory.get_consumables().is_empty()

	action_menu.show_menu(can_attack, can_skill, can_item)

func _on_action_selected(action: String) -> void:
	match action:
		"attack":
			player_state = PlayerState.CHOOSING_TARGET
			cursor.set_active(true)
			tile_highlighter.show_attack_range(_attack_cells)
		"skill":
			if skill_menu:
				player_state = PlayerState.CHOOSING_SKILL
				skill_menu.show_menu(selected_unit)
		"item":
			if item_menu:
				player_state = PlayerState.CHOOSING_ITEM
				item_menu.show_menu()
		"wait":
			selected_unit.end_action()
			_deselect_unit()
			_check_player_turn_end()
		"cancel":
			# 取消行動：若已移動則還原到移動前位置，並重新顯示移動範圍
			cursor.set_active(true)
			if _has_moved_this_action:
				_undo_move()
				# 重新選中並顯示移動範圍
				player_state = PlayerState.UNIT_SELECTED
				_reachable_cells = pathfinder.get_reachable_cells(
					selected_unit.cell, selected_unit.stats.get_effective_movement(), selected_unit.team
				)
				tile_highlighter.show_move_range(_reachable_cells)
			else:
				_deselect_unit()

func _on_submenu_cancelled() -> void:
	_show_action_menu()

## ========== 攻擊 ==========

func _handle_target_select(cell: Vector2i) -> void:
	if cell in _attack_cells:
		var target = battle_map.get_unit_at(cell)
		if target and target.team != selected_unit.team and target.is_alive():
			_execute_attack(selected_unit, target)

func _execute_attack(attacker: Unit, target: Unit) -> void:
	player_state = PlayerState.ATTACKING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	var result := damage_calculator.calculate_damage(attacker, target)
	_show_damage_popup(target, result)

	var killed := false
	if result["is_hit"]:
		target.take_damage(result["damage"])
		killed = not target.is_alive()

	await get_tree().create_timer(0.5).timeout

	# 經驗結算（僅我方攻擊敵方時給經驗）
	if attacker.team == Unit.Team.PLAYER and target.team != Unit.Team.PLAYER:
		_grant_exp(attacker, target, killed)

	attacker.end_action()
	hud.show_unit_info(target)

	_deselect_unit()
	_check_battle_end()
	if current_phase != Phase.BATTLE_OVER:
		_wait_for_level_ups_then(func(): _check_player_turn_end())

## ========== 技能 ==========

func _on_skill_selected(skill: Skill) -> void:
	_pending_skill = skill
	# 依 target_type 決定行為
	match skill.target_type:
		Skill.TargetType.SINGLE_SELF:
			_execute_self_skill(selected_unit, skill)
		Skill.TargetType.SINGLE_ENEMY:
			_attack_cells = pathfinder.get_attack_range(selected_unit.cell, skill.range_min, skill.range_max)
			player_state = PlayerState.CHOOSING_SKILL_TARGET
			cursor.set_active(true)
			tile_highlighter.show_attack_range(_attack_cells)
		Skill.TargetType.SINGLE_ALLY:
			_attack_cells = pathfinder.get_attack_range(selected_unit.cell, skill.range_min, skill.range_max)
			_attack_cells.append(selected_unit.cell)  # 可以對自己用
			player_state = PlayerState.CHOOSING_SKILL_TARGET
			cursor.set_active(true)
			tile_highlighter.show_attack_range(_attack_cells)
		_:
			# AOE 簡化：先不支援，退回選單
			_show_action_menu()

func _handle_skill_target_select(cell: Vector2i) -> void:
	if not (cell in _attack_cells):
		return
	var target = battle_map.get_unit_at(cell)
	if target == null:
		return
	var valid := false
	match _pending_skill.target_type:
		Skill.TargetType.SINGLE_ENEMY:
			valid = target.team != selected_unit.team and target.is_alive()
		Skill.TargetType.SINGLE_ALLY:
			valid = target.team == selected_unit.team and target.is_alive()
	if not valid:
		return

	_execute_skill_on_target(selected_unit, _pending_skill, target)

func _execute_self_skill(caster: Unit, skill: Skill) -> void:
	player_state = PlayerState.ATTACKING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	caster.stats.mp = maxi(caster.stats.mp - skill.mp_cost, 0)

	# BUFF：這裡先簡化為立即視覺提示，實際狀態系統可日後加入
	_show_floating_text(caster, skill.display_name + "!")

	await get_tree().create_timer(0.5).timeout
	caster.end_action()
	_deselect_unit()
	_check_player_turn_end()

func _execute_skill_on_target(caster: Unit, skill: Skill, target: Unit) -> void:
	player_state = PlayerState.ATTACKING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	caster.stats.mp = maxi(caster.stats.mp - skill.mp_cost, 0)

	var killed := false
	match skill.skill_type:
		Skill.SkillType.PHYSICAL, Skill.SkillType.MAGICAL:
			for i in range(skill.hit_count):
				if not target.is_alive():
					break
				var result := damage_calculator.calculate_skill_damage(caster, target, skill)
				_show_damage_popup(target, result)
				if result["is_hit"]:
					target.take_damage(result["damage"])
					killed = not target.is_alive()
				await get_tree().create_timer(0.25).timeout

		Skill.SkillType.HEAL:
			var amount := skill.heal_amount
			if skill.heal_ratio > 0.0:
				amount += roundi(caster.stats.get_effective_magic_attack() * skill.heal_ratio)
			target.heal(amount)
			_show_heal_popup(target, amount)

	await get_tree().create_timer(0.3).timeout

	if caster.team == Unit.Team.PLAYER and target.team != Unit.Team.PLAYER:
		_grant_exp(caster, target, killed)

	caster.end_action()
	hud.show_unit_info(target)
	_deselect_unit()
	_check_battle_end()
	if current_phase != Phase.BATTLE_OVER:
		_wait_for_level_ups_then(func(): _check_player_turn_end())

## ========== 道具 ==========

func _on_item_selected(item: Item) -> void:
	_pending_item = item
	# 對自身使用（簡化：所有道具都對選中單位生效；復活需選倒下目標，這裡暫略）
	_execute_item_on_target(selected_unit, item)

func _handle_item_target_select(cell: Vector2i) -> void:
	# 目前未啟用（所有道具對自身生效）
	pass

func _execute_item_on_target(target: Unit, item: Item) -> void:
	player_state = PlayerState.ATTACKING
	cursor.set_active(false)
	tile_highlighter.clear_all()

	if not Inventory.remove_item(item.item_id, 1):
		_show_action_menu()
		return

	match item.consumable_effect:
		Item.ConsumableEffect.HEAL_HP_FLAT:
			var amt := int(item.effect_value)
			target.heal(amt)
			_show_heal_popup(target, amt)
		Item.ConsumableEffect.HEAL_HP_PERCENT:
			var amt := int(target.stats.hp_max * item.effect_value)
			target.heal(amt)
			_show_heal_popup(target, amt)
		Item.ConsumableEffect.HEAL_MP_FLAT:
			target.stats.mp = mini(target.stats.mp + int(item.effect_value), target.stats.mp_max)
			_show_floating_text(target, "MP +" + str(int(item.effect_value)))
		Item.ConsumableEffect.HEAL_MP_PERCENT:
			var amt := int(target.stats.mp_max * item.effect_value)
			target.stats.mp = mini(target.stats.mp + amt, target.stats.mp_max)
			_show_floating_text(target, "MP +" + str(amt))

	await get_tree().create_timer(0.4).timeout
	target.end_action()
	hud.show_unit_info(target)
	_deselect_unit()
	_check_player_turn_end()

## ========== 經驗 / 升級 ==========

func _grant_exp(attacker: Unit, defender: Unit, killed: bool) -> void:
	var exp_amount := ExpSystem.calc_exp_gained(attacker, defender, killed)
	_show_floating_text(attacker, "+%d EXP" % exp_amount)
	var level_ups := ExpSystem.grant_exp(attacker, exp_amount)
	if not level_ups.is_empty():
		_pending_level_ups.append({"unit": attacker, "level_ups": level_ups})

func _wait_for_level_ups_then(callback: Callable) -> void:
	if _pending_level_ups.is_empty() or level_up_popup == null:
		callback.call()
		return
	# 連續顯示所有升級彈窗
	_process_next_level_up(callback)

var _level_up_continuation: Callable

func _process_next_level_up(callback: Callable) -> void:
	if _pending_level_ups.is_empty():
		callback.call()
		return
	var entry: Dictionary = _pending_level_ups.pop_front()
	_level_up_continuation = callback
	player_state = PlayerState.LEVEL_UP
	level_up_popup.show_level_up(entry["unit"], entry["level_ups"])

func _on_level_up_closed() -> void:
	if _pending_level_ups.is_empty():
		if _level_up_continuation.is_valid():
			var cb := _level_up_continuation
			_level_up_continuation = Callable()
			cb.call()
	else:
		_process_next_level_up(_level_up_continuation)

## ========== 其他 ==========

func _check_player_turn_end() -> void:
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

func _unhandled_input(event: InputEvent) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if player_state != PlayerState.IDLE:
		return
	if event.is_action_pressed("end_turn"):
		_start_enemy_turn()

func _show_damage_popup(target: Unit, result: Dictionary) -> void:
	var popup_scene := preload("res://scenes/battle/damage_popup.tscn")
	var popup: DamagePopup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = target.global_position + Vector2(0, -20)
	popup.show_damage(result["damage"], result["is_crit"], not result["is_hit"])

func _show_heal_popup(target: Unit, amount: int) -> void:
	var popup_scene := preload("res://scenes/battle/damage_popup.tscn")
	var popup: DamagePopup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = target.global_position + Vector2(0, -20)
	popup.show_damage(amount, false, false)
	popup.modulate = Color(0.4, 1.0, 0.4)

func _show_floating_text(target: Unit, text: String) -> void:
	var popup_scene := preload("res://scenes/battle/damage_popup.tscn")
	var popup: DamagePopup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = target.global_position + Vector2(0, -20)
	popup.show_text(text)
