class_name TouchButton
extends Node2D
## 圆形虚拟按键。内部用 TouchScreenButton 处理多点触控并触发输入动作，这里只负责外观。

const BACKGROUND_COLOR := Color(0.05, 0.06, 0.09, 0.45)
const PRESSED_COLOR := Color(1.0, 0.9, 0.6, 0.45)
const RING_COLOR := Color(1, 1, 1, 0.55)

var radius: float
var icon: Texture2D:
	set(value):
		icon = value
		queue_redraw()
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
var _is_pressed: bool = false


func _init(action: StringName, icon_texture: Texture2D, button_radius: float, slide_to_press: bool = false) -> void:
	radius = button_radius
	icon = icon_texture
	var shape := CircleShape2D.new()
	shape.radius = button_radius * 1.15
	var button := TouchScreenButton.new()
	button.shape = shape
	button.action = action
	button.passby_press = slide_to_press
	button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	button.pressed.connect(_set_pressed.bind(true))
	button.released.connect(_set_pressed.bind(false))
	add_child(button)


func _set_pressed(pressed: bool) -> void:
	_is_pressed = pressed
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, PRESSED_COLOR if _is_pressed else BACKGROUND_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, RING_COLOR, 4.0, true)
	var icon_size := radius * 1.0
	draw_texture_rect(icon, Rect2(Vector2.ONE * -icon_size / 2.0, Vector2.ONE * icon_size), false, tint)
