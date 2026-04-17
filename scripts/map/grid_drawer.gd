extends Node2D

## 繪製地圖格線和地形顏色 — Phase 1 使用程式碼繪圖代替 TileSet

const CELL_SIZE := 64

# 地形顏色
var terrain_colors := {
	TerrainData.TerrainType.PLAIN:  Color(0.45, 0.65, 0.35),
	TerrainData.TerrainType.GRASS:  Color(0.35, 0.75, 0.30),
	TerrainData.TerrainType.FOREST: Color(0.20, 0.45, 0.15),
	TerrainData.TerrainType.ROCK:   Color(0.55, 0.50, 0.45),
	TerrainData.TerrainType.WALL:   Color(0.30, 0.25, 0.25),
	TerrainData.TerrainType.WATER:  Color(0.25, 0.40, 0.70),
}

var grid_line_color := Color(0, 0, 0, 0.15)

func _draw() -> void:
	var map: BattleMap = get_parent() as BattleMap
	if not map:
		return

	# 繪製地形色塊
	for x in range(map.map_width):
		for y in range(map.map_height):
			var cell := Vector2i(x, y)
			var terrain_type := map.get_terrain_type(cell)
			var color: Color = terrain_colors.get(terrain_type, Color.MAGENTA)
			var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			draw_rect(rect, color)

	# 繪製格線
	for x in range(map.map_width + 1):
		var from := Vector2(x * CELL_SIZE, 0)
		var to := Vector2(x * CELL_SIZE, map.map_height * CELL_SIZE)
		draw_line(from, to, grid_line_color, 1.0)
	for y in range(map.map_height + 1):
		var from := Vector2(0, y * CELL_SIZE)
		var to := Vector2(map.map_width * CELL_SIZE, y * CELL_SIZE)
		draw_line(from, to, grid_line_color, 1.0)

	# 在特殊地形格子上繪製符號
	for x in range(map.map_width):
		for y in range(map.map_height):
			var cell := Vector2i(x, y)
			var terrain_type := map.get_terrain_type(cell)
			var center := Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)

			match terrain_type:
				TerrainData.TerrainType.FOREST:
					# 簡單三角形代表樹
					_draw_tree(center)
				TerrainData.TerrainType.ROCK:
					# 簡單菱形代表岩石
					_draw_rock(center)
				TerrainData.TerrainType.WALL:
					# X 代表不可通行
					_draw_x(center)

func _draw_tree(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -12),
		center + Vector2(-10, 8),
		center + Vector2(10, 8),
	])
	draw_colored_polygon(points, Color(0.1, 0.3, 0.1, 0.6))

func _draw_rock(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -10),
		center + Vector2(10, 0),
		center + Vector2(0, 10),
		center + Vector2(-10, 0),
	])
	draw_colored_polygon(points, Color(0.4, 0.35, 0.3, 0.5))

func _draw_x(center: Vector2) -> void:
	draw_line(center + Vector2(-10, -10), center + Vector2(10, 10), Color(0.6, 0.2, 0.2, 0.6), 3.0)
	draw_line(center + Vector2(10, -10), center + Vector2(-10, 10), Color(0.6, 0.2, 0.2, 0.6), 3.0)
