class_name StoryBackdrop
extends Node2D
## 序章/标题共用的屏幕空间背景：暴雨夜、远景城市、洪水、屋顶、对面楼的手电光

const SCREEN := Vector2(1920, 1080)
const WATER_TOP := 860.0
const ROOF_RECT := Rect2(120, 700, 720, 400)
## 屋顶上小猫立绘的显示高度（与贴图分辨率无关）
const CAT_HEIGHT := 378.0
const BUILDING_RECT := Rect2(1250, 300, 520, WATER_TOP - 300)
const WINDOW_ORIGIN := Vector2(1290, 350)
const WINDOW_STEP := 120.0
const WINDOW_SIZE := Vector2(60, 70)
const WINDOW_GRID := Vector2i(4, 4)
## 有手电光的窗口（列, 行）
const LIT_WINDOW := Vector2i(2, 1)

var is_flashlight_on: bool = false
var _time: float = 0.0


func _ready() -> void:
	var far := CityBackdrop.new()
	far.width = SCREEN.x + 800.0
	far.seed_value = 5
	far.base_color = Color(0.12, 0.14, 0.19)
	far.max_height = 520.0
	far.position = Vector2(-400, WATER_TOP)
	far.show_behind_parent = true
	add_child(far)


static func get_window_rect(cell: Vector2i) -> Rect2:
	return Rect2(WINDOW_ORIGIN + Vector2(cell) * WINDOW_STEP, WINDOW_SIZE)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var water_wave := sin(_time * 1.4) * 6.0
	draw_rect(BUILDING_RECT, Color(0.2, 0.2, 0.25))
	for row in WINDOW_GRID.y:
		for column in WINDOW_GRID.x:
			draw_rect(get_window_rect(Vector2i(column, row)), Color(0.15, 0.15, 0.19))
	if is_flashlight_on:
		var blink := clampf(sin(_time * 7.0) * 2.0, 0.0, 1.0)
		var lit := get_window_rect(LIT_WINDOW)
		draw_circle(lit.get_center(), 90.0, Color(1.0, 0.93, 0.6, 0.12 * blink))
		draw_rect(lit, Color(1.0, 0.93, 0.6, 0.35 + 0.65 * blink))
	draw_rect(Rect2(0, WATER_TOP + water_wave, SCREEN.x, SCREEN.y - WATER_TOP), Color(0.12, 0.17, 0.24, 0.95))
	draw_line(Vector2(0, WATER_TOP + water_wave), Vector2(SCREEN.x, WATER_TOP + water_wave), Color(0.35, 0.45, 0.55), 3.0)
	draw_rect(ROOF_RECT, Color(0.24, 0.23, 0.25))
	draw_rect(Rect2(ROOF_RECT.position - Vector2(10, 18), Vector2(ROOF_RECT.size.x + 20, 22)), Color(0.32, 0.3, 0.32))
