class_name UnitData
extends RefCounted

## 恐龍基礎數值表 + 成長曲線 + 預設技能

enum DinoType {
	# 突擊型
	VELOCIRAPTOR,
	DEINONYCHUS,
	UTAHRAPTOR,
	# 坦克型
	TRICERATOPS,
	ANKYLOSAURUS,
	STEGOSAURUS,
	# 重砲型
	TREX,
	SPINOSAURUS,
	# 遠程型
	DILOPHOSAURUS,
	PARASAUROLOPHUS,
	# 飛行型
	PTERANODON,
	# 支援型
	MAIASAURA,
}

## 取得物種對應的 species ID
static func species_id(t: DinoType) -> String:
	match t:
		DinoType.VELOCIRAPTOR: return "velociraptor"
		DinoType.DEINONYCHUS: return "deinonychus"
		DinoType.UTAHRAPTOR: return "utahraptor"
		DinoType.TRICERATOPS: return "triceratops"
		DinoType.ANKYLOSAURUS: return "ankylosaurus"
		DinoType.STEGOSAURUS: return "stegosaurus"
		DinoType.TREX: return "trex"
		DinoType.SPINOSAURUS: return "spinosaurus"
		DinoType.DILOPHOSAURUS: return "dilophosaurus"
		DinoType.PARASAUROLOPHUS: return "parasaurolophus"
		DinoType.PTERANODON: return "pteranodon"
		DinoType.MAIASAURA: return "maiasaura"
	return ""

static func create_stats(dino_type: DinoType, dino_name: String = "", lv: int = 1) -> UnitStats:
	var stats := UnitStats.new()
	stats.level = 1
	stats.species = species_id(dino_type)

	match dino_type:
		# ===== 突擊型 =====
		DinoType.VELOCIRAPTOR:
			_set_base(stats, dino_name, "迅猛龍", "striker",
				45, 15, 14, 6, 8, 7, 15, 6, 1, 1)
			_set_growth(stats, Vector2i(3, 5), Vector2i(2, 3), Vector2i(1, 2),
				Vector2i(1, 2), Vector2i(1, 2), Vector2i(2, 3))
			stats.active_skill_ids = ["quick_strike"] as Array[String]
			stats.passive_skill_ids = ["pack_hunt"] as Array[String]

		DinoType.DEINONYCHUS:
			_set_base(stats, dino_name, "恐爪龍", "striker",
				40, 14, 16, 5, 6, 6, 16, 7, 1, 1)
			_set_growth(stats, Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 2),
				Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 3))
			stats.active_skill_ids = ["claw_combo", "quick_strike"] as Array[String]
			stats.passive_skill_ids = ["pack_hunt"] as Array[String]

		DinoType.UTAHRAPTOR:
			_set_base(stats, dino_name, "猶他盜龍", "striker",
				55, 16, 13, 8, 7, 7, 13, 5, 1, 1)
			_set_growth(stats, Vector2i(4, 5), Vector2i(2, 3), Vector2i(2, 3),
				Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2))
			stats.active_skill_ids = ["claw_combo"] as Array[String]
			stats.passive_skill_ids = ["pack_hunt"] as Array[String]

		# ===== 坦克型 =====
		DinoType.TRICERATOPS:
			_set_base(stats, dino_name, "三角龍", "tank",
				80, 12, 11, 16, 4, 10, 7, 4, 1, 1)
			_set_growth(stats, Vector2i(5, 7), Vector2i(1, 2), Vector2i(2, 3),
				Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 1))
			stats.active_skill_ids = ["iron_wall", "horn_charge"] as Array[String]
			stats.passive_skill_ids = ["counter_stance"] as Array[String]

		DinoType.ANKYLOSAURUS:
			_set_base(stats, dino_name, "甲龍", "tank",
				90, 10, 9, 18, 3, 12, 5, 3, 1, 1)
			_set_growth(stats, Vector2i(6, 8), Vector2i(1, 2), Vector2i(3, 4),
				Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 1))
			stats.active_skill_ids = ["iron_wall"] as Array[String]
			stats.passive_skill_ids = ["counter_stance"] as Array[String]

		DinoType.STEGOSAURUS:
			_set_base(stats, dino_name, "劍龍", "tank",
				70, 13, 12, 14, 5, 8, 6, 4, 1, 1)
			_set_growth(stats, Vector2i(4, 6), Vector2i(2, 3), Vector2i(2, 3),
				Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 1))
			stats.active_skill_ids = ["iron_wall"] as Array[String]
			stats.passive_skill_ids = ["counter_stance"] as Array[String]

		# ===== 重砲型 =====
		DinoType.TREX:
			_set_base(stats, dino_name, "暴龍", "heavy",
				100, 18, 20, 12, 6, 8, 6, 4, 1, 1)
			_set_growth(stats, Vector2i(6, 8), Vector2i(3, 4), Vector2i(2, 3),
				Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 1))
			stats.active_skill_ids = ["bite_crush", "intimidate"] as Array[String]
			stats.passive_skill_ids = ["predator_instinct"] as Array[String]

		DinoType.SPINOSAURUS:
			_set_base(stats, dino_name, "棘龍", "heavy",
				90, 16, 18, 10, 10, 9, 7, 4, 1, 1)
			_set_growth(stats, Vector2i(5, 7), Vector2i(2, 4), Vector2i(2, 3),
				Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 1))
			stats.active_skill_ids = ["bite_crush"] as Array[String]
			stats.passive_skill_ids = ["predator_instinct"] as Array[String]

		# ===== 遠程型 =====
		DinoType.DILOPHOSAURUS:
			_set_base(stats, dino_name, "雙冠龍", "ranged",
				35, 12, 7, 5, 15, 8, 12, 5, 1, 3)
			_set_growth(stats, Vector2i(2, 4), Vector2i(1, 2), Vector2i(1, 2),
				Vector2i(2, 3), Vector2i(1, 2), Vector2i(1, 2))
			stats.active_skill_ids = ["venom_spit"] as Array[String]

		DinoType.PARASAUROLOPHUS:
			_set_base(stats, dino_name, "副櫛龍", "ranged",
				40, 14, 6, 6, 13, 10, 10, 5, 1, 2)
			_set_growth(stats, Vector2i(3, 4), Vector2i(1, 2), Vector2i(1, 2),
				Vector2i(2, 3), Vector2i(2, 3), Vector2i(1, 2))
			stats.active_skill_ids = ["heal_lick", "sonic_blast"] as Array[String]

		# ===== 飛行型 =====
		DinoType.PTERANODON:
			_set_base(stats, dino_name, "翼龍", "flyer",
				30, 12, 8, 4, 10, 6, 14, 7, 1, 2)
			_set_growth(stats, Vector2i(2, 3), Vector2i(1, 2), Vector2i(0, 1),
				Vector2i(1, 2), Vector2i(1, 1), Vector2i(2, 3))

		# ===== 支援型 =====
		DinoType.MAIASAURA:
			_set_base(stats, dino_name, "慈母龍", "support",
				50, 16, 5, 8, 14, 12, 8, 5, 1, 2)
			_set_growth(stats, Vector2i(3, 5), Vector2i(1, 1), Vector2i(1, 2),
				Vector2i(2, 3), Vector2i(2, 3), Vector2i(1, 2))
			stats.active_skill_ids = ["heal_lick"] as Array[String]

	# 套用等級（從 Lv.1 升到 lv）
	if lv > 1:
		for i in range(1, lv):
			_apply_level_up_growth(stats)
		stats.level = lv

	stats.hp = stats.hp_max
	stats.mp = stats.mp_max
	return stats

