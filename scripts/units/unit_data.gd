class_name UnitData
extends RefCounted

## 恐龍基礎數值表 — Phase 1 先定義 3 種

enum DinoType {
	VELOCIRAPTOR,  # 迅猛龍（突擊型）
	TRICERATOPS,   # 三角龍（坦克型）
	TREX,          # 暴龍（重砲型）
}

static func create_stats(dino_type: DinoType, dino_name: String = "", lv: int = 1) -> UnitStats:
	var stats := UnitStats.new()
	stats.level = lv

	match dino_type:
		DinoType.VELOCIRAPTOR:
			stats.species = "velociraptor"
			stats.display_name = dino_name if dino_name != "" else "迅猛龍"
			stats.hp_max = 45
			stats.attack = 14
			stats.defense = 6
			stats.magic_attack = 8
			stats.magic_defense = 7
			stats.speed = 15
			stats.movement = 6
			stats.attack_range_min = 1
			stats.attack_range_max = 1

		DinoType.TRICERATOPS:
			stats.species = "triceratops"
			stats.display_name = dino_name if dino_name != "" else "三角龍"
			stats.hp_max = 80
			stats.attack = 11
			stats.defense = 16
			stats.magic_attack = 4
			stats.magic_defense = 10
			stats.speed = 7
			stats.movement = 4
			stats.attack_range_min = 1
			stats.attack_range_max = 1

		DinoType.TREX:
			stats.species = "trex"
			stats.display_name = dino_name if dino_name != "" else "暴龍"
			stats.hp_max = 100
			stats.attack = 20
			stats.defense = 12
			stats.magic_attack = 6
			stats.magic_defense = 8
			stats.speed = 6
			stats.movement = 4
			stats.attack_range_min = 1
			stats.attack_range_max = 1

	# 等級加成（每級 +簡易成長）
	for i in range(1, lv):
		stats.hp_max += randi_range(2, 4)
		stats.attack += randi_range(1, 2)
		stats.defense += randi_range(1, 2)
		stats.speed += randi_range(0, 1)

	stats.hp = stats.hp_max
	return stats
