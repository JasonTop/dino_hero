class_name DialogueBox
extends CanvasLayer

## 對話框 UI — 逐字顯示、說話者切換、選項

signal line_finished()           # 當前行播放完畢（含逐字）
signal choice_selected(index: int, alignment_change: int, next_id: String)

const CHAR_DELAY := 0.03         # 每字顯示間隔（秒）

@onready var panel: PanelContainer = $Panel
@onready var portrait: ColorRect = $Panel/HBox/PortraitBox/Portrait
@onready var speaker_label: Label = $Panel/HBox/RightBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/HBox/RightBox/TextLabel
@onready var next_indicator: Label = $Panel/HBox/RightBox/NextIndicator
@onready var choice_panel: VBoxContainer = $ChoicePanel/VBox

var _full_text: String = ""
var _typing: bool = false
var _char_timer: float = 0.0
var _visible_chars: int = 0
var _pending_choices: Array = []  # 當前行的選項

func _ready() -> void:
	visible = false
	next_indicator.visible = false
	$ChoicePanel.visible = false

func show_line(speaker: String, text: String, portrait_color: Color = Color(0.4, 0.7, 0.4)) -> void:
	visible = true
	speaker_label.text = speaker
	portrait.color = portrait_color
	_full_text = text
	text_label.text = text
	text_label.visible_characters = 0
	_visible_chars = 0
	_char_timer = 0.0
	_typing = true
	next_indicator.visible = false
	$ChoicePanel.visible = false

func show_choices(choices: Array) -> void:
	_pending_choices = choices
	# 清除舊按鈕
	for child in choice_panel.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", "...")
		btn.add_theme_font_size_override("font_size", 18)
		var idx := i
		btn.pressed.connect(func(): _on_choice_picked(idx))
		choice_panel.add_child(btn)

	$ChoicePanel.visible = true
	next_indicator.visible = false

	await get_tree().process_frame
	if choice_panel.get_child_count() > 0:
		choice_panel.get_child(0).grab_focus()

func hide_box() -> void:
	visible = false
	$ChoicePanel.visible = false

func _process(delta: float) -> void:
	if not _typing:
		return
	_char_timer += delta
	while _char_timer >= CHAR_DELAY and _visible_chars < _full_text.length():
		_char_timer -= CHAR_DELAY
		_visible_chars += 1
		text_label.visible_characters = _visible_chars

	if _visible_chars >= _full_text.length():
		_typing = false
		next_indicator.visible = true

func _on_choice_picked(index: int) -> void:
	if index < 0 or index >= _pending_choices.size():
		return
	var choice: Dictionary = _pending_choices[index]
	var alignment_change: int = int(choice.get("alignment", 0))
	var next_id: String = str(choice.get("next", ""))
	$ChoicePanel.visible = false
	choice_selected.emit(index, alignment_change, next_id)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if $ChoicePanel.visible:
		# 選項階段，讓 Button 處理輸入
		return

	if event.is_action_pressed("confirm") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if _typing:
			# 跳過逐字效果
			_visible_chars = _full_text.length()
			text_label.visible_characters = _visible_chars
			_typing = false
			next_indicator.visible = true
		else:
			line_finished.emit()
		get_viewport().set_input_as_handled()
