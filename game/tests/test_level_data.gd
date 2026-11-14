extends GutTest
## 关卡数据校验：所有正式关卡必须通过，坏数据要报出对应问题


func _make(objects: Array) -> LevelData:
	return LevelData.from_dict("test", {
		"camera_limits": [0, -1000, 4000, 2000],
		"player_start": [100, 0],
		"objects": objects,
	})


func _base_objects() -> Array:
	return [
		{ "type": "block", "pos": [0, 0], "size": [4000, 500] },
		{ "type": "resident", "id": "r", "pos": [500, 0], "name": "居民" },
		{ "type": "goal", "pos": [3500, 0] },
	]


func _assert_has_error(level: LevelData, keyword: String) -> void:
	var errors := level.validate()
	assert_true(Array(errors).any(func(error: String) -> bool: return error.contains(keyword)),
		"应该报出包含“%s”的问题，实际：%s" % [keyword, errors])


func test_all_levels_in_catalog_are_valid() -> void:
	var ids := LevelCatalog.get_ids()
	assert_gt(ids.size(), 0)
	for level_id in ids:
		var errors := LevelData.load_level(level_id).validate()
		assert_eq(errors.size(), 0, "%s：%s" % [level_id, errors])


func test_base_fixture_is_valid() -> void:
	assert_eq(_make(_base_objects()).validate().size(), 0)


func test_unknown_type() -> void:
	var objects := _base_objects()
	objects.append({ "type": "dragon", "pos": [0, 0] })
	_assert_has_error(_make(objects), "未知类型")


func test_missing_required_field() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "pos": [100, 0], "size": [300, 200] })
	_assert_has_error(_make(objects), "缺少字段 name")


func test_duplicate_id() -> void:
	var objects := _base_objects()
	objects.append({ "type": "checkpoint", "id": "r", "pos": [800, 0] })
	_assert_has_error(_make(objects), "id 重复")


func test_missing_reference() -> void:
	var objects := _base_objects()
	objects.append({ "type": "raft", "zone": "nowhere" })
	_assert_has_error(_make(objects), "不存在")


func test_reference_of_wrong_type() -> void:
	var objects := _base_objects()
	objects.append({ "type": "raft", "zone": "r" })
	_assert_has_error(_make(objects), "只能引用")


func test_dock_outside_zone() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [100, 0], "size": [300, 200], "docks": [50, 400] })
	_assert_has_error(_make(objects), "超出水域宽度")


func test_raft_dock_index_out_of_range() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [100, 0], "size": [300, 200], "docks": [50] })
	objects.append({ "type": "raft", "zone": "w", "dock": 1 })
	_assert_has_error(_make(objects), "停靠点序号")


func test_two_rafts_on_same_dock() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [100, 0], "size": [300, 200], "docks": [50, 200] })
	objects.append({ "type": "raft", "zone": "w", "dock": 0 })
	objects.append({ "type": "raft", "zone": "w", "dock": 0 })
	_assert_has_error(_make(objects), "同一个停靠点")


func test_object_outside_camera() -> void:
	var objects := _base_objects()
	objects.append({ "type": "checkpoint", "pos": [9000, 0] })
	_assert_has_error(_make(objects), "超出镜头范围")


func test_goal_must_be_unique() -> void:
	var objects := _base_objects()
	objects.append({ "type": "goal", "pos": [3000, 0] })
	_assert_has_error(_make(objects), "goal 必须恰好一个")


func test_level_needs_objective() -> void:
	var objects := _base_objects()
	objects.remove_at(1)
	_assert_has_error(_make(objects), "没有任何通关目标")


func test_catalog_order() -> void:
	var ids := LevelCatalog.get_ids()
	assert_eq(LevelCatalog.first(), ids[0])
	assert_eq(LevelCatalog.get_next(ids[-1]), "")
	assert_eq(LevelCatalog.get_next("missing"), "")
