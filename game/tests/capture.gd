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
		"call":
			var obj: Node = current_scene.get("map").get_object(step["id"])
			obj.callv(step["method"], step.get("args", []))
		"prop":
			var obj2: Node = current_scene.get("map").get_object(step["id"])
			obj2.set(step["prop"], step["value"])
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
				{ "frame": 430, "do": "teleport", "to": Vector2(3170, 0) },
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
				{ "frame": 200, "do": "teleport", "to": Vector2(3170, 0) },
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
		"gondola":
			# 吊斗：走向吊斗被斗壁挡住 → 跳进斗里 → 风推滑行 → 到 C 端跳出
			return [
				{ "frame": 50, "do": "teleport", "to": Vector2(1350, -600) },
				{ "frame": 60, "do": "press", "action": "move_right" },
				{ "frame": 110, "do": "release", "action": "move_right" },
				{ "frame": 115, "do": "shot", "name": "gondola_blocked" },
				{ "frame": 116, "do": "log", "name": "blocked" },
				{ "frame": 130, "do": "press", "action": "move_right" },
				{ "frame": 135, "do": "press", "action": "jump" },
				{ "frame": 155, "do": "release", "action": "move_right" },
				{ "frame": 180, "do": "release", "action": "jump" },
				{ "frame": 245, "do": "log", "name": "in_bucket" },
				{ "frame": 250, "do": "shot", "name": "gondola_in" },
				{ "frame": 270, "do": "weather", "weather": Weather.Type.WIND },
				{ "frame": 275, "do": "cast" },
				{ "frame": 380, "do": "shot", "name": "gondola_mid" },
				{ "frame": 500, "do": "log", "name": "arrived" },
				{ "frame": 505, "do": "shot", "name": "gondola_arrived" },
				{ "frame": 540, "do": "press", "action": "move_left" },
				{ "frame": 545, "do": "press", "action": "jump" },
				{ "frame": 565, "do": "release", "action": "move_left" },
				{ "frame": 590, "do": "release", "action": "jump" },
				{ "frame": 640, "do": "log", "name": "out" },
				{ "frame": 645, "do": "shot", "name": "gondola_out" },
			]
		"valley":
			var steps: Array[Dictionary] = []
			var stops: Array[Dictionary] = [
				{ "name": "a", "at": Vector2(400, -700) },
				{ "name": "b", "at": Vector2(1200, -600) },
				{ "name": "c", "at": Vector2(2500, -250) },
				{ "name": "d", "at": Vector2(3550, -450) },
				{ "name": "e", "at": Vector2(4500, -450) },
				{ "name": "f", "at": Vector2(5150, 150) },
				{ "name": "g", "at": Vector2(6150, -300) },
				{ "name": "i", "at": Vector2(7500, -700) },
				{ "name": "k", "at": Vector2(8900, -1050) },
				{ "name": "l", "at": Vector2(9550, -1150) },
			]
			for index in stops.size():
				steps.append({ "frame": 60 + index * 40, "do": "teleport", "to": stops[index]["at"] })
				steps.append({ "frame": 95 + index * 40, "do": "shot", "name": "valley_%s" % stops[index]["name"] })
			# 吊斗滑行中途
			steps.append({ "frame": 470, "do": "teleport", "to": Vector2(1500, -640) })
			steps.append({ "frame": 475, "do": "weather", "weather": Weather.Type.WIND })
			steps.append({ "frame": 480, "do": "cast" })
			steps.append({ "frame": 560, "do": "shot", "name": "valley_gondola_mid" })
			# stage_2 后：H 岩架出现、G 翻白沫
			steps.append({ "frame": 620, "do": "call", "id": "weir", "method": "confirm" })
			steps.append({ "frame": 810, "do": "prop", "id": "weir", "prop": "selection", "value": 1 })
			steps.append({ "frame": 812, "do": "call", "id": "weir", "method": "confirm" })
			steps.append({ "frame": 1000, "do": "teleport", "to": Vector2(5150, 150) })
			steps.append({ "frame": 1040, "do": "shot", "name": "valley_f_after_stage2" })
			steps.append({ "frame": 1045, "do": "teleport", "to": Vector2(5600, -800) })
			steps.append({ "frame": 1085, "do": "shot", "name": "valley_h" })
			return steps
		"valley_moves":
			# 真实按键验证关键跳跃：沙洲冰面 → C 高台；E ↔ F 台阶；H 岩架；K 山坡到渡口
			# 每段落水后给够 respawn 时间再 teleport，避免挂起的重生把猫拽回检查点
			return [
				{ "frame": 50, "do": "teleport", "to": Vector2(2760, -160) },
				{ "frame": 55, "do": "weather", "weather": Weather.Type.SNOW },
				{ "frame": 60, "do": "cast" },
				{ "frame": 100, "do": "teleport", "to": Vector2(2950, -250) },
				{ "frame": 110, "do": "press", "action": "move_right" },
				{ "frame": 118, "do": "press", "action": "jump" },
				{ "frame": 140, "do": "release", "action": "jump" },
				{ "frame": 150, "do": "release", "action": "move_right" },
				{ "frame": 180, "do": "log", "name": "sandbar_to_step" },
				{ "frame": 185, "do": "shot", "name": "moves_step_c" },
				# step_c → C 高台
				{ "frame": 210, "do": "teleport", "to": Vector2(3150, -350) },
				{ "frame": 220, "do": "press", "action": "move_right" },
				{ "frame": 228, "do": "press", "action": "jump" },
				{ "frame": 250, "do": "release", "action": "jump" },
				{ "frame": 260, "do": "release", "action": "move_right" },
				{ "frame": 280, "do": "log", "name": "step_to_platform" },
				{ "frame": 285, "do": "shot", "name": "moves_platform_c" },
				# E → F 下台阶（走着下去，在岸边停，不进深水）
				{ "frame": 310, "do": "teleport", "to": Vector2(4750, -450) },
				{ "frame": 320, "do": "press", "action": "move_right" },
				{ "frame": 370, "do": "release", "action": "move_right" },
				{ "frame": 390, "do": "log", "name": "e_to_f_down" },
				{ "frame": 395, "do": "shot", "name": "moves_f_shore" },
				# F → E 跳回三级台阶
				{ "frame": 420, "do": "press", "action": "move_left" },
				{ "frame": 435, "do": "press", "action": "jump" },
				{ "frame": 475, "do": "release", "action": "jump" },
				{ "frame": 490, "do": "press", "action": "jump" },
				{ "frame": 530, "do": "release", "action": "jump" },
				{ "frame": 550, "do": "press", "action": "jump" },
				{ "frame": 590, "do": "release", "action": "jump" },
				{ "frame": 610, "do": "press", "action": "jump" },
				{ "frame": 650, "do": "release", "action": "jump" },
				{ "frame": 660, "do": "release", "action": "move_left" },
				{ "frame": 675, "do": "log", "name": "f_to_e_up" },
				{ "frame": 680, "do": "shot", "name": "moves_back_on_e" },
				# 推进到 stage_2 显示 H 岩架，再跳上去
				{ "frame": 720, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 920, "do": "prop", "id": "weir", "prop": "selection", "value": 1 },
				{ "frame": 922, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 1070, "do": "teleport", "to": Vector2(4600, -620) },
				{ "frame": 1080, "do": "press", "action": "move_right" },
				{ "frame": 1090, "do": "press", "action": "jump" },
				{ "frame": 1130, "do": "release", "action": "jump" },
				{ "frame": 1160, "do": "release", "action": "move_right" },
				{ "frame": 1170, "do": "log", "name": "on_ledge_h" },
				{ "frame": 1175, "do": "shot", "name": "moves_ledge_h" },
				# K 山坡：从水文站平台一路跳到渡口
				{ "frame": 1220, "do": "teleport", "to": Vector2(7600, -700) },
				{ "frame": 1230, "do": "log", "name": "on_platform_i" },
				{ "frame": 1240, "do": "press", "action": "move_right" },
				{ "frame": 1280, "do": "press", "action": "jump" },
				{ "frame": 1320, "do": "release", "action": "jump" },
				{ "frame": 1345, "do": "press", "action": "jump" },
				{ "frame": 1385, "do": "release", "action": "jump" },
				{ "frame": 1410, "do": "press", "action": "jump" },
				{ "frame": 1450, "do": "release", "action": "jump" },
				{ "frame": 1475, "do": "press", "action": "jump" },
				{ "frame": 1515, "do": "release", "action": "jump" },
				{ "frame": 1550, "do": "release", "action": "move_right" },
				{ "frame": 1570, "do": "log", "name": "k_to_l" },
				{ "frame": 1575, "do": "shot", "name": "moves_ferry" },
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
		"spots":
			# 远程天气目标：A 区无可见框、HUD 行高亮；施放后镜头切到真实地点看特效再回来；点 HUD 行预览
			# 只施放一次（水尺 3→4），避免第二次施放触发溃泄抢走镜头焦点
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(0, -700) },
				{ "frame": 90, "do": "shot", "name": "spots_a" },
				{ "frame": 100, "do": "weather", "weather": Weather.Type.RAIN },
				{ "frame": 105, "do": "cast" },
				{ "frame": 170, "do": "shot", "name": "lake_rain" },
				{ "frame": 400, "do": "shot", "name": "spots_back" },
				{ "frame": 740, "do": "touch", "at": Vector2(1700, 226) },
				{ "frame": 742, "do": "touch", "at": Vector2(1700, 226), "pressed": false },
				{ "frame": 800, "do": "shot", "name": "snowline_preview" },
			]
		"spots_sun":
			# 雪线日照单独一轮：水尺 3→4 不触发溃泄，镜头能停在雪坡看日照粒子
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(600, -700) },
				{ "frame": 90, "do": "shot", "name": "snowline_a" },
				{ "frame": 100, "do": "weather", "weather": Weather.Type.SUN },
				{ "frame": 105, "do": "cast" },
				{ "frame": 170, "do": "shot", "name": "snowline_sun" },
				{ "frame": 400, "do": "shot", "name": "snowline_back" },
				{ "frame": 450, "do": "teleport", "to": Vector2(8900, -1050) },
				{ "frame": 500, "do": "shot", "name": "ridge_from_k" },
			]
		"spots_over":
			# 在 A 连放两场雨把水尺推到 5：先看湖口（view 焦点先入队），溃泄传送期间镜头锁在湖面不跳，再看 F，最后回安全点
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(0, -700) },
				{ "frame": 100, "do": "weather", "weather": Weather.Type.RAIN },
				{ "frame": 105, "do": "cast" },
				{ "frame": 335, "do": "weather", "weather": Weather.Type.RAIN },
				{ "frame": 340, "do": "cast" },
				{ "frame": 420, "do": "shot", "name": "over_lake" },
				{ "frame": 510, "do": "shot", "name": "over_lake_after_respawn" },
				{ "frame": 600, "do": "shot", "name": "over_collapse" },
				{ "frame": 720, "do": "shot", "name": "over_safe" },
			]
		"continue":
			# 预写存档再进标题页：「继续游戏 · 第二关」在最上方带焦点，回车进入第二关
			SaveGame.save_level_id("level_02")
			return [
				{ "frame": 60, "do": "shot", "name": "title_continue" },
				{ "frame": 90, "do": "press", "action": "ui_accept" },
				{ "frame": 92, "do": "release", "action": "ui_accept" },
				{ "frame": 240, "do": "shot", "name": "continue_level" },
			]
		"level_select":
			# 标题页 → 下移进次要按钮行，再左→右归位到「选关」→ 回车打开弹层
			return [
				{ "frame": 60, "do": "shot", "name": "title" },
				{ "frame": 80, "do": "press", "action": "ui_down" },
				{ "frame": 82, "do": "release", "action": "ui_down" },
				{ "frame": 100, "do": "press", "action": "ui_left" },
				{ "frame": 102, "do": "release", "action": "ui_left" },
				{ "frame": 120, "do": "press", "action": "ui_right" },
				{ "frame": 122, "do": "release", "action": "ui_right" },
				{ "frame": 150, "do": "press", "action": "ui_accept" },
				{ "frame": 152, "do": "release", "action": "ui_accept" },
				{ "frame": 220, "do": "shot", "name": "level_select" },
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
