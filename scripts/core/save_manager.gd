extends Node

## 存檔管理（Autoload）— 6 個手動存檔欄位 + 1 個自動存檔欄位

signal save_completed(slot: int)
signal load_completed(slot: int)

const MANUAL_SLOTS := 6
const AUTO_SLOT := 0        # 欄位 0 為自動存檔
const SAVE_VERSION := 1

## 取得存檔路徑
static func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

## ===== 存檔 =====
## battle_snapshot: 若為戰鬥中存檔，帶入 battle_scene 產生的快照
func save_to_slot(slot: int, battle_snapshot: Dictionary = {}) -> bool:
	var data := {
		"version": SAVE_VERSION,
		"save_date": Time.get_datetime_string_from_system(),
		"difficulty": GameManager.current_difficulty,
		"story": StoryManager.to_dict(),
		"inventory": Inventory.to_dict(),
		"party": PartyManager.to_dict(),
	}

	if not battle_snapshot.is_empty():
		data["location"] = "battle"
		data["battle_snapshot"] = battle_snapshot
	else:
		data["location"] = "world_map"

	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open save file for slot %d" % slot)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	save_completed.emit(slot)
	return true

## 自動存檔（回到世界地圖時呼叫）
func auto_save() -> void:
	save_to_slot(AUTO_SLOT)

## ===== 讀檔 =====
func load_from_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return {}

	# 還原各系統
	GameManager.set_difficulty(int(parsed.get("difficulty", 1)))
	StoryManager.from_dict(parsed.get("story", {}))
	Inventory.from_dict(parsed.get("inventory", {}))
	PartyManager.from_dict(parsed.get("party", {}))

	load_completed.emit(slot)
	return parsed  # 呼叫方判斷 location / battle_snapshot

## ===== 檢查與刪除 =====
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

## 取得存檔預覽（不載入全域狀態）
func get_save_info(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return {}

	var story: Dictionary = parsed.get("story", {})
	var party: Dictionary = parsed.get("party", {})
	var members: Array = party.get("members", [])
	var max_lv: int = 0
	var leader_name: String = "—"
	if members.size() > 0:
		leader_name = str(members[0].get("display_name", "—"))
		for m: Dictionary in members:
			max_lv = maxi(max_lv, int(m.get("level", 1)))

	return {
		"save_date": str(parsed.get("save_date", "")),
		"difficulty": int(parsed.get("difficulty", 1)),
		"location": str(parsed.get("location", "world_map")),
		"current_chapter": str(story.get("current_chapter", "")),
		"completed_count": (story.get("completed_chapters", []) as Array).size(),
		"alignment": int(story.get("alignment", 0)),
		"leader_name": leader_name,
		"max_level": max_lv,
		"gold": int((parsed.get("inventory", {}) as Dictionary).get("gold", 0)),
	}

func delete_slot(slot: int) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true
