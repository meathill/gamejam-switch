@tool
class_name Telescope
extends Interactable
## 望远镜：按 E 使用后镜头切到所对远程天气目标（spot.view）的真实地点一直看，再按 E 返回。
## 只用来看；看的时候小猫锁输入不能动也不能施放。原点在地面。

## 镜筒朝向右上仰角
const TUBE_ANGLE := -0.62
const TUBE_LENGTH := 110.0
const LEG_HEIGHT := 90.0
const METAL := Color(0.32, 0.3, 0.38)
const BRASS := Color(0.72, 0.58, 0.3)
const BRASS_DARK := Color(0.5, 0.4, 0.22)

## 所对的远程天气目标，关卡数据里用 "spot" 引用
var spot: WeatherSpot
var _is_looking := false


func get_action_name() -> String:
	if _is_looking:
		return "返回"
	return "望远镜：" + (spot.get_display_name() if spot else "")


func can_interact() -> bool:
	if _is_looking:
		return true
	var player := get_player()
	return player == null or not player.is_input_locked


func _interact() -> void:
	_is_looking = not _is_looking
	if _is_looking:
		var back := GameState.pick_hint("按 E 返回", "点互动键返回")
		GameState.lookout_started.emit(spot.get_view_center(), "%s：%s · %s" % [spot.get_display_name(), spot.status, back])
	else:
		GameState.lookout_ended.emit()
		# 解锁在镜头补间完成后才发生，等解锁再刷新，不然提示要走出再走回检测区才出现
		_refresh_prompt_when_unlocked()


func _refresh_prompt_when_unlocked() -> void:
	var player := get_player()
	while player and player.is_input_locked:
		await get_tree().physics_frame
	refresh_prompt()


func _draw() -> void:
	# 三脚架
	for angle: float in [0.42, -0.42]:
		draw_line(Vector2.ZERO, Vector2(sin(angle), -cos(angle)) * LEG_HEIGHT, METAL, 7.0)
	draw_line(Vector2.ZERO, Vector2(0, -LEG_HEIGHT - 14.0), METAL, 7.0)
	# 斜向右上的镜筒：尾部窄环 + 筒身 + 前端目镜环
	var base := Vector2(0, -LEG_HEIGHT - 18.0)
	var dir := Vector2(cos(TUBE_ANGLE), sin(TUBE_ANGLE))
	var side := Vector2(-dir.y, dir.x)
	var tail := base - dir * 14.0
	var tip := base + dir * TUBE_LENGTH
	draw_line(tail, tip, BRASS, 26.0)
	draw_line(tail - side * 15.0, tail + side * 15.0, BRASS_DARK, 8.0)
	draw_line(tip - side * 17.0, tip + side * 17.0, BRASS_DARK, 10.0)
	draw_circle(tip + dir * 4.0, 7.0, Color(0.65, 0.8, 0.95, 0.9))
