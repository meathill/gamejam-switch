class_name Level
extends Node2D
## 关卡根节点：初始化状态、HUD、虚拟按键、开场对白、重开、暂停、通关

const TITLE_SCENE := "res://scenes/story/title.tscn"
const COMPLETE_DELAY := 1.2

@export_file("*.json") var intro_dialogue: String = ""
@export var camera_limits: Rect2i = Rect2i(-400, -1300, 11000, 2000)

@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D

var _rain: RainOverlay
var _touch_controls: TouchControls


func _enter_tree() -> void:
	# 在子节点 _ready（居民注册）之前重置
	GameState.reset_level()


func _ready() -> void:
	GameState.checkpoint_position = _player.global_position
	_camera.limit_left = camera_limits.position.x
	_camera.limit_top = camera_limits.position.y
	_camera.limit_right = camera_limits.end.x
	_camera.limit_bottom = camera_limits.end.y
	_rain = RainOverlay.new()
	add_child(_rain)
	add_child(Hud.new())
	_touch_controls = TouchControls.new()
	add_child(_touch_controls)
	add_child(PauseMenu.new())
	GameState.level_completed.connect(_on_level_completed)
	if intro_dialogue and not GameState.has_seen_level_intro:
		GameState.has_seen_level_intro = true
		_set_gameplay_active(false)
		var dialogue := DialogueBox.new()
		add_child(dialogue)
		await dialogue.play(DialogueBox.load_lines(intro_dialogue))
		dialogue.queue_free()
		_set_gameplay_active(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		SceneRouter.reload()


func _set_gameplay_active(active: bool) -> void:
	_player.is_input_locked = not active
	_touch_controls.is_active = active


func _on_level_completed() -> void:
	_set_gameplay_active(false)
	_rain.fade_to(0.15, 3.0)
	await get_tree().create_timer(COMPLETE_DELAY).timeout
	var text := "第一关完成\n\n你救下了 %d 位居民。城市的广播重新响起，雨声渐渐小了。\n残缺的圆环，亮起了一段。" % GameState.rescued_count
	var menu := MenuOverlay.new(text, 30)
	menu.add_button("再玩一次", SceneRouter.reload)
	menu.add_button("返回标题", SceneRouter.go_to.bind(TITLE_SCENE))
	add_child(menu)
	menu.focus_first()
