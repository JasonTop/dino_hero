class_name DamageCalculator
extends RefCounted

## 戰鬥傷害計算（含屬性相剋、被動、裝備加成）

var battle_map: BattleMap

func _init(map: BattleMap) -> void:
	battle_map = map

## 屬性相剋倍率
static func class_advantage(attacker_class: String, defender_class: String) -> float:
	var chart := {
		"striker": ["ranged", "support"],
		"ranged": ["heavy"],
		"heavy": ["tank"],
		"tank": ["striker"],
		"flyer": ["striker", "tank", "heavy"],
	}
	if chart.has(attacker_class):
		var strong_vs: Array = chart[attacker_class]
		if defender_class in strong_vs:
			if attacker_class == "flyer":
				return 1.2
			return 1.3
	return 1.0

func calculate_damage(attacker: Unit, defender: Unit) -> Dictionary:
	return _calculate(attacker, defender, 1.0, false)

func calculate_skill_damage(attacker: Unit, defender: Unit, skill: Skill) -> Dictionary:
	var is_magical := skill.skill_type == Skill.SkillType.MAGICAL
	return _calculate(attacker, defender, skill.damage_multiplier, is_magical)

func _calculate(attacker: Unit, defender: Unit, multiplier: float, is_magical: bool) -> Dictionary:
	var atk_base: int = attacker.stats.get_effective_magic_attack() if is_magical else attacker.stats.get_effective_attack()
	var def_base: int = defender.stats.get_effective_magic_defense() if is_magical else defender.stats.get_effective_defense()
	var def_factor := 0.4 if is_magical else 0.5

	# 狀態異常對攻防的影響
	var atk_stat_name := "matk" if is_magical else "atk"
	var def_stat_name := "mdef" if is_magical else "def"
	var atk := float(atk_base) * attacker.get_stat_multiplier(atk_stat_name)
	var def := float(def_base) * defender.get_stat_multiplier(def_stat_name)

	var base_damage: float = atk * multiplier - def * def_factor

	# 地形防禦
	var terrain_info := battle_map.get_terrain_info(defender.cell)
	var terrain_def_bonus: float = terrain_info["def"]
	base_damage *= (1.0 - terrain_def_bonus)

	# 屬性相剋
	var advantage := class_advantage(attacker.stats.class_type, defender.stats.class_type)
	base_damage *= advantage

	# 被動技能
	base_damage = _apply_passive_bonus(attacker, defender, base_damage)

	# 隨機浮動
	base_damage *= randf_range(0.9, 1.1)
	var final_damage := maxi(roundi(base_damage), 1)

	# 命中/暴擊
	var hit_rate := _calculate_hit_rate(attacker, defender)
	var is_hit := (randf() * 100.0) <= hit_rate
	var crit_rate := _calculate_crit_rate(attacker, defender)
	var is_crit := is_hit and (randf() * 100.0) <= crit_rate

	if is_crit:
		final_damage = roundi(final_damage * 1.5)
	if not is_hit:
		final_damage = 0

	return {
		"damage": final_damage,
		"is_hit": is_hit,
		"is_crit": is_crit,
		"hit_rate": hit_rate,
		"crit_rate": crit_rate,
		"advantage": advantage,
	}

func _apply_passive_bonus(attacker: Unit, defender: Unit, damage: float) -> float:
	for skill_id in attacker.stats.passive_skill_ids:
		var skill := SkillDatabase.get_skill(skill_id)
		if skill == null or skill.passive_data.is_empty():
			continue
		var kind: String = skill.passive_data.get("kind", "")
		match kind:
			"predator":
				var threshold: float = skill.passive_data.get("threshold", 0.4)
				var bonus_pct: float = skill.passive_data.get("bonus", 30)
				var hp_ratio := float(defender.stats.hp) / float(defender.stats.hp_max)
				if hp_ratio <= threshold:
					damage *= (1.0 + bonus_pct / 100.0)
	return damage

func _calculate_hit_rate(attacker: Unit, defender: Unit) -> float:
	var base_hit := 90.0
	var attacker_spd := float(attacker.stats.get_effective_speed()) * attacker.get_stat_multiplier("spd")
	var defender_spd := float(defender.stats.get_effective_speed()) * defender.get_stat_multiplier("spd")
	var spd_diff: float = attacker_spd - defender_spd * 0.5
	var terrain_info := battle_map.get_terrain_info(defender.cell)
	var evasion_bonus: float = terrain_info["eva"] * 100.0
	var pack_bonus := _pack_hunt_bonus(attacker, "hit")
	# 攻擊方的 accuracy_mod 加在命中；防禦方的 accuracy_mod 減少命中（例如被盲目）
	var acc_mod := attacker.get_accuracy_mod()
	return clampf(base_hit + spd_diff - evasion_bonus + pack_bonus + acc_mod, 10.0, 100.0)

func _calculate_crit_rate(attacker: Unit, defender: Unit) -> float:
	var base_crit := 5.0
	var spd_diff: float = (float(attacker.stats.get_effective_speed()) - float(defender.stats.get_effective_speed())) * 0.5
	var pack_bonus := _pack_hunt_bonus(attacker, "crit")
	return clampf(base_crit + spd_diff + pack_bonus, 0.0, 50.0)

func _pack_hunt_bonus(attacker: Unit, stat: String) -> float:
	for skill_id in attacker.stats.passive_skill_ids:
		var skill := SkillDatabase.get_skill(skill_id)
		if skill == null or skill.passive_data.is_empty():
			continue
		if skill.passive_data.get("kind", "") != "pack_hunt":
			continue
		var ally_count := 0
		for neighbor in battle_map.get_neighbors(attacker.cell):
			var other = battle_map.get_unit_at(neighbor)
			if other and other != attacker and other.team == attacker.team and other.is_alive():
				ally_count += 1
		var per_ally: float = skill.passive_data.get(stat + "_per_ally", 0)
		return ally_count * per_ally
	return 0.0

func preview_damage(attacker: Unit, defender: Unit) -> Dictionary:
	var atk := attacker.stats.get_effective_attack()
	var def := defender.stats.get_effective_defense()
	var base_damage: float = atk - def * 0.5
	var terrain_info := battle_map.get_terrain_info(defender.cell)
	base_damage *= (1.0 - terrain_info["def"])
	base_damage *= class_advantage(attacker.stats.class_type, defender.stats.class_type)
	var estimated_damage := maxi(roundi(base_damage), 1)
	return {
		"estimated_damage": estimated_damage,
		"hit_rate": _calculate_hit_rate(attacker, defender),
		"crit_rate": _calculate_crit_rate(attacker, defender),
	}
