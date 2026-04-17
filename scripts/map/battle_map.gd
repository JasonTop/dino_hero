class_name BattleMap
extends Node2D

## 戰場地圖管理 — 格子座標管理、地形查詢、單位位置追蹤
## Phase 1：使用程式碼生成地形（無 TileSet 美術時）

const CELL_SIZE := Vector2i(64, 64)

@onready var tile_highlighter: TileHighlighter = $TileHighlighter
@onready var grid_drawer: Node2D = $GridDrawer

# 地圖尺寸（格子數）
var map_width: int = 15
var map_height: int = 10

# 地形資料：cell -> TerrainType
var terrain_grid: Dictionary = {}  # Vector2i -> TerrainData.TerrainType

# 單位位置追蹤：cell -> Unit
var unit_positions: Dictionary = {}  # Vector2i -> Unit

func _ready() -> void:
	_generate_test_map()

## 程式生成測試地圖
func _generate_test_map() -> void:
	terrain_grid.clear()
	for x in range(map_width):
		for y in range(map_height):
			var cell := Vector2i(x, y)
			terrain_grid[cell] = TerrainData.TerrainType.PLAIN

	# 加入一些地形變化
	# 草叢區域
	for cell in [Vector2i(4,3), Vector2i(4,4), Vector2i(5,3), Vector2i(5,4), Vector2i(5,5),
				 Vector2i(9,5), Vector2i(9,6), Vector2i(10,5), Vector2i(10,6)]:
		terrain_grid[cell] = TerrainData.TerrainType.GRASS

	# 森林
	for cell in [Vector2i(6,1), Vector2i(6,2), Vector2i(7,1), Vector2i(7,2),
				 Vector2i(7,7), Vector2i(7,8), Vector2i(8,7), Vector2i(8,8)]:
		terrain_grid[cell] = TerrainData.TerrainType.FOREST

	# 岩地
	for cell in [Vector2i(8,4), Vector2i(8,5), Vector2i(9,4)]:
		terrain_grid[cell] = TerrainData.TerrainType.ROCK

	# 不可通行障壁
	for cell in [Vector2i(6,4), Vector2i(6,5)]:
		terrain_grid[cell] = TerrainData.TerrainType.WALL

	# 通知 GridDrawer 重繪
	if grid_drawer:
		grid_drawer.queue_redraw()

## 格子座標 → 世界座標（格子中心）
func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Vector2(CELL_SIZE) + Vector2(CELL_SIZE) / 2.0

## 世界座標 → 格子座標
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / CELL_SIZE.x, int(world_pos.y) / CELL_SIZE.y)

## 取得地形類型
func get_terrain_type(cell: Vector2i) -> TerrainData.TerrainType:
	return terrain_grid.get(cell, TerrainData.TerrainType.WALL)

## 取得地形資料
func get_terrain_info(cell: Vector2i) -> Dictionary:
	var t := get_terrain_type(cell)
	return TerrainData.get_terrain(t)

## 格子是否在地圖範圍內
func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_width and cell.y >= 0 and cell.y < map_height

## 格子是否可通行（考慮地形+是否有單位佔據）
func is_cell_passable(cell: Vector2i, ignore_units: bool = false) -> bool:
	if not is_within_bounds(cell):
		return false
	var info := get_terrain_info(cell)
	if not info["pass"]:
		return false
	if not ignore_units and unit_positions.has(cell):
		return false
	return true

## 格子是否可以停留（可通行 + 沒有單位）
func is_cell_available(cell: Vector2i) -> bool:
	if not is_within_bounds(cell):
		return false
	var info := get_terrain_info(cell)
	if not info["pass"]:
		return false
	if unit_positions.has(cell):
		return false
	return true

## 取得相鄰格子（上下左右）
func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d: Vector2i in dirs:
		var n: Vector2i = cell + d
		if is_within_bounds(n):
			neighbors.append(n)
	return neighbors

## 註冊單位到格子
func place_unit(unit: Node, cell: Vector2i) -> void:
	unit_positions[cell] = unit

## 移除格子上的單位
func remove_unit(cell: Vector2i) -> void:
	unit_positions.erase(cell)

## 移動單位（更新位置追蹤）
func move_unit(from: Vector2i, to: Vector2i) -> void:
	if unit_positions.has(from):
		var unit = unit_positions[from]
		unit_positions.erase(from)
		unit_positions[to] = unit

## 取得格子上的單位
func get_unit_at(cell: Vector2i):
	return unit_positions.get(cell, null)
