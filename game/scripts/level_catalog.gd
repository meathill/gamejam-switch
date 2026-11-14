class_name LevelCatalog
extends RefCounted
## 关卡顺序，读取 data/levels/levels.json

const CATALOG_PATH := "res://data/levels/levels.json"


static func get_ids() -> Array[String]:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var ids: Array[String] = []
	ids.assign(data["levels"])
	return ids


static func first() -> String:
	return get_ids()[0]


## 下一关的 id；已经是最后一关时返回空字符串
static func get_next(level_id: String) -> String:
	var ids := get_ids()
	var index := ids.find(level_id)
	return ids[index + 1] if index >= 0 and index + 1 < ids.size() else ""
