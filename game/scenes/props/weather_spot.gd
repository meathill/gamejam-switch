@tool
class_name WeatherSpot
extends WeatherTarget
## 远程天气目标：对某个区域施放限定的天气，成功后发出以天气为名的事件。
## 原点是矩形左上角（pos），size 是选中范围；status 显示在状态栏（如「上游雪线：日照融雪，水尺 +1」）。

const FLAG_COLOR := Color(0.9, 0.7, 0.3)
const DASH := 18.0

@export var size: Vector2 = Vector2(400, 200):
	set(value):
		size = value
		queue_redraw()
@export var status: String = ""
## 接受的天气
var accepts: Array[Weather.Type] = []

var _highlight_color: Color = Color.TRANSPARENT


func _ready() -> void:
	# 名字用 Label 画（draw_string 的 fallback 字体在 Web 上没有中文字形）
	var label := Label.new()
	label.text = display_name
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", FLAG_COLOR.lightened(0.3))
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.size = Vector2(400, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(size.x / 2.0 - 200, -140)
	add_child(label)


func get_display_name() -> String:
	return display_name if display_name else "天气点"


func get_status_text() -> String:
	return status


func get_target_rect() -> Rect2:
	return Rect2(global_position, size)


func get_effect_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y, size.x, 1.0)


func get_center_global() -> Vector2:
	return global_position + size / 2.0


func set_highlight(color: Color) -> void:
	_highlight_color = color
	queue_redraw()


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if not accepts.has(weather):
		var names: Array[String] = []
		for accepted in accepts:
			names.append(Weather.get_display_name(accepted))
		return CastResult.fail("这里只能用" + "或".join(names))
	level_event.emit(Weather.get_key(weather))
	return CastResult.ok()


func _draw() -> void:
	# 矩形顶边中点的小旗标 + 名字
	var top := Vector2(size.x / 2.0, 0.0)
	draw_line(top, top + Vector2(0, -90), FLAG_COLOR.darkened(0.3), 4.0)
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(0, -90), top + Vector2(56, -78), top + Vector2(0, -64),
	]), FLAG_COLOR)
	if _highlight_color.a > 0.0:
		var corners := [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]
		for index in 4:
			draw_dashed_line(corners[index], corners[(index + 1) % 4], _highlight_color, 4.0, DASH)