static func _set_base(stats: UnitStats, custom_name: String, default_name: String,
		class_type: String,
		hp: int, mp: int, atk: int, def_v: int, matk: int, mdef: int,
		spd: int, mov: int, range_min: int, range_max: int) -> void:
	stats.display_name = custom_name if custom_name != "" else default_name
	stats.class_type = class_type
	stats.hp_max = hp
	stats.mp_max = mp
	stats.attack = atk
	stats.defense = def_v
	stats.magic_attack = matk
	stats.magic_defense = mdef
	stats.speed = spd
	stats.movement = mov
	stats.attack_range_min = range_min
	stats.attack_range_max = range_max

static func _set_growth(stats: UnitStats, hp: Vector2i, atk: Vector2i, def_v: Vector2i,
		matk: Vector2i, mdef: Vector2i, spd: Vector2i) -> void:
	stats.growth_hp = hp
	stats.growth_atk = atk
	stats.growth_def = def_v
	stats.growth_matk = matk
	stats.growth_mdef = mdef
	stats.growth_spd = spd

## 套用一次升級成長（內部用）
static func _apply_level_up_growth(stats: UnitStats) -> void:
	stats.hp_max += randi_range(stats.growth_hp.x, stats.growth_hp.y)
	stats.attack += randi_range(stats.growth_atk.x, stats.growth_atk.y)
	stats.defense += randi_range(stats.growth_def.x, stats.growth_def.y)
	stats.magic_attack += randi_range(stats.growth_matk.x, stats.growth_matk.y)
	stats.magic_defense += randi_range(stats.growth_mdef.x, stats.growth_mdef.y)
	stats.speed += randi_range(stats.growth_spd.x, stats.growth_spd.y)
	stats.mp_max += 1

## 公開的升級函式（給 LevelUpSystem 用），回傳各屬性增加值
static func apply_level_up(stats: UnitStats) -> Dictionary:
	var before := {
		"hp": stats.hp_max, "atk": stats.attack, "def": stats.defense,
		"matk": stats.magic_attack, "mdef": stats.magic_defense,
		"spd": stats.speed, "mp": stats.mp_max,
	}
	_apply_level_up_growth(stats)
	stats.level += 1
	stats.hp = stats.hp_max  # 升級回滿 HP/MP
	stats.mp = stats.mp_max
	return {
		"hp": stats.hp_max - before["hp"],
		"atk": stats.attack - before["atk"],
		"def": stats.defense - before["def"],
		"matk": stats.magic_attack - before["matk"],
		"mdef": stats.magic_defense - before["mdef"],
		"spd": stats.speed - before["spd"],
		"mp": stats.mp_max - before["mp"],
	}
