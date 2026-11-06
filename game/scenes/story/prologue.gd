extends Node2D
## 序章文游：屋顶上的小猫遇见伊尔妲。对白数据在 data/dialogue/prologue.json。

const DIALOGUE_PATH := "res://data/dialogue/prologue.json"
const LEVEL_SCENE := "res://scenes/levels/level_01.tscn"
const CAT_PORTRAIT := preload("res://assets/portraits/cat.png")
const CAT_POSITION := Vector2(480, 520)
const RING_POSITION := Vector2(1080, 300)

var _backdrop: StoryBackdrop
var _ring: IldaRing
var _cat: Sprite2D
var _mark: Node2D
var _tint: ColorRect


func _ready() -> void:
	_backdrop = StoryBackdrop.new()
	add_child(_backdrop)
	_cat = Sprite2D.new()
	_cat.texture = CAT_PORTRAIT
	_cat.scale = Vector2.ONE * 0.42
	_cat.position = CAT_POSITION
	add_child(_cat)
	_ring = IldaRing.new()
	_ring.position = RING_POSITION
	_ring.modulate.a = 0.0
	add_child(_ring)
	var tint_layer := CanvasLayer.new()
	tint_layer.layer = 4
	add_child(tint_layer)
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(1, 1, 1, 0)
	tint_layer.add_child(_tint)
	add_child(RainOverlay.new())

	var dialogue := DialogueBox.new()
	add_child(dialogue)
	dialogue.event_triggered.connect(_on_event)
	await get_tree().create_timer(0.6).timeout
	await dialogue.play(DialogueBox.load_lines(DIALOGUE_PATH))
	await _show_title_card()
	SceneRouter.go_to(LEVEL_SCENE)


func _on_event(event_name: String) -> void:
	match event_name:
		"flashlight":
			_backdrop.is_flashlight_on = true
		"ilda_appear":
			_flash(Color(1, 1, 1, 0.8), 0.9)
			create_tween().tween_property(_ring, "modulate:a", 1.0, 1.2)
		"weather_rain":
			_demo_weather(Weather.Type.RAIN)
		"weather_wind":
			_demo_weather(Weather.Type.WIND)
		"weather_snow":
			_demo_weather(Weather.Type.SNOW)
		"weather_sun":
			_demo_weather(Weather.Type.SUN)
		"accept_power":
			_ring.modulate.a = 1.0
			_ring.lit_segments = 1
			_flash(Color(1.0, 0.85, 0.4, 0.6), 1.0)
			_show_mark()
		"seed_drop":
			_drop_seed()


func _demo_weather(weather: Weather.Type) -> void:
	_flash(Color(Weather.get_color(weather), 0.28), 1.2)
	WeatherEffect.spawn(self, weather, Rect2(200, StoryBackdrop.WATER_TOP, 1500, 1), 1, 2.0)


func _flash(color: Color, seconds: float) -> void:
	_tint.color = color
	create_tween().tween_property(_tint, "color:a", 0.0, seconds)


func _show_mark() -> void:
	_mark = Node2D.new()
	_mark.position = CAT_POSITION + Vector2(0, -170)
	_mark.draw.connect(func() -> void:
		_mark.draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.82, 0.35, 0.3))
		_mark.draw_colored_polygon(PackedVector2Array([Vector2(0, -16), Vector2(10, 4), Vector2(0, 14), Vector2(-10, 4)]), Color(1.0, 0.82, 0.35))
	)
	add_child(_mark)
	_mark.modulate.a = 0.0
	create_tween().tween_property(_mark, "modulate:a", 1.0, 1.0)


func _drop_seed() -> void:
	var seed_node := Node2D.new()
	seed_node.position = RING_POSITION
	seed_node.draw.connect(func() -> void:
		seed_node.draw_circle(Vector2.ZERO, 26.0, Color(0.75, 1.0, 0.6, 0.25))
		seed_node.draw_circle(Vector2.ZERO, 9.0, Color(0.85, 1.0, 0.7))
	)
	add_child(seed_node)
	var landing := Vector2(CAT_POSITION.x + 150, StoryBackdrop.ROOF_RECT.position.y - 30)
	create_tween().tween_property(seed_node, "position", landing, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _show_title_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.text = "第一关\n被淹没的城市"
	label.modulate.a = 0.0
	layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.6)
	await tween.finished
