@tool
class_name WeatherRuleArea
extends Area2D
## 天气限制区域：小猫在里面时，disabled_weathers 里的天气不能施放（轮盘和按钮变灰，施放时提示 reason）。
## 原点在左上角。is_active 为 false 时不生效，机关可以随时开关它。

@export var size: Vector2 = Vector2(600, 600):
	set(value):
		size = value
		queue_redraw()
@export var disabled_weathers: Array[Weather.Type] = []
@export var reason: String = "这里不能使用这种天气"
@export var is_active: bool = true:
	set(value):
		is_active = value
		if not Engine.is_editor_hint() and is_inside_tree():
			GameState.weather_rules_changed.emit()


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = size / 2.0
	add_child(collision)
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			GameState.enter_weather_rule(self)
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			GameState.exit_weather_rule(self)
	)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.4, 0.3, 0.12))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.4, 0.3, 0.6), false, 3.0)
