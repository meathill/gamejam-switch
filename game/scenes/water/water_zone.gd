@tool
class_name WaterZone
extends WeatherTarget
## 一个可被天气作用的水域（洼地）。原点在洼地左上角、与地面齐平，向下 size.y 为池底。
## 洼地两侧的墙由相邻的地面块提供，这里只生成池底和冰面碰撞。

const SHALLOW_HEIGHT := 60.0
## 深水水面与地面齐平，结冰后冰面可以直接走过去，不会有台阶
const DEEP_SURFACE_MARGIN := 0.0
const FLOOR_THICKNESS := 200.0
const ICE_THICKNESS := 24.0
const TWEEN_SECONDS := 0.45
const TARGET_MARGIN := 280.0
const TARGET_HEIGHT_ABOVE := 600.0
const RAFT_FLOAT_OFFSET := 20.0

const CLEAN_COLOR := Color(0.24, 0.45, 0.7, 0.72)
const POLLUTED_COLOR := Color(0.42, 0.33, 0.48, 0.86)
const ICE_COLOR := Color(0.78, 0.9, 1.0, 0.95)
const BASIN_COLOR := Color(0.15, 0.14, 0.24)

@export var zone_name: String = "水域"
@export var size: Vector2 = Vector2(900, 220):
	set(value):
		size = value
		_refresh()
@export_range(0, 2) var level: int = 2:
	set(value):
		level = value
		_refresh()
@export var is_frozen: bool = false:
	set(value):
		is_frozen = value
		_refresh()
@export var is_polluted: bool = false:
	set(value):
		is_polluted = value
		_refresh()
## 浮箱停靠点（本地 x 坐标，从左到右）
@export var dock_positions: PackedFloat32Array = PackedFloat32Array()
## 只能冻结浅水（地下深水冻不住）
@export var shallow_freeze_only: bool = false

var _display_surface_y: float = 0.0:
	set(value):
		_display_surface_y = value
		queue_redraw()
var _highlight_color: Color = Color.TRANSPARENT
var _ice_shape: CollisionShape2D
var _is_busy: bool = false


func _ready() -> void:
	z_index = 1
	_display_surface_y = get_surface_y_for(level)
	if Engine.is_editor_hint():
		return
	add_to_group("water_zones")
	_build_bodies()
	for raft in get_rafts():
		raft.position = Vector2(dock_positions[raft.dock_index], get_raft_y_for(_display_surface_y))
		raft.set_frozen(is_frozen)


func get_state() -> WaterState:
	return WaterState.new(level, is_frozen, is_polluted)


func get_surface_y_for(target_level: int) -> float:
	match target_level:
		0:
			return size.y
		1:
			return size.y - SHALLOW_HEIGHT
	return DEEP_SURFACE_MARGIN


func get_raft_y_for(surface_y: float) -> float:
	var resting_y := size.y - Raft.HEIGHT / 2.0
	return minf(surface_y + RAFT_FLOAT_OFFSET - Raft.HEIGHT / 2.0, resting_y)


func get_surface_global_y() -> float:
	return global_position.y + _display_surface_y


func get_floor_global_y() -> float:
	return global_position.y + size.y


func contains_x(global_x: float) -> bool:
	return global_x >= global_position.x and global_x <= global_position.x + size.x


func get_target_rect() -> Rect2:
	return Rect2(
		global_position + Vector2(-TARGET_MARGIN, -TARGET_HEIGHT_ABOVE),
		Vector2(size.x + TARGET_MARGIN * 2.0, size.y + TARGET_HEIGHT_ABOVE + 120.0),
	)


func get_center_global() -> Vector2:
	return global_position + size / 2.0


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x, get_surface_global_y(), size.x, 1.0)


func get_display_name() -> String:
	return zone_name


func get_status_text() -> String:
	var level_names: Array[String] = ["干燥", "浅水", "深水"]
	var parts: Array[String] = ["水位 %d %s" % [level, level_names[level]]]
	parts.append("冰面" if is_frozen else "液态")
	if is_polluted:
		parts.append("污染")
	var rafts := get_rafts().size()
	if rafts > 0:
		parts.append("浮箱 ×%d" % rafts)
	return " · ".join(parts)


func get_rafts() -> Array[Raft]:
	var rafts: Array[Raft] = []
	for child in get_children():
		if child is Raft:
			rafts.append(child)
	return rafts


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


func is_busy() -> bool:
	return _is_busy


## 施放天气；风需要方向（-1 左 / 1 右）。返回带规则原因的结果，WeatherCaster 走 cast_weather
func apply_weather(weather: Weather.Type, direction: int = 0) -> WaterRules.Result:
	if _is_busy:
		return WaterRules.Result.new(false, get_state(), WaterRules.Reason.BUSY)
	var result := WaterRules.apply(weather, get_state(), shallow_freeze_only)
	if not result.is_success:
		return result
	if weather == Weather.Type.WIND:
		var reason := _blow_rafts(direction)
		if reason != WaterRules.Reason.NONE:
			return WaterRules.Result.new(false, get_state(), reason)
	else:
		transition_to(result.state)
	return result


func _cast(weather: Weather.Type, direction: int) -> CastResult:
	var result := apply_weather(weather, direction)
	if result.is_success:
		return CastResult.ok()
	if result.reason == WaterRules.Reason.BUSY:
		return CastResult.busy()
	return CastResult.fail(WaterRules.get_reason_text(result.reason))


