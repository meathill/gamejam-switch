@tool
class_name TextureDraw
extends RefCounted
## CanvasItem 绘制贴图的小工具：按高度缩放后横向平铺、按世界坐标对齐平铺（相邻地形块之间纹理连续）。


## 贴图等比缩放到 rect 的高度，从左往右重复铺满 rect，最后一块按比例截断
static func draw_strip(canvas: CanvasItem, texture: Texture2D, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	var tile_width := texture.get_width() * rect.size.y / texture.get_height()
	var x := 0.0
	while x < rect.size.x - 0.5:
		var width := minf(tile_width, rect.size.x - x)
		var source := Rect2(0, 0, texture.get_width() * width / tile_width, texture.get_height())
		canvas.draw_texture_rect_region(texture, Rect2(rect.position + Vector2(x, 0), Vector2(width, rect.size.y)), source, modulate)
		x += tile_width


## 1:1 平铺，纹理坐标取自节点的全局位置，相邻节点拼起来没有接缝。节点需要开启 texture_repeat
static func draw_world_tiled(canvas: Node2D, texture: Texture2D, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(texture, rect, Rect2(canvas.global_position + rect.position, rect.size))
