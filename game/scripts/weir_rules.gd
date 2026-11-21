@tool
class_name WeirRules
extends RefCounted
## 三级活动堰的规则。纯逻辑，不依赖节点。
## 三块堰板只能按序放倒（下 → 中 → 上），stage 就是已放倒的段数；
## 压力涨到 5 格或放倒顺序错了都会溃泄；恢复后回到最近一次正确泄流后的压力。

const BOARD_COUNT := 3
const MAX_PRESSURE := 5
const WARNING_PRESSURE := 4
const INITIAL_PRESSURE := 3
const BOARD_NAMES: Array[String] = ["下段", "中段", "上段"]

enum Outcome { LOWERED, ALREADY_LOWERED, COLLAPSE, LOCKED, RAISED, WARNING, IGNORED }


class WeirState:
	extends RefCounted

	var stage: int = 0
	var pressure: int = INITIAL_PRESSURE
	## 最近一次正确泄流后的压力，溃泄恢复时回到它
	var stable_pressure: int = INITIAL_PRESSURE
	var is_collapsed: bool = false


	func copy() -> WeirState:
		var state := WeirState.new()
		state.stage = stage
		state.pressure = pressure
		state.stable_pressure = stable_pressure
		state.is_collapsed = is_collapsed
		return state


class Result:
	extends RefCounted

	var outcome: Outcome
	var state: WeirState


	func _init(result_outcome: Outcome, next_state: WeirState) -> void:
		outcome = result_outcome
		state = next_state


## 绞盘循环选中：下 → 中 → 上 → 下
static func next_selection(selected: int) -> int:
	return (selected + 1) % BOARD_COUNT


## 在操作台确认放倒绞盘选中的堰板
static func confirm(state: WeirState, selected: int) -> Result:
	if state.is_collapsed:
		return Result.new(Outcome.LOCKED, state.copy())
	if selected < state.stage:
		return Result.new(Outcome.ALREADY_LOWERED, state.copy())
	if selected > state.stage:
		var collapsed := state.copy()
		collapsed.is_collapsed = true
		return Result.new(Outcome.COLLAPSE, collapsed)
	var next := state.copy()
	next.stage += 1
	next.pressure = 0 if next.stage == BOARD_COUNT else maxi(next.pressure - 1, 0)
	next.stable_pressure = next.pressure
	return Result.new(Outcome.LOWERED, next)


## 上游来水 / 沙洲变深，压力 +1
static func add_pressure(state: WeirState) -> Result:
	if state.is_collapsed or state.stage == BOARD_COUNT:
		return Result.new(Outcome.IGNORED, state.copy())
	var next := state.copy()
	next.pressure += 1
	if next.pressure >= MAX_PRESSURE:
		next.is_collapsed = true
		return Result.new(Outcome.COLLAPSE, next)
	if next.pressure == WARNING_PRESSURE:
		return Result.new(Outcome.WARNING, next)
	return Result.new(Outcome.RAISED, next)


## 溃泄后恢复：取消溃泄、压力回到 stable_pressure，已放倒的板保留
static func recover(state: WeirState) -> WeirState:
	var next := state.copy()
	next.is_collapsed = false
	next.pressure = next.stable_pressure
	return next
