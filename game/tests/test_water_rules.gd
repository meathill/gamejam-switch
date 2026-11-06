extends GutTest



func _apply(weather: Weather.Type, level: int, frozen: bool = false, polluted: bool = false) -> WaterRules.Result:
	return WaterRules.apply(weather, WaterState.new(level, frozen, polluted))


func _assert_state(result: WaterRules.Result, level: int, frozen: bool) -> void:
	assert_true(result.is_success, "expected success, got reason %s" % result.reason)
	assert_eq(result.state.level, level)
	assert_eq(result.state.is_frozen, frozen)


func _assert_fail(result: WaterRules.Result, reason: WaterRules.Reason) -> void:
	assert_false(result.is_success)
	assert_eq(result.reason, reason)


func test_rain_raises_liquid_level_one_step() -> void:
	_assert_state(_apply(Weather.Type.RAIN, 0), 1, false)
	_assert_state(_apply(Weather.Type.RAIN, 1), 2, false)


func test_rain_caps_at_max_level() -> void:
	_assert_fail(_apply(Weather.Type.RAIN, 2), WaterRules.Reason.LEVEL_FULL)


func test_rain_cannot_raise_ice() -> void:
	_assert_fail(_apply(Weather.Type.RAIN, 1, true), WaterRules.Reason.FROZEN_NO_RISE)


func test_rain_works_on_polluted_water() -> void:
	var result := _apply(Weather.Type.RAIN, 1, false, true)
	_assert_state(result, 2, false)
	assert_true(result.state.is_polluted)


func test_snow_freezes_and_keeps_level() -> void:
	_assert_state(_apply(Weather.Type.SNOW, 1), 1, true)
	_assert_state(_apply(Weather.Type.SNOW, 2), 2, true)


func test_snow_fails_without_water_or_when_frozen() -> void:
	_assert_fail(_apply(Weather.Type.SNOW, 0), WaterRules.Reason.NO_WATER)
	_assert_fail(_apply(Weather.Type.SNOW, 2, true), WaterRules.Reason.ALREADY_FROZEN)


func test_snow_cannot_freeze_polluted_water() -> void:
	_assert_fail(_apply(Weather.Type.SNOW, 2, false, true), WaterRules.Reason.POLLUTED_NO_FREEZE)


func test_sun_melts_ice_without_lowering_level() -> void:
	_assert_state(_apply(Weather.Type.SUN, 2, true), 2, false)


func test_sun_lowers_liquid_one_step() -> void:
	_assert_state(_apply(Weather.Type.SUN, 2), 1, false)
	_assert_state(_apply(Weather.Type.SUN, 1), 0, false)


func test_sun_fails_on_dry_or_polluted() -> void:
	_assert_fail(_apply(Weather.Type.SUN, 0), WaterRules.Reason.ALREADY_DRY)
	_assert_fail(_apply(Weather.Type.SUN, 2, false, true), WaterRules.Reason.POLLUTED_NO_EVAPORATE)


func test_wind_needs_deep_liquid() -> void:
	assert_true(_apply(Weather.Type.WIND, 2).is_success)
	_assert_fail(_apply(Weather.Type.WIND, 1), WaterRules.Reason.TOO_SHALLOW)
	_assert_fail(_apply(Weather.Type.WIND, 0), WaterRules.Reason.TOO_SHALLOW)
	_assert_fail(_apply(Weather.Type.WIND, 2, true), WaterRules.Reason.FROZEN_NO_WIND)


func test_failed_apply_does_not_mutate_input() -> void:
	var state := WaterState.new(2, false, false)
	WaterRules.apply(Weather.Type.RAIN, state)
	WaterRules.apply(Weather.Type.SUN, state)
	assert_eq(state.level, 2)


func test_every_reason_has_text_entry() -> void:
	for reason: int in WaterRules.Reason.values():
		assert_true(WaterRules._REASON_TEXTS.has(reason), "missing text for %s" % reason)


func test_find_next_dock() -> void:
	var none: Array[int] = []
	assert_eq(WaterRules.find_next_dock(0, 1, 3, none), 1)
	assert_eq(WaterRules.find_next_dock(0, -1, 3, none), -1)
	assert_eq(WaterRules.find_next_dock(2, 1, 3, none), -1)
	assert_eq(WaterRules.find_next_dock(1, 0, 3, none), -1)
	var occupied: Array[int] = [2]
	assert_eq(WaterRules.find_next_dock(1, 1, 3, occupied), -1)


func test_weather_cycle_wraps() -> void:
	assert_eq(Weather.cycle(Weather.Type.SUN, 1), Weather.Type.RAIN)
	assert_eq(Weather.cycle(Weather.Type.RAIN, -1), Weather.Type.SUN)
