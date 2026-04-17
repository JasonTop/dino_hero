extends Node

## 全域遊戲管理器 — 場景切換、全域狀態、難度設定

signal scene_change_requested(scene_path: String)
signal difficulty_changed(difficulty: int)

enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

## 難度屬性修正表
## hp/atk/def 乘數、等級補正、AI 聰明度
const DIFFICULTY_TABLE := {
	Difficulty.EASY: {
		"name": "簡單", "hp": 0.75, "atk": 0.8, "def": 0.9,
		"level_bonus": -1, "ai_smart": 0,
	},
	Difficulty.NORMAL: {
		"name": "普通", "hp": 1.0, "atk": 1.0, "def": 1.0,
		"level_bonus": 0, "ai_smart": 1,
	},
	Difficulty.HARD: {
		"name": "困難", "hp": 1.3, "atk": 1.2, "def": 1.15,
		"level_bonus": 2, "ai_smart": 2,
	},
	Difficulty.NIGHTMARE: {
		"name": "惡夢", "hp": 1.6, "atk": 1.4, "def": 1.3,
		"level_bonus": 4, "ai_smart": 3,
	},
}

var current_difficulty: int = Difficulty.NORMAL

func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func set_difficulty(d: int) -> void:
	current_difficulty = clampi(d, Difficulty.EASY, Difficulty.NIGHTMARE)
	difficulty_changed.emit(current_difficulty)

func cycle_difficulty() -> void:
	var next := (current_difficulty + 1) % DIFFICULTY_TABLE.size()
	set_difficulty(next)

func get_difficulty_config() -> Dictionary:
	return DIFFICULTY_TABLE[current_difficulty]

func get_difficulty_name() -> String:
	return DIFFICULTY_TABLE[current_difficulty]["name"]

## 對敵方單位套用難度修正
func apply_difficulty_to_enemy(stats: UnitStats) -> void:
	var cfg := get_difficulty_config()
	stats.hp_max = int(stats.hp_max * cfg["hp"])
	stats.hp = stats.hp_max
	stats.attack = int(stats.attack * cfg["atk"])
	stats.magic_attack = int(stats.magic_attack * cfg["atk"])
	stats.defense = int(stats.defense * cfg["def"])
	stats.magic_defense = int(stats.magic_defense * cfg["def"])
