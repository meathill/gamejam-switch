extends SceneTree
## 开发用截图脚本：加载场景、执行脚本化步骤、按帧截图。
## godot --path game -s res://tests/capture.gd -- <scene> <output_dir> <scenario>

var _scene_path: String
var _output_dir: String
var _scenario: String
var _frame: int = 0
var _steps: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_scene_path = args[0]
	_output_dir = args[1]
	_scenario = args[2] if args.size() > 2 else "idle"
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_steps = _build_steps(_scenario)
	change_scene_to_file.call_deferred(_scene_path)


## 按物理帧计时：渲染帧不锁帧率，用它计时会比真实时间快很多
func _physics_process(_delta: float) -> bool:
	_frame += 1
	for step in _steps:
		if step["frame"] == _frame:
			_run(step)
	return _frame > int(_steps.back()["frame"])


func _run(step: Dictionary) -> void:
	# 不引用 Player 等依赖 autoload 的类型：-s 脚本编译时 autoload 尚未注册
	var player: Node = current_scene.get_node_or_null("Player")
	match step["do"]:
		"shot":
			var image := root.get_texture().get_image()
			image.save_png("%s/%s.png" % [_output_dir, step["name"]])
			if player:
				print("[capture] %s player=%s velocity=%s on_floor=%s state=%s animation=%s" % [
					step["name"], player.get("global_position"), player.get("velocity"),
					player.call("is_on_floor"), player.get("_state"), player.get_node("Sprite").get("animation"),
				])
		"teleport":
			player.call("respawn", step["to"])
		"weather":
			root.get_node("GameState").call("set_weather", step["weather"])
		"cast":
			player.set("facing", step.get("facing", 1))
			player.call("_cast")
		"press":
			_press(step["action"], true)
		"release":
			_press(step["action"], false)
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = step["key"]
			event.pressed = true
			Input.parse_input_event(event)
		"touch":
			var touch := InputEventScreenTouch.new()
			touch.index = step.get("index", 0)
			# 步骤里写的是 1920×1080 视口坐标，转换成窗口坐标
			touch.position = root.get_final_transform() * Vector2(step["at"])
			touch.pressed = step.get("pressed", true)
			Input.parse_input_event(touch)
		"log":
			var state: Node = root.get_node("GameState")
			print("[capture] %s x=%.0f weather=%s rescued=%d touch=%s paused=%s" % [
				step["name"], player.get("global_position").x, state.get("current_weather"),
				state.get("rescued_count"), state.get("is_touch_mode"), paused,
			])


