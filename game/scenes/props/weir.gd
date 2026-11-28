@tool
class_name Weir
extends WeatherTarget
## 三级活动堰：风转动绞盘循环选中下/中/上段，操作台（WeirConsole 子节点）按 E 确认放倒。
## 放倒一块板时镜头先补间到堰板（request_focus 排在联动镜头之前），板角度 0→-80° 补间、
## 随后水帘淡入；三段都放倒后湖面到跌水潭连成一整条阶梯水帘。
## 顺序错了或压力涨到 5 格 → 溃泄：小猫送回最远安全点并启用对应的应急便道；
## 下游河湾变回浅水时 do_recover 恢复。原点在绞盘风车地面中点。

signal pressure_changed(value: int)

const WINCH_TEXTURE := preload("res://assets/sprites/valley/winch.png")
const WINCH_DIAMETER := 360.0
## 绞盘中心在原点上方的高度
const WINCH_HEIGHT := 300.0
const BOARD_COLORS: Array[Color] = [Color("3fa69a"), Color("e0a030"), Color("c8c8c0")]
const TURN_SECONDS := 0.5
## 放倒一块板的整段演出时长：镜头补间 0.4 + 看板 BOARD_FOCUS_SECONDS + 后果镜头补间 0.4 + 停留 ≤3.0
const LOWER_SECONDS := 7.0
## 放倒一块板时，镜头停在堰板上的时长
const BOARD_FOCUS_SECONDS := 3.0
## 板角度补间和之后水帘淡入的时长
const BOARD_LOWER_SECONDS := 0.8
const CASCADE_FADE_SECONDS := 0.5
const COLLAPSE_DELAY := 2.2
const TARGET_HALF_WIDTH := 400.0
const TARGET_HEIGHT_ABOVE := 600.0
const LABEL_FONT_SIZE := 22

## 三块堰板的位置（世界坐标，板的底边中点）
var boards: PackedVector2Array = PackedVector2Array()
## { "route": Passage, "from_x": float }，从左到右的安全点；位置就是便道起点
var safe_points: Array[Dictionary] = []
var initial_pressure: int = WeirRules.INITIAL_PRESSURE

var state := WeirRules.WeirState.new()
var selection: int = 0
var pressure: int:
	get:
		return state.pressure
var stage: int:
	get:
		return state.stage
var is_collapsed: bool:
	get:
		return state.is_collapsed

var _max_x: float = -INF
var _is_busy: bool = false
var _is_turning: bool = false
var _pending_pressure: int = 0
var _collapse_timer: float = -1.0
## 被冲开的堰板序号（-1 没有，如满压溃泄）
var _blown_board: int = -1
var _active_route: Passage = null
## 每块板自己的显示角度（度），放倒动画补间它
var _board_angles: Array[float] = [0.0, 0.0, 0.0]
## 每块板水帘的透明度；湖口水帘单独一个
var _cascade_alphas: Array[float] = [0.0, 0.0, 0.0]
var _cascade_time: float = 0.0
var _winch_angle: float = 0.0:
	set(value):
		_winch_angle = value
		queue_redraw()
var _highlight_color: Color = Color.TRANSPARENT


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	state.pressure = initial_pressure
	state.stable_pressure = initial_pressure
	add_child(WeirConsole.new())
	for index in boards.size():
		add_child(_make_board_label(index))
	_update_gauge()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _has_flow():
		return
	_cascade_time += delta
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _collapse_timer >= 0.0:
		_collapse_timer -= delta
		if _collapse_timer < 0.0:
			_send_player_to_safety()
	var player := _get_player()
	if player:
		_max_x = maxf(_max_x, player.global_position.x)


func _get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _has_flow() -> bool:
	return _cascade_alphas.any(func(alpha: float) -> bool: return alpha > 0.0)


func is_busy() -> bool:
	return _is_busy


func get_display_name() -> String:
	return display_name if display_name else "活动堰"


func get_status_text() -> String:
	return "绞盘指向：%s · 已放倒 %d/%d · 水尺 %d/%d" % [
		WeirRules.BOARD_NAMES[selection], state.stage, WeirRules.BOARD_COUNT, state.pressure, WeirRules.MAX_PRESSURE]


