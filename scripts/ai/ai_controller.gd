class_name AIController
extends Node

## 敵方 AI 控制器 — 基礎決策：找最近目標、移動、攻擊

signal ai_turn_completed()
signal ai_unit_action_start(unit: Unit)
signal ai_unit_action_end(unit: Unit)

var battle_map: BattleMap
var pathfinder: Pathfinder
var damage_calculator: DamageCalculator

var _processing_units: Array[Unit] = []
var _current_index: int = 0
var _is_processing: bool = false

const ACTION_DELAY := 0.5  # 每個單位行動之間的延遲

func init(map: BattleMap, pf: Pathfinder, dc: DamageCalculator) -> void:
	battle_map = map
	pathfinder = pf
	damage_calculator = dc

## 開始 AI 回合
func start_ai_turn(enemy_units: Array[Unit], player_units: Array[Unit]) -> void:
	_processing_units.clear()
	for u in enemy_units:
		if u.is_alive() and not u.has_acted:
			_processing_units.append(u)
	_current_index = 0
	_is_processing = true
	_process_next_unit(player_units)

func _process_next_unit(player_units: Array[Unit]) -> void:
	if _current_index >= _processing_units.size():
		_is_processing = false
		ai_turn_completed.emit()
		return

	var unit := _processing_units[_current_index]
	_current_index += 1

	if not unit.is_alive():
		_process_next_unit(player_units)
		return

	ai_unit_action_start.emit(unit)

	# 找最佳目標和行動
	var action := _decide_action(unit, player_units)

	if action["type"] == "attack":
		# 移動到攻擊位置
		var move_target: Vector2i = action["move_to"]
		var attack_target: Unit = action["target"]

		if move_target != unit.cell:
			var path := pathfinder.get_path(unit.cell, move_target, unit.team)
			if path.size() > 0:
				battle_map.move_unit(unit.cell, move_target)
				unit.move_along_path(path)
				await unit.move_finished
				await get_tree().create_timer(0.2).timeout

		# 攻擊
		if attack_target and attack_target.is_alive():
			var result := damage_calculator.calculate_damage(unit, attack_target)
			attack_target.take_damage(result["damage"])
			await get_tree().create_timer(0.3).timeout

	elif action["type"] == "move":
		# 只移動，不攻擊
		var move_target: Vector2i = action["move_to"]
		if move_target != unit.cell:
			var path := pathfinder.get_path(unit.cell, move_target, unit.team)
			if path.size() > 0:
				battle_map.move_unit(unit.cell, move_target)
				unit.move_along_path(path)
				await unit.move_finished

	unit.end_action()
	ai_unit_action_end.emit(unit)

	await get_tree().create_timer(ACTION_DELAY).timeout
	_process_next_unit(player_units)

## AI 決策：找目標、計算最佳位置
## AI 聰明度（ai_smart）：
##   0 = 無腦衝，只看最近距離
##   1 = 基礎，會挑可擊殺/低HP目標
##   2 = 進階，優先攻擊支援/遠程、考慮地形
##   3 = 高智能，會協同包圍、保護己方支援
func _decide_action(unit: Unit, player_units: Array[Unit]) -> Dictionary:
	var cfg := GameManager.get_difficulty_config()
	var ai_smart: int = cfg.get("ai_smart", 1)

	var reachable := pathfinder.get_reachable_cells(unit.cell, unit.stats.movement, unit.team)
	reachable.append(unit.cell)

	var best_action := { "type": "wait", "move_to": unit.cell, "target": null, "score": -999.0 }

	# 對每個可到達位置，檢查是否能攻擊到敵人
	for move_cell in reachable:
		var attack_cells := pathfinder.get_attack_range(
			move_cell, unit.stats.attack_range_min, unit.stats.attack_range_max
		)
		for target in player_units:
			if not target.is_alive():
				continue
			if target.cell in attack_cells:
				var preview := damage_calculator.preview_damage(unit, target)
				var score := float(preview["estimated_damage"])

				if ai_smart >= 1:
					# 可擊殺加分
					if preview["estimated_damage"] >= target.stats.hp:
						score += 100.0
					# 低 HP 目標加分
					score += (1.0 - float(target.stats.hp) / float(target.stats.hp_max)) * 20.0

				if ai_smart >= 2:
					# 優先攻擊支援/遠程（脆皮）
					match target.stats.class_type:
						"support": score += 30.0
						"ranged": score += 20.0
					# 命中率加權
					score *= (float(preview["hit_rate"]) / 100.0)

				if ai_smart >= 3:
					# 從背後/側面攻擊（地形防禦低的位置）加分
					var terrain := battle_map.get_terrain_info(move_cell)
					score -= terrain["def"] * 5.0  # 自己站在低防禦地形扣分
					# 避免被包夾：檢查移動後是否被多個敵人威脅
					var threat_count := _count_threats(move_cell, player_units, unit.team)
					score -= threat_count * 10.0

				if score > best_action["score"]:
					best_action = {
						"type": "attack",
						"move_to": move_cell,
						"target": target,
						"score": score,
					}

	# 如果無法攻擊到任何人，朝最近的敵人移動
	if best_action["type"] == "wait" and player_units.size() > 0:
		var closest_target: Unit = null
		var closest_dist := 9999.0
		for target in player_units:
			if not target.is_alive():
				continue
			var dist := _manhattan_distance(unit.cell, target.cell)
			if dist < closest_dist:
				closest_dist = dist
				closest_target = target

		if closest_target:
			var best_cell := unit.cell
			var best_dist := closest_dist
			for move_cell in reachable:
				var dist := _manhattan_distance(move_cell, closest_target.cell)
				if dist < best_dist:
					best_dist = dist
					best_cell = move_cell
			best_action["type"] = "move"
			best_action["move_to"] = best_cell

	return best_action

func _manhattan_distance(a: Vector2i, b: Vector2i) -> float:
	return float(absi(a.x - b.x) + absi(a.y - b.y))

## 計算該位置有多少敵人可以攻擊到（威脅數）
func _count_threats(cell: Vector2i, enemies: Array[Unit], own_team: int) -> int:
	var count := 0
	for e in enemies:
		if not e.is_alive():
			continue
		if e.team == own_team:
			continue
		var dist := absi(e.cell.x - cell.x) + absi(e.cell.y - cell.y)
		if dist >= e.stats.attack_range_min and dist <= e.stats.attack_range_max + e.stats.movement:
			count += 1
	return count
