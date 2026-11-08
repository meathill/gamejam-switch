class_name StoryBackdrop
extends Node2D
## 序章/标题共用的屏幕空间背景（1920×1080）：美术的城市远景分层 + 小猫所在的屋顶 + 对面楼的手电光。
## 对面楼用远景素材里的前景楼水平翻转放到右侧。

const MANIFEST_PATH := "res://data/backdrops/city_far.json"
const SCREEN := Vector2(1920, 1080)
## 天气演示粒子的参考水面高度
const WATER_TOP := 860.0
const ROOF_RECT := Rect2(120, 700, 720, 400)
const ROOF_COLOR := Color(0.16, 0.14, 0.27)
const ROOF_EDGE_COLOR := Color(0.24, 0.21, 0.38)
## 屋顶上小猫立绘的显示高度（与贴图分辨率无关）
const CAT_HEIGHT := 378.0
## 翻转后对面楼上那扇竖条纹窗户（设计稿坐标）
const LIT_WINDOW := Rect2(1536, 452, 136, 142)
const FLASHLIGHT_COLOR := Color(1.0, 0.93, 0.6)

var is_flashlight_on: bool = false
## 标题画面右侧要放标题和按钮，不显示对面楼
var has_opposite_building: bool = true
var _time: float = 0.0
var _overlay: Node2D


func _ready() -> void:
	var manifest := BackdropManifest.new(MANIFEST_PATH)
	var sky := manifest.make_sprite("sky")
	sky.scale = SCREEN / sky.texture.get_size()
	add_child(sky)
	add_child(manifest.make_sprite("far"))
	var mid := manifest.make_sprite("mid")
	# 中景是镜像平铺贴图，这里只取原图那一半
	mid.region_enabled = true
	mid.region_rect = Rect2(0, 0, SCREEN.x, mid.texture.get_height())
	add_child(mid)
	add_child(manifest.make_sprite("near"))
	if has_opposite_building:
		var building := manifest.make_sprite("building_front")
		building.flip_h = true
		add_child(building)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _process(delta: float) -> void:
	if is_flashlight_on:
		_time += delta
		_overlay.queue_redraw()


func _draw_overlay() -> void:
	if is_flashlight_on:
		var blink := clampf(sin(_time * 7.0) * 2.0, 0.0, 1.0)
		_overlay.draw_circle(LIT_WINDOW.get_center(), 130.0, Color(FLASHLIGHT_COLOR, 0.14 * blink))
		_overlay.draw_rect(LIT_WINDOW, Color(FLASHLIGHT_COLOR, 0.25 + 0.6 * blink))
	_overlay.draw_rect(ROOF_RECT, ROOF_COLOR)
	_overlay.draw_rect(Rect2(ROOF_RECT.position - Vector2(10, 18), Vector2(ROOF_RECT.size.x + 20, 22)), ROOF_EDGE_COLOR)