func get_target_rect() -> Rect2:
	return Rect2(
		global_position + Vector2(-TARGET_HALF_WIDTH, -TARGET_HEIGHT_ABOVE),
		Vector2(TARGET_HALF_WIDTH * 2.0, TARGET_HEIGHT_ABOVE + 150.0))


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x - WINCH_DIAMETER / 2.0, global_position.y - WINCH_HEIGHT, WINCH_DIAMETER, 1.0)


## 三块板都能入画的镜头焦点（中段板的底边）
func get_boards_focus() -> Vector2:
	if boards.size() < WeirRules.BOARD_COUNT:
		return global_position
	return Vector2((boards[0].x + boards[WeirRules.BOARD_COUNT - 1].x) * 0.5, boards[1].y)


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


## 条件 { "stage": n } / { "is": collapsed|stable }
func get_unmet_reason(condition: Dictionary) -> String:
	if condition.has("stage"):
		var target := int(condition["stage"])
		return "" if state.stage >= target else "还要先放倒%s堰板" % WeirRules.BOARD_NAMES[state.stage]
	match condition.get("is", ""):
		"collapsed":
			return "" if state.is_collapsed else "堰体还没有溃泄"
		"stable":
			return "" if not state.is_collapsed else "堰体还在溃泄中"
	return ""


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if _is_busy or _is_turning:
		return CastResult.busy()
	if state.is_collapsed:
		return CastResult.fail("溃泄中，绞盘被锁住了")
	if weather != Weather.Type.WIND:
		return CastResult.fail("只有风能转动绞盘")
	selection = WeirRules.next_selection(selection)
	GameState.post_message("绞盘指向：%s" % WeirRules.BOARD_NAMES[selection])
	_turn_winch()
	return CastResult.ok()


## 绞盘贴图转向选中段；转完前拒绝再次施放，防止连点
func _turn_winch() -> void:
	_is_turning = true
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "_winch_angle", selection * TAU / 3.0, TURN_SECONDS)
	await tween.finished
	_is_turning = false
	state_changed.emit(self)


## 操作台确认放倒选中的堰板。先把看堰板的镜头排进队列，再发 stage 事件，
## 联动里「后果」的 focus / 水位变化就排在这之后依次播放
func confirm() -> void:
	var result := WeirRules.confirm(state, selection)
	match result.outcome:
		WeirRules.Outcome.LOWERED:
			state = result.state
			GameState.post_message("%s堰板放倒了" % WeirRules.BOARD_NAMES[selection])
			GameState.request_focus(get_boards_focus(), BOARD_FOCUS_SECONDS)
			level_event.emit("stage_%d" % state.stage)
			_lower_board(selection)
			_update_gauge()
			state_changed.emit(self)
			_hold_busy()
		WeirRules.Outcome.ALREADY_LOWERED:
			GameState.post_warning("这一段已经放下")
		WeirRules.Outcome.COLLAPSE:
			state = result.state
			_blown_board = selection
			_start_collapse()
		_:
			pass


## 放倒动画：等镜头补间到位（FOCUS_PAN_SECONDS），板角 0 → -80°，水帘随后淡入
func _lower_board(index: int) -> void:
	await get_tree().create_timer(Level.FOCUS_PAN_SECONDS, false).timeout
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(_set_board_angle.bind(index), 0.0, WeirDrawing.LOWERED_ANGLE, BOARD_LOWER_SECONDS)
	tween.tween_method(_set_cascade_alpha.bind(index), 0.0, 1.0, CASCADE_FADE_SECONDS)


func _set_board_angle(angle: float, index: int) -> void:
	_board_angles[index] = angle
	queue_redraw()


func _set_cascade_alpha(alpha: float, index: int) -> void:
	_cascade_alphas[index] = alpha


## 放倒堰板后的忙碌期覆盖整段演出：期间风和确认都忙，涨压先记下再补结算
func _hold_busy() -> void:
	_is_busy = true
	await get_tree().create_timer(LOWER_SECONDS, false).timeout
	_is_busy = false
	var count := _pending_pressure
	_pending_pressure = 0
	for index in count:
		_apply_pressure()
	queue_redraw()
	state_changed.emit(self)


func do_add_pressure(_params: Dictionary) -> void:
	if _is_busy:
		_pending_pressure += 1
		return
	_apply_pressure()


