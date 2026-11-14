extends RefCounted
## 在关卡里执行解法步骤并断言（tests/solutions/<id>.json）。每个步骤只有一个动作：
##   { "teleport": [x, y] }                      传送小猫
##   { "cast": "snow", "facing": 1, "wait": 0.9 } 切换天气并施放，之后等待动画（秒）
##   { "interact": true }                         按一次互动键
##   { "walk": 1, "seconds": 2.0 }                按住方向键走一段
##   { "wait": 1.5 }                              等待
##   { "expect_water": "id", "level": 2, "frozen": true, "polluted": false, "raft_dock": 1 }
##   { "expect": { "rescued": 2, "fields": 3, "complete": true } }

const PHYSICS_FPS := 60
const SETTLE_FRAMES := 8
const DEFAULT_CAST_WAIT := 0.9

var _test: GutTest
var _level: Level
var _player: Player


func _init(test: GutTest, level: Level) -> void:
	_test = test
	_level = level
	_player = level.get_node("Player")


func run(steps: Array) -> void:
	for index in steps.size():
		var step: Dictionary = steps[index]
		await _run_step(step, "步骤 #%d %s" % [index, JSON.stringify(step)])


func _run_step(step: Dictionary, label: String) -> void:
	if step.has("teleport"):
		_player.respawn(LevelData.to_vector(step["teleport"]))
		await _wait_frames(SETTLE_FRAMES)
		for frame in PHYSICS_FPS * 2:
			if _player.is_on_floor():
				break
			await _wait_frames(1)
	elif step.has("cast"):
		GameState.set_weather(Weather.from_key(step["cast"]))
		_player.facing = step.get("facing", _player.facing)
		_test.assert_true(_player.is_on_floor(), "%s：小猫不在地面上，无法施放" % label)
		_player.call("_cast")
		await _wait_seconds(step.get("wait", DEFAULT_CAST_WAIT))
	elif step.has("interact"):
		_press("interact", true)
		await _wait_frames(2)
		_press("interact", false)
		await _wait_frames(2)
	elif step.has("walk"):
		var action := "move_right" if int(step["walk"]) > 0 else "move_left"
		Input.action_press(action)
		await _wait_seconds(step.get("seconds", 1.0))
		Input.action_release(action)
		await _wait_frames(SETTLE_FRAMES)
	elif step.has("wait"):
		await _wait_seconds(step["wait"])
	elif step.has("expect_water"):
		_expect_water(step, label)
	elif step.has("expect"):
		_expect(step["expect"], label)
	else:
		_test.fail_test("%s：未知步骤" % label)


func _expect_water(step: Dictionary, label: String) -> void:
	var zone := _level.map.get_object(step["expect_water"]) as WaterZone
	_test.assert_not_null(zone, "%s：找不到水域" % label)
	if not zone:
		return
	var state := zone.get_state()
	if step.has("level"):
		_test.assert_eq(state.level, int(step["level"]), "%s：水位" % label)
	if step.has("frozen"):
		_test.assert_eq(state.is_frozen, step["frozen"], "%s：结冰" % label)
	if step.has("polluted"):
		_test.assert_eq(state.is_polluted, step["polluted"], "%s：污染" % label)
	if step.has("raft_dock"):
		_test.assert_eq(zone.get_rafts()[0].dock_index, int(step["raft_dock"]), "%s：浮箱停靠点" % label)


func _expect(expected: Dictionary, label: String) -> void:
	if expected.has("rescued"):
		_test.assert_eq(GameState.get_objective("resident").x, int(expected["rescued"]), "%s：救出人数" % label)
	if expected.has("fields"):
		_test.assert_eq(GameState.get_objective("field").x, int(expected["fields"]), "%s：恢复的田" % label)
	if expected.has("complete"):
		_test.assert_eq(GameState.is_level_complete, expected["complete"], "%s：通关" % label)


func _press(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _wait_seconds(seconds: float) -> void:
	await _wait_frames(ceili(seconds * PHYSICS_FPS))


func _wait_frames(count: int) -> void:
	for frame in count:
		await _level.get_tree().physics_frame
