extends Control

## 世界地圖 — 章節節點選單

const EventPopupRes := preload("res://scenes/world_map/event_popup.tscn")
const ShopPopupRes := preload("res://scenes/world_map/shop_popup.tscn")
const SaveLoadScene := preload("res://scenes/ui/save_load_screen.tscn")

const NODE_SIZE := Vector2(64, 64)

const TYPE_COLORS := {
	"main":  Color(0.3, 0.8, 0.4),   # 綠圓
	"side":  Color(0.4, 0.6, 0.9),   # 藍菱形
	"boss":  Color(0.9, 0.2, 0.2),   # 紅星
	"shop":  Color(1.0, 0.85, 0.3),  # 黃屋
	"event": Color(0.7, 0.4, 0.9),   # 紫色
}

@onready var nodes_layer: Control = $MapView/NodesLayer
@onready var paths_layer: Node2D = $MapView/PathsLayer
@onready var info_panel: PanelContainer = $UILayer/InfoPanel
@onready var info_title: Label = $UILayer/InfoPanel/VBox/Title
@onready var info_desc: Label = $UILayer/InfoPanel/VBox/Description
@onready var info_level: Label = $UILayer/InfoPanel/VBox/Level
@onready var enter_button: Button = $UILayer/InfoPanel/VBox/EnterButton
@onready var back_button: Button = $UILayer/TopBar/HBox/BackButton
@onready var status_label: Label = $UILayer/TopBar/HBox/StatusLabel
@onready var gold_label: Label = $UILayer/TopBar/HBox/GoldLabel

var _map_data: Dictionary = {}
var _nodes: Array = []                # 所有節點資料
var _node_buttons: Dictionary = {}    # id -> Button node
var _selected_node_id: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	enter_button.pressed.connect(_on_enter_pressed)
	info_panel.visible = false

	# 若有存檔按鈕/暫停按鈕，連接
	var save_btn := get_node_or_null("UILayer/TopBar/HBox/SaveButton") as Button
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)

	_load_map_data()
	_build_map()
	_refresh_status()

	# 自動存檔（回到世界地圖即自動存）
	SaveManager.auto_save()

func _on_save_pressed() -> void:
	if SaveLoadScreen.is_open():
		return
	SaveLoadScreen.open_singleton(self, SaveLoadScene, SaveLoadScreen.Mode.SAVE)

func _load_map_data() -> void:
	var path := "res://data/world_map.json"
	if not FileAccess.file_exists(path):
		push_error("world_map.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error("world_map.json parse error")
		return
	_map_data = parsed
	_nodes = _map_data.get("nodes", [])

func _build_map() -> void:
	_draw_paths()
	_draw_nodes()

func _draw_paths() -> void:
	# 清除
	for c in paths_layer.get_children():
		c.queue_free()

	for node_data: Dictionary in _nodes:
		var from_pos: Vector2 = _pos_of(node_data)
		for connect_id: String in node_data.get("connects", []):
			var target := _find_node(connect_id)
			if target.is_empty():
				continue
			var to_pos := _pos_of(target)
			var line := Line2D.new()
			line.width = 3.0
			line.default_color = Color(0.6, 0.6, 0.6, 0.6)
			line.add_point(from_pos)
			line.add_point(to_pos)
			paths_layer.add_child(line)

func _draw_nodes() -> void:
	for c in nodes_layer.get_children():
		c.queue_free()
	_node_buttons.clear()

	for node_data: Dictionary in _nodes:
		var btn := _create_node_button(node_data)
		nodes_layer.add_child(btn)
		_node_buttons[node_data["id"]] = btn

func _create_node_button(data: Dictionary) -> Button:
	var btn := Button.new()
	var pos: Vector2 = _pos_of(data) - NODE_SIZE / 2.0
	btn.position = pos
	btn.custom_minimum_size = NODE_SIZE
	btn.size = NODE_SIZE

	var type_str: String = data.get("type", "main")
	var color: Color = TYPE_COLORS.get(type_str, Color.WHITE)

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color(0, 0, 0, 0.6)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	# 依類型顯示符號
	var icon_char := _get_icon_char(type_str)
	btn.text = icon_char
	btn.add_theme_font_size_override("font_size", 32)

	var is_unlocked := _is_node_unlocked(data)
	var is_completed := _is_node_completed(data)

	if not is_unlocked:
		btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
		btn.disabled = true
	elif is_completed:
		btn.modulate = Color(0.8, 1.0, 0.8)
		# 打勾標記
		var check := Label.new()
		check.text = "✓"
		check.position = Vector2(42, -8)
		check.add_theme_font_size_override("font_size", 20)
		check.modulate = Color.GOLD
		btn.add_child(check)
	else:
		# 可挑戰 → 輕微脈動
		btn.modulate = Color.WHITE
		var tween := create_tween().set_loops()
		tween.tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.6)
		tween.tween_property(btn, "modulate", Color.WHITE, 0.6)

	# Tooltip = 節點標題
	btn.tooltip_text = data.get("title", "")

	btn.pressed.connect(_on_node_clicked.bind(data["id"]))
	return btn

