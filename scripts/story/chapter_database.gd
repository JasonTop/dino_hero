extends Node

## 章節資料庫（Autoload）— 載入 data/chapters/*.json

var _chapters: Dictionary = {}  # chapter_id -> Dictionary

func _ready() -> void:
	_load_all_chapters()

func _load_all_chapters() -> void:
	var dir := DirAccess.open("res://data/chapters")
	if dir == null:
		push_warning("ChapterDatabase: data/chapters directory not found")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_chapter_file("res://data/chapters/" + file_name)
		file_name = dir.get_next()

func _load_chapter_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	var parsed = JSON.parse_string(txt)
	if parsed == null or not parsed is Dictionary:
		push_warning("ChapterDatabase: failed to parse " + path)
		return
	var cid: String = parsed.get("chapter_id", "")
	if cid == "":
		push_warning("ChapterDatabase: missing chapter_id in " + path)
		return
	_chapters[cid] = parsed

func get_chapter(chapter_id: String) -> Dictionary:
	return _chapters.get(chapter_id, {})

func has_chapter(chapter_id: String) -> bool:
	return _chapters.has(chapter_id)
