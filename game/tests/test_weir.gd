extends GutTest

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func _make_weir() -> Weir:
	var weir := Weir.new()
	weir.boards = PackedVector2Array([Vector2(600, 0), Vector2(700, 0), Vector2(800, 0)])
	return weir


func _make_passage(at: Vector2) -> Passage:
	var passage := Passage.new()
	passage.path = PackedVector2Array([at, at + Vector2(400, 200)])
	passage.position = at
	add_child_autofree(passage)
	return passage


func _make_setup(player_x: float) -> Dictionary:
	var passages: Array[Passage] = [
		_make_passage(Vector2(0, 0)),
		_make_passage(Vector2(100, 0)),
		_make_passage(Vector2(200, 0)),
	]
	var weir := _make_weir()
	weir.safe_points = [
		{ "route": passages[0], "from_x": 0.0 },
		{ "route": passages[1], "from_x": 100.0 },
		{ "route": passages[2], "from_x": 500.0 },
	]
	add_child_autofree(weir)
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	player.global_position = Vector2(player_x, 0)
	add_child_autofree(player)
	return { "weir": weir, "passages": passages, "player": player }


func test_wind_cycles_selection() -> void:
	var weir := _make_weir()
	add_child_autofree(weir)
	assert_eq(weir.selection, 0)
	var result := weir.cast_weather(Weather.Type.WIND, 1)
	assert_not_null(result, "cast_weather 必须同步返回结果")
	assert_true(result.is_success)
	assert_eq(weir.selection, 1)
	assert_true(weir.cast_weather(Weather.Type.WIND, 1).is_busy, "绞盘转动中返回 busy")
	await wait_seconds(0.7)
	weir.cast_weather(Weather.Type.WIND, -1)
	assert_eq(weir.selection, 2, "不管朝向都循环到下一段")
	await wait_seconds(0.7)
	assert_true(weir.cast_weather(Weather.Type.RAIN, 1).reason_text.contains("风"), "非风天气提示只有风能转动绞盘")


func test_confirm_in_order_emits_stage_events() -> void:
	var weir := _make_weir()
	add_child_autofree(weir)
	watch_signals(weir)
	weir.confirm()
	assert_signal_emitted_with_parameters(weir, "level_event", ["stage_1"])
	assert_true(weir.cast_weather(Weather.Type.WIND, 1).is_busy, "放倒结算期间风返回 busy")
	await wait_seconds(3.2)
	weir.cast_weather(Weather.Type.WIND, 1)
	weir.confirm()
	assert_signal_emitted_with_parameters(weir, "level_event", ["stage_2"])
	assert_eq(weir.state.stage, 2)
	assert_eq(weir.state.pressure, 1)
	assert_eq(GameState.gauge_value, 1)
	assert_eq(GameState.gauge_max, WeirRules.MAX_PRESSURE)


func test_wrong_order_collapses_and_enables_passage() -> void:
	var setup := _make_setup(200.0)
	var weir := setup["weir"] as Weir
	var passages := setup["passages"] as Array[Passage]
	var player := setup["player"] as Player
	await wait_physics_frames(3)
	watch_signals(weir)
	weir.cast_weather(Weather.Type.WIND, 1)
	await wait_seconds(0.7)
	weir.cast_weather(Weather.Type.WIND, 1)
	weir.confirm()
	assert_signal_emitted_with_parameters(weir, "level_event", ["collapsed"])
	await wait_seconds(2.6)
	# 小猫到过 x=200，最远安全点是 from_x=100 的第二条便道
	assert_true(passages[1].is_enabled)
	assert_false(passages[0].is_enabled)
	assert_false(passages[2].is_enabled)
	assert_almost_eq(player.global_position.x, passages[1].global_position.x, 1.0)
	assert_eq(GameState.checkpoint_position, passages[1].global_position)


func test_recover_keeps_stage_and_restores_pressure() -> void:
	var setup := _make_setup(200.0)
	var weir := setup["weir"] as Weir
	var passages := setup["passages"] as Array[Passage]
	await wait_physics_frames(3)
	weir.confirm()
	await wait_seconds(3.2)
	weir.cast_weather(Weather.Type.WIND, 1)
	await wait_seconds(0.7)
	weir.cast_weather(Weather.Type.WIND, 1)
	weir.confirm()
	assert_true(weir.state.is_collapsed)
	await wait_seconds(2.6)
	watch_signals(weir)
	weir.do_recover({})
	assert_signal_emitted_with_parameters(weir, "level_event", ["recovered"])
	assert_false(weir.state.is_collapsed)
	assert_eq(weir.state.stage, 1, "已经放倒的保留")
	assert_eq(weir.state.pressure, 2, "压力回到上一次正确泄流后的值")
	assert_false(passages[1].is_enabled, "便道在恢复后关闭")


func test_add_pressure_events() -> void:
	var weir := _make_weir()
	add_child_autofree(weir)
	watch_signals(weir)
	weir.do_add_pressure({})
	assert_signal_emitted_with_parameters(weir, "level_event", ["pressure_warning"])
	assert_eq(weir.state.pressure, 4)
	weir.do_add_pressure({})
	assert_signal_emitted_with_parameters(weir, "level_event", ["collapsed"])
	assert_true(weir.state.is_collapsed)
	weir.do_add_pressure({})
	assert_eq(weir.state.pressure, 5, "溃泄中涨压被忽略")
