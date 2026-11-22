extends GutTest
## 进度存档：只存下次该进的关卡 id

const TEST_PATH := "user://test_save.cfg"


func before_each() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.clear()


func after_all() -> void:
	SaveGame.clear()
	SaveGame.path = SaveGame.SAVE_PATH


func test_no_save_returns_empty() -> void:
	assert_eq(SaveGame.load_level_id(), "")


func test_saved_id_loads_back() -> void:
	SaveGame.save_level_id("level_02")
	assert_eq(SaveGame.load_level_id(), "level_02")


func test_unknown_id_returns_empty() -> void:
	SaveGame.save_level_id("level_99")
	assert_eq(SaveGame.load_level_id(), "")


func test_clear_removes_save() -> void:
	SaveGame.save_level_id("level_02")
	SaveGame.clear()
	assert_eq(SaveGame.load_level_id(), "")
