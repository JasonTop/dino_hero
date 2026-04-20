class_name ShopPopup
extends CanvasLayer

## 商店 — 購買道具與裝備
## 同時只有一個實例；離開時需確認，確認後視為通關此節點

signal closed()

static var _active: ShopPopup = null

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var gold_label: Label = $Root/Panel/VBox/GoldLabel
@onready var list_container: VBoxContainer = $Root/Panel/VBox/Scroll/ListContainer
@onready var result_label: Label = $Root/Panel/VBox/ResultLabel
@onready var leave_button: Button = $Root/Panel/VBox/LeaveButton
@onready var confirm_panel: PanelContainer = $Root/ConfirmPanel
@onready var confirm_yes: Button = $Root/ConfirmPanel/VBox/HBox/YesButton
@onready var confirm_no: Button = $Root/ConfirmPanel/VBox/HBox/NoButton

# 商店商品（item_id -> 價格）
const STOCK := {
	"raw_meat": 30,
	"fresh_fish": 60,
	"ancient_nectar": 80,
	"revive_herb": 150,
	"evolution_stone_s": 500,
	"sharp_claw_ring": 200,
	"hard_scale_armor": 250,
	"swift_foot_band": 220,
	"ancient_amber": 400,
}

static func open_singleton(parent: Node, scene: PackedScene, shop_title: String) -> ShopPopup:
	if _active != null and is_instance_valid(_active):
		return _active
	var inst: ShopPopup = scene.instantiate()
	parent.add_child(inst)
	inst.show_shop(shop_title)
	return inst

static func is_open() -> bool:
	return _active != null and is_instance_valid(_active)

static func close_if_open() -> void:
	if _active != null and is_instance_valid(_active):
		_active.queue_free()
		_active = null

func _ready() -> void:
	_active = self
	leave_button.pressed.connect(_on_leave_pressed)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)
	Inventory.gold_changed.connect(_refresh_gold)
	result_label.text = ""
	confirm_panel.visible = false

func _exit_tree() -> void:
	if _active == self:
		_active = null

func show_shop(shop_title: String) -> void:
	title_label.text = shop_title
	_refresh_gold(Inventory.get_gold())
	_build_list()

func _refresh_gold(amount: int) -> void:
	gold_label.text = "擁有金幣：%d" % amount

func _build_list() -> void:
	for c in list_container.get_children():
		c.queue_free()

	for item_id in STOCK.keys():
		var item := ItemDatabase.get_item(item_id)
		if item == null:
			continue
		var price: int = STOCK[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 16)

		var desc_label := Label.new()
		desc_label.text = item.description
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		desc_label.add_theme_font_size_override("font_size", 13)

		var price_label := Label.new()
		price_label.text = "%d G" % price
		price_label.custom_minimum_size = Vector2(80, 0)
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))

		var buy_btn := Button.new()
		buy_btn.text = "購買"
		buy_btn.custom_minimum_size = Vector2(80, 0)
		buy_btn.pressed.connect(_on_buy.bind(item_id, price))

		row.add_child(name_label)
		row.add_child(desc_label)
		row.add_child(price_label)
		row.add_child(buy_btn)
		list_container.add_child(row)

func _on_buy(item_id: String, price: int) -> void:
	if Inventory.spend_gold(price):
		Inventory.add_item(item_id, 1)
		var item := ItemDatabase.get_item(item_id)
		result_label.text = "購買成功：" + (item.display_name if item else item_id)
		result_label.modulate = Color(0.6, 1, 0.6)
	else:
		result_label.text = "金幣不足！"
		result_label.modulate = Color(1, 0.4, 0.4)

func _on_leave_pressed() -> void:
	confirm_panel.visible = true
	confirm_no.grab_focus()

func _on_confirm_no() -> void:
	confirm_panel.visible = false
	leave_button.grab_focus()

func _on_confirm_yes() -> void:
	closed.emit()
	queue_free()
