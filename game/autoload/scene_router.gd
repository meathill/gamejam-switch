extends CanvasLayer
## 场景切换，带淡入淡出

const FADE_SECONDS := 0.45
const LEVEL_SCENE := "res://scenes/levels/level.tscn"

var _overlay: ColorRect
var _is_busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func go_to(scene_path: String) -> void:
	if _is_busy:
		return
	_is_busy = true
	await _fade_to(1.0)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_to(0.0)
	_is_busy = false


func go_to_level(level_id: String) -> void:
	GameState.current_level_id = level_id
	go_to(LEVEL_SCENE)


func reload() -> void:
	go_to(get_tree().current_scene.scene_file_path)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", alpha, FADE_SECONDS)
	await tween.finished
