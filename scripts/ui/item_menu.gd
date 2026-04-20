class_name ItemMenu
extends PanelContainer

## 道具選擇選單

signal item_selected(item: Item)
signal cancelled()

@onready var list: VBoxContainer = $VBox/ItemList
@onready var title: Label = $VBox/Title

func _ready() -> void:
	visible = false

func show_menu() -> void:
	title.text = "使用道具"
	_refresh_list()
	visible = true
	if list.get_child_count() > 0:
		list.get_child(0).grab_focus()

func hide_menu() -> void:
	visible = false

func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()

	var consumables := Inventory.get_consumables()
	if consumables.is_empty():
		var empty := Label.new()
		empty.text = "（背包中沒有消耗品）"
		list.add_child(empty)
		return

	for entry in consumables:
		var item: Item = entry["item"]
		var count: int = entry["count"]
		var btn := Button.new()
		btn.text = "%s x%d — %s" % [item.display_name, count, item.description]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_item_picked.bind(item))
		list.add_child(btn)

func _on_item_picked(item: Item) -> void:
	hide_menu()
	item_selected.emit(item)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		hide_menu()
		cancelled.emit()
