class_name DamageCalculator
extends RefCounted

## 戰鬥傷害計算

var battle_map: BattleMap

func _init(map: BattleMap) -> void:
	battle_map = map

## 計算物理傷害
func calculate_damage(attacker: Unit, defender: Unit) -> Dictionary:
	var atk := attacker.stats.attack
	var def := defender.stats.defense

	# 基礎傷害
	var base_damage := atk * 1.0 - def * 0.5

	# 地形防禦加成
	var terrain_info := battle_map.get_terrain_info(defender.cell)
	var terrain_def_bonus: float = terrain_info["def"]
	base_damage *= (1.0 - terrain_def_bonus)

	# 隨機浮動 (0.9 ~ 1.1)
	var random_factor := randf_range(0.9, 1.1)
	base_damage *= random_factor

	# 保底傷害
	var final_damage := maxi(roundi(base_damage), 1)

	# 命中判定
	var hit_rate := _calculate_hit_rate(attacker, defender)
	var hit_roll := randf() * 100.0
	var is_hit := hit_roll <= hit_rate

	# 暴擊判定
	var crit_rate := _calculate_crit_rate(attacker, defender)
	var crit_roll := randf() * 100.0
	var is_crit := is_hit and crit_roll <= crit_rate

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
	}

## 預覽傷害（不含隨機，供 UI 顯示）
func preview_damage(attacker: Unit, defender: Unit) -> Dictionary:
	var atk := attacker.stats.attack
	var def := defender.stats.defense
	var base_damage := atk * 1.0 - def * 0.5

	var terrain_info := battle_map.get_terrain_info(defender.cell)
	base_damage *= (1.0 - terrain_info["def"])

	var estimated_damage := maxi(roundi(base_damage), 1)
	var hit_rate := _calculate_hit_rate(attacker, defender)
	var crit_rate := _calculate_crit_rate(attacker, defender)

	return {
		"estimated_damage": estimated_damage,
		"hit_rate": hit_rate,
		"crit_rate": crit_rate,
	}

func _calculate_hit_rate(attacker: Unit, defender: Unit) -> float:
	var base_hit := 90.0
	var spd_diff := attacker.stats.speed - defender.stats.speed * 0.5

	var terrain_info := battle_map.get_terrain_info(defender.cell)
	var evasion_bonus: float = terrain_info["eva"] * 100.0

	var hit := base_hit + spd_diff - evasion_bonus
	return clampf(hit, 10.0, 100.0)

func _calculate_crit_rate(attacker: Unit, defender: Unit) -> float:
	var base_crit := 5.0
	var spd_diff := (attacker.stats.speed - defender.stats.speed) * 0.5
	return clampf(base_crit + spd_diff, 0.0, 50.0)
