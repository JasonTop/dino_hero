extends Node

## 輔助：用來包裝 UnitStats 給 ExpSystem 使用
## 因為 ExpSystem 原本預期 Unit 有 stats 和 update_health_bar

var stats: UnitStats

func update_health_bar() -> void:
	pass  # 非戰鬥情境無需更新
