@tool
class_name Field
extends WeatherTarget
## 农田，计入通关目标（恢复后完成）。原点在田面左上角（地面高度），规则见 FarmRules。
## is_pit：低洼田，田面在原点下方 depth 处；积水淤泥时掉进去会陷住，泥冰时可以在地面高度走过去。

const SOIL_HEIGHT := 40.0
const TARGET_MARGIN := 240.0
const TARGET_HEIGHT_ABOVE := 520.0
const ICE_THICKNESS := 24.0
const COLORS: Dictionary[FarmRules.FieldState, Color] = {
	FarmRules.FieldState.DRY: Color(0.66, 0.52, 0.34),
	FarmRules.FieldState.WATERLOGGED: Color(0.27, 0.2, 0.18),
	FarmRules.FieldState.MUD_ICE: Color(0.78, 0.88, 0.95),
	FarmRules.FieldState.RESTORED: Color(0.56, 0.31, 0.27),
}
const SPROUT_HEIGHT := 46.0
const DRY_TEXTURE := preload("res://assets/sprites/farm/dry_field.png")
const WATER_TEXTURE := preload("res://assets/sprites/farm/field_water.png")
const ROCKS_TEXTURE := preload("res://assets/sprites/farm/field_rocks.png")
const SPROUTS_TEXTURE := preload("res://assets/sprites/farm/sprouts.png")

@export var field_name: String = "农田"
@export var width: float = 500.0:
	set(value):
		width = value
		queue_redraw()
@export var depth: float = 0.0:
	set(value):
		depth = value
		queue_redraw()
@export var is_pit: bool = false
@export var state: FarmRules.FieldState = FarmRules.FieldState.DRY:
	set(value):
		state = value
		queue_redraw()
## 只能靠排水泵灌溉
@export var is_pump_only: bool = false
## 恢复后再下雨会重新积水
@export var can_flood: bool = false
@export var wheel: Waterwheel
@export_range(1, 3) var irrigation_gear: int = 1

var _highlight_color: Color = Color.TRANSPARENT
var _ice_shape: CollisionShape2D
var _hazard: Area2D
var _is_counted: bool = false


func _ready() -> void:
	z_index = 1
	if Engine.is_editor_hint():
		return
	GameState.register_objective("field")
	_sync_objective()
	if is_pit:
		_build_pit_bodies()


func get_target_rect() -> Rect2:
	return Rect2(global_position + Vector2(-TARGET_MARGIN, -TARGET_HEIGHT_ABOVE),
		Vector2(width + TARGET_MARGIN * 2.0, depth + TARGET_HEIGHT_ABOVE + 120.0))


func get_center_global() -> Vector2:
	return global_position + Vector2(width / 2.0, depth)


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y + depth, width, 1.0)


func get_display_name() -> String:
	return field_name


func get_status_text() -> String:
	var text := FarmRules.FIELD_STATE_NAMES[state]
	if is_pump_only:
		return text + " · 靠地下抽水灌溉"
	if wheel and state != FarmRules.FieldState.RESTORED:
		text += " · 农田管" + ("通水" if wheel.is_gear(irrigation_gear) else "未通水")
	return text


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


## 联动：直接浇灌（如排水泵把地下水抽上来浇井口田）
func do_irrigate(_params: Dictionary) -> void:
	_set_state(FarmRules.FieldState.RESTORED)


## 条件 { "is": restored / dry / waterlogged }
func get_unmet_reason(condition: Dictionary) -> String:
	var expected: FarmRules.FieldState = FarmRules.FieldState[(condition["is"] as String).to_upper()]
	return "" if state == expected else "%s还不是%s" % [field_name, FarmRules.FIELD_STATE_NAMES[expected]]


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	var is_pipe_open := wheel != null and wheel.is_gear(irrigation_gear)
	var result := FarmRules.apply_field(weather, state, is_pipe_open, can_flood, is_pump_only)
	if not result.is_success:
		return CastResult.fail(result.reason_text)
	_set_state(result.state)
	return CastResult.ok()


