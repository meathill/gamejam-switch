@tool
class_name Gondola
extends WeatherTarget
## 渡河谷的吊斗。原点在 B 端停靠点地面中点，end 是 C 端停靠点（世界坐标）。
## 小猫跳进吊斗后用风推到另一端，滑行中锁输入。两端外侧画吊塔，塔顶间画缆绳。

const BUCKET_TEXTURE := preload("res://assets/sprites/valley/gondola.png")
const TOWER_TEXTURE := preload("res://assets/sprites/valley/tower.png")
## 斗沿在源图里的行号：以上是吊钩立杆（画在小猫后面），以下是斗身（遮住小猫下半身）
const RIM_SOURCE_Y := 280.0
## 斗内地板顶面比停靠点地面高这么多，小猫必须跳进来
const FLOOR_TOP := -30.0
const FLOOR_SIZE := Vector2(200, 24)
const WALL_X := 100.0
const WALL_WIDTH := 12.0
## 吊斗贴图绘制宽度（底边贴着停靠点地面）
const DRAW_WIDTH := 260.0
const TOWER_HEIGHT := 520.0
## 塔中心离停靠点的水平距离
const TOWER_MARGIN := 260.0
const SPEED := 360.0
## 判定小猫坐进斗里：水平偏移 < 60、脚底贴着斗底（±12），站上斗沿不算
const RIDE_RANGE := Vector2(60, 12)
const CABLE_COLOR := Color(0.2, 0.18, 0.22)

## C 端停靠点（世界坐标）
var end: Vector2 = Vector2.ZERO
var _bucket: AnimatableBody2D
## 0 = 停在 pos 端，1 = 停在 end 端
var _progress: float = 0.0
var _is_moving: bool = false


func _ready() -> void:
	_bucket = AnimatableBody2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = FLOOR_SIZE
	var floor_collision := CollisionShape2D.new()
	floor_collision.shape = floor_shape
	floor_collision.position = Vector2(0, FLOOR_TOP + FLOOR_SIZE.y / 2.0)
	_bucket.add_child(floor_collision)
	var tex_scale := DRAW_WIDTH / BUCKET_TEXTURE.get_width()
	# 斗沿比地板顶面高出一截斗身，两侧斗壁挡住直接走进来
	var rim_y := -(BUCKET_TEXTURE.get_height() - RIM_SOURCE_Y) * tex_scale
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(WALL_WIDTH, FLOOR_TOP - rim_y)
	for side: float in [-WALL_X, WALL_X]:
		var wall := CollisionShape2D.new()
		wall.shape = wall_shape
		wall.position = Vector2(side, (rim_y + FLOOR_TOP) / 2.0)
		_bucket.add_child(wall)
	# 贴图拆两层挂在斗上随它滑行：后半层在小猫后面，斗身在小猫前面遮住下半身
	var tex_size := BUCKET_TEXTURE.get_size()
	var top_y := -tex_size.y * tex_scale
	_bucket.add_child(_make_bucket_sprite(Rect2(0, 0, tex_size.x, RIM_SOURCE_Y), Vector2(-DRAW_WIDTH / 2.0, top_y), tex_scale, 0))
	_bucket.add_child(_make_bucket_sprite(Rect2(0, RIM_SOURCE_Y, tex_size.x, tex_size.y - RIM_SOURCE_Y), Vector2(-DRAW_WIDTH / 2.0, rim_y), tex_scale, 1))
	add_child(_bucket)


func _make_bucket_sprite(src: Rect2, top_left: Vector2, tex_scale: float, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = BUCKET_TEXTURE
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = src
	sprite.position = top_left
	sprite.scale = Vector2(tex_scale, tex_scale)
	sprite.z_index = z
	return sprite


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
		return CastResult.fail("先跳进吊斗，再用风推它过去")
	_travel(player)
	return CastResult.ok()


func _player_in_bucket() -> Player:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if not player or not player.is_on_floor():
			continue
		var offset := player.global_position - _bucket_global()
		if absf(offset.x) < RIDE_RANGE.x and absf(offset.y - FLOOR_TOP) < RIDE_RANGE.y:
			return player
	return null


func _travel(player: Player) -> void:
	var target := 1.0 - _progress
	var distance := _local_end().length() * absf(target - _progress)
	_is_moving = true
	player.is_input_locked = true
	player.velocity = Vector2.ZERO
	# 小猫带着上斗时的水平偏移滑到对岸
	var ride_offset := player.global_position.x - _bucket_global().x
	if _progress == 0.0:
		level_event.emit("departed")
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(value: float) -> void:
		_progress = value
		_bucket.position = _local_end() * value
		player.global_position = _bucket_global() + Vector2(ride_offset, FLOOR_TOP - 1.0)
		queue_redraw()
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
	# 斗顶到缆绳的吊绳，滑行时跟着吊斗走
	var bucket := _local_end() * _progress
	var bucket_top := bucket + Vector2(0, -BUCKET_TEXTURE.get_height() * DRAW_WIDTH / BUCKET_TEXTURE.get_width())
	var span := right_x - left_x
	if span > 1.0:
		var t := inverse_lerp(left_x, right_x, bucket.x)
		var cable_point := left_top.lerp(right_top, clampf(t, 0.0, 1.0))
		draw_line(bucket_top, cable_point, CABLE_COLOR, 4.0)
