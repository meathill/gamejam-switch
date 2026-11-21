@tool
class_name Gondola
extends WeatherTarget
## 渡河谷的吊斗。原点在 B 端停靠点地面中点，end 是 C 端停靠点（世界坐标）。
## 小猫站进吊斗后用风推到另一端，滑行中锁输入。两端外侧画吊塔，塔顶间画缆绳。

const BUCKET_TEXTURE := preload("res://assets/sprites/valley/gondola.png")
const TOWER_TEXTURE := preload("res://assets/sprites/valley/tower.png")
const FLOOR_SIZE := Vector2(220, 24)
## 吊斗贴图宽度（底边贴着地板）
const DRAW_WIDTH := 260.0
const TOWER_HEIGHT := 520.0
## 塔中心离停靠点的水平距离
const TOWER_MARGIN := 260.0
const SPEED := 360.0
## 判定小猫在斗里的范围
const BOARD_RANGE := Vector2(110, 24)
const CABLE_COLOR := Color(0.2, 0.18, 0.22)

## C 端停靠点（世界坐标）
var end: Vector2 = Vector2.ZERO
var _bucket: AnimatableBody2D
## 0 = 停在 pos 端，1 = 停在 end 端
var _progress: float = 0.0
var _is_moving: bool = false


func _ready() -> void:
	_bucket = AnimatableBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = FLOOR_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, FLOOR_SIZE.y / 2.0)
	_bucket.add_child(collision)
	add_child(_bucket)


func get_display_name() -> String:
	return display_name if display_name else "吊斗"


func get_status_text() -> String:
	return "滑行中" if _is_moving else ""


func get_target_rect() -> Rect2:
	return Rect2(_bucket_global() + Vector2(-300, -500), Vector2(600, 650))


func get_effect_rect() -> Rect2:
	return Rect2(_bucket_global().x - DRAW_WIDTH / 2.0, _bucket_global().y - 160.0, DRAW_WIDTH, 1.0)


func _bucket_global() -> Vector2:
	return global_position + _local_end() * _progress


func _local_end() -> Vector2:
	return end - global_position


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if _is_moving:
		return CastResult.busy()
	if weather != Weather.Type.WIND:
		return CastResult.fail("只有风能推动吊斗")
	var player := _player_in_bucket()
	if not player:
		return CastResult.fail("先坐进吊斗，再用风推它过去")
	_travel(player)
	return CastResult.ok()


func _player_in_bucket() -> Player:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if not player or not player.is_on_floor():
			continue
		var offset := (player.global_position - _bucket_global()).abs()
		if offset.x < BOARD_RANGE.x and offset.y < BOARD_RANGE.y:
			return player
	return null


func _travel(player: Player) -> void:
	var target := 1.0 - _progress
	var distance := _local_end().length() * absf(target - _progress)
	_is_moving = true
	player.is_input_locked = true
	player.velocity = Vector2.ZERO
	if _progress == 0.0:
		level_event.emit("departed")
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(value: float) -> void:
		_progress = value
		_bucket.position = _local_end() * value
		player.global_position = _bucket_global() + Vector2(0, -1.0)
	, _progress, target, distance / SPEED)
	await tween.finished
	_progress = target
	player.is_input_locked = false
	_is_moving = false
	state_changed.emit(self)
	if _progress == 1.0:
		level_event.emit("arrived")


func _tower_top(end_x: float, ground_y: float, direction: float) -> Vector2:
	return Vector2(end_x + TOWER_MARGIN * direction, ground_y - TOWER_HEIGHT)


func _draw() -> void:
	var local_end := _local_end()
	var left_x := minf(0.0, local_end.x)
	var right_x := maxf(0.0, local_end.x)
	var left_y := 0.0 if local_end.x >= 0.0 else local_end.y
	var right_y := local_end.y if local_end.x >= 0.0 else 0.0
	var tower_size := TOWER_TEXTURE.get_size() * TOWER_HEIGHT / TOWER_TEXTURE.get_height()
	var left_top := _tower_top(left_x, left_y, -1.0)
	var right_top := _tower_top(right_x, right_y, 1.0)
	for top: Vector2 in [left_top, right_top]:
		draw_texture_rect(TOWER_TEXTURE, Rect2(top - Vector2(tower_size.x / 2.0, 0), tower_size), false)
	# 两塔顶之间的缆绳
	draw_line(left_top, right_top, CABLE_COLOR, 5.0)
	# 吊斗 + 连到缆绳的吊绳
	var bucket := _local_end() * _progress
	var bucket_size := BUCKET_TEXTURE.get_size() * DRAW_WIDTH / BUCKET_TEXTURE.get_width()
	draw_texture_rect(BUCKET_TEXTURE, Rect2(bucket - Vector2(bucket_size.x / 2.0, bucket_size.y), bucket_size), false)
	var span := right_x - left_x
	if span > 1.0:
		var t := inverse_lerp(left_x, right_x, bucket.x)
		var cable_point := left_top.lerp(right_top, clampf(t, 0.0, 1.0))
		draw_line(bucket + Vector2(0, -bucket_size.y), cable_point, CABLE_COLOR, 4.0)
