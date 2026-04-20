extends Node

## 劇情管理器（Autoload）— 路線值、劇情旗標、章節進度

signal alignment_changed(new_value: int)
signal flag_changed(flag_id: String, value: Variant)
signal chapter_completed(chapter_id: String)

## 路線值範圍：-100（極端霸主/征服）~ +100（極端共生/仁慈）
const ALIGNMENT_MIN := -100
const ALIGNMENT_MAX := 100

var alignment: int = 0
var flags: Dictionary = {}             # String -> Variant
var completed_chapters: Array[String] = []
var current_chapter: String = "ch01"

## 說話者顯示資料（肖像顏色）
var speaker_data := {
	"raptor": {"name": "銳牙", "color": Color(0.2, 0.7, 0.3)},
	"deinonychus": {"name": "疾風", "color": Color(0.3, 0.6, 0.9)},
	"triceratops": {"name": "鐵壁", "color": Color(0.7, 0.5, 0.3)},
	"maiasaura": {"name": "春芽", "color": Color(0.9, 0.7, 0.8)},
	"trex": {"name": "雷顎", "color": Color(0.8, 0.2, 0.2)},
	"narrator": {"name": "—", "color": Color(0.5, 0.5, 0.5)},
	"enemy_raptor": {"name": "敵方偵察兵", "color": Color(0.8, 0.4, 0.4)},
}

func get_speaker_info(speaker_id: String) -> Dictionary:
	return speaker_data.get(speaker_id, {"name": speaker_id, "color": Color(0.6, 0.6, 0.6)})

func change_alignment(delta: int) -> void:
	alignment = clampi(alignment + delta, ALIGNMENT_MIN, ALIGNMENT_MAX)
	alignment_changed.emit(alignment)

func set_flag(flag_id: String, value: Variant = true) -> void:
	flags[flag_id] = value
	flag_changed.emit(flag_id, value)

func get_flag(flag_id: String, default: Variant = false) -> Variant:
	return flags.get(flag_id, default)

func complete_chapter(chapter_id: String) -> void:
	if not chapter_id in completed_chapters:
		completed_chapters.append(chapter_id)
	chapter_completed.emit(chapter_id)

## 取得目前路線判定（供 UI 顯示/分歧判斷）
func get_current_route() -> String:
	if alignment >= 50:
		return "harmony"     # 共生路線
	elif alignment <= -50:
		return "conquest"    # 霸主路線
	else:
		return "neutral"

func get_route_name() -> String:
	match get_current_route():
		"harmony": return "共生傾向"
		"conquest": return "霸主傾向"
		_: return "中立"

## 重置（新遊戲）
func reset() -> void:
	alignment = 0
	flags.clear()
	completed_chapters.clear()
	current_chapter = "ch01"

## ===== 序列化 =====
func to_dict() -> Dictionary:
	return {
		"alignment": alignment,
		"flags": flags.duplicate(),
		"completed_chapters": completed_chapters.duplicate(),
		"current_chapter": current_chapter,
	}

func from_dict(d: Dictionary) -> void:
	alignment = int(d.get("alignment", 0))
	flags.clear()
	var flags_data: Dictionary = d.get("flags", {})
	for k in flags_data:
		flags[str(k)] = flags_data[k]
	completed_chapters.clear()
	var completed: Array = d.get("completed_chapters", [])
	for c in completed:
		completed_chapters.append(str(c))
	current_chapter = str(d.get("current_chapter", "ch01"))
	alignment_changed.emit(alignment)
