class_name EventPopup
extends CanvasLayer

## 事件節點 — 隨機福利選擇
## 同時僅一個實例

signal closed()

static var _active: EventPopup = null

static func open_singleton(parent: Node, scene: PackedScene, event_title: String) -> EventPopup:
	if _active != null and is_instance_valid(_active):
		return _active
	var inst: EventPopup = scene.instantiate()
	parent.add_child(inst)
	inst.show_event(event_title)
	return inst

static func is_open() -> bool:
	return _active != null and is_instance_valid(_active)

static func close_if_open() -> void:
	if _active != null and is_instance_valid(_active):
		_active.queue_free()
		_active = null

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var desc_label: Label = $Root/Panel/VBox/Description
@onready var options_container: VBoxContainer = $Root/Panel/VBox/OptionsContainer
@onready var result_label: Label = $Root/Panel/VBox/ResultLabel
@onready var close_button: Button = $Root/Panel/VBox/CloseButton

var _rewards: Array = []  # 當前 roll 出的獎勵

const POSSIBLE_ITEMS := ["raw_meat", "fresh_fish", "ancient_nectar", "revive_herb",
	"evolution_stone_s", "sharp_claw_ring", "hard_scale_armor", "swift_foot_band"]

func _ready() -> void:
	_active = self
	close_button.pressed.connect(_on_close)
	result_label.visible = false
	close_button.visible = false

func _exit_tree() -> void:
	if _active == self:
		_active = null

func show_event(event_title: String) -> void:
	title_label.text = event_title
	desc_label.text = "你在遺跡中發現了幾個發光的寶箱，選擇其中一個打開..."
	_generate_rewards()
	_build_option_buttons()

## 隨機產生 3 個不同類型的獎勵
func _generate_rewards() -> void:
	_rewards.clear()
	var types := ["item", "exp", "gold", "level_up"]
	types.shuffle()
	# 取前 3 個
	for i in range(3):
		_rewards.append(_roll_reward(types[i]))

func _roll_reward(kind: String) -> Dictionary:
	match kind:
		"item":
			var item_id: String = POSSIBLE_ITEMS[randi() % POSSIBLE_ITEMS.size()]
			var item := ItemDatabase.get_item(item_id)
			return {
				"kind": "item", "item_id": item_id,
				"display": "獲得道具：" + (item.display_name if item else item_id),
				"amount": 1,
			}
		"exp":
			var amount := randi_range(30, 80)
			return {
				"kind": "exp", "amount": amount,
				"display": "全隊獲得經驗值：+%d" % amount,
			}
		"gold":
			var amount := randi_range(50, 200)
			return {
				"kind": "gold", "amount": amount,
				"display": "獲得金幣：+%d" % amount,
			}
		"level_up":
			return {
				"kind": "level_up",
				"display": "隨機一名我方單位升級！",
			}
	return {"kind": "none", "display": "無"}

func _build_option_buttons() -> void:
	for c in options_container.get_children():
		c.queue_free()
	for i in range(_rewards.size()):
		var reward: Dictionary = _rewards[i]
		var btn := Button.new()
		btn.text = "寶箱 %d：%s" % [i + 1, _obscure_label(reward)]
		btn.add_theme_font_size_override("font_size", 18)
		var idx := i
		btn.pressed.connect(func(): _on_option_picked(idx))
		options_container.add_child(btn)
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

## 不揭露具體獎勵，只顯示類別暗示
func _obscure_label(reward: Dictionary) -> String:
	match reward.get("kind", ""):
		"item": return "散發著草藥香氣"
		"exp": return "閃耀著智慧之光"
		"gold": return "傳來金屬碰撞聲"
		"level_up": return "散發神秘能量"
	return "???"

func _on_option_picked(idx: int) -> void:
	if idx < 0 or idx >= _rewards.size():
		return
	var reward: Dictionary = _rewards[idx]
	_apply_reward(reward)

	# 清除按鈕，顯示結果
	for c in options_container.get_children():
		c.queue_free()
	result_label.text = reward["display"]
	result_label.visible = true
	close_button.visible = true
	close_button.grab_focus()

func _apply_reward(reward: Dictionary) -> void:
	match reward.get("kind", ""):
		"item":
			Inventory.add_item(reward["item_id"], reward.get("amount", 1))
		"gold":
			Inventory.add_gold(reward.get("amount", 0))
		"exp":
			# 給予全隊經驗（透過 StoryManager 暫存旗標，下場戰鬥時使用 / 或直接套用已知隊伍）
			# 簡化：存到全域旗標，由下場戰鬥讀取。此處只是示意。
			var current: int = int(StoryManager.get_flag("pending_exp", 0))
			StoryManager.set_flag("pending_exp", current + reward.get("amount", 0))
		"level_up":
			StoryManager.set_flag("pending_free_levelup", int(StoryManager.get_flag("pending_free_levelup", 0)) + 1)

func _on_close() -> void:
	closed.emit()
	queue_free()