func _press(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _build_steps(scenario: String) -> Array[Dictionary]:
	match scenario:
		"level":
			return [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 90, "do": "shot", "name": "01_start" },
				{ "frame": 95, "do": "teleport", "to": Vector2(1300, 0) },
				{ "frame": 140, "do": "shot", "name": "02_street_deep" },
				{ "frame": 141, "do": "weather", "weather": Weather.Type.SNOW },
				{ "frame": 142, "do": "cast" },
				{ "frame": 190, "do": "shot", "name": "03_street_ice" },
				{ "frame": 195, "do": "teleport", "to": Vector2(3500, 0) },
				{ "frame": 196, "do": "weather", "weather": Weather.Type.SUN },
				{ "frame": 240, "do": "cast" },
				{ "frame": 260, "do": "shot", "name": "04_plaza_polluted" },
				{ "frame": 265, "do": "teleport", "to": Vector2(2950, 0) },
				{ "frame": 266, "do": "weather", "weather": Weather.Type.RAIN },
				{ "frame": 300, "do": "cast" },
				{ "frame": 360, "do": "cast" },
				{ "frame": 420, "do": "shot", "name": "05_channel_full" },
				{ "frame": 480, "do": "teleport", "to": Vector2(3500, 0) },
				{ "frame": 530, "do": "shot", "name": "06_plaza_drained" },
				{ "frame": 535, "do": "teleport", "to": Vector2(5530, -60) },
				{ "frame": 580, "do": "cast" },
				{ "frame": 640, "do": "shot", "name": "07_canal_deep" },
				{ "frame": 641, "do": "weather", "weather": Weather.Type.WIND },
				{ "frame": 680, "do": "cast" },
				{ "frame": 760, "do": "cast" },
				{ "frame": 840, "do": "shot", "name": "08_raft_at_building" },
			]
		"finale":
			return [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 60, "do": "teleport", "to": Vector2(7340, -200) },
				{ "frame": 90, "do": "press", "action": "interact" },
				{ "frame": 92, "do": "release", "action": "interact" },
				{ "frame": 110, "do": "shot", "name": "11_rescue_window" },
				{ "frame": 120, "do": "teleport", "to": Vector2(8200, 0) },
				{ "frame": 121, "do": "weather", "weather": Weather.Type.SNOW },
				{ "frame": 150, "do": "cast" },
				{ "frame": 200, "do": "shot", "name": "12_lowland_ice" },
				{ "frame": 201, "do": "press", "action": "move_right" },
				{ "frame": 380, "do": "release", "action": "move_right" },
				{ "frame": 400, "do": "shot", "name": "13_goal_missing" },
				{ "frame": 410, "do": "teleport", "to": Vector2(4350, -40) },
				{ "frame": 440, "do": "press", "action": "interact" },
				{ "frame": 442, "do": "release", "action": "interact" },
				{ "frame": 460, "do": "teleport", "to": Vector2(9500, 0) },
				{ "frame": 470, "do": "press", "action": "move_right" },
				{ "frame": 560, "do": "release", "action": "move_right" },
				{ "frame": 680, "do": "shot", "name": "14_complete" },
			]
		"standing":
			return [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 90, "do": "shot", "name": "stand" },
				{ "frame": 91, "do": "log", "name": "stand" },
				{ "frame": 520, "do": "shot", "name": "rest" },
			]
		"touch":
			return [
				{ "frame": 20, "do": "touch", "at": Vector2(960, 300) },
				{ "frame": 22, "do": "touch", "at": Vector2(960, 300), "pressed": false },
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 70, "do": "shot", "name": "touch_01_controls" },
				{ "frame": 71, "do": "log", "name": "before_move" },
				{ "frame": 72, "do": "touch", "at": Vector2(420, 900) },
				{ "frame": 132, "do": "touch", "at": Vector2(420, 900), "pressed": false },
				{ "frame": 133, "do": "log", "name": "after_move_right" },
				{ "frame": 140, "do": "touch", "at": Vector2(1530, 735), "index": 1 },
				{ "frame": 142, "do": "touch", "at": Vector2(1530, 735), "index": 1, "pressed": false },
				{ "frame": 143, "do": "log", "name": "after_weather" },
				{ "frame": 150, "do": "teleport", "to": Vector2(4350, -40) },
				{ "frame": 180, "do": "shot", "name": "touch_02_interact" },
				{ "frame": 181, "do": "touch", "at": Vector2(1745, 640) },
				{ "frame": 183, "do": "touch", "at": Vector2(1745, 640), "pressed": false },
				{ "frame": 200, "do": "log", "name": "after_interact" },
				{ "frame": 210, "do": "touch", "at": Vector2(1855, 150) },
				{ "frame": 212, "do": "touch", "at": Vector2(1855, 150), "pressed": false },
				{ "frame": 240, "do": "shot", "name": "touch_03_paused" },
				{ "frame": 241, "do": "log", "name": "after_pause" },
			]
		"prologue":
			var steps: Array[Dictionary] = []
			for index in 34:
				var frame := 60 + index * 30
				steps.append({ "frame": frame, "do": "press", "action": "advance" })
				steps.append({ "frame": frame + 1, "do": "release", "action": "advance" })
				if index in [1, 6, 12, 22, 26, 33]:
					steps.append({ "frame": frame + 25, "do": "shot", "name": "prologue_%02d" % index })
			# 选项出现后按 Enter 选“接受”，再推进到种子落下
			steps.append({ "frame": 1100, "do": "press", "action": "ui_accept" })
			steps.append({ "frame": 1102, "do": "release", "action": "ui_accept" })
			for index in 4:
				steps.append({ "frame": 1160 + index * 40, "do": "press", "action": "advance" })
				steps.append({ "frame": 1161 + index * 40, "do": "release", "action": "advance" })
			steps.append({ "frame": 1420, "do": "shot", "name": "prologue_seed" })
			return steps
	return [{ "frame": 90, "do": "shot", "name": "idle" }, { "frame": 200, "do": "shot", "name": "idle_later" }]
