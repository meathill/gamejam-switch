@tool
class_name WeatherSpot
extends WeatherTarget
## 远程天气目标：对远处某个区域施放限定的天气，成功后镜头切到真实地点（view）看效果再回来。
## 原点是矩形左上角（pos），size 是选中范围，不可见；status 显示在状态栏，HUD 右上角列出行供点击预览。

const SPOTS_GROUP := "weather_spots"
const FOCUS_SECONDS := 3.0

@export var size: Vector2 = Vector2(400, 200)
@export var status: String = ""
## HUD 行里的附加说明（如「水尺 +1」），留空则省掉箭头后缀
var note: String = ""
## 接受的天气
var accepts: Array[Weather.Type] = []
## 真实地点（世界坐标矩形）：特效落在顶边，镜头对准中心
var view: Rect2 = Rect2()


func _init() -> void:
	# _init 不自动链调父类，WeatherTarget 的 weather_targets 组也要在这里加上
	add_to_group(GROUP)
	add_to_group(SPOTS_GROUP)


func get_display_name() -> String:
	return display_name if display_name else "天气点"


func get_status_text() -> String:
	return status


func get_target_rect() -> Rect2:
	return Rect2(global_position, size)


func get_effect_rect() -> Rect2:
	return view


func get_view_center() -> Vector2:
	return view.get_center()


func get_effect_delay() -> float:
	# 特效等镜头补间到位再放，不然粒子寿命（0.8–1.3 秒）在镜头到达前就放完了
	return Level.FOCUS_PAN_SECONDS


func _cast(weather: Weather.Type, _direction: int) -> CastResult:
	if not accepts.has(weather):
		var names: Array[String] = []
		for accepted in accepts:
			names.append(Weather.get_display_name(accepted))
		return CastResult.fail("这里只能用" + "或".join(names))
	# 先看原因后看后果：view 焦点先入队，联动（比如涨满溃泄）触发的焦点排在后面
	GameState.focus_requested.emit(get_view_center(), FOCUS_SECONDS)
	level_event.emit(Weather.get_key(weather))
	return CastResult.ok()
