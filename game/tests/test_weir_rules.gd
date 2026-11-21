extends GutTest


func test_next_selection_cycles() -> void:
	assert_eq(WeirRules.next_selection(0), 1)
	assert_eq(WeirRules.next_selection(1), 2)
	assert_eq(WeirRules.next_selection(2), 0)


func test_confirm_lowers_in_order_and_releases_pressure() -> void:
	var state := WeirRules.WeirState.new()
	var result := WeirRules.confirm(state, 0)
	assert_eq(result.outcome, WeirRules.Outcome.LOWERED)
	assert_eq(result.state.stage, 1)
	assert_eq(result.state.pressure, 2)
	assert_eq(result.state.stable_pressure, 2)
	result = WeirRules.confirm(result.state, 1)
	assert_eq(result.outcome, WeirRules.Outcome.LOWERED)
	assert_eq(result.state.stage, 2)
	assert_eq(result.state.pressure, 1)
	result = WeirRules.confirm(result.state, 2)
	assert_eq(result.outcome, WeirRules.Outcome.LOWERED)
	assert_eq(result.state.stage, 3)
	assert_eq(result.state.pressure, 0, "三段全放完后泄空")
	assert_eq(result.state.stable_pressure, 0)


func test_confirm_already_lowered() -> void:
	var state := WeirRules.WeirState.new()
	state = WeirRules.confirm(state, 0).state
	var result := WeirRules.confirm(state, 0)
	assert_eq(result.outcome, WeirRules.Outcome.ALREADY_LOWERED)
	assert_eq(result.state.stage, 1)
	assert_eq(result.state.pressure, 2)


func test_confirm_wrong_order_collapses() -> void:
	var result := WeirRules.confirm(WeirRules.WeirState.new(), 1)
	assert_eq(result.outcome, WeirRules.Outcome.COLLAPSE)
	assert_true(result.state.is_collapsed)
	assert_eq(result.state.stage, 0)
	var state := WeirRules.confirm(WeirRules.WeirState.new(), 0).state
	result = WeirRules.confirm(state, 2)
	assert_eq(result.outcome, WeirRules.Outcome.COLLAPSE)
	assert_eq(result.state.stage, 1, "已经正确放倒的保留")


func test_confirm_locked_after_collapse() -> void:
	var state := WeirRules.WeirState.new()
	state.is_collapsed = true
	assert_eq(WeirRules.confirm(state, 0).outcome, WeirRules.Outcome.LOCKED)


func test_recover_restores_stable_pressure() -> void:
	var state := WeirRules.WeirState.new()
	state.is_collapsed = true
	var recovered := WeirRules.recover(state)
	assert_false(recovered.is_collapsed)
	assert_eq(recovered.pressure, 3)
	# 下过一次雨（3→4）再放倒第一段（4→3）后崩溃，恢复仍回 stable 的 3
	var risen := WeirRules.add_pressure(WeirRules.WeirState.new()).state
	var lowered := WeirRules.confirm(risen, 0).state
	assert_eq(lowered.stable_pressure, 3)
	lowered.is_collapsed = true
	assert_eq(WeirRules.recover(lowered).pressure, 3)


func test_warning_at_four_and_collapse_at_five() -> void:
	var state := WeirRules.WeirState.new()
	var result := WeirRules.add_pressure(state)
	assert_eq(result.outcome, WeirRules.Outcome.WARNING)
	assert_eq(result.state.pressure, 4)
	result = WeirRules.add_pressure(result.state)
	assert_eq(result.outcome, WeirRules.Outcome.COLLAPSE)
	assert_true(result.state.is_collapsed)


func test_add_pressure_ignored_when_collapsed_or_fully_lowered() -> void:
	var collapsed := WeirRules.WeirState.new()
	collapsed.is_collapsed = true
	assert_eq(WeirRules.add_pressure(collapsed).outcome, WeirRules.Outcome.IGNORED)
	var done := WeirRules.WeirState.new()
	done.stage = WeirRules.BOARD_COUNT
	assert_eq(WeirRules.add_pressure(done).outcome, WeirRules.Outcome.IGNORED)


func test_add_pressure_raised_below_warning() -> void:
	var state := WeirRules.WeirState.new()
	state.pressure = 1
	var result := WeirRules.add_pressure(state)
	assert_eq(result.outcome, WeirRules.Outcome.RAISED)
	assert_eq(result.state.pressure, 2)


func test_pressure_never_below_zero() -> void:
	var state := WeirRules.WeirState.new()
	state.pressure = 0
	var result := WeirRules.confirm(state, 0)
	assert_eq(result.outcome, WeirRules.Outcome.LOWERED)
	assert_eq(result.state.pressure, 0)


func test_original_state_is_not_mutated() -> void:
	var state := WeirRules.WeirState.new()
	WeirRules.confirm(state, 0)
	WeirRules.add_pressure(state)
	assert_eq(state.stage, 0)
	assert_eq(state.pressure, 3)
	assert_false(state.is_collapsed)
