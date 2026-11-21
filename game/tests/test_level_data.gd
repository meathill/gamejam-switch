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


func test_gondola_needs_to() -> void:
	var objects := _base_objects()
	objects.append({ "type": "gondola", "pos": [800, 0] })
	_assert_has_error(_make(objects), "缺少字段 to")


func test_evacuee_needs_name() -> void:
	var objects := _base_objects()
	objects.append({ "type": "evacuee", "pos": [800, 0] })
	_assert_has_error(_make(objects), "缺少字段 name")


func test_passage_path_needs_two_points() -> void:
	var objects := _base_objects()
	objects.append({ "type": "passage", "pos": [800, 0], "path": [[800, 0]] })
	_assert_has_error(_make(objects), "path 至少要 2 个点")


func test_weather_spot_accepts_must_be_weather() -> void:
	var objects := _base_objects()
	objects.append({ "type": "weather_spot", "pos": [800, 0], "size": [300, 200], "name": "雪线", "accepts": ["snow", "hail"] })
	_assert_has_error(_make(objects), "不是天气")


func test_gauge_must_reference_weir() -> void:
	var objects := _base_objects()
	objects.append({ "type": "water", "id": "w", "name": "水", "pos": [600, 0], "size": [300, 200] })
	objects.append({ "type": "gauge", "pos": [900, 0], "weir": "w" })
	_assert_has_error(_make(objects), "只能引用")


func test_raft_ashore_is_a_water_event() -> void:
	var level := _make_with_links([{ "when": "w", "event": "raft_ashore", "do": "message", "text": "上岸了" }])
	assert_eq(level.validate().size(), 0, str(level.validate()))


func _weir_objects(safe_points: Array = []) -> Array:
	var objects := _base_objects()
	var index := 0
	for route: String in ["pa", "pb", "pc"]:
		objects.append({ "type": "passage", "id": route, "pos": [index * 100, 0], "path": [[index * 100, 0], [index * 100 + 200, 0]] })
		index += 1
	var weir := {
		"type": "weir", "id": "weir", "pos": [1000, 0],
		"boards": [[1100, 0], [1200, 0], [1300, 0]],
		"safe_points": [
			{ "route": "pa", "from_x": 0 }, { "route": "pb", "from_x": 100 }, { "route": "pc", "from_x": 200 },
		],
	}
	if not safe_points.is_empty():
		weir["safe_points"] = safe_points
	objects.append(weir)
	return objects


func test_weir_is_valid() -> void:
	var level := _make(_weir_objects())
	assert_eq(level.validate().size(), 0, str(level.validate()))


func test_weir_needs_three_boards() -> void:
	var objects := _weir_objects()
	objects[-1]["boards"] = [[1100, 0], [1200, 0]]
	_assert_has_error(_make(objects), "boards 必须恰好")


func test_weir_safe_point_route_must_exist() -> void:
	var objects := _weir_objects([{ "route": "nowhere", "from_x": 0 }])
	_assert_has_error(_make(objects), "不存在")


func test_weir_safe_point_route_must_be_passage() -> void:
	var objects := _weir_objects([{ "route": "weir", "from_x": 0 }])
	_assert_has_error(_make(objects), "必须是 passage")


func test_weir_requires_stage_range() -> void:
	var objects := _weir_objects()
	objects.append({ "type": "lever", "pos": [1500, 0], "requires": [{ "target": "weir", "stage": 4 }] })
	_assert_has_error(_make(objects), "堰板段数必须在")


func test_weir_pressure_range() -> void:
	var objects := _weir_objects()
	objects[-1]["pressure"] = 6
	_assert_has_error(_make(objects), "pressure 必须在")
