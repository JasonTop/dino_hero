extends Node

## 道具資料庫（Autoload）

var _items: Dictionary = {}  # item_id -> Item

func _ready() -> void:
	_register_all_items()

func _register_all_items() -> void:
	# ===== 消耗品 =====
	_register_consumable("raw_meat", "生肉", "回復 30% 最大 HP",
		Item.ConsumableEffect.HEAL_HP_PERCENT, 0.3)
	_register_consumable("fresh_fish", "鮮魚", "回復 50% 最大 HP",
		Item.ConsumableEffect.HEAL_HP_PERCENT, 0.5)
	_register_consumable("ancient_nectar", "遠古花蜜", "完全回復 MP",
		Item.ConsumableEffect.HEAL_MP_PERCENT, 1.0)
	_register_consumable("revive_herb", "復活草", "復活倒下的恐龍（30% HP）",
		Item.ConsumableEffect.REVIVE, 0.3)

	# ===== 裝備 =====
	_register_equipment("sharp_claw_ring", "利齒項圈", "ATK +3", {"attack": 3})
	_register_equipment("hard_scale_armor", "堅鱗護甲", "DEF +5", {"defense": 5})
	_register_equipment("swift_foot_band", "迅足腕環", "SPD +4, MOV +1",
		{"speed": 4, "movement": 1})
	_register_equipment("ancient_amber", "遠古琥珀", "全屬性 +2",
		{"attack": 2, "defense": 2, "magic_attack": 2, "magic_defense": 2, "speed": 2})

	# ===== 進化化石 =====
	_register_evolution_stone("evolution_stone_s", "進化化石（小）", "Lv.15 進化所需", 1)
	_register_evolution_stone("evolution_stone_l", "進化化石（大）", "Lv.30 進化所需", 2)
	_register_evolution_stone("ancestor_fossil", "始祖化石", "傳說進化所需", 3)

func _register_consumable(id: String, name: String, desc: String,
		effect: Item.ConsumableEffect, value: float) -> void:
	var item := Item.new()
	item.item_id = id
	item.display_name = name
	item.description = desc
	item.item_type = Item.ItemType.CONSUMABLE
	item.consumable_effect = effect
	item.effect_value = value
	_items[id] = item

func _register_equipment(id: String, name: String, desc: String, bonuses: Dictionary) -> void:
	var item := Item.new()
	item.item_id = id
	item.display_name = name
	item.description = desc
	item.item_type = Item.ItemType.EQUIPMENT
	item.stat_bonuses = bonuses
	_items[id] = item

func _register_evolution_stone(id: String, name: String, desc: String, stage: int) -> void:
	var item := Item.new()
	item.item_id = id
	item.display_name = name
	item.description = desc
	item.item_type = Item.ItemType.EVOLUTION_STONE
	item.evolution_stage = stage
	_items[id] = item

func get_item(item_id: String) -> Item:
	return _items.get(item_id, null)

func get_all_items() -> Array:
	return _items.values()
