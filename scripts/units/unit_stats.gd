class_name UnitStats
extends Resource

## 恐龍單位屬性資源

@export var display_name: String = ""
@export var species: String = ""          # 物種 ID（對應 UnitData.DinoType 名稱）
@export var class_type: String = "striker" # 職業分類：striker/tank/ranged/heavy/flyer/support/aquatic

# ===== 基礎屬性 =====
@export var hp_max: int = 50
@export var hp: int = 50
@export var mp_max: int = 10
@export var mp: int = 10
@export var attack: int = 10
@export var defense: int = 5
@export var magic_attack: int = 5
@export var magic_defense: int = 5
@export var speed: int = 10
@export var movement: int = 4             # 移動力（格數）
@export var attack_range_min: int = 1     # 最小攻擊距離
@export var attack_range_max: int = 1     # 最大攻擊距離

# ===== 等級與經驗 =====
@export var level: int = 1
@export var exp: int = 0
@export var evolution_stage: int = 0      # 進化階段：0=初始, 1=進化一次, 2=最終形態

# ===== 技能 =====
@export var active_skill_ids: Array[String] = []   # 主動技能 ID 列表（最多 4 個）
@export var passive_skill_ids: Array[String] = []  # 被動技能 ID 列表（最多 2 個）

# ===== 裝備 =====
@export var equipped_item_id: String = ""  # 裝備的道具 ID

# ===== 成長率（升級時每級增加的範圍）=====
@export var growth_hp: Vector2i = Vector2i(3, 5)
@export var growth_atk: Vector2i = Vector2i(2, 3)
@export var growth_def: Vector2i = Vector2i(1, 2)
@export var growth_matk: Vector2i = Vector2i(1, 2)
@export var growth_mdef: Vector2i = Vector2i(1, 2)
@export var growth_spd: Vector2i = Vector2i(1, 2)

func duplicate_stats() -> UnitStats:
	var s := UnitStats.new()
	s.display_name = display_name
	s.species = species
	s.class_type = class_type
	s.hp_max = hp_max
	s.hp = hp
	s.mp_max = mp_max
	s.mp = mp
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
	s.evolution_stage = evolution_stage
	s.active_skill_ids = active_skill_ids.duplicate()
	s.passive_skill_ids = passive_skill_ids.duplicate()
	s.equipped_item_id = equipped_item_id
	s.growth_hp = growth_hp
	s.growth_atk = growth_atk
	s.growth_def = growth_def
	s.growth_matk = growth_matk
	s.growth_mdef = growth_mdef
	s.growth_spd = growth_spd
	return s

## 升級所需經驗值
static func exp_required_for_level(lv: int) -> int:
	return lv * 10 + int(pow(lv, 1.5) * 5)

## 取得有效屬性（含裝備加成）
func get_effective_attack() -> int:
	return attack + _equipment_bonus("attack")

func get_effective_defense() -> int:
	return defense + _equipment_bonus("defense")

func get_effective_magic_attack() -> int:
	return magic_attack + _equipment_bonus("magic_attack")

func get_effective_magic_defense() -> int:
	return magic_defense + _equipment_bonus("magic_defense")

func get_effective_speed() -> int:
	return speed + _equipment_bonus("speed")

func get_effective_movement() -> int:
	return movement + _equipment_bonus("movement")

func _equipment_bonus(stat: String) -> int:
	if equipped_item_id == "":
		return 0
	var item := ItemDatabase.get_item(equipped_item_id)
	if item == null:
		return 0
	return item.stat_bonuses.get(stat, 0)

## ===== 序列化 =====
func to_dict() -> Dictionary:
	return {
		"display_name": display_name,
		"species": species,
		"class_type": class_type,
		"hp_max": hp_max, "hp": hp,
		"mp_max": mp_max, "mp": mp,
		"attack": attack, "defense": defense,
		"magic_attack": magic_attack, "magic_defense": magic_defense,
		"speed": speed, "movement": movement,
		"attack_range_min": attack_range_min,
		"attack_range_max": attack_range_max,
		"level": level, "exp": exp,
		"evolution_stage": evolution_stage,
		"active_skill_ids": active_skill_ids,
		"passive_skill_ids": passive_skill_ids,
		"equipped_item_id": equipped_item_id,
		"growth_hp": [growth_hp.x, growth_hp.y],
		"growth_atk": [growth_atk.x, growth_atk.y],
		"growth_def": [growth_def.x, growth_def.y],
		"growth_matk": [growth_matk.x, growth_matk.y],
		"growth_mdef": [growth_mdef.x, growth_mdef.y],
		"growth_spd": [growth_spd.x, growth_spd.y],
	}

static func from_dict(d: Dictionary) -> UnitStats:
	var s := UnitStats.new()
	s.display_name = d.get("display_name", "")
	s.species = d.get("species", "")
	s.class_type = d.get("class_type", "striker")
	s.hp_max = int(d.get("hp_max", 50))
	s.hp = int(d.get("hp", s.hp_max))
	s.mp_max = int(d.get("mp_max", 10))
	s.mp = int(d.get("mp", s.mp_max))
	s.attack = int(d.get("attack", 10))
	s.defense = int(d.get("defense", 5))
	s.magic_attack = int(d.get("magic_attack", 5))
	s.magic_defense = int(d.get("magic_defense", 5))
	s.speed = int(d.get("speed", 10))
	s.movement = int(d.get("movement", 4))
	s.attack_range_min = int(d.get("attack_range_min", 1))
	s.attack_range_max = int(d.get("attack_range_max", 1))
	s.level = int(d.get("level", 1))
	s.exp = int(d.get("exp", 0))
	s.evolution_stage = int(d.get("evolution_stage", 0))
	var active: Array = d.get("active_skill_ids", [])
	s.active_skill_ids = []
	for a in active:
		s.active_skill_ids.append(str(a))
	var passive: Array = d.get("passive_skill_ids", [])
	s.passive_skill_ids = []
	for p in passive:
		s.passive_skill_ids.append(str(p))
	s.equipped_item_id = str(d.get("equipped_item_id", ""))
	s.growth_hp = _v2i(d.get("growth_hp", [3, 5]))
	s.growth_atk = _v2i(d.get("growth_atk", [2, 3]))
	s.growth_def = _v2i(d.get("growth_def", [1, 2]))
	s.growth_matk = _v2i(d.get("growth_matk", [1, 2]))
	s.growth_mdef = _v2i(d.get("growth_mdef", [1, 2]))
	s.growth_spd = _v2i(d.get("growth_spd", [1, 2]))
	return s

static func _v2i(arr: Array) -> Vector2i:
	if arr.size() >= 2:
		return Vector2i(int(arr[0]), int(arr[1]))
	return Vector2i(1, 1)
