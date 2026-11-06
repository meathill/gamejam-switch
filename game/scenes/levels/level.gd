class_name Level
extends Node2D
## 关卡根节点：初始化状态、HUD、开场对白、重开、暂停、通关

const TITLE_SCENE := "res://scenes/story/title.tscn"

@export_file("*.json") var intro_dialogue: String = ""
@export var camera_limits: Rect2i = Rect2i(-400, -1300, 11000, 2000)

@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D

var _hud: Hud
var _rain: RainOverlay
var _complete_layer: CanvasLayer


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
	_hud = Hud.new()
	add_child(_hud)
	add_child(PauseMenu.new())
	GameState.level_completed.connect(_on_level_completed)
	if intro_dialogue and not GameState.has_seen_level_intro:
		GameState.has_seen_level_intro = true
		_player.is_input_locked = true
		var dialogue := DialogueBox.new()
		add_child(dialogue)
		await dialogue.play(DialogueBox.load_lines(intro_dialogue))
		dialogue.queue_free()
		_player.is_input_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		SceneRouter.reload()
	elif _complete_layer and event.is_action_pressed("advance"):
		SceneRouter.go_to(TITLE_SCENE)


func _on_level_completed() -> void:
	_player.is_input_locked = true
	_rain.fade_to(0.15, 3.0)
	_complete_layer = CanvasLayer.new()
	_complete_layer.layer = 30
	add_child(_complete_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_complete_layer.add_child(backdrop)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.text = "第一关完成\n\n你救下了 %d 位居民。城市的广播重新响起，雨声渐渐小了。\n\n残缺的圆环，亮起了一段。\n\n\nEnter 返回标题　　R 再玩一次" % GameState.rescued_count
	_complete_layer.add_child(label)
	backdrop.modulate.a = 0.0
	label.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(backdrop, "modulate:a", 1.0, 1.0)
	tween.tween_property(label, "modulate:a", 1.0, 1.5)
