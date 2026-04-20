extends Node

## 隊伍管理（Autoload）— 持有所有我方成員的 UnitStats，跨場景保留

signal party_changed()

var members: Array[UnitStats] = []

## 重置為預設新遊戲隊伍
func reset_to_default() -> void:
	members.clear()

	var raptor := UnitData.create_stats(UnitData.DinoType.VELOCIRAPTOR, "銳牙", 3)
	raptor.equipped_item_id = "sharp_claw_ring"
	members.append(raptor)

	var deinonychus := UnitData.create_stats(UnitData.DinoType.DEINONYCHUS, "疾風", 3)
	members.append(deinonychus)

	var trike := UnitData.create_stats(UnitData.DinoType.TRICERATOPS, "鐵壁", 3)
	trike.equipped_item_id = "hard_scale_armor"
	members.append(trike)

	var maia := UnitData.create_stats(UnitData.DinoType.MAIASAURA, "春芽", 2)
	members.append(maia)

	party_changed.emit()

## 取得當前隊伍（回傳複本以免戰鬥中修改影響）
## 實際戰鬥使用原 reference 才能保留成長，這裡僅供 UI 預覽
func get_members() -> Array[UnitStats]:
	return members

## 全隊回滿 HP/MP（章節結束時呼叫）
func full_heal() -> void:
	for m in members:
		m.hp = m.hp_max
		m.mp = m.mp_max

## 給予所有成員經驗（事件獎勵用）
func grant_exp_all(amount: int) -> Array:
	var all_level_ups: Array = []
	for m in members:
		# 透過一個臨時 wrapper 讓 ExpSystem 能處理
		var dummy_unit := _create_dummy_for_exp(m)
		var level_ups := ExpSystem.grant_exp(dummy_unit, amount)
		if not level_ups.is_empty():
			all_level_ups.append({"stats": m, "level_ups": level_ups})
	return all_level_ups

func _create_dummy_for_exp(stats: UnitStats) -> Node:
	# ExpSystem 需要 unit.stats 結構，建一個臨時 Node
	var dummy := Node.new()
	dummy.set_script(preload("res://scripts/units/unit_stats_wrapper.gd"))
	dummy.stats = stats
	return dummy

## ===== 序列化 =====
func to_dict() -> Dictionary:
	var arr: Array = []
	for m in members:
		arr.append(m.to_dict())
	return {"members": arr}

func from_dict(d: Dictionary) -> void:
	members.clear()
	var arr: Array = d.get("members", [])
	for entry in arr:
		if entry is Dictionary:
			members.append(UnitStats.from_dict(entry))
	party_changed.emit()
