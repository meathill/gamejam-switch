extends GutTest

const TIMEOUT := 3.0


func _make_zone(level: int, polluted: bool = false, docks: PackedFloat32Array = PackedFloat32Array()) -> WaterZone:
	var zone := WaterZone.new()
	zone.size = Vector2(1000, 260)
	zone.level = level
	zone.is_polluted = polluted
	zone.dock_positions = docks
	return zone


func _add_raft(zone: WaterZone, dock_index: int) -> Raft:
	var raft := Raft.new()
	raft.dock_index = dock_index
	zone.add_child(raft)
	return raft


func test_rain_raises_level_and_floats_raft() -> void:
	var zone := _make_zone(1, false, PackedFloat32Array([100, 500, 900]))
	var raft := _add_raft(zone, 0)
	add_child_autofree(zone)
	var resting_y := raft.position.y
	assert_true(zone.apply_weather(Weather.Type.RAIN).is_success)
	await wait_for_signal(zone.state_changed, TIMEOUT)
	assert_eq(zone.level, 2)
	assert_lt(raft.position.y, resting_y, "raft should float up")


func test_wind_moves_raft_toward_direction() -> void:
	var zone := _make_zone(2, false, PackedFloat32Array([100, 500, 900]))
	var raft := _add_raft(zone, 0)
	add_child_autofree(zone)
	assert_true(zone.apply_weather(Weather.Type.WIND, 1).is_success)
	await wait_for_signal(zone.state_changed, TIMEOUT)
	assert_eq(raft.dock_index, 1)
	assert_almost_eq(raft.position.x, 500.0, 0.5)


func test_wind_fails_at_lane_end() -> void:
	var zone := _make_zone(2, false, PackedFloat32Array([100, 500]))
	_add_raft(zone, 0)
	add_child_autofree(zone)
	assert_eq(zone.apply_weather(Weather.Type.WIND, -1).reason, WaterRules.Reason.NO_DOCK)


func test_wind_fails_without_raft() -> void:
	var zone := _make_zone(2)
	add_child_autofree(zone)
	assert_eq(zone.apply_weather(Weather.Type.WIND, 1).reason, WaterRules.Reason.NO_RAFT)


func test_frozen_zone_locks_raft() -> void:
	var zone := _make_zone(2, false, PackedFloat32Array([100, 500]))
	_add_raft(zone, 0)
	add_child_autofree(zone)
	zone.apply_weather(Weather.Type.SNOW)
	await wait_for_signal(zone.state_changed, TIMEOUT)
	assert_eq(zone.apply_weather(Weather.Type.WIND, 1).reason, WaterRules.Reason.FROZEN_NO_WIND)


func test_cast_is_rejected_while_animating() -> void:
	var zone := _make_zone(0)
	add_child_autofree(zone)
	assert_true(zone.apply_weather(Weather.Type.RAIN).is_success)
	assert_eq(zone.apply_weather(Weather.Type.RAIN).reason, WaterRules.Reason.BUSY)
	await wait_for_signal(zone.state_changed, TIMEOUT)
	assert_eq(zone.level, 1)


func _make_switch(channel: WaterZone) -> Lever:
	var lever := Lever.new()
	lever.lever_name = "排水开关"
	lever.requirements.append(Requirement.new(channel, { "is": "deep" }))
	add_child_autofree(lever)
	return lever


func _locked_message(channel_level: int, frozen: bool = false) -> String:
	var channel := _make_zone(channel_level)
	channel.zone_name = "排水槽"
	channel.is_frozen = frozen
	add_child_autofree(channel)
	return Requirement.first_unmet(_make_switch(channel).requirements)


## 回归：排水槽只下过一次雨（浅水）时，开关还提示“排水槽是干的”，让人以为雨水没用
func test_switch_requirement_explains_what_is_missing() -> void:
	assert_string_contains(_locked_message(0), "干")
	assert_string_contains(_locked_message(1), "不够")
	assert_string_contains(_locked_message(2, true), "冻")
	assert_eq(_locked_message(2), "")


func test_custom_hint_overrides_generated_reason() -> void:
	var channel := _make_zone(0)
	add_child_autofree(channel)
	var requirement := Requirement.new(channel, { "is": "deep", "hint": "先灌满排水槽" })
	assert_eq(requirement.get_unmet_reason(), "先灌满排水槽")


func test_station_starts_after_switch_is_pulled() -> void:
	var channel := _make_zone(2)
	add_child_autofree(channel)
	var lever := _make_switch(channel)
	var station := DrainageStation.new()
	station.start_delay = 0.1
	station.requirements.append(Requirement.new(lever, { "is": "pulled" }))
	add_child_autofree(station)
	await wait_physics_frames(3)
	assert_false(station.is_running)
	lever.call("_interact")
	await wait_for_signal(station.level_event, TIMEOUT)
	assert_true(station.is_running)


func test_lower_action_drains_and_cleans() -> void:
	var plaza := _make_zone(2, true)
	add_child_autofree(plaza)
	plaza.do_lower({ "clean": true })
	await wait_for_signal(plaza.state_changed, TIMEOUT)
	assert_eq(plaza.level, 1)
	assert_false(plaza.is_polluted)


func test_unblock_action_allows_weather_again() -> void:
	var plaza := _make_zone(1)
	plaza.blocked_weathers = { "snow": "会冻坏站顶的大叔" }
	add_child_autofree(plaza)
	assert_false(plaza.cast_weather(Weather.Type.SNOW, 1).is_success)
	plaza.do_unblock({ "weather": "snow" })
	assert_true(plaza.cast_weather(Weather.Type.SNOW, 1).is_success)