func _apply_pressure() -> void:
	var result := WeirRules.add_pressure(state)
	match result.outcome:
		WeirRules.Outcome.RAISED:
			state = result.state
			GameState.post_message("水尺涨到 %d 格" % state.pressure)
		WeirRules.Outcome.WARNING:
			state = result.state
			GameState.post_warning("水尺 %d 格！再涨一次就会溃泄" % WeirRules.WARNING_PRESSURE)
			level_event.emit("pressure_warning")
		WeirRules.Outcome.COLLAPSE:
			state = result.state
			_blown_board = -1
			_start_collapse()
			return
		_:
			return
	_update_gauge()
	state_changed.emit(self)


func _start_collapse() -> void:
	level_event.emit("collapsed")
	GameState.post_warning("溃泄！洪水冲向下游……")
	_update_gauge()
	state_changed.emit(self)
	_collapse_timer = COLLAPSE_DELAY
	queue_redraw()


## 溃泄 1.5 秒后：小猫送到到过的最远安全点，设为检查点并启用那条便道
func _send_player_to_safety() -> void:
	var best: Dictionary = {}
	for point in safe_points:
		if _max_x >= point["from_x"]:
			best = point
	if best.is_empty():
		return
	var route := best["route"] as Passage
	_active_route = route
	var player := _get_player()
	if player:
		player.respawn(route.global_position)
	GameState.checkpoint_position = route.global_position
	route.do_enable({})
	GameState.post_message("沿发光的应急便道去下游河湾，用雪筑冰堰，再用日照退水")


## 下游河湾变回浅水后恢复：误开的板复位，已放倒的保留
func do_recover(_params: Dictionary) -> void:
	if not state.is_collapsed:
		return
	state = WeirRules.recover(state)
	_blown_board = -1
	_update_gauge()
	state_changed.emit(self)
	level_event.emit("recovered")
	if _active_route:
		_active_route.do_disable({})
		_active_route.carry_back()
		_active_route = null
	GameState.post_message("水退了，堰体恢复到上一次正确泄流后的状态")
	queue_redraw()


func _update_gauge() -> void:
	GameState.set_gauge(state.pressure, WeirRules.MAX_PRESSURE)
	pressure_changed.emit(state.pressure)


## 堰板上方的段名标签。Web 上 draw_string 没有中文字形，必须用 Label
func _make_board_label(index: int) -> Label:
	var label := Label.new()
	label.text = WeirRules.BOARD_NAMES[index]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.size = Vector2(90, 30)
	label.position = boards[index] - global_position + Vector2(-45, -WeirDrawing.BOARD_SIZE.y - 42)
	return label


func _draw() -> void:
	# 三块堰板：底边在 boards 给的世界坐标上，各自按 _board_angles 显示
	for index in boards.size():
		var base := boards[index] - global_position
		var is_selected := index == selection and not state.is_collapsed
		var is_blown := index == _blown_board
		var angle := _board_angles[index] if index < state.stage else 0.0
		WeirDrawing.draw_board(self, base, angle, BOARD_COLORS[index], is_selected and not is_blown, is_blown)
	# 水帘：每块放倒的板一道（被冲开的那块没有）；stage 3 后湖口再接一段
	for index in boards.size():
		if index < state.stage and index != _blown_board and _cascade_alphas[index] > 0.0:
			var path := WeirDrawing.cascade_path(boards, index, global_position)
			WeirDrawing.draw_cascade(self, path[0], path[1], path[2], _cascade_alphas[index], _cascade_time)
	# 绞盘风车，按选中角度旋转
	var winch_size := WINCH_TEXTURE.get_size() * WINCH_DIAMETER / WINCH_TEXTURE.get_width()
	draw_set_transform(Vector2(0, -WINCH_HEIGHT), _winch_angle)
	draw_texture_rect(WINCH_TEXTURE, Rect2(-winch_size / 2.0, winch_size), false)
	draw_set_transform(Vector2.ZERO)
	# 上方三盏指示灯，选中的放大加光晕
	for index in WeirRules.BOARD_COUNT:
		var center := Vector2((index - 1) * 100.0, -WINCH_HEIGHT - WINCH_DIAMETER / 2.0 - 70.0)
		var is_selected := index == selection and not state.is_collapsed
		var color := BOARD_COLORS[index]
		if is_selected:
			draw_circle(center, 42.0, Color(color, 0.3))
			draw_circle(center, 26.0, color)
		else:
			draw_circle(center, 18.0, color.darkened(0.5))
	if _highlight_color.a > 0.0:
		draw_arc(Vector2(0, -WINCH_HEIGHT), WINCH_DIAMETER / 2.0 + 24.0, 0.0, TAU, 48, _highlight_color, 5.0)
