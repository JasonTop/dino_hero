extends Node

## 狀態異常資料庫（Autoload）
## 每個狀態定義欄位：
##   name         顯示名
##   color        圖示顏色
##   kind         "dot"(持續傷害) | "hot"(持續治療) | "buff" | "debuff" | "control"
##   tick_hp_pct  每回合開始 HP 變化（正=治療，負=傷害），為最大 HP 的百分比
##   atk_mult / def_mult / matk_mult / mdef_mult / spd_mult  1.0 = 無效果
##   accuracy_mod 命中加成（正/負百分比點）
##   skip_chance  被跳過回合機率（0~100）

var _defs: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	# === DOT ===
	_defs["poison"] = {
		"name": "中毒", "color": Color(0.5, 0.9, 0.3),
		"kind": "dot", "tick_hp_pct": -0.10,
	}
	_defs["burn"] = {
		"name": "燃燒", "color": Color(1.0, 0.5, 0.2),
		"kind": "dot", "tick_hp_pct": -0.08,
	}

	# === HOT ===
	_defs["regen"] = {
		"name": "再生", "color": Color(0.4, 1.0, 0.6),
		"kind": "hot", "tick_hp_pct": 0.10,
	}

	# === BUFF ===
	_defs["attack_up"] = {
		"name": "攻擊提升", "color": Color(1.0, 0.7, 0.3),
		"kind": "buff", "atk_mult": 1.3,
	}
	_defs["defense_up"] = {
		"name": "防禦提升", "color": Color(0.3, 0.7, 1.0),
		"kind": "buff", "def_mult": 1.3,
	}
	_defs["speed_up"] = {
		"name": "迅捷", "color": Color(0.8, 0.8, 1.0),
		"kind": "buff", "spd_mult": 1.3,
	}

	# === DEBUFF ===
	_defs["intimidate"] = {
		"name": "恐嚇", "color": Color(0.6, 0.2, 0.6),
		"kind": "debuff", "atk_mult": 0.85, "def_mult": 0.85,
	}
	_defs["blind"] = {
		"name": "盲目", "color": Color(0.3, 0.3, 0.3),
		"kind": "debuff", "accuracy_mod": -30,
	}
	_defs["weaken"] = {
		"name": "虛弱", "color": Color(0.6, 0.4, 0.4),
		"kind": "debuff", "atk_mult": 0.7,
	}

	# === CONTROL ===
	_defs["paralysis"] = {
		"name": "麻痺", "color": Color(1.0, 1.0, 0.2),
		"kind": "control", "skip_chance": 35,
	}
	_defs["sleep"] = {
		"name": "沉睡", "color": Color(0.4, 0.4, 0.8),
		"kind": "control", "skip_chance": 100,  # 100% 跳過但被攻擊時會消除
	}

func get_definition(effect_id: String) -> Dictionary:
	return _defs.get(effect_id, {})

func has_effect(effect_id: String) -> bool:
	return _defs.has(effect_id)

func get_display_name(effect_id: String) -> String:
	var d := get_definition(effect_id)
	return d.get("name", effect_id)
