class_name Skill
extends Resource

## 技能定義

enum SkillType {
	PHYSICAL,   # 物理攻擊技能
	MAGICAL,    # 特殊攻擊技能（毒液、音波等）
	HEAL,       # 治療技能
	BUFF,       # 增益技能
	DEBUFF,     # 減益技能
	PASSIVE,    # 被動技能
}

enum TargetType {
	SINGLE_ENEMY,    # 單一敵人
	SINGLE_ALLY,     # 單一友軍
	SINGLE_SELF,     # 僅自身
	AOE_ENEMIES,     # 範圍敵人
	AOE_ALLIES,      # 範圍友軍
	AOE_ALL,         # 範圍全體
}

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var skill_type: SkillType = SkillType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

# 消耗
@export var mp_cost: int = 0

# 範圍
@export var range_min: int = 1
@export var range_max: int = 1
@export var aoe_radius: int = 0  # AOE 半徑（0=單體）

# 倍率/效果
@export var damage_multiplier: float = 1.0   # 傷害倍率（相對於基礎 attack）
@export var hit_count: int = 1                # 連擊次數
@export var heal_amount: int = 0              # 固定治療量
@export var heal_ratio: float = 0.0           # 施術者 MATK 的治療倍率

# 狀態效果（未實作異常系統，先保留欄位）
@export var status_effect: String = ""
@export var status_duration: int

# 被動效果資料（PASSIVE 型技能用）
@export var passive_data: Dictionary = {}
