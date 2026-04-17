class_name Item
extends Resource

## 道具/裝備定義

enum ItemType {
	CONSUMABLE,     # 消耗品（生肉、花蜜等）
	EQUIPMENT,      # 裝備（永久加成）
	EVOLUTION_STONE, # 進化化石
	KEY_ITEM,       # 劇情道具
}

enum ConsumableEffect {
	NONE,
	HEAL_HP_FLAT,       # 固定 HP 量
	HEAL_HP_PERCENT,    # HP 百分比
	HEAL_MP_FLAT,
	HEAL_MP_PERCENT,
	REVIVE,             # 復活
	CURE_STATUS,        # 解除異常
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE

# 消耗品效果
@export var consumable_effect: ConsumableEffect = ConsumableEffect.NONE
@export var effect_value: float = 0.0

# 裝備屬性加成 { "attack": 3, "defense": 5, ... }
@export var stat_bonuses: Dictionary = {}

# 進化用
@export var evolution_stage: int = 0   # 1=小化石 2=大化石 3=始祖化石
