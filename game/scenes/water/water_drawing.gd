@tool
class_name WaterDrawing
## WaterZone 水面装饰的静态绘制辅助；在节点的 _draw() 里把自身传进来调用。


## 冰面裂纹：沿水面等距画折线
static func draw_ice_cracks(canvas: CanvasItem, width: float, surface_y: float) -> void:
	var crack_color := Color(0.55, 0.75, 0.95, 0.9)
	var step := 140.0
	var x := 40.0
	while x < width - 40.0:
		var top := surface_y + 6.0
		canvas.draw_polyline(
			PackedVector2Array([
				Vector2(x, top), Vector2(x + 18, top + 22), Vector2(x + 6, top + 40), Vector2(x + 26, top + 64),
			]),
			crack_color, 2.0)
		x += step


## 污染斑点：沿水面散布不规则小块
static func draw_pollution_specks(canvas: CanvasItem, width: float, surface_y: float) -> void:
	var speck_color := Color(0.25, 0.2, 0.25, 0.8)
	var x := 30.0
	var index := 0
	while x < width - 30.0:
		var offset := float((index * 37) % 23)
		canvas.draw_rect(Rect2(x, surface_y + 4.0 + offset * 0.3, 26.0 - offset * 0.5, 8.0), speck_color)
		x += 90.0 + offset * 2.0
		index += 1
