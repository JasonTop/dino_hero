extends Node

## 全域背包系統（Autoload）— 儲存玩家持有的道具數量

signal inventory_changed(item_id: String, new_count: int)
signal gold_changed(new_amount: int)

var _items: Dictionary = {}  # item_id -> count
var gold: int = 100

func _ready() -> void:
	# 初始配給
	add_item("raw_meat", 3)
	add_item("fresh_fish", 1)
	add_item("ancient_nectar", 2)
	add_item("revive_herb", 1)

func add_item(item_id: String, count: int = 1) -> void:
	var current: int = _items.get(item_id, 0)
	_items[item_id] = current + count
	inventory_changed.emit(item_id, _items[item_id])

func remove_item(item_id: String, count: int = 1) -> bool:
	var current: int = _items.get(item_id, 0)
	if current < count:
		return false
	_items[item_id] = current - count
	if _items[item_id] <= 0:
		_items.erase(item_id)
	inventory_changed.emit(item_id, _items.get(item_id, 0))
	return true

func get_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func has_item(item_id: String) -> bool:
	return get_count(item_id) > 0

## 取得所有消耗品（用於道具選單）
func get_consumables() -> Array:
	var result: Array = []
	for id in _items:
		var item := ItemDatabase.get_item(id)
		if item and item.item_type == Item.ItemType.CONSUMABLE:
			result.append({"id": id, "item": item, "count": _items[id]})
	return result

func clear_all() -> void:
	_items.clear()

## ===== 金幣 =====
func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func get_gold() -> int:
	return gold