## 外部机关（如排水站）也通过这里改变水域状态
func transition_to(next: WaterState) -> void:
	var was_frozen := is_frozen
	level = next.level
	is_frozen = next.is_frozen
	is_polluted = next.is_polluted
	_ice_shape.set_deferred("disabled", not is_frozen)
	if is_frozen and not was_frozen:
		_lift_bodies_onto_ice()
	_is_busy = true
	var target_y := get_surface_y_for(level)
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "_display_surface_y", target_y, TWEEN_SECONDS)
	for raft in get_rafts():
		raft.set_frozen(is_frozen)
		tween.tween_property(raft, "position:y", get_raft_y_for(target_y), TWEEN_SECONDS)
	await tween.finished
	_is_busy = false
	state_changed.emit(self)


func _blow_rafts(direction: int) -> WaterRules.Reason:
	var rafts := get_rafts()
	if rafts.is_empty():
		return WaterRules.Reason.NO_RAFT
	var occupied: Array[int] = []
	for raft in rafts:
		occupied.append(raft.dock_index)
	var moves: Dictionary[Raft, int] = {}
	for raft in rafts:
		var next := WaterRules.find_next_dock(raft.dock_index, direction, dock_positions.size(), occupied)
		if next >= 0:
			moves[raft] = next
	if moves.is_empty():
		return WaterRules.Reason.NO_DOCK
	_animate_raft_moves(moves)
	return WaterRules.Reason.NONE


func _animate_raft_moves(moves: Dictionary[Raft, int]) -> void:
	_is_busy = true
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for raft: Raft in moves:
		raft.dock_index = moves[raft]
		tween.tween_property(raft, "position:x", dock_positions[raft.dock_index], TWEEN_SECONDS * 1.6)
	await tween.finished
	_is_busy = false
	state_changed.emit(self)


func _build_bodies() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.add_child(_make_rect_shape(Vector2(size.x, FLOOR_THICKNESS), Vector2(size.x / 2.0, size.y + FLOOR_THICKNESS / 2.0)))
	add_child(floor_body)
	var ice_body := StaticBody2D.new()
	ice_body.name = "Ice"
	ice_body.add_to_group("ice")
	_ice_shape = _make_rect_shape(Vector2(size.x, ICE_THICKNESS), Vector2(size.x / 2.0, ICE_THICKNESS / 2.0))
	ice_body.add_child(_ice_shape)
	add_child(ice_body)
	_update_ice_position()
	_ice_shape.disabled = not is_frozen


func _update_ice_position() -> void:
	if _ice_shape:
		_ice_shape.get_parent().position.y = get_surface_y_for(level)


## 结冰瞬间如果有角色泡在水里，把它抬到冰面上，避免卡进碰撞体
func _lift_bodies_onto_ice() -> void:
	_update_ice_position()
	var ice_top := global_position.y + get_surface_y_for(level)
	for node in get_tree().get_nodes_in_group("player"):
		var body := node as Node2D
		if body and contains_x(body.global_position.x) and body.global_position.y > ice_top - 4.0:
			body.global_position.y = ice_top - 1.0


func _make_rect_shape(shape_size: Vector2, center: Vector2) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = shape_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = center
	return collision


func _refresh() -> void:
	if not is_node_ready():
		return
	_update_ice_position()
	if Engine.is_editor_hint():
		_display_surface_y = get_surface_y_for(level)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, size.y, size.x, FLOOR_THICKNESS), BASIN_COLOR)
	var water_height := size.y - _display_surface_y
	if water_height > 0.5:
		var water_rect := Rect2(0, _display_surface_y, size.x, water_height)
		var color := POLLUTED_COLOR if is_polluted else CLEAN_COLOR
		draw_rect(water_rect, ICE_COLOR if is_frozen else color)
		var surface_color := Color.WHITE if is_frozen else color.lightened(0.35)
		draw_line(Vector2(0, _display_surface_y), Vector2(size.x, _display_surface_y), surface_color, 4.0)
		if is_frozen:
			_draw_ice_cracks()
		elif is_polluted:
			_draw_pollution_specks()
	if _highlight_color.a > 0.0:
		draw_rect(Rect2(-6, -6, size.x + 12, size.y + 12), _highlight_color, false, 4.0)


func _draw_ice_cracks() -> void:
	var crack_color := Color(0.55, 0.75, 0.95, 0.9)
	var step := 140.0
	var x := 40.0
	while x < size.x - 40.0:
		var top := _display_surface_y + 6.0
		draw_polyline(PackedVector2Array([
			Vector2(x, top), Vector2(x + 18, top + 22), Vector2(x + 6, top + 40), Vector2(x + 26, top + 64),
		]), crack_color, 2.0)
		x += step


func _draw_pollution_specks() -> void:
	var speck_color := Color(0.25, 0.2, 0.25, 0.8)
	var x := 30.0
	var index := 0
	while x < size.x - 30.0:
		var offset := float((index * 37) % 23)
		draw_rect(Rect2(x, _display_surface_y + 4.0 + offset * 0.3, 26.0 - offset * 0.5, 8.0), speck_color)
		x += 90.0 + offset * 2.0
		index += 1
