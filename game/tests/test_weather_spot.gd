extends GutTest
## 远程天气目标：view 是特效和镜头对准的真实地点，选中范围本身不可见


func _make_spot() -> WeatherSpot:
	var spot := WeatherSpot.new()
	spot.position = Vector2(-200, -950)
	spot.size = Vector2(450, 350)
	spot.view = Rect2(7000, -450, 1200, 1)
	add_child(spot)
	return spot


func test_effect_rect_and_view_center_come_from_view() -> void:
	var spot := _make_spot()
	assert_eq(spot.get_effect_rect(), Rect2(7000, -450, 1200, 1))
	assert_eq(spot.get_view_center(), Vector2(7600, -449.5))
	spot.free()


func test_target_rect_is_selection_area() -> void:
	var spot := _make_spot()
	assert_eq(spot.get_target_rect(), Rect2(Vector2(-200, -950), Vector2(450, 350)))
	spot.free()


func test_spot_is_in_group_and_delays_effect() -> void:
	var spot := _make_spot()
	assert_true(spot.is_in_group(WeatherSpot.SPOTS_GROUP))
	assert_eq(spot.get_effect_delay(), Level.FOCUS_PAN_SECONDS)
	spot.free()
