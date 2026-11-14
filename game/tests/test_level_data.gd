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


func test_unknown_blocked_weather() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "name": "水", "pos": [100, 0], "size": [300, 200], "blocked_weathers": { "fog": "x" } })
	_assert_has_error(_make(objects), "不是天气")


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
	_assert_has_error(_make(objects), "通关方式必须恰好一种")


func test_level_needs_objective() -> void:
	var objects := _base_objects()
	objects.remove_at(1)
	_assert_has_error(_make(objects), "没有任何通关目标")


func test_catalog_order() -> void:
	var ids := LevelCatalog.get_ids()
	assert_eq(LevelCatalog.first(), ids[0])
	assert_eq(LevelCatalog.get_next(ids[-1]), "")
	assert_eq(LevelCatalog.get_next("missing"), "")


func test_field_gear_range() -> void:
	var objects := _base_objects()
	objects.append({ "type": "waterwheel", "id": "wheel", "pos": [1000, 0] })
	objects.append({ "type": "field", "name": "田", "pos": [1200, 0], "width": 300, "wheel": "wheel", "gear": 4 })
	_assert_has_error(_make(objects), "档位必须在")


func test_field_needs_wheel_unless_pump_only() -> void:
	var objects := _base_objects()
	objects.append({ "type": "field", "name": "田", "pos": [1200, 0], "width": 300 })
	_assert_has_error(_make(objects), "必须连接水车")


func _make_with_links(links: Array) -> LevelData:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [100, 0], "size": [300, 200] })
	objects.append({ "type": "lever", "id": "k", "pos": [900, 0], "requires": [{ "target": "w", "is": "deep" }] })
	var level := _make(objects)
	level.links.assign(links)
	return level


func test_valid_links() -> void:
	var level := _make_with_links([
		{ "when": "k", "event": "pulled", "do": "lower", "target": "w", "clean": true },
		{ "when": "r", "event": "rescued", "do": "unblock", "target": "w", "weather": "snow" },
		{ "when": "w", "event": "dry", "do": "message", "text": "干了" },
	])
	assert_eq(level.validate().size(), 0, str(level.validate()))


func test_link_unknown_event() -> void:
	_assert_has_error(_make_with_links([{ "when": "k", "event": "opened", "do": "message", "text": "x" }]), "没有事件")


func test_link_unknown_action() -> void:
	_assert_has_error(_make_with_links([{ "when": "k", "event": "pulled", "do": "explode", "target": "w" }]), "没有动作")


func test_link_missing_param() -> void:
	_assert_has_error(_make_with_links([{ "when": "k", "event": "pulled", "do": "unblock", "target": "w" }]), "缺少参数 weather")


func test_link_global_action_needs_no_target() -> void:
	_assert_has_error(_make_with_links([{ "when": "k", "event": "pulled", "do": "lower" }]), "全局动作")


func test_requires_unknown_condition() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [100, 0], "size": [300, 200] })
	objects.append({ "type": "lever", "pos": [900, 0], "requires": [{ "target": "w", "is": "boiling" }] })
	_assert_has_error(_make(objects), "只能是")


func test_requires_not_supported_by_type() -> void:
	var objects := _base_objects()
	objects.append({ "type": "checkpoint", "pos": [900, 0], "requires": [{ "target": "r", "is": "rescued" }] })
	_assert_has_error(_make(objects), "不支持 requires")


func test_cart_ending_replaces_goal() -> void:
	var objects := _base_objects()
	objects.remove_at(2)
	objects.append({ "type": "seed_cart", "id": "cart", "pos": [800, 0], "to_x": 3000 })
	var level := _make(objects)
	level.links.assign([{ "when": "cart", "event": "arrived", "do": "complete_level" }])
	assert_eq(level.validate().size(), 0, str(level.validate()))
