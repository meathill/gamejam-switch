extends GutTest
## 通关目标计数与天气限制


func before_each() -> void:
	GameState.reset_level()


func after_all() -> void:
	GameState.reset_level()


func test_objectives_by_kind() -> void:
	GameState.register_objective("resident")
	GameState.register_objective("resident")
	GameState.register_objective("field")
	assert_false(GameState.is_all_objectives_done())
	GameState.complete_objective("resident")
	assert_eq(GameState.get_objective("resident"), Vector2i(1, 2))
	assert_eq(GameState.get_remaining_text(), "还有 1 位居民没有得救，还有 1 块田没有恢复")
	GameState.complete_objective("resident")
	GameState.complete_objective("field")
	assert_true(GameState.is_all_objectives_done())
	assert_eq(GameState.get_remaining_text(), "")


func test_weather_rule_area_disables_weather() -> void:
	var area := WeatherRuleArea.new()
	area.disabled_weathers = [Weather.Type.RAIN]
	area.reason = "雨水会灌进井里"
	add_child_autofree(area)
	GameState.enter_weather_rule(area)
	assert_true(GameState.is_weather_disabled(Weather.Type.RAIN))
	assert_false(GameState.is_weather_disabled(Weather.Type.SUN))
	assert_eq(GameState.get_disabled_reason(Weather.Type.RAIN), "雨水会灌进井里")
	area.is_active = false
	assert_false(GameState.is_weather_disabled(Weather.Type.RAIN))
	area.is_active = true
	GameState.exit_weather_rule(area)
	assert_false(GameState.is_weather_disabled(Weather.Type.RAIN))


func test_interact_available_while_any_source_is_near() -> void:
	var first := Node.new()
	var second := Node.new()
	GameState.set_interact_available(first, true)
	GameState.set_interact_available(second, true)
	GameState.set_interact_available(first, false)
	assert_true(GameState.is_interact_available)
	GameState.set_interact_available(second, false)
	assert_false(GameState.is_interact_available)
	first.free()
	second.free()


func test_blocked_weather_on_target() -> void:
	var zone := WaterZone.new()
	zone.blocked_weathers = { "snow": "会冻坏站顶的居民" }
	add_child_autofree(zone)
	var result := zone.cast_weather(Weather.Type.SNOW, 1)
	assert_false(result.is_success)
	assert_eq(result.reason_text, "会冻坏站顶的居民")
	assert_true(zone.cast_weather(Weather.Type.SUN, 1).is_success)