func _get_icon_char(type_str: String) -> String:
	match type_str:
		"main": return "🟢"
		"side": return "🔵"
		"boss": return "🔴"
		"shop": return "🟡"
		"event": return "💠"
	return "●"

func _pos_of(data: Dictionary) -> Vector2:
	var p: Array = data.get("position", [0, 0])
	return Vector2(p[0], p[1])

func _find_node(id: String) -> Dictionary:
	for n: Dictionary in _nodes:
		if n.get("id", "") == id:
			return n
	return {}

func _is_node_unlocked(data: Dictionary) -> bool:
	var req: Array = data.get("unlock", [])
	for req_id: String in req:
		if not req_id in StoryManager.completed_chapters:
			return false
	return true

func _is_node_completed(data: Dictionary) -> bool:
	var id: String = data.get("id", "")
	return id in StoryManager.completed_chapters

## ===== 選擇與進入 =====

func _on_node_clicked(node_id: String) -> void:
	_selected_node_id = node_id
	var data := _find_node(node_id)
	if data.is_empty():
		return

	info_title.text = data.get("title", "")
	info_desc.text = data.get("description", "")
	var lv: int = data.get("recommended_level", 0)
	info_level.text = ("推薦等級 Lv." + str(lv)) if lv > 0 else ""
	var type_str: String = data.get("type", "main")
	enter_button.text = _get_enter_button_text(type_str)
	enter_button.disabled = _is_node_completed(data) and type_str in ["main", "side", "boss"]
	info_panel.visible = true

func _get_enter_button_text(type_str: String) -> String:
	match type_str:
		"main", "side": return "進入戰鬥"
		"boss": return "挑戰 BOSS"
		"shop": return "進入商店"
		"event": return "探索"
	return "進入"

func _on_enter_pressed() -> void:
	var data := _find_node(_selected_node_id)
	if data.is_empty():
		return
	var type_str: String = data.get("type", "main")

	match type_str:
		"main", "side", "boss":
			var chapter_id: String = data.get("chapter_id", "")
			if chapter_id != "":
				StoryManager.current_chapter = chapter_id
				StoryManager.set_flag("pending_world_node", _selected_node_id)
				get_tree().change_scene_to_file("res://scenes/story/chapter_flow.tscn")
		"event":
			_open_event(data)
		"shop":
			_open_shop(data)

func _open_event(data: Dictionary) -> void:
	# 關閉同層級的其他選單
	ShopPopup.close_if_open()
	if EventPopup.is_open():
		return
	var popup := EventPopup.open_singleton(self, EventPopupRes, data.get("title", ""))
	popup.closed.connect(func(): _on_node_completed(data["id"]))

func _open_shop(data: Dictionary) -> void:
	# 關閉同層級的其他選單
	EventPopup.close_if_open()
	if ShopPopup.is_open():
		return
	var popup := ShopPopup.open_singleton(self, ShopPopupRes, data.get("title", ""))
	# 確認離開後標記此節點為通關
	popup.closed.connect(func(): _on_node_completed(data["id"]))

func _on_node_completed(node_id: String) -> void:
	StoryManager.complete_chapter(node_id)
	_build_map()
	info_panel.visible = false
	_refresh_status()

## ===== 頂部狀態列 =====

func _refresh_status() -> void:
	var done := StoryManager.completed_chapters.size()
	var total := _nodes.size()
	status_label.text = "進度：%d/%d   路線：%s (%+d)" % [done, total, StoryManager.get_route_name(), StoryManager.alignment]
	gold_label.text = "金幣：%d" % Inventory.get_gold()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
