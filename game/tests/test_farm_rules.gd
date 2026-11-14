extends GutTest
## 第二关规则：水车档位循环、农田状态机

const S := FarmRules.FieldState


func _apply(weather: Weather.Type, state: FarmRules.FieldState, pipe_open: bool = true, can_flood: bool = false) -> FarmRules.FieldResult:
	return FarmRules.apply_field(weather, state, pipe_open, can_flood, false)


func test_gear_cycles_through_three_positions() -> void:
	var gear := 0
	var visited: Array[int] = []
	for step in 5:
		gear = FarmRules.next_gear(gear)
		visited.append(gear)
	assert_eq(visited, [1, 2, 3, 1, 2])


func test_dry_field_needs_pipe_open() -> void:
	var blocked := _apply(Weather.Type.RAIN, S.DRY, false)
	assert_false(blocked.is_success)
	assert_string_contains(blocked.reason_text, "档位 1")
	var restored := _apply(Weather.Type.RAIN, S.DRY, true)
	assert_true(restored.is_success)
	assert_eq(restored.state, S.RESTORED)


func test_waterlogged_field_must_dry_before_rain() -> void:
	assert_false(_apply(Weather.Type.RAIN, S.WATERLOGGED).is_success)
	var dried := _apply(Weather.Type.SUN, S.WATERLOGGED)
	assert_eq(dried.state, S.DRY)
	assert_eq(_apply(Weather.Type.RAIN, dried.state).state, S.RESTORED)


func test_snow_freezes_mud_and_sun_thaws_it() -> void:
	var frozen := _apply(Weather.Type.SNOW, S.WATERLOGGED)
	assert_eq(frozen.state, S.MUD_ICE)
	assert_false(_apply(Weather.Type.RAIN, S.MUD_ICE).is_success)
	assert_eq(_apply(Weather.Type.SUN, S.MUD_ICE).state, S.WATERLOGGED)


func test_restored_lowland_floods_again() -> void:
	var flooded := _apply(Weather.Type.RAIN, S.RESTORED, true, true)
	assert_true(flooded.is_success)
	assert_eq(flooded.state, S.WATERLOGGED)
	assert_false(_apply(Weather.Type.RAIN, S.RESTORED, true, false).is_success)


func test_pump_only_field_ignores_weather() -> void:
	for weather: int in Weather.Type.values():
		assert_false(FarmRules.apply_field(weather, S.DRY, true, false, true).is_success)


func test_wind_never_changes_a_field() -> void:
	for state: int in S.values():
		assert_false(_apply(Weather.Type.WIND, state).is_success)
