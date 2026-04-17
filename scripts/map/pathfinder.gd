class_name Pathfinder
extends RefCounted

## 尋路與範圍計算 — BFS 移動範圍 + AStar2D 最短路徑

var battle_map: BattleMap

func _init(map: BattleMap) -> void:
	battle_map = map

## BFS 計算可移動範圍
## 回傳所有可到達的格子（不含起點）
func get_reachable_cells(origin: Vector2i, movement: int, team: int = -1) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}  # Vector2i -> int (剩餘移動力)
	var queue: Array = []  # [cell, remaining_movement]

	visited[origin] = movement
	queue.append([origin, movement])

	while queue.size() > 0:
		var current = queue.pop_front()
		var cell: Vector2i = current[0]
		var remaining: int = current[1]

		for neighbor in battle_map.get_neighbors(cell):
			if not battle_map.is_within_bounds(neighbor):
				continue

			var terrain_info := battle_map.get_terrain_info(neighbor)
			if not terrain_info["pass"]:
				continue

			var cost: int = terrain_info["cost"]
			var new_remaining := remaining - cost

			if new_remaining < 0:
				continue

			# 可以穿過友軍，但不能穿過敵軍
			var unit_at = battle_map.get_unit_at(neighbor)
			if unit_at and unit_at.team != team and team >= 0:
				continue

			if visited.has(neighbor) and visited[neighbor] >= new_remaining:
				continue

			visited[neighbor] = new_remaining

			# 只有沒有單位佔據的格子才能停留
			if not unit_at or neighbor == origin:
				if neighbor != origin:
					reachable.append(neighbor)

			queue.append([neighbor, new_remaining])

	return reachable

## AStar2D 計算兩點間最短路徑
func get_path(from: Vector2i, to: Vector2i, team: int = -1) -> Array[Vector2i]:
	var astar := AStar2D.new()
	var id_map: Dictionary = {}  # Vector2i -> int
	var next_id: int = 0

	# 建立 AStar 節點（整張地圖可通行格子）
	for x in range(battle_map.map_width):
		for y in range(battle_map.map_height):
			var cell := Vector2i(x, y)
			var terrain_info := battle_map.get_terrain_info(cell)
			if not terrain_info["pass"]:
				continue
			# 敵方單位所在格子不可通行
			var unit_at = battle_map.get_unit_at(cell)
			if unit_at and unit_at.team != team and team >= 0 and cell != from and cell != to:
				continue

			id_map[cell] = next_id
			astar.add_point(next_id, Vector2(cell))
			next_id += 1

	# 建立連線
	for cell in id_map:
		var cell_id: int = id_map[cell]
		for neighbor in battle_map.get_neighbors(cell):
			if id_map.has(neighbor):
				var neighbor_id: int = id_map[neighbor]
				var terrain_info := battle_map.get_terrain_info(neighbor)
				if not astar.are_points_connected(cell_id, neighbor_id):
					astar.connect_points(cell_id, neighbor_id)
				# 權重用地形消耗
				astar.set_point_weight_scale(neighbor_id, terrain_info["cost"])

	if not id_map.has(from) or not id_map.has(to):
		return []

	var path_ids := astar.get_id_path(id_map[from], id_map[to])
	var path: Array[Vector2i] = []
	for pid in path_ids:
		var pos := astar.get_point_position(pid)
		path.append(Vector2i(pos))

	return path

## 計算攻擊範圍（曼哈頓距離）
func get_attack_range(origin: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			var dist := absi(dx) + absi(dy)
			if dist < min_range or dist > max_range:
				continue
			var cell := origin + Vector2i(dx, dy)
			if battle_map.is_within_bounds(cell) and cell != origin:
				cells.append(cell)
	return cells
