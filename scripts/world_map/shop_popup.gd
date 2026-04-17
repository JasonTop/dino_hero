class_name ShopPopup
extends Control

## 商店 — 購買道具與裝備

signal closed()

@onready var title_label: Label = $Panel/VBox/Title
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var list_container: VBoxContainer = $Panel/VBox/Scroll/ListContainer
@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var close_button: Button = $Panel/VBox/CloseButton

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

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	Inventory.gold_changed.connect(_refresh_gold)
	result_label.text = ""

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

func _on_close() -> void:
	closed.emit()
	queue_free()
