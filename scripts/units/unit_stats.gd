class_name UnitStats
extends Resource

## 恐龍單位屬性資源

@export var display_name: String = ""
@export var species: String = ""          # 物種 ID

# 基礎屬性
@export var hp_max: int = 50
@export var hp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var magic_attack: int = 5
@export var magic_defense: int = 5
@export var speed: int = 10
@export var movement: int = 4             # 移動力（格數）
@export var attack_range_min: int = 1     # 最小攻擊距離
@export var attack_range_max: int = 1     # 最大攻擊距離

# 等級
@export var level: int = 1
@export var exp: int = 0

func duplicate_stats() -> UnitStats:
	var s := UnitStats.new()
	s.display_name = display_name
	s.species = species
	s.hp_max = hp_max
	s.hp = hp
	s.attack = attack
	s.defense = defense
	s.magic_attack = magic_attack
	s.magic_defense = magic_defense
	s.speed = speed
	s.movement = movement
	s.attack_range_min = attack_range_min
	s.attack_range_max = attack_range_max
	s.level = level
	s.exp = exp
	return s
