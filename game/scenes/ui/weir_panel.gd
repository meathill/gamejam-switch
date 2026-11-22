class_name WeirPanel
extends Control
## HUD 活动堰示意图：小猫选中绞盘时显示。三块板按 下/中/上 从左到右、由低到高排成阶梯，
## 右上「湖」、左下「河湾」，箭头表示水往左下流；选中的板加白框，溃泄时面板红闪。

const PANEL_SIZE := Vector2(320, 150)
const FONT_SIZE := 18
const FLASH_SPEED := 8.0
## 每块板的底边中点（面板内坐标）：下段最低最左，上段最高最右
const BOARD_BASES: Array[Vector2] = [Vector2(80, 118), Vector2(160, 90), Vector2(240, 62)]
const BOARD_STAND := Vector2(16, 44)
const BOARD_FLAT := Vector2(46, 8)

var _weir: Weir = null
var _flash_time := 0.0


func _init() -> void:
	custom_minimum_size = PANEL_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	for index in WeirRules.BOARD_COUNT:
		add_child(_make_label(WeirRules.BOARD_NAMES[index], BOARD_BASES[index] + Vector2(-24, 6)))
	add_child(_make_label("湖", Vector2(282, 8)))
	add_child(_make_label("河湾", Vector2(10, 124)))


func set_weir(weir: Weir) -> void:
	if _weir == weir:
		return
	if _weir and _weir.state_changed.is_connected(_on_weir_state_changed):
		_weir.state_changed.disconnect(_on_weir_state_changed)
	_weir = weir
	if _weir:
		_weir.state_changed.connect(_on_weir_state_changed)
	visible = _weir != null
	queue_redraw()


func _on_weir_state_changed(_target: WeatherTarget) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if _weir and _weir.is_collapsed:
		_flash_time += delta
		queue_redraw()


func _make_label(text: String, at: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Color(0.08, 0.09, 0.13, 0.6))
	if not _weir:
		return
	# 水流箭头：湖 → 河湾，指向左下
	var arrow_from := Vector2(272, 42)
	var arrow_to := Vector2(60, 100)
	draw_line(arrow_from, arrow_to, WeirDrawing.WATER_COLOR, 5.0)
	var dir := (arrow_to - arrow_from).normalized()
	var side := dir.orthogonal() * 7.0
	draw_colored_polygon(PackedVector2Array([arrow_to + dir * 12.0, arrow_to + side, arrow_to - side]), WeirDrawing.WATER_COLOR)
	# 三块板：站立画竖条，放倒画平条带水流色；选中的加白框
	for index in WeirRules.BOARD_COUNT:
		var base := BOARD_BASES[index]
		var color: Color = Weir.BOARD_COLORS[index]
		if index < _weir.state.stage:
			var flat := Rect2(base - Vector2(BOARD_FLAT.x / 2.0, BOARD_FLAT.y), BOARD_FLAT)
			draw_rect(flat, WeirDrawing.WATER_COLOR)
			draw_rect(flat, color.darkened(0.3), false, 2.0)
		else:
			var stand := Rect2(base - Vector2(BOARD_STAND.x / 2.0, BOARD_STAND.y), BOARD_STAND)
			draw_rect(stand, color)
			if index == _weir.selection and not _weir.is_collapsed:
				draw_rect(stand.grow(3.0), Color.WHITE, false, 3.0)
	# 溃泄时整块面板红闪
	if _weir.is_collapsed:
		var alpha := 0.12 + 0.1 * (0.5 + 0.5 * sin(_flash_time * FLASH_SPEED))
		draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Color(1.0, 0.15, 0.1, alpha))
		draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Color(1.0, 0.2, 0.15, alpha * 2.5), false, 3.0)
