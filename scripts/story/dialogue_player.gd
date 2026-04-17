class_name DialoguePlayer
extends Node

## 對話播放器 — 讀取 JSON 對話資料，驅動 DialogueBox

signal dialogue_finished()

var dialogue_box: DialogueBox

var _lines: Array = []            # 當前對話行列表（JSON array）
var _index: int = 0
var _line_ids: Dictionary = {}    # id -> index 快速跳轉

func _init(box: DialogueBox) -> void:
	dialogue_box = box

## 啟動對話播放
## lines: Array of Dictionary
##   每行格式：{speaker, text, [choices], [id], [next], [flag], [alignment]}
func play(lines: Array) -> void:
	_lines = lines
	_build_id_map()
	_index = 0
	_show_current()

	# 連接信號
	if not dialogue_box.line_finished.is_connected(_on_line_finished):
		dialogue_box.line_finished.connect(_on_line_finished)
	if not dialogue_box.choice_selected.is_connected(_on_choice_selected):
		dialogue_box.choice_selected.connect(_on_choice_selected)

func _build_id_map() -> void:
	_line_ids.clear()
	for i in range(_lines.size()):
		var line: Dictionary = _lines[i]
		if line.has("id"):
			_line_ids[line["id"]] = i

func _show_current() -> void:
	if _index < 0 or _index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[_index]

	# 處理旗標設定
	if line.has("flag"):
		StoryManager.set_flag(str(line["flag"]), line.get("flag_value", true))

	# 處理路線值變動（非選項也能用）
	if line.has("alignment"):
		StoryManager.change_alignment(int(line["alignment"]))

	# 處理跳轉
	if line.has("jump_to"):
		_jump_to(str(line["jump_to"]))
		return

	# 檢查是否為純標記行（無對話內容）
	if not line.has("text") and not line.has("choices"):
		_index += 1
		_show_current()
		return

	var speaker_id: String = str(line.get("speaker", "narrator"))
	var speaker_info: Dictionary = StoryManager.get_speaker_info(speaker_id)
	var display_name: String = line.get("name_override", speaker_info["name"])
	var portrait_color: Color = speaker_info["color"]
	var text: String = str(line.get("text", ""))

	if text != "":
		dialogue_box.show_line(display_name, text, portrait_color)

	# 若此行帶選項，等逐字播完後顯示選項
	if line.has("choices"):
		var choices: Array = line["choices"]
		# 等行播完才顯示選項（line_finished 觸發時再顯示）
		await dialogue_box.line_finished
		dialogue_box.show_choices(choices)

func _on_line_finished() -> void:
	# 若有選項，等使用者選，不在此前進
	var line: Dictionary = _lines[_index] if _index < _lines.size() else {}
	if line.has("choices"):
		return
	# 下一行
	_advance_to_next(line)

func _advance_to_next(line: Dictionary) -> void:
	if line.has("next"):
		_jump_to(str(line["next"]))
	else:
		_index += 1
		_show_current()

func _jump_to(label: String) -> void:
	if label == "" or label == "end":
		_finish()
		return
	if _line_ids.has(label):
		_index = _line_ids[label]
		_show_current()
	else:
		push_warning("DialoguePlayer: unknown label '" + label + "'")
		_finish()

func _on_choice_selected(_idx: int, alignment_change: int, next_id: String) -> void:
	if alignment_change != 0:
		StoryManager.change_alignment(alignment_change)
	if next_id != "":
		_jump_to(next_id)
	else:
		_index += 1
		_show_current()

func _finish() -> void:
	dialogue_box.hide_box()
	if dialogue_box.line_finished.is_connected(_on_line_finished):
		dialogue_box.line_finished.disconnect(_on_line_finished)
	if dialogue_box.choice_selected.is_connected(_on_choice_selected):
		dialogue_box.choice_selected.disconnect(_on_choice_selected)
	dialogue_finished.emit()
