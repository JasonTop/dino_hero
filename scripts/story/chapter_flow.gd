extends Node2D

## 章節流程控制 — 戰前對話 → 戰鬥 → 戰後對話 → 下一章

const BattleSceneRes := preload("res://scenes/battle/battle_scene.tscn")
const DialogueBoxRes := preload("res://scenes/ui/dialogue_box.tscn")

@onready var background: ColorRect = $Background
@onready var chapter_title_label: Label = $TitleLayer/ChapterTitleLabel

var chapter_id: String = ""
var chapter_data: Dictionary = {}
var dialogue_box: DialogueBox
var dialogue_player: DialoguePlayer
var battle_scene: Node = null

func _ready() -> void:
	# 章節 ID 透過 StoryManager 或預設取得
	chapter_id = StoryManager.current_chapter
	chapter_data = ChapterDatabase.get_chapter(chapter_id)

	if chapter_data.is_empty():
		push_error("ChapterFlow: chapter not found: " + chapter_id)
		_return_to_title()
		return

	# 建立對話框
	dialogue_box = DialogueBoxRes.instantiate()
	add_child(dialogue_box)
	dialogue_player = DialoguePlayer.new(dialogue_box)
	add_child(dialogue_player)

	# 顯示章節標題
	var title: String = chapter_data.get("title", chapter_id)
	_show_chapter_title(title)

	await get_tree().create_timer(2.0).timeout
	_play_pre_battle()

func _show_chapter_title(title: String) -> void:
	chapter_title_label.text = title
	chapter_title_label.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(chapter_title_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.2)
	tween.tween_property(chapter_title_label, "modulate:a", 0.0, 0.5)

## 1. 戰前對話
func _play_pre_battle() -> void:
	var lines: Array = chapter_data.get("pre_battle", [])
	if lines.is_empty():
		_start_battle()
		return
	dialogue_player.dialogue_finished.connect(_on_pre_battle_finished, CONNECT_ONE_SHOT)
	dialogue_player.play(lines)

func _on_pre_battle_finished() -> void:
	_start_battle()

## 2. 戰鬥
func _start_battle() -> void:
	background.visible = false
	battle_scene = BattleSceneRes.instantiate()
	add_child(battle_scene)

	# 等待 BattleManager 就緒，連接結束信號
	await get_tree().process_frame
	var bm: Node = battle_scene.get_node_or_null("BattleManager")
	if bm:
		bm.battle_ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)

func _on_battle_ended(is_victory: bool) -> void:
	if not is_victory:
		# 敗北：回世界地圖，節點不標記完成
		await get_tree().create_timer(2.0).timeout
		StoryManager.set_flag("pending_world_node", "")
		get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")
		return

	# 勝利 → 戰後對話
	await get_tree().create_timer(1.5).timeout
	_play_post_battle()

## 3. 戰後對話
func _play_post_battle() -> void:
	# 隱藏戰鬥場景
	if battle_scene:
		battle_scene.queue_free()
		battle_scene = null
	background.visible = true

	var lines: Array = chapter_data.get("post_battle", [])
	if lines.is_empty():
		_finish_chapter()
		return
	dialogue_player.dialogue_finished.connect(_on_post_battle_finished, CONNECT_ONE_SHOT)
	dialogue_player.play(lines)

func _on_post_battle_finished() -> void:
	_finish_chapter()

## 4. 章節結束
func _finish_chapter() -> void:
	StoryManager.complete_chapter(chapter_id)
	# 也標記世界地圖節點為已完成
	var node_id: String = str(StoryManager.get_flag("pending_world_node", ""))
	if node_id != "" and node_id != chapter_id:
		StoryManager.complete_chapter(node_id)
	StoryManager.set_flag("pending_world_node", "")

	# 回到世界地圖
	get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")

func _show_ending() -> void:
	chapter_title_label.text = "章節結束\n路線傾向：" + StoryManager.get_route_name()
	var tween := create_tween()
	tween.tween_property(chapter_title_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_callback(_return_to_title)

func _return_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
