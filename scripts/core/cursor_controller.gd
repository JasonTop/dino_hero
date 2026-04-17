class_name CursorController
extends Node2D

## 格子游標控制 — 鍵盤+滑鼠操控，發出格子選擇信號

signal cell_hovered(cell: Vector2i)
signal cell_selected(cell: Vector2i)
signal cancel_pressed()

const CELL_SIZE := 64
const MOVE_REPEAT_DELAY := 0.15  # 按住方向鍵的重複間隔

var current_cell := Vector2i.ZERO
var battle_map: BattleMap
var is_active: bool = true

var _move_timer: float = 0.0
var _move_dir := Vector2i.ZERO

@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
	_update_visual()

func init(map: BattleMap, start_cell: Vector2i = Vector2i.ZERO) -> void:
	battle_map = map
	current_cell = start_cell
	_update_visual()

func _process(delta: float) -> void:
	if not is_active:
		return
	_handle_keyboard_input(delta)
	_handle_mouse_input()

func _handle_keyboard_input(delta: float) -> void:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("cursor_up"):
		dir.y = -1
	elif Input.is_action_pressed("cursor_down"):
		dir.y = 1
	if Input.is_action_pressed("cursor_left"):
		dir.x = -1
	elif Input.is_action_pressed("cursor_right"):
		dir.x = 1

	if dir != Vector2i.ZERO:
		if dir != _move_dir:
			# 新方向，立即移動
			_move_dir = dir
			_move_timer = 0.0
			_try_move(dir)
		else:
			_move_timer += delta
			if _move_timer >= MOVE_REPEAT_DELAY:
				_move_timer -= MOVE_REPEAT_DELAY
				_try_move(dir)
	else:
		_move_dir = Vector2i.ZERO
		_move_timer = 0.0

	if Input.is_action_just_pressed("confirm"):
		cell_selected.emit(current_cell)
	if Input.is_action_just_pressed("cancel"):
		cancel_pressed.emit()

func _handle_mouse_input() -> void:
	if not battle_map:
		return
	# 滑鼠移動時更新游標位置
	var mouse_pos := get_global_mouse_position()
	var mouse_cell := battle_map.world_to_cell(mouse_pos)
	if mouse_cell != current_cell and battle_map.is_within_bounds(mouse_cell):
		current_cell = mouse_cell
		_update_visual()
		cell_hovered.emit(current_cell)

	# 滑鼠左鍵點擊 = 確認
	if Input.is_action_just_pressed("confirm"):
		pass  # 已在鍵盤區處理
	# 這裡用 mouse button 直接偵測
func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if battle_map:
				var mouse_cell := battle_map.world_to_cell(get_global_mouse_position())
				if battle_map.is_within_bounds(mouse_cell):
					current_cell = mouse_cell
					_update_visual()
					cell_selected.emit(current_cell)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			cancel_pressed.emit()

func _try_move(dir: Vector2i) -> void:
	var new_cell := current_cell + dir
	if battle_map and battle_map.is_within_bounds(new_cell):
		current_cell = new_cell
		_update_visual()
		cell_hovered.emit(current_cell)

func _update_visual() -> void:
	position = Vector2(current_cell) * CELL_SIZE
	if sprite:
		sprite.size = Vector2(CELL_SIZE, CELL_SIZE)

func set_active(active: bool) -> void:
	is_active = active
