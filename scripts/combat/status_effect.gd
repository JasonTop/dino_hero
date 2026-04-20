class_name StatusEffect
extends RefCounted

## 狀態異常實例 — 每個 Unit 可同時持有多個

var effect_id: String
var duration: int         # 剩餘回合數
var magnitude: float      # 倍率或數值（視效果而定，不用則為 0）

func _init(id: String = "", dur: int = 3, mag: float = 0.0) -> void:
	effect_id = id
	duration = dur
	magnitude = mag

func get_def() -> Dictionary:
	return StatusEffectDatabase.get_definition(effect_id)

func to_dict() -> Dictionary:
	return {"effect_id": effect_id, "duration": duration, "magnitude": magnitude}

static func from_dict(d: Dictionary) -> StatusEffect:
	return StatusEffect.new(str(d.get("effect_id", "")), int(d.get("duration", 0)), float(d.get("magnitude", 0.0)))
