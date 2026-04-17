class_name ExpSystem
extends RefCounted

## 經驗值計算與等級提升邏輯

## 計算擊殺獎勵經驗值
static func calc_exp_gained(attacker: Unit, defender: Unit, killed: bool) -> int:
	var base_exp := 10
	var level_diff := defender.stats.level - attacker.stats.level
	var level_bonus := clampi(level_diff * 5, -10, 30)
	var kill_bonus := 20 if killed else 0
	return maxi(base_exp + level_bonus + kill_bonus, 1)

## 給予經驗值並處理升級（回傳所有發生的升級資訊）
## 回傳：Array of Dictionaries: [{gains: {...}, new_level: int, learned_skills: [...]}, ...]
static func grant_exp(unit: Unit, amount: int) -> Array:
	var level_ups: Array = []
	unit.stats.exp += amount

	while unit.stats.exp >= UnitStats.exp_required_for_level(unit.stats.level):
		unit.stats.exp -= UnitStats.exp_required_for_level(unit.stats.level)
		var gains := UnitData.apply_level_up(unit.stats)
		var learned := _auto_learn_skills(unit.stats)
		level_ups.append({
			"new_level": unit.stats.level,
			"gains": gains,
			"learned_skills": learned,
		})
		unit.update_health_bar()

	return level_ups

## 升級時自動學習技能
## 根據物種和等級在特定等級時學習預設技能
static func _auto_learn_skills(stats: UnitStats) -> Array:
	var learn_table := _get_learn_table(stats.species)
	var newly_learned: Array = []
	for entry in learn_table:
		var lv: int = entry["level"]
		var skill_id: String = entry["skill"]
		if stats.level == lv and not stats.active_skill_ids.has(skill_id):
			if stats.active_skill_ids.size() < 4:
				stats.active_skill_ids.append(skill_id)
				newly_learned.append(skill_id)
	return newly_learned

## 各物種的技能學習表
static func _get_learn_table(species: String) -> Array:
	var tables := {
		"velociraptor": [
			{"level": 5, "skill": "claw_combo"},
			{"level": 10, "skill": "quick_strike"},
		],
		"deinonychus": [
			{"level": 5, "skill": "claw_combo"},
		],
		"triceratops": [
			{"level": 5, "skill": "iron_wall"},
			{"level": 10, "skill": "horn_charge"},
		],
		"ankylosaurus": [
			{"level": 5, "skill": "iron_wall"},
		],
		"trex": [
			{"level": 5, "skill": "intimidate"},
			{"level": 10, "skill": "bite_crush"},
		],
		"maiasaura": [
			{"level": 5, "skill": "heal_lick"},
		],
	}
	return tables.get(species, [])
