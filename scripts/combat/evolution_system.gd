class_name EvolutionSystem
extends RefCounted

## 進化系統 — 判定進化條件、執行進化

## 進化路線表
## species -> { min_level, required_stage, options: [ {target_species, name, bonuses} ] }
static func _evolution_routes() -> Dictionary:
	return {
		"velociraptor": {
			"min_level": 15,
			"required_stage": 0,
			"options": [
				{
					"target": "deinonychus",
					"name": "恐爪龍（純攻擊路線）",
					"stat_bonus": {"atk": 3, "spd": 2, "hp": 5},
					"skill_add": "claw_combo",
				},
				{
					"target": "utahraptor",
					"name": "猶他盜龍（群攻路線）",
					"stat_bonus": {"hp": 10, "def": 2, "atk": 2},
					"skill_add": "",
				},
			],
		},
		"triceratops": {
			"min_level": 15,
			"required_stage": 0,
			"options": [
				{
					"target": "ankylosaurus",
					"name": "甲龍（重裝坦克）",
					"stat_bonus": {"hp": 10, "def": 4},
					"skill_add": "",
				},
				{
					"target": "stegosaurus",
					"name": "劍龍（反擊特化）",
					"stat_bonus": {"atk": 2, "def": 2},
					"skill_add": "",
				},
			],
		},
		"trex": {
			"min_level": 20,
			"required_stage": 0,
			"options": [
				{
					"target": "spinosaurus",
					"name": "棘龍（水陸雙棲）",
					"stat_bonus": {"hp": 5, "matk": 3, "spd": 1},
					"skill_add": "",
				},
			],
		},
	}

## 檢查單位是否可以進化
static func can_evolve(stats: UnitStats) -> bool:
	var routes := _evolution_routes()
	if not routes.has(stats.species):
		return false
	var info: Dictionary = routes[stats.species]
	if stats.level < info["min_level"]:
		return false
	if stats.evolution_stage < info["required_stage"]:
		return false
	# 需要進化化石
	var stone_id := _required_stone_for_stage(stats.evolution_stage)
	if stone_id != "" and Inventory.get_count(stone_id) <= 0:
		return false
	return true

## 缺什麼（給 UI 提示用）
static func get_evolution_info(stats: UnitStats) -> Dictionary:
	var routes := _evolution_routes()
	if not routes.has(stats.species):
		return {"available": false, "reason": "此物種無可用進化路線"}
	var info: Dictionary = routes[stats.species]
	if stats.level < info["min_level"]:
		return {"available": false, "reason": "需要 Lv." + str(info["min_level"])}
	var stone_id := _required_stone_for_stage(stats.evolution_stage)
	if stone_id != "" and Inventory.get_count(stone_id) <= 0:
		var stone := ItemDatabase.get_item(stone_id)
		return {"available": false, "reason": "需要「" + (stone.display_name if stone else stone_id) + "」"}
	return {"available": true, "options": info["options"]}

static func _required_stone_for_stage(current_stage: int) -> String:
	match current_stage:
		0: return "evolution_stone_s"
		1: return "evolution_stone_l"
		2: return "ancestor_fossil"
	return ""

## 執行進化
static func evolve(stats: UnitStats, option_index: int) -> bool:
	var routes := _evolution_routes()
	if not routes.has(stats.species):
		return false
	var info: Dictionary = routes[stats.species]
	var options: Array = info["options"]
	if option_index < 0 or option_index >= options.size():
		return false

	# 消耗進化化石
	var stone_id := _required_stone_for_stage(stats.evolution_stage)
	if stone_id != "":
		if not Inventory.remove_item(stone_id, 1):
			return false

	var choice: Dictionary = options[option_index]
	var target_species: String = choice["target"]
	var bonus: Dictionary = choice["stat_bonus"]

	# 套用屬性加成
	stats.hp_max += int(bonus.get("hp", 0))
	stats.attack += int(bonus.get("atk", 0))
	stats.defense += int(bonus.get("def", 0))
	stats.magic_attack += int(bonus.get("matk", 0))
	stats.magic_defense += int(bonus.get("mdef", 0))
	stats.speed += int(bonus.get("spd", 0))
	stats.hp = stats.hp_max

	# 更新物種
	stats.species = target_species
	stats.evolution_stage += 1
	stats.display_name = choice.get("name", stats.display_name).split("（")[0]

	# 新增技能
	var skill_add: String = choice.get("skill_add", "")
	if skill_add != "" and not stats.active_skill_ids.has(skill_add):
		if stats.active_skill_ids.size() < 4:
			stats.active_skill_ids.append(skill_add)

	return true
