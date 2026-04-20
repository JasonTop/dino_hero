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

# 狀態異常
var status_effects: Array[StatusEffect] = []

# 移動動畫
var _move_path: Array[Vector2i] = []
var _move_index: int = 0
const MOVE_SPEED := 300.0  # 像素/秒
const CELL_SIZE := 64

@onready var sprite: ColorRect = $Sprite
@onready var health_bar: Control = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var selection_indicator: ColorRect = $SelectionIndicator
@onready var status_icons: HBoxContainer = get_node_or_null("StatusIcons")

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
	# 被攻擊叫醒沉睡
	if has_status("sleep"):
		remove_status("sleep")
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

## ===== 狀態異常 =====

## 套用狀態（已存在同 id 則刷新 duration/magnitude，取較長/較大值）
func apply_status(effect_id: String, duration: int, magnitude: float = 0.0) -> void:
	if not StatusEffectDatabase.has_effect(effect_id):
		push_warning("Unknown status effect: " + effect_id)
		return
	for e in status_effects:
		if e.effect_id == effect_id:
			e.duration = maxi(e.duration, duration)
			e.magnitude = maxf(e.magnitude, magnitude)
			_refresh_status_icons()
			return
	var effect := StatusEffect.new(effect_id, duration, magnitude)
	status_effects.append(effect)
	_refresh_status_icons()

func remove_status(effect_id: String) -> void:
	for i in range(status_effects.size() - 1, -1, -1):
		if status_effects[i].effect_id == effect_id:
			status_effects.remove_at(i)
	_refresh_status_icons()

func clear_all_status() -> void:
	status_effects.clear()
	_refresh_status_icons()

func has_status(effect_id: String) -> bool:
	for e in status_effects:
		if e.effect_id == effect_id:
			return true
	return false

## 取得乘數（若同類效果有多個，取相乘）
func get_stat_multiplier(stat: String) -> float:
	var mult := 1.0
	for e in status_effects:
		var d := e.get_def()
		if d.has(stat + "_mult"):
			mult *= float(d[stat + "_mult"])
	return mult

## 取得命中率修正（加總）
func get_accuracy_mod() -> float:
	var total := 0.0
	for e in status_effects:
		var d := e.get_def()
		if d.has("accuracy_mod"):
			total += float(d["accuracy_mod"])
	return total

## 判定是否跳過本回合（麻痺/沉睡）
func should_skip_turn() -> bool:
	for e in status_effects:
		var d := e.get_def()
		var chance: float = float(d.get("skip_chance", 0))
		if chance > 0 and randf() * 100.0 < chance:
			return true
	return false

## 回合開始 tick（傷害/治療/狀態倒數）
## 回傳：{damage: int, heal: int, expired: [effect_ids]}
func tick_status() -> Dictionary:
	var total_damage := 0
	var total_heal := 0
	var expired: Array[String] = []

	for e in status_effects:
		var d := e.get_def()
		var pct: float = float(d.get("tick_hp_pct", 0.0))
		if pct < 0:
			var dmg := maxi(roundi(stats.hp_max * -pct), 1)
			total_damage += dmg
		elif pct > 0:
			var heal_amt := maxi(roundi(stats.hp_max * pct), 1)
			total_heal += heal_amt

	# 套用效果
	if total_damage > 0:
		stats.hp = maxi(stats.hp - total_damage, 0)
	if total_heal > 0:
		stats.hp = mini(stats.hp + total_heal, stats.hp_max)

	# 倒數 duration 並清除過期
	for i in range(status_effects.size() - 1, -1, -1):
		status_effects[i].duration -= 1
		if status_effects[i].duration <= 0:
			expired.append(status_effects[i].effect_id)
			status_effects.remove_at(i)

	update_health_bar()
	_refresh_status_icons()

	if stats.hp <= 0:
		die()

	return {"damage": total_damage, "heal": total_heal, "expired": expired}

func _refresh_status_icons() -> void:
	if status_icons == null:
		return
	for c in status_icons.get_children():
		c.queue_free()
	for e in status_effects:
		var d := e.get_def()
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = d.get("color", Color.WHITE)
		dot.tooltip_text = "%s (%d)" % [d.get("name", e.effect_id), e.duration]
		status_icons.add_child(dot)
