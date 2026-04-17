extends Node

## 全域遊戲管理器 — 場景切換、全域狀態

signal scene_change_requested(scene_path: String)

func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
