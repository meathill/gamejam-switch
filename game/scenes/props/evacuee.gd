@tool
class_name Evacuee
extends Interactable
## 撤离对象（村民、狗、守河人），计入通关目标。原点在脚底。
## rescue：沿 rescue_path 走（不走物理），走完发 rescued；evacuate：沿 evacuate_path 走到画面边缘，
## 淡出后经过“画面外路程”，再从 arrive_path 起点淡入走到渡口，发 arrived。
## 未获救就收到 evacuate 时先记下，获救后接着走。
## escort（守河人）：按 E 后开始跟随，每段路出发前等小猫跟上来。

signal level_event(event: String)

const ESCORT_RANGE := 600.0
const BOB_HEIGHT := 4.0
const SWAY_RADIANS := 0.087
const SWAY_OMEGA := 15.7
const FADE_SECONDS := 0.4
## 画面外路程按步行耗时算，封顶这么多秒
const OFFSCREEN_WALK_MAX := 12.0

@export var evacuee_name: String = "撤离对象"
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var display_height: float = 220.0
## 获救路线 / 木排解法获救路线 / 撤离路线（离开画面的一段）/ 走进画面的路线（世界坐标点列）
## 各自的 *_jumps 记录「跳到该下标点」的下标，即同高也强制跳
@export var rescue_path: PackedVector2Array = PackedVector2Array()
@export var raft_rescue_path: PackedVector2Array = PackedVector2Array()
@export var evacuate_path: PackedVector2Array = PackedVector2Array()
@export var arrive_path: PackedVector2Array = PackedVector2Array()
@export var rescue_jumps: PackedInt32Array = PackedInt32Array()
@export var raft_rescue_jumps: PackedInt32Array = PackedInt32Array()
@export var evacuate_jumps: PackedInt32Array = PackedInt32Array()
@export var arrive_jumps: PackedInt32Array = PackedInt32Array()
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
var _is_hopping: bool = false
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


func do_rescue(params: Dictionary) -> void:
	if _rescue_started:
		return
	_rescue_started = true
	# links 里 route 选路线：木排解法走 raft_rescue_path，默认（冰路）走 rescue_path
	var path := rescue_path
	var jumps := rescue_jumps
	if params.get("route") == "raft" and not raft_rescue_path.is_empty():
		path = raft_rescue_path
		jumps = raft_rescue_jumps
	if not path.is_empty():
		await _walk_points(path, jumps)
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


## 沿点列逐段补间行走；相邻两点有落差或该点在 jumps 里就走 WalkPath 的抛物线跳跃，不走物理
func _walk_points(points: PackedVector2Array, jumps: PackedInt32Array = PackedInt32Array()) -> void:
	_is_walking = true
	for index in points.size():
		await _walk_to(points[index], jumps.has(index))
	_is_walking = false
	_walk_time = 0.0


func _walk_to(point: Vector2, force_hop := false) -> void:
	var start := global_position
	var duration := WalkPath.get_duration(start, point, force_hop)
	if duration < 0.01:
		return
	_walk_dir = -1 if point.x < global_position.x else 1
	_is_hopping = WalkPath.is_hop(start, point, force_hop)
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(_apply_walk_sample.bind(start, point, force_hop), 0.0, 1.0, duration)
	await tween.finished
	_is_hopping = false


func _apply_walk_sample(t: float, start: Vector2, point: Vector2, force_hop: bool) -> void:
	global_position = WalkPath.sample(start, point, t, force_hop)


## 护送：每段出发前等小猫进入跟随范围，第一次等待时提示一次
func _follow_path() -> void:
	var player := get_player()
	var has_prompted := false
	_is_walking = true
	for index in evacuate_path.size():
		while player.global_position.distance_to(global_position) > ESCORT_RANGE:
			_is_walking = false
			if not has_prompted:
				has_prompted = true
				GameState.post_message("%s在路口等你" % evacuee_name)
			await get_tree().physics_frame
			if not is_instance_valid(player):
				return
		_is_walking = true
		await _walk_to(evacuate_path[index], evacuate_jumps.has(index))
	_is_walking = false
	_walk_time = 0.0
	_arrive()


func _start_evacuate() -> void:
	_evacuate_started = true
	_evacuate_pending = false
	await _walk_points(evacuate_path, evacuate_jumps)
	if arrive_path.is_empty():
		_arrive()
		return
	# 画面外那段路：淡出 → 按步行耗时等待 → 瞬移到 arrive_path 起点，淡入后走完
	await _fade_to(0.0)
	var offscreen := evacuate_path[evacuate_path.size() - 1].distance_to(arrive_path[0]) / WalkPath.WALK_SPEED
	await get_tree().create_timer(minf(offscreen, OFFSCREEN_WALK_MAX)).timeout
	global_position = arrive_path[0]
	_walk_dir = -1 if arrive_path.size() > 1 and arrive_path[1].x < arrive_path[0].x else 1
	await _fade_to(1.0)
	await _walk_points(arrive_path, arrive_jumps)
	_arrive()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished


func _arrive() -> void:
	if _has_arrived:
		return
	_has_arrived = true
	GameState.complete_objective("evacuee")
	GameState.post_message("%s抵达了高地渡口" % evacuee_name)
	level_event.emit("arrived")


func _draw() -> void:
	var bob := sin(_walk_time * 10.0) * BOB_HEIGHT if _is_walking else 0.0
	# 平走时绕脚底左右摇摆，跳跃时不摇
	var sway := 0.0
	if _is_walking and not _is_hopping:
		sway = sin(_walk_time * SWAY_OMEGA) * SWAY_RADIANS
	if not texture:
		draw_rect(Rect2(-30, -display_height + bob, 60, display_height), Color(0.6, 0.55, 0.5))
		return
	var size := texture.get_size() * display_height / texture.get_height()
	var flip := Vector2(-1, 1) if is_flipped != (_walk_dir < 0) else Vector2.ONE
	draw_set_transform(Vector2(0, bob), sway, flip)
	draw_texture_rect(texture, Rect2(Vector2(-size.x / 2.0, -size.y), size), false)
	draw_set_transform(Vector2.ZERO)
