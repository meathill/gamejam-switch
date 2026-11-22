class_name SaveGame
extends RefCounted
## 通关进度存档：只记下次该从哪一关开始，不存关内检查点。
## Web 版的 user:// 由引擎写进 IndexedDB，写完不需要额外处理。

const SAVE_PATH := "user://save.cfg"
const SECTION := "progress"
const KEY := "level_id"

## 测试可改成别的路径，不碰真实存档
static var path: String = SAVE_PATH


## 下次该进的关卡 id；无存档、文件损坏或 id 已不在目录里（改名等）都返回空串
static func load_level_id() -> String:
	if not FileAccess.file_exists(path):
		return ""
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return ""
	var level_id := str(config.get_value(SECTION, KEY, ""))
	return level_id if LevelCatalog.get_ids().has(level_id) else ""


static func save_level_id(level_id: String) -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, KEY, level_id)
	config.save(path)


static func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
