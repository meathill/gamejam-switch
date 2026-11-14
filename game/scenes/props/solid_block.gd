@tool
class_name SolidBlock
extends StaticBody2D
## 灰盒地形块。原点在左上角。

@export var size: Vector2 = Vector2(800, 600):
	set(value):
		size = value
		_rebuild()
@export var color: Color = Color(0.22, 0.2, 0.33):
	set(value):
		color = value
		queue_redraw()
## 纹理（按世界坐标 1:1 平铺）；为空时用纯色
@export var texture: Texture2D:
	set(value):
		texture = value
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		queue_redraw()
## 顶面的土色带（地表）；透明时只画一条亮边
@export var top_color: Color = Color.TRANSPARENT:
	set(value):
		top_color = value
		queue_redraw()
## 作为楼房绘制窗户
@export var is_building: bool = false:
	set(value):
		is_building = value
		queue_redraw()

const TOP_BAND_HEIGHT := 40.0

## 隐藏的平台：运行时不显示、没有碰撞，直到联动 reveal
@export var is_hidden: bool = false

var _collision: CollisionShape2D


func do_reveal(_params: Dictionary) -> void:
	visible = true
	_collision.set_deferred("disabled", false)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func do_hide(_params: Dictionary) -> void:
	_collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void: visible = false)


func _ready() -> void:
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	add_child(_collision)
	_rebuild()
	if is_hidden and not Engine.is_editor_hint():
		visible = false
		_collision.disabled = true


func _rebuild() -> void:
	if not _collision:
		return
	(_collision.shape as RectangleShape2D).size = size
	_collision.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	if texture:
		TextureDraw.draw_world_tiled(self, texture, Rect2(Vector2.ZERO, size))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), color)
	if top_color.a > 0.0:
		draw_rect(Rect2(0, 0, size.x, minf(TOP_BAND_HEIGHT, size.y)), top_color)
		draw_line(Vector2(0, TOP_BAND_HEIGHT), Vector2(size.x, TOP_BAND_HEIGHT), top_color.darkened(0.12), 3.0)
	elif not texture:
		draw_line(Vector2.ZERO, Vector2(size.x, 0), color.lightened(0.25), 6.0)
	if is_building:
		_draw_windows()


func _draw_windows() -> void:
	var window_color := color.darkened(0.35)
	var cell := Vector2(110, 130)
	var columns := int(size.x / cell.x)
	var rows := int(size.y / cell.y)
	var margin_x := (size.x - columns * cell.x) / 2.0
	for row in rows:
		for column in columns:
			var origin := Vector2(margin_x + column * cell.x + 25, row * cell.y + 35)
			draw_rect(Rect2(origin, Vector2(60, 70)), window_color)
