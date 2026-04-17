class_name TerrainData
extends Resource

## 地形資料定義

enum TerrainType {
	PLAIN,
	GRASS,
	FOREST,
	ROCK,
	WALL,    # 不可通行
	WATER,   # 不可通行（水棲單位除外）
}

@export var terrain_type: TerrainType = TerrainType.PLAIN
@export var display_name: String = "平地"
@export var move_cost: int = 1          # 移動消耗
@export var defense_bonus: float = 0.0  # 防禦加成 (0.1 = +10%)
@export var evasion_bonus: float = 0.0  # 迴避加成
@export var is_passable: bool = true    # 是否可通行

static func get_terrain(type: TerrainType) -> Dictionary:
	var data := {
		TerrainType.PLAIN:  { "name": "平地", "cost": 1, "def": 0.0,  "eva": 0.0,  "pass": true },
		TerrainType.GRASS:  { "name": "草叢", "cost": 1, "def": 0.0,  "eva": 0.1,  "pass": true },
		TerrainType.FOREST: { "name": "森林", "cost": 2, "def": 0.1,  "eva": 0.2,  "pass": true },
		TerrainType.ROCK:   { "name": "岩地", "cost": 2, "def": 0.15, "eva": 0.0,  "pass": true },
		TerrainType.WALL:   { "name": "障壁", "cost": 99, "def": 0.0, "eva": 0.0,  "pass": false },
		TerrainType.WATER:  { "name": "水域", "cost": 99, "def": 0.0, "eva": 0.0,  "pass": false },
	}
	return data.get(type, data[TerrainType.PLAIN])
