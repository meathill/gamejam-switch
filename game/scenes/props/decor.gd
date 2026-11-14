@tool
class_name Decor
extends Node2D
## 装饰，没有碰撞：
##   有贴图、没有 size：原点在底边中点，按 height 等比缩放
##   有 size：原点在左上角，铺满 size（有贴图时按世界坐标 1:1 平铺，否则纯色）

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var height: float = 300.0:
	set(value):
		height = value
		queue_redraw()
@export var size: Vector2 = Vector2.ZERO:
	set(value):
		size = value
		queue_redraw()
## 纯色矩形的颜色（没有贴图时）
@export var color: Color = Color(0.1, 0.1, 0.14):
	set(value):
		color = value
		queue_redraw()
@export var is_flipped: bool = false:
	set(value):
		is_flipped = value
		queue_redraw()


func _draw() -> void:
	if size != Vector2.ZERO:
		if texture:
			texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			TextureDraw.draw_world_tiled(self, texture, Rect2(Vector2.ZERO, size))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), color)
		return
	if not texture:
		return
	var display_size := texture.get_size() * height / texture.get_height()
	if is_flipped:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect(texture, Rect2(Vector2(-display_size.x / 2.0, -display_size.y), display_size), false)