func _set_state(next: FarmRules.FieldState) -> void:
	var previous := state
	state = next
	_sync_objective()
	if is_pit:
		_ice_shape.set_deferred("disabled", state != FarmRules.FieldState.MUD_ICE)
		if state == FarmRules.FieldState.MUD_ICE:
			_lift_player_onto_ice()
		_check_hazard()
	state_changed.emit(self)
	if state == FarmRules.FieldState.RESTORED and previous != state:
		level_event.emit("restored")
	elif state == FarmRules.FieldState.WATERLOGGED and previous == FarmRules.FieldState.RESTORED:
		level_event.emit("flooded")


func _sync_objective() -> void:
	var is_restored := state == FarmRules.FieldState.RESTORED
	if is_restored == _is_counted:
		return
	_is_counted = is_restored
	if is_restored:
		GameState.complete_objective("field")
	else:
		GameState.revert_objective("field")


func _build_pit_bodies() -> void:
	var ice_body := StaticBody2D.new()
	ice_body.add_to_group("ice")
	_ice_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, ICE_THICKNESS)
	_ice_shape.shape = shape
	_ice_shape.position = Vector2(width / 2.0, ICE_THICKNESS / 2.0)
	_ice_shape.disabled = state != FarmRules.FieldState.MUD_ICE
	ice_body.add_child(_ice_shape)
	add_child(ice_body)
	_hazard = Area2D.new()
	_hazard.collision_layer = 0
	_hazard.collision_mask = 2
	var hazard_shape := CollisionShape2D.new()
	var hazard_rect := RectangleShape2D.new()
	hazard_rect.size = Vector2(width, depth * 0.6)
	hazard_shape.shape = hazard_rect
	hazard_shape.position = Vector2(width / 2.0, depth * 0.7)
	_hazard.add_child(hazard_shape)
	_hazard.body_entered.connect(func(_body: Node2D) -> void: _check_hazard())
	add_child(_hazard)


func _check_hazard() -> void:
	if state != FarmRules.FieldState.WATERLOGGED:
		return
	for body in _hazard.get_overlapping_bodies():
		if body is Player:
			(body as Player).drown("小猫陷进了淤泥里……")


func _lift_player_onto_ice() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var body := node as Node2D
		var local := body.global_position - global_position
		if local.x >= 0.0 and local.x <= width and local.y > -4.0:
			body.global_position.y = global_position.y - 1.0


func _draw() -> void:
	var surface := 0.0 if state == FarmRules.FieldState.MUD_ICE else depth
	match state:
		FarmRules.FieldState.DRY:
			TextureDraw.draw_strip(self, DRY_TEXTURE, Rect2(0, depth, width, SOIL_HEIGHT))
		FarmRules.FieldState.WATERLOGGED:
			draw_rect(Rect2(0, depth, width, SOIL_HEIGHT), COLORS[state])
			var water_top := depth * 0.4
			draw_texture_rect(WATER_TEXTURE, Rect2(0, water_top, width, depth - water_top + SOIL_HEIGHT * 0.5), false, Color(1, 1, 1, 0.92))
			TextureDraw.draw_strip(self, ROCKS_TEXTURE, Rect2(0, depth - 34, width, 40))
		FarmRules.FieldState.MUD_ICE:
			draw_rect(Rect2(0, 0, width, depth + SOIL_HEIGHT), COLORS[state])
			TextureDraw.draw_strip(self, ROCKS_TEXTURE, Rect2(0, depth - 34, width, 40), Color(0.8, 0.9, 1.0, 0.6))
			draw_line(Vector2(0, 2), Vector2(width, 2), Color.WHITE, 4.0)
		FarmRules.FieldState.RESTORED:
			draw_rect(Rect2(0, depth, width, SOIL_HEIGHT), COLORS[state])
			TextureDraw.draw_strip(self, SPROUTS_TEXTURE, Rect2(0, depth - SPROUT_HEIGHT + 4.0, width, SPROUT_HEIGHT))
	if _highlight_color.a > 0.0:
		draw_rect(Rect2(-6, surface - 50.0, width + 12, depth - surface + SOIL_HEIGHT + 56.0), _highlight_color, false, 4.0)
