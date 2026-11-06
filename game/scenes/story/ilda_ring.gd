class_name IldaRing
extends Node2D
## 伊尔妲的残缺圆环（光影形态）。lit_segments 表示已点亮的段数。

const RADIUS := 150.0
const WIDTH := 14.0
const SEGMENTS := 4
const GAP := 0.18
const GLOW_COLOR := Color(0.75, 1.0, 0.8)
const MARK_COLOR := Color(1.0, 0.82, 0.35)

var lit_segments: int = 0:
	set(value):
		lit_segments = value
		queue_redraw()
var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var flicker := 0.7 + 0.3 * sin(_time * 2.3) * sin(_time * 5.1)
	draw_circle(Vector2.ZERO, RADIUS * 1.6, Color(GLOW_COLOR, 0.06 * flicker))
	var segment := TAU / SEGMENTS
	for index in SEGMENTS:
		var start := -PI / 2.0 + index * segment + GAP
		var end := start + segment - GAP * 2.0
		# 第四段缺一块，表现“残缺”
		if index == SEGMENTS - 1:
			end = start + segment * 0.45
		var is_lit := index < lit_segments
		var color := Color(MARK_COLOR if is_lit else GLOW_COLOR, (0.95 if is_lit else 0.55) * flicker)
		draw_arc(Vector2.ZERO, RADIUS, start, end, 32, color, WIDTH, true)
		draw_arc(Vector2.ZERO, RADIUS, start, end, 32, Color(color, 0.18), WIDTH * 3.0, true)
	draw_circle(Vector2(0, -RADIUS * 0.15), 10.0, Color(MARK_COLOR, 0.8 * flicker))
