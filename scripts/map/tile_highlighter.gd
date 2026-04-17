class_name TileHighlighter
extends Node2D

## 繪製移動範圍（藍色）、攻擊範圍（紅色）、威脅範圍預覽（橘色）的高亮層

const CELL_SIZE := 64

var move_cells: Array[Vector2i] = []
var attack_cells: Array[Vector2i] = []
var path_cells: Array[Vector2i] = []
var threat_move_cells: Array[Vector2i] = []    # 敵方移動範圍預覽（橘色）
var threat_attack_cells: Array[Vector2i] = []  # 敵方攻擊範圍預覽（深紅）

var move_color := Color(0.2, 0.5, 1.0, 0.35)
var attack_color := Color(1.0, 0.2, 0.2, 0.35)
var path_color := Color(0.2, 0.8, 1.0, 0.5)
var threat_move_color := Color(1.0, 0.6, 0.1, 0.3)
var threat_attack_color := Color(0.8, 0.0, 0.0, 0.25)

func _draw() -> void:
	# 威脅攻擊範圍（最底層）
	for cell in threat_attack_cells:
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, threat_attack_color)

	# 威脅移動範圍
	for cell in threat_move_cells:
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, threat_move_color)
		draw_rect(rect, threat_move_color * 1.3, false, 2.0)

	for cell in move_cells:
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, move_color)
		draw_rect(rect, move_color * 1.5, false, 2.0)

	for cell in attack_cells:
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, attack_color)
		draw_rect(rect, attack_color * 1.5, false, 2.0)

	for cell in path_cells:
		var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, path_color)

func show_move_range(cells: Array[Vector2i]) -> void:
	move_cells = cells
	queue_redraw()

func show_attack_range(cells: Array[Vector2i]) -> void:
	attack_cells = cells
	queue_redraw()

func show_path(cells: Array[Vector2i]) -> void:
	path_cells = cells
	queue_redraw()

## 顯示威脅預覽（敵方/已行動單位的移動+攻擊範圍）
func show_threat_range(move: Array[Vector2i], attack: Array[Vector2i]) -> void:
	threat_move_cells = move
	threat_attack_cells = attack
	queue_redraw()

func clear_threat_range() -> void:
	threat_move_cells.clear()
	threat_attack_cells.clear()
	queue_redraw()

func clear_move_range() -> void:
	move_cells.clear()
	queue_redraw()

func clear_attack_range() -> void:
	attack_cells.clear()
	queue_redraw()

func clear_path() -> void:
	path_cells.clear()
	queue_redraw()

func clear_all() -> void:
	move_cells.clear()
	attack_cells.clear()
	path_cells.clear()
	threat_move_cells.clear()
	threat_attack_cells.clear()
	queue_redraw()
