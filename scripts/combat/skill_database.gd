extends Node

## 技能資料庫（Autoload）

var _skills: Dictionary = {}  # skill_id -> Skill

func _ready() -> void:
	_register_all_skills()

func _register_all_skills() -> void:
	# ===== 迅猛龍系 =====
	_register({
		"id": "claw_combo", "name": "利爪連斬",
		"desc": "連續攻擊 2 次，每次傷害 80%",
		"type": Skill.SkillType.PHYSICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 8, "range_max": 1, "mult": 0.8, "hits": 2,
	})
	_register({
		"id": "pack_hunt", "name": "群獵本能",
		"desc": "被動：每有 1 隻相鄰友軍，命中+5%、暴擊+3%",
		"type": Skill.SkillType.PASSIVE,
		"passive": {"kind": "pack_hunt", "hit_per_ally": 5, "crit_per_ally": 3},
	})
	_register({
		"id": "quick_strike", "name": "迅捷突襲",
		"desc": "對敵人造成 120% 傷害，並有高暴擊率",
		"type": Skill.SkillType.PHYSICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 6, "range_max": 1, "mult": 1.2, "hits": 1,
	})

	# ===== 三角龍系 =====
	_register({
		"id": "iron_wall", "name": "堅甲護盾",
		"desc": "自身 DEF +30%，持續 3 回合",
		"type": Skill.SkillType.BUFF, "target": Skill.TargetType.SINGLE_SELF,
		"mp": 10, "status": "defense_up", "duration": 3,
	})
	_register({
		"id": "counter_stance", "name": "反擊架式",
		"desc": "被動：被近戰攻擊時 50% 機率反擊",
		"type": Skill.SkillType.PASSIVE,
		"passive": {"kind": "counter", "chance": 50},
	})
	_register({
		"id": "horn_charge", "name": "犄角衝撞",
		"desc": "物理傷害 140%，推退目標 1 格",
		"type": Skill.SkillType.PHYSICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 8, "range_max": 1, "mult": 1.4,
	})

	# ===== 暴龍系 =====
	_register({
		"id": "intimidate", "name": "恐嚇咆哮",
		"desc": "周圍 2 格敵人 ATK/DEF -15%，持續 3 回合",
		"type": Skill.SkillType.DEBUFF, "target": Skill.TargetType.AOE_ENEMIES,
		"mp": 12, "range_max": 2, "aoe": 2, "status": "intimidate", "duration": 3,
	})
	_register({
		"id": "bite_crush", "name": "噬咬粉碎",
		"desc": "毀滅性咬擊，物理傷害 180%",
		"type": Skill.SkillType.PHYSICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 15, "range_max": 1, "mult": 1.8,
	})
	_register({
		"id": "predator_instinct", "name": "獵食本能",
		"desc": "被動：對 HP < 40% 的敵人傷害 +30%",
		"type": Skill.SkillType.PASSIVE,
		"passive": {"kind": "predator", "threshold": 0.4, "bonus": 30},
	})

	# ===== 通用治療 =====
	_register({
		"id": "heal_lick", "name": "舔舐治癒",
		"desc": "回復友軍 HP (MATK * 1.5)",
		"type": Skill.SkillType.HEAL, "target": Skill.TargetType.SINGLE_ALLY,
		"mp": 8, "range_max": 1, "heal_ratio": 1.5,
	})

	# ===== 雙冠龍毒霧 =====
	_register({
		"id": "venom_spit", "name": "毒液噴射",
		"desc": "遠程攻擊並使目標中毒 3 回合",
		"type": Skill.SkillType.MAGICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 10, "range_max": 3, "mult": 1.0,
		"status": "poison", "duration": 3,
	})
	_register({
		"id": "sonic_blast", "name": "音波震擊",
		"desc": "特殊攻擊並使目標進入盲目狀態",
		"type": Skill.SkillType.MAGICAL, "target": Skill.TargetType.SINGLE_ENEMY,
		"mp": 8, "range_max": 2, "mult": 0.9,
		"status": "blind", "duration": 2,
	})

func _register(d: Dictionary) -> void:
	var s := Skill.new()
	s.skill_id = d["id"]
	s.display_name = d["name"]
	s.description = d["desc"]
	s.skill_type = d["type"]
	s.target_type = d.get("target", Skill.TargetType.SINGLE_ENEMY)
	s.mp_cost = d.get("mp", 0)
	s.range_min = d.get("range_min", 1)
	s.range_max = d.get("range_max", 1)
	s.aoe_radius = d.get("aoe", 0)
	s.damage_multiplier = d.get("mult", 1.0)
	s.hit_count = d.get("hits", 1)
	s.heal_amount = d.get("heal", 0)
	s.heal_ratio = d.get("heal_ratio", 0.0)
	s.status_effect = d.get("status", "")
	s.status_duration = d.get("duration", 0)
	s.passive_data = d.get("passive", {})
	_skills[s.skill_id] = s

func get_skill(skill_id: String) -> Skill:
	return _skills.get(skill_id, null)

func get_all_skills() -> Array:
	return _skills.values()
