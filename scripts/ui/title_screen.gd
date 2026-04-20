extends Control

## 標題畫面 — 新遊戲 / 繼續 / 難度 / 離開

const SaveLoadScene := preload("res://scenes/ui/save_load_screen.tscn")

@onready var start_btn: Button = $VBoxContainer/StartButton
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var difficulty_btn: Button = $VBoxContainer/DifficultyButton
@onready var dev_mode_btn: CheckButton = $VBoxContainer/DevModeToggle
@onready var quit_btn: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	difficulty_btn.pressed.connect(_on_difficulty_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	start_btn.grab_focus()
	_update_difficulty_label()
	_refresh_continue_state()
	_setup_dev_mode_toggle()

func _setup_dev_mode_toggle() -> void:
	# release build（非 debug）隱藏開發模式開關
	if not GameManager.is_dev_mode_available():
		dev_mode_btn.visible = false
		return
	dev_mode_btn.button_pressed = GameManager.dev_mode_enabled
	dev_mode_btn.toggled.connect(func(on: bool): GameManager.set_dev_mode(on))

func _refresh_continue_state() -> void:
	# 只要任何欄位有存檔就啟用
	var any := false
	for i in range(SaveManager.MANUAL_SLOTS + 1):
		if SaveManager.has_save(i):
			any = true
			break
	continue_btn.disabled = not any

func _on_start_pressed() -> void:
	StoryManager.reset()
	PartyManager.reset_to_default()
	Inventory.clear_all()
	Inventory.gold = 100
	Inventory.add_item("raw_meat", 3)
	Inventory.add_item("fresh_fish", 1)
	Inventory.add_item("ancient_nectar", 2)
	Inventory.add_item("revive_herb", 1)
	get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")

func _on_continue_pressed() -> void:
	if SaveLoadScreen.is_open():
		return
	var screen := SaveLoadScreen.open_singleton(self, SaveLoadScene, SaveLoadScreen.Mode.LOAD)
	screen.slot_selected.connect(_on_slot_picked)

func _on_slot_picked(slot: int) -> void:
	var data := SaveManager.load_from_slot(slot)
	if data.is_empty():
		return
	var location: String = data.get("location", "world_map")
	if location == "battle":
		# 將 battle snapshot 暫存，由 battle_scene 讀取還原
		StoryManager.set_flag("pending_battle_snapshot", data.get("battle_snapshot", {}))
		get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/world_map/world_map.tscn")

func _on_difficulty_pressed() -> void:
	GameManager.cycle_difficulty()
	_update_difficulty_label()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _update_difficulty_label() -> void:
	difficulty_btn.text = "難度：" + GameManager.get_difficulty_name()
