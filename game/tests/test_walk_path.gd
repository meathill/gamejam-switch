extends GutTest
## WalkPath：平走匀速、跳跃走抛物线、同高也能强制跳

func test_flat_walk_is_constant_speed() -> void:
	var a := Vector2(0, -250)
	var b := Vector2(440, -250)
	assert_almost_eq(WalkPath.get_duration(a, b), 2.0, 0.001)
	for t: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var p := WalkPath.sample(a, b, t)
		assert_almost_eq(p.y, -250.0, 0.001)
		assert_almost_eq(p.x, 440.0 * t, 0.001)


func test_small_y_difference_still_flat() -> void:
	assert_true(WalkPath.is_flat(Vector2(0, -250), Vector2(100, -248.5)))
	assert_false(WalkPath.is_flat(Vector2(0, -250), Vector2(100, -255)))


func test_hop_endpoints_exact_and_midpoint_high() -> void:
	var a := Vector2(3100, -250)
	var b := Vector2(3140, -350)
	assert_eq(WalkPath.sample(a, b, 0.0), a)
	assert_eq(WalkPath.sample(a, b, 1.0), b)
	var apex := minf(a.y, b.y) - WalkPath.HOP_HEIGHT - 40.0 * WalkPath.HOP_SPAN_RISE
	assert_almost_eq(WalkPath.sample(a, b, 0.5).y, apex, 0.001)
	assert_lt(WalkPath.sample(a, b, 0.25).y, a.y)


func test_hop_down_also_arcs() -> void:
	var a := Vector2(7700, -700)
	var b := Vector2(7790, -760)
	var apex := -760.0 - WalkPath.HOP_HEIGHT - 90.0 * WalkPath.HOP_SPAN_RISE
	assert_almost_eq(WalkPath.sample(a, b, 0.5).y, apex, 0.001)


func test_long_hop_takes_longer() -> void:
	var a := Vector2(0, -250)
	assert_almost_eq(WalkPath.get_duration(a, Vector2(60, -350)), WalkPath.HOP_SECONDS, 0.001)
	assert_almost_eq(WalkPath.get_duration(a, Vector2(330, -350)), 1.0, 0.001)


func test_force_hop_on_flat_points() -> void:
	var a := Vector2(2690, -250)
	var b := Vector2(2940, -250)
	assert_almost_eq(WalkPath.get_duration(a, b, true), 250.0 / WalkPath.HOP_SPEED, 0.001)
	assert_eq(WalkPath.sample(a, b, 0.0, true), a)
	assert_eq(WalkPath.sample(a, b, 1.0, true), b)
	var apex := a.y - WalkPath.HOP_HEIGHT - 250.0 * WalkPath.HOP_SPAN_RISE
	assert_almost_eq(WalkPath.sample(a, b, 0.5, true).y, apex, 0.001)
