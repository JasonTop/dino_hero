class_name EquipSelectPopup
extends CanvasLayer

## 裝備選擇子選單 — 列出背包中的裝備，讓玩家挑選

signal equip_selected(item_id: String)

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var list: VBoxContainer = $Root/Panel/VBox/Scroll/List
@onready var close_btn: Button = $Root/Panel/VBox/CloseButton

var _current_stats: UnitStats

func _ready() -> void:
	close_btn.pressed.connect(queue_free)

func open(stats: UnitStats) -> void:
	_current_stats = stats
	title_label.text = stats.display_name + "  選擇裝備"
	_build_list()

func _build_list() -> void:
	for c in list.get_children():
		c.queue_free()

	var any := false
	for key in Inventory._items.keys():
		var item_id: String = str(key)
		var item := ItemDatabase.get_item(item_id)
		if item == null or item.item_type != Item.ItemType.EQUIPMENT:
			continue
		any = true
		var count: int = Inventory.get_count(item_id)
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 15)
		btn.text = "%s x%d — %s" % [item.display_name, count, _bonuses_str(item.stat_bonuses)]
		var id: String = item_id
		btn.pressed.connect(func(): _on_pick(id))
		list.add_child(btn)

	if not any:
		var empty := Label.new()
		empty.text = "（背包中沒有可用裝備）"
		list.add_child(empty)

func _bonuses_str(bonuses: Dictionary) -> String:
	var parts: Array[String] = []
	for k in bonuses:
		parts.append("%s+%d" % [k.to_upper(), int(bonuses[k])])
	return " ".join(parts)

func _on_pick(item_id: String) -> void:
	equip_selected.emit(item_id)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		queue_free()
