class_name DamagePopup
extends Node2D

## 浮動傷害數字

@onready var label: Label = $Label

func show_damage(amount: int, is_crit: bool = false, is_miss: bool = false) -> void:
	if is_miss:
		label.text = "MISS"
		label.modulate = Color.GRAY
	elif is_crit:
		label.text = str(amount) + "!"
		label.modulate = Color.YELLOW
		label.scale = Vector2(1.3, 1.3)
	else:
		label.text = str(amount)
		label.modulate = Color.WHITE

	# 動畫：上浮 + 淡出
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
