extends GutTest
## 望远镜：按 E 在看 / 返回间切换，分别发出 lookout_started / lookout_ended

func _make_scope() -> Telescope:
	var spot := WeatherSpot.new()
	spot.display_name = "上游湖口"
	spot.view = Rect2(7000, -450, 1200, 1)
	add_child_autofree(spot)
	var scope := Telescope.new()
	scope.spot = spot
	add_child_autofree(scope)
	return scope


func test_interact_toggles_lookout() -> void:
	var scope := _make_scope()
	watch_signals(GameState)
	assert_eq(scope.get_action_name(), "望远镜：上游湖口")
	scope._interact()
	assert_signal_emitted(GameState, "lookout_started")
	assert_eq(get_signal_parameters(GameState, "lookout_started")[0], Vector2(7600.0, -449.5))
	assert_eq(scope.get_action_name(), "返回")
	scope._interact()
	assert_signal_emitted(GameState, "lookout_ended")
	assert_eq(scope.get_action_name(), "望远镜：上游湖口")
