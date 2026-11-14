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


func _make_station(channel: WaterZone, plaza: WaterZone) -> Lever:
	var lever := Lever.new()
	lever.requires_deep = channel
	add_child_autofree(lever)
	var station := DrainageStation.new()
	station.switch = lever
	station.drained_zone = plaza
	add_child_autofree(station)
	return lever


func test_drainage_switch_is_locked_until_channel_is_full() -> void:
	var channel := _make_zone(1)
	var plaza := _make_zone(2, true)
	add_child_autofree(channel)
	add_child_autofree(plaza)
	var lever := _make_station(channel, plaza)
	lever.call("_interact")
	assert_false(lever.is_pulled)


func test_drainage_station_drains_and_cleans_target() -> void:
	var channel := _make_zone(2)
	var plaza := _make_zone(2, true)
	add_child_autofree(channel)
	add_child_autofree(plaza)
	var lever := _make_station(channel, plaza)
	lever.call("_interact")
	assert_true(lever.is_pulled)
	await wait_for_signal(plaza.state_changed, TIMEOUT)
	assert_eq(plaza.level, 1)
	assert_false(plaza.is_polluted)
