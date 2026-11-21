@tool
class_name Evacuee
extends Interactable
## 撤离对象（村民、狗、守河人），计入通关目标。原点在脚底。
## rescue：沿 rescue_path 走（不走物理），走完发 rescued；evacuate：沿 evacuate_path 走到渡口，
## 完成一个 evacuee 目标并发 arrived。未获救就收到 evacuate 时先记下，获救后接着走。
## escort（守河人）：按 E 后开始跟随，每段路出发前等小猫跟上来。

signal level_event(event: String)

const WALK_SPEED := 220.0
const ESCORT_RANGE := 600.0
const BOB_HEIGHT := 4.0

@export var evacuee_name: String = "撤离对象"
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var display_height: float = 220.0
## 获救路线 / 撤离路线（世界坐标点列）
@export var rescue_path: PackedVector2Array = PackedVector2Array()
@export var evacuate_path: PackedVector2Array = PackedVector2Array()
## 护送模式：按 E 后跟随小猫走撤离路线
@export var is_escort: bool = false
@export_file("*.json") var dialogue: String = ""
@export var is_flipped: bool = false

var _rescue_started: bool = false
var _is_rescued: bool = false
var _evacuate_started: bool = false
var _evacuate_pending: bool = false
var _has_arrived: bool = false
var _is_following: bool = false
var _is_walking: bool = false
var _walk_dir: int = 1
var _walk_time: float = 0.0


func _ready() -> void:
	prompt_height = display_height + 60.0
	super()
	if not Engine.is_editor_hint():
		GameState.register_objective("evacuee")


func _process(delta: float) -> void:
	if _is_walking:
		_walk_time += delta
		queue_redraw()


func get_action_name() -> String:
	return "对话"


func can_interact() -> bool:
	if is_escort:
		return not _is_following
	return not dialogue.is_empty() and not _is_walking


func get_unmet_reason(condition: Dictionary) -> String:
	match condition.get("is", ""):
		"rescued":
			return "" if _is_rescued else "%s还没获救" % evacuee_name
		"arrived":
			return "" if _has_arrived else "%s还没撤到渡口" % evacuee_name
	return ""


func do_rescue(_params: Dictionary) -> void:
	if _rescue_started:
		return
	_rescue_started = true
	if not rescue_path.is_empty():
		await _walk_path(rescue_path)
	_is_rescued = true
	refresh_prompt()
	level_event.emit("rescued")
	if _evacuate_pending:
		_start_evacuate()


func do_evacuate(_params: Dictionary) -> void:
	if _evacuate_started or _has_arrived:
		return
	if not _is_rescued:
		_evacuate_pending = true
		return
	_start_evacuate()


func _interact() -> void:
	if not is_escort:
		await GameState.play_dialogue(dialogue)
		return
	_is_following = true
	refresh_prompt()
	if not dialogue.is_empty():
		await GameState.play_dialogue(dialogue)
	_follow_path()


## 沿点列逐段补间行走，不走物理
func _walk_path(points: PackedVector2Array) -> void:
	_is_walking = true
	for point in points:
		await _walk_to(point)
	_is_walking = false
	_walk_time = 0.0


func _walk_to(point: Vector2) -> void:
	var distance := global_position.distance_to(point)
	if distance < 1.0:
		return
	_walk_dir = -1 if point.x < global_position.x else 1
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", point, distance / WALK_SPEED)
	await tween.finished


## 护送：每段出发前等小猫进入跟随范围，第一次等待时提示一次
func _follow_path() -> void:
	var player := get_player()
	var has_prompted := false
	_is_walking = true
	for point in evacuate_path:
		while player.global_position.distance_to(global_position) > ESCORT_RANGE:
			_is_walking = false
			if not has_prompted:
				has_prompted = true
				GameState.post_message("%s在路口等你" % evacuee_name)
			await get_tree().physics_frame
			if not is_instance_valid(player):
				return
		_is_walking = true
		await _walk_to(point)
	_is_walking = false
	_walk_time = 0.0
	_arrive()


func _start_evacuate() -> void:
	_evacuate_started = true
	_evacuate_pending = false
	await _walk_path(evacuate_path)
	_arrive()


func _arrive() -> void:
	if _has_arrived:
		return
	_has_arrived = true
	GameState.complete_objective("evacuee")
	GameState.post_message("%s抵达了高地渡口" % evacuee_name)
	level_event.emit("arrived")


func _draw() -> void:
	var bob := sin(_walk_time * 10.0) * BOB_HEIGHT if _is_walking else 0.0
	if not texture:
		draw_rect(Rect2(-30, -display_height + bob, 60, display_height), Color(0.6, 0.55, 0.5))
		return
	var size := texture.get_size() * display_height / texture.get_height()
	if is_flipped != (_walk_dir < 0):
		draw_set_transform(Vector2(0, bob), 0.0, Vector2(-1, 1))
	else:
		draw_set_transform(Vector2(0, bob))
	draw_texture_rect(texture, Rect2(Vector2(-size.x / 2.0, -size.y), size), false)
	draw_set_transform(Vector2.ZERO)
