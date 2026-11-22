extends GutTest


func test_level_select_feature_name() -> void:
	assert_eq(BuildFlags.LEVEL_SELECT_FEATURE, "level_select")


func test_level_select_enabled_in_editor() -> void:
	assert_true(BuildFlags.is_level_select_enabled(), "编辑器/测试环境下始终开启")
