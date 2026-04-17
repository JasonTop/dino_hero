class_name Unit
extends Node2D

## 戰場單位 — 恐龍

signal unit_selected(unit: Unit)
signal unit_died(unit: Unit)
signal move_finished(unit: Unit)
signal attack_finished(unit: Unit)

enum Team { PLAYER = 0, ENEMY = 1, NPC = 2 }

@export var team: int = Team.PLAYER
@export var stats: UnitStats

var cell := Vector2i.ZERO          # 當前格子座標
var has_moved: bool = false        # 本回合是否已移動
var has_acted: bool = false        # 本回合是否已行動
var is_moving: bool = false        # 正在移動動畫中

# 移動動畫
var _move_path: Array[Vector2i] = []
var _move_index: int = 0
const MOVE_SPEED := 300.0  # 像素/秒
const CELL_SIZE := 64

@onready var sprite: ColorRect = $Sprite
@onready var health_bar: Control = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var selection_indicator: ColorRect = $SelectionIndicator

func _ready() -> void:
	_update_visual()
	update_health_bar()
	set_selected(false)

func init(unit_stats: UnitStats, unit_team: int, start_cell: Vector2i) -> void:
	stats = unit_stats
	team = unit_team
	cell = start_cell
	position = Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	_update_visual()
	update_health_bar()

func _process(delta: float) -> void:
	if is_moving:
		_process_movement(delta)

## 開始沿路徑移動
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() <= 1:
		move_finished.emit(self)
		return
	_move_path = path
	_move_index = 1  # 第0個是起點
	is_moving = true
	has_moved = true

func _process_movement(delta: float) -> void:
	if _move_index >= _move_path.size():
		is_moving = false
		cell = _move_path[_move_path.size() - 1]
		position = Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
		move_finished.emit(self)
		return

	var target_pos := Vector2(_move_path[_move_index]) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	var move_delta := MOVE_SPEED * delta
	var diff := target_pos - position

	if diff.length() <= move_delta:
		position = target_pos
		_move_index += 1
	else:
		position += diff.normalized() * move_delta

## 受傷
func take_damage(damage: int) -> int:
	var actual_damage := maxi(damage, 1)
	stats.hp = maxi(stats.hp - actual_damage, 0)
	update_health_bar()
	_flash_damage()
	if stats.hp <= 0:
		die()
	return actual_damage

func heal(amount: int) -> void:
	stats.hp = mini(stats.hp + amount, stats.hp_max)
	update_health_bar()

func die() -> void:
	unit_died.emit(self)
	# 簡單的死亡動畫：淡出後隱藏（不 queue_free，避免陣列引用失效）
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false; set_process(false))

func is_alive() -> bool:
	return stats.hp > 0

## 回合開始重置行動狀態
func reset_turn() -> void:
	has_moved = false
	has_acted = false
	modulate = Color.WHITE

## 標記已行動完畢（灰顯）
func end_action() -> void:
	has_acted = true
	modulate = Color(0.5, 0.5, 0.5, 1.0)

func set_selected(selected: bool) -> void:
	if selection_indicator:
		selection_indicator.visible = selected

func update_health_bar() -> void:
	if not health_fill or not stats:
		return
	var ratio := float(stats.hp) / float(stats.hp_max)
	health_fill.size.x = 48.0 * ratio
	if ratio > 0.5:
		health_fill.color = Color.GREEN
	elif ratio > 0.25:
		health_fill.color = Color.YELLOW
	else:
		health_fill.color = Color.RED

func _update_visual() -> void:
	if not sprite:
		return
	# 用顏色區分陣營
	match team:
		Team.PLAYER:
			sprite.color = Color(0.2, 0.7, 0.3)   # 綠色=我方
		Team.ENEMY:
			sprite.color = Color(0.8, 0.2, 0.2)   # 紅色=敵方
		Team.NPC:
			sprite.color = Color(0.8, 0.8, 0.2)   # 黃色=NPC

func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if has_acted:
		tween.tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 1.0), 0.0)
