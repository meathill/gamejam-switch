class_name Level
extends Node2D
## 关卡根节点：按 GameState.current_level_id 读取关卡数据，初始化状态、HUD、虚拟按键、开场对白、重开、暂停、通关

const TITLE_SCENE := "res://scenes/story/title.tscn"
const COMPLETE_DELAY := 1.2

@onready var map: LevelMap = $LevelMap
@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D

var data: LevelData
var _rain: RainOverlay
var _touch_controls: TouchControls


func _enter_tree() -> void:
	# 在子节点 _ready（居民注册、地图生成）之前重置并读取数据
	GameState.reset_level()
	if GameState.current_level_id.is_empty():
		GameState.current_level_id = LevelCatalog.first()
	data = LevelData.load_level(GameState.current_level_id)
	($LevelMap as LevelMap).data = data


func _ready() -> void:
	_player.global_position = data.player_start
	GameState.checkpoint_position = _player.global_position
	_camera.limit_left = data.camera_limits.position.x
	_camera.limit_top = data.camera_limits.position.y
	_camera.limit_right = data.camera_limits.end.x
	_camera.limit_bottom = data.camera_limits.end.y
	_camera.reset_smoothing()
	_rain = RainOverlay.new()
	add_child(_rain)
	add_child(Hud.new())
	_touch_controls = TouchControls.new()
	add_child(_touch_controls)
	add_child(PauseMenu.new())
	GameState.level_completed.connect(_on_level_completed)
	if data.intro_dialogue and not GameState.seen_intros.get(data.id, false):
		GameState.seen_intros[data.id] = true
		_set_gameplay_active(false)
		await _play_dialogue(data.intro_dialogue)
		_set_gameplay_active(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		SceneRouter.reload()


func _set_gameplay_active(active: bool) -> void:
	_player.is_input_locked = not active
	_touch_controls.is_active = active


func _play_dialogue(path: String) -> void:
	var dialogue := DialogueBox.new()
	add_child(dialogue)
	await dialogue.play(DialogueBox.load_lines(path))
	dialogue.queue_free()


func _on_level_completed() -> void:
	_set_gameplay_active(false)
	_rain.fade_to(0.15, 3.0)
	await get_tree().create_timer(COMPLETE_DELAY).timeout
	if data.outro_dialogue:
		await _play_dialogue(data.outro_dialogue)
	var menu := MenuOverlay.new(data.complete_text.format({ "rescued": GameState.rescued_count }), 30)
	var next_id := LevelCatalog.get_next(data.id)
	if next_id:
		menu.add_button("下一关", SceneRouter.go_to_level.bind(next_id))
	menu.add_button("再玩一次", SceneRouter.reload)
	menu.add_button("返回标题", SceneRouter.go_to.bind(TITLE_SCENE))
	add_child(menu)
	menu.focus_first()
