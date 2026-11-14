extends SceneTree
## 开发用截图脚本：加载场景、执行脚本化步骤、按帧截图。
## godot --path game -s res://tests/capture.gd -- <scene> <output_dir> <scenario> [level_id]

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
	_start.call_deferred(args[3] if args.size() > 3 else "")


func _start(level_id: String) -> void:
	if level_id:
		# 指定关卡时跳过开场标题卡和对白，场景步骤里不需要再按 Esc
		var state: Node = root.get_node("GameState")
		state.set("current_level_id", level_id)
		(state.get("seen_intros") as Dictionary)[level_id] = true
	change_scene_to_file(_scene_path)


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
			print("[capture] %s pos=%s locked=%s weather=%s rescued=%d touch=%s paused=%s" % [
				step["name"], player.get("global_position"), player.get("is_input_locked"), state.get("current_weather"),
				state.call("get_objective", "resident").x, state.get("is_touch_mode"), paused,
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
				{ "frame": 430, "do": "teleport", "to": Vector2(3550, 0) },
				{ "frame": 450, "do": "press", "action": "interact" },
				{ "frame": 452, "do": "release", "action": "interact" },
				{ "frame": 530, "do": "shot", "name": "06_plaza_drained" },
				{ "frame": 535, "do": "teleport", "to": Vector2(5530, -60) },
				{ "frame": 580, "do": "cast" },
				{ "frame": 640, "do": "shot", "name": "07_canal_deep" },
				{ "frame": 641, "do": "weather", "weather": Weather.Type.WIND },
				{ "frame": 680, "do": "cast" },
				{ "frame": 700, "do": "shot", "name": "07b_wind" },
				{ "frame": 760, "do": "cast" },
				{ "frame": 840, "do": "shot", "name": "08_raft_at_building" },
			]
		"finale":
			return [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 60, "do": "teleport", "to": Vector2(2700, 0) },
				{ "frame": 80, "do": "cast" },
				{ "frame": 140, "do": "cast" },
				{ "frame": 200, "do": "teleport", "to": Vector2(3550, 0) },
				{ "frame": 220, "do": "press", "action": "interact" },
				{ "frame": 222, "do": "release", "action": "interact" },
				{ "frame": 320, "do": "shot", "name": "11_uncle_leaves" },
				{ "frame": 330, "do": "teleport", "to": Vector2(7340, -200) },
				{ "frame": 360, "do": "press", "action": "interact" },
				{ "frame": 362, "do": "release", "action": "interact" },
				{ "frame": 380, "do": "shot", "name": "12_rescue_window" },
				{ "frame": 390, "do": "teleport", "to": Vector2(10450, -540) },
				{ "frame": 400, "do": "press", "action": "move_right" },
				{ "frame": 490, "do": "release", "action": "move_right" },
				{ "frame": 620, "do": "shot", "name": "14_complete" },
			]
		"stairs":
			var steps: Array[Dictionary] = [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 50, "do": "teleport", "to": Vector2(9200, 220) },
				{ "frame": 70, "do": "press", "action": "move_right" },
			]
			for index in 4:
				var frame := 80 + index * 45
				steps.append({ "frame": frame, "do": "press", "action": "jump" })
				steps.append({ "frame": frame + 20, "do": "release", "action": "jump" })
				steps.append({ "frame": frame + 40, "do": "log", "name": "after_jump_%d" % index })
			steps.append({ "frame": 270, "do": "shot", "name": "stairs_top" })
			steps.append({ "frame": 420, "do": "release", "action": "move_right" })
			steps.append({ "frame": 440, "do": "shot", "name": "stairs_goal" })
			steps.append({ "frame": 401, "do": "log", "name": "goal" })
			return steps
		"garden":
			return [
				{ "frame": 40, "do": "key", "key": KEY_ESCAPE },
				{ "frame": 50, "do": "teleport", "to": Vector2(8150, 0) },
				{ "frame": 51, "do": "press", "action": "move_right" },
				{ "frame": 75, "do": "release", "action": "move_right" },
				{ "frame": 120, "do": "shot", "name": "garden_trash" },
				{ "frame": 121, "do": "teleport", "to": Vector2(8600, 220) },
				{ "frame": 130, "do": "press", "action": "move_left" },
				{ "frame": 150, "do": "press", "action": "jump" },
				{ "frame": 170, "do": "release", "action": "jump" },
				{ "frame": 200, "do": "release", "action": "move_left" },
				{ "frame": 210, "do": "log", "name": "garden_exit" },
				{ "frame": 211, "do": "shot", "name": "garden_exit" },
			]
		"farm":
			var steps: Array[Dictionary] = []
			var stops: Array[Vector2] = [
				Vector2(150, 0), Vector2(1100, -260), Vector2(2300, 0), Vector2(2900, 0), Vector2(3550, 0),
				Vector2(4300, 0), Vector2(3300, 1300), Vector2(2800, 1300), Vector2(2200, 1300), Vector2(5000, 0),
			]
			for index in stops.size():
				steps.append({ "frame": 60 + index * 40, "do": "teleport", "to": stops[index] })
				steps.append({ "frame": 95 + index * 40, "do": "shot", "name": "farm_%02d" % index })
			return steps
		"farm_moves":
			# B 助跑跳过低洼田到 D；从 D 跳回低洼田左侧台阶再上 B；地下从隐藏平台跳上泵房平台
			return [
				{ "frame": 50, "do": "teleport", "to": Vector2(1250, -260) },
				{ "frame": 60, "do": "press", "action": "move_right" },
				{ "frame": 85, "do": "press", "action": "jump" },
				{ "frame": 110, "do": "release", "action": "jump" },
				{ "frame": 170, "do": "release", "action": "move_right" },
				{ "frame": 180, "do": "log", "name": "b_to_d" },
				{ "frame": 190, "do": "teleport", "to": Vector2(2000, 0) },
				{ "frame": 200, "do": "press", "action": "move_left" },
				{ "frame": 205, "do": "press", "action": "jump" },
				{ "frame": 225, "do": "release", "action": "jump" },
				{ "frame": 260, "do": "press", "action": "jump" },
				{ "frame": 285, "do": "release", "action": "jump" },
				{ "frame": 320, "do": "release", "action": "move_left" },
				{ "frame": 330, "do": "log", "name": "d_to_b" },
				{ "frame": 340, "do": "teleport", "to": Vector2(2760, 1300) },
				{ "frame": 345, "do": "weather", "weather": Weather.Type.WIND },
				{ "frame": 360, "do": "cast" },
				{ "frame": 380, "do": "teleport", "to": Vector2(2300, 1300) },
				{ "frame": 381, "do": "weather", "weather": Weather.Type.SUN },
				{ "frame": 400, "do": "cast" },
				{ "frame": 440, "do": "teleport", "to": Vector2(2720, 1300) },
				{ "frame": 450, "do": "press", "action": "move_left" },
				{ "frame": 455, "do": "press", "action": "jump" },
				{ "frame": 475, "do": "release", "action": "jump" },
				{ "frame": 479, "do": "release", "action": "move_left" },
				{ "frame": 510, "do": "log", "name": "on_platform" },
				{ "frame": 515, "do": "press", "action": "move_left" },
				{ "frame": 518, "do": "press", "action": "jump" },
				{ "frame": 540, "do": "release", "action": "jump" },
				{ "frame": 560, "do": "release", "action": "move_left" },
				{ "frame": 580, "do": "log", "name": "on_ledge" },
				{ "frame": 581, "do": "shot", "name": "on_ledge" },
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
