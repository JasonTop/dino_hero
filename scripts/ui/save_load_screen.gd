class_name SaveLoadScreen
extends CanvasLayer

## 存檔/讀檔選單 — 6 個手動欄位 + 1 個自動存檔欄位
## 同時僅允許一個實例存在（靜態 _active 追蹤）

signal slot_selected(slot: int)
signal closed()

enum Mode { LOAD, SAVE }

static var _active: SaveLoadScreen = null

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var slot_list: VBoxContainer = $Root/Panel/VBox/Scroll/SlotList
@onready var close_button: Button = $Root/Panel/VBox/CloseButton

var mode: int = Mode.LOAD
var battle_snapshot: Dictionary = {}

## 靜態入口：同時只能有一個存檔選單。已存在則直接回傳現有實例（不重複開啟）。
static func open_singleton(parent: Node, scene: PackedScene, mode_: int, snapshot: Dictionary = {}) -> SaveLoadScreen:
	if _active != null and is_instance_valid(_active):
		return _active
	var inst: SaveLoadScreen = scene.instantiate()
	parent.add_child(inst)
	inst.open(mode_, snapshot)
	return inst

static func is_open() -> bool:
	return _active != null and is_instance_valid(_active)

func _ready() -> void:
	_active = self
	close_button.pressed.connect(_on_close)

func _exit_tree() -> void:
	if _active == self:
		_active = null

func open(mode_: int, snapshot: Dictionary = {}) -> void:
	mode = mode_
	battle_snapshot = snapshot
	title_label.text = "讀取存檔" if mode == Mode.LOAD else "存檔"
	_build_list()

func _build_list() -> void:
	for c in slot_list.get_children():
		c.queue_free()

	var auto_row := _make_slot_row(SaveManager.AUTO_SLOT, true)
	slot_list.add_child(auto_row)

	for i in range(1, SaveManager.MANUAL_SLOTS + 1):
		var row := _make_slot_row(i, false)
		slot_list.add_child(row)

func _make_slot_row(slot: int, is_auto: bool) -> Control:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.22)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var slot_label := Label.new()
	slot_label.add_theme_font_size_override("font_size", 16)
	if is_auto:
		slot_label.text = "【自動存檔】"
		slot_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	else:
		slot_label.text = "欄位 %d" % slot
	info.add_child(slot_label)

	var detail := Label.new()
	detail.add_theme_font_size_override("font_size", 13)
	detail.modulate = Color(0.85, 0.85, 0.85)

	if SaveManager.has_save(slot):
		var s := SaveManager.get_save_info(slot)
		var loc_text: String = "戰鬥中" if s.get("location", "") == "battle" else "世界地圖"
		var diff_name: String = GameManager.DIFFICULTY_TABLE[int(s.get("difficulty", 1))]["name"]
		detail.text = "%s · %s · 進度 %d · Lv.%d %s · %+d · %d G · %s" % [
			s.get("save_date", "—"),
			loc_text,
			int(s.get("completed_count", 0)),
			int(s.get("max_level", 1)),
			str(s.get("leader_name", "—")),
			int(s.get("alignment", 0)),
			int(s.get("gold", 0)),
			diff_name,
		]
	else:
		detail.text = "— 空白 —"
	info.add_child(detail)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(100, 40)
	if mode == Mode.LOAD:
		btn.text = "載入"
		btn.disabled = not SaveManager.has_save(slot)
	else:
		btn.text = "覆蓋" if SaveManager.has_save(slot) else "存檔"
		btn.disabled = is_auto
	btn.pressed.connect(func(): _on_slot_button(slot))
	hbox.add_child(btn)

	var del := Button.new()
	del.text = "刪除"
	del.custom_minimum_size = Vector2(80, 40)
	del.disabled = not SaveManager.has_save(slot)
	del.pressed.connect(func(): _on_delete(slot))
	hbox.add_child(del)

	return row

func _on_slot_button(slot: int) -> void:
	if mode == Mode.LOAD:
		slot_selected.emit(slot)
	else:
		SaveManager.save_to_slot(slot, battle_snapshot)
		_build_list()

func _on_delete(slot: int) -> void:
	SaveManager.delete_slot(slot)
	_build_list()

func _on_close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_on_close()
