extends GutTest
## WeatherTarget 基类的 block / unblock 联动：任何目标都能禁用某种天气，reason 是拒绝提示


func test_block_rejects_cast_with_reason_and_unblock_restores() -> void:
	var target := WeatherTarget.new()
	add_child_autofree(target)
	target.do_block({ "weather": "rain", "reason": "水存不住，下雨也没有用" })
	var blocked := target.cast_weather(Weather.Type.RAIN, 1)
	assert_false(blocked.is_success)
	assert_eq(blocked.reason_text, "水存不住，下雨也没有用")
	# 其他天气不受影响
	var other := target.cast_weather(Weather.Type.WIND, 1)
	assert_ne(other.reason_text, "水存不住，下雨也没有用")
	target.do_unblock({ "weather": "rain" })
	var unblocked := target.cast_weather(Weather.Type.RAIN, 1)
	assert_eq(unblocked.reason_text, "这里施放不了天气", "解禁后回到基类的默认失败原因")
