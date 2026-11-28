extends SceneTree
## 开发用截图脚本：加载场景、执行脚本化步骤、按帧截图。
## godot --path game --always-on-top -s res://tests/capture.gd -- <scene> <output_dir> <scenario> [level_id]
## macOS 上必须加 --always-on-top：窗口被遮住就停止渲染，截出来的全是同一帧

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
			var cam: Camera2D = player.get_node("Camera2D")
			var weir: Node = current_scene.get("map").get_object("weir")
			print("[capture] %s pos=%s cam=%s locked=%s stage=%d focusing=%s q=%d paused=%s" % [
				step["name"], player.get("global_position"), player.get("global_position") + cam.get("offset"),
				player.get("is_input_locked"), weir.get("state").stage,
				current_scene.get("_is_focusing"), (current_scene.get("_focus_queue") as Array).size(), paused,
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
				# 4620 在 checkpoint_e 的 reached 判定之外，不触发首到对白；场景里另有 weir 专项
				{ "name": "e", "at": Vector2(4620, -450) },
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
		"weir":
			# 活动堰演出：首到 E 看三块板+对白 → HUD 示意图 → 逐段放倒的水帘和水位
			var steps: Array[Dictionary] = [
				{ "frame": 50, "do": "teleport", "to": Vector2(4500, -450) },
				# reached：镜头 0.4s 补间到堰板停 3s → 对白 delay 4.0
				{ "frame": 110, "do": "shot", "name": "weir_arrive_boards" },
				{ "frame": 330, "do": "shot", "name": "weir_dialogue" },
			]
			for index in 8:
				steps.append({ "frame": 340 + index * 8, "do": "press", "action": "advance" })
				steps.append({ "frame": 342 + index * 8, "do": "release", "action": "advance" })
			steps.append({ "frame": 420, "do": "log", "name": "before_panels" })
			steps.append({ "frame": 430, "do": "shot", "name": "weir_panel_low" })
			# 绞盘指向上段：白框移到上段板
			steps.append({ "frame": 440, "do": "prop", "id": "weir", "prop": "selection", "value": 2 })
			steps.append({ "frame": 442, "do": "call", "id": "weir", "method": "_turn_winch" })
			steps.append({ "frame": 490, "do": "shot", "name": "weir_panel_top" })
			# 放回下段再确认：板角 0.8s 补间（f514-562）→ 水帘淡入（f562-592）
			steps.append({ "frame": 500, "do": "prop", "id": "weir", "prop": "selection", "value": 0 })
			steps.append({ "frame": 502, "do": "call", "id": "weir", "method": "confirm" })
			steps.append({ "frame": 540, "do": "shot", "name": "weir_lower_mid" })
			steps.append({ "frame": 541, "do": "log", "name": "lower_mid" })
			steps.append({ "frame": 620, "do": "shot", "name": "weir_cascade_low" })
			# 后果镜头 f706 补间到 F，bay set 开始补间 2s → 中点 ~f766
			steps.append({ "frame": 780, "do": "shot", "name": "weir_bay_falling" })
			# 中段：f926-974 倒板，f974-1004 水帘淡入 → 两级水帘+泡沫
			steps.append({ "frame": 900, "do": "log", "name": "pre_mid" })
			steps.append({ "frame": 920, "do": "prop", "id": "weir", "prop": "selection", "value": 1 })
			steps.append({ "frame": 922, "do": "call", "id": "weir", "method": "confirm" })
			steps.append({ "frame": 1030, "do": "shot", "name": "weir_cascade_mid" })
			steps.append({ "frame": 1031, "do": "log", "name": "cascade_mid" })
			# ledge_h 镜头 f1130 到位停 1.5s
			steps.append({ "frame": 1170, "do": "shot", "name": "weir_ledge" })
			# 上段：整条阶梯水帘 f1400；湖镜头 f1508 到位，湖水 2.5s 补间中点 ~f1583
			steps.append({ "frame": 1290, "do": "prop", "id": "weir", "prop": "selection", "value": 2 })
			steps.append({ "frame": 1292, "do": "call", "id": "weir", "method": "confirm" })
			steps.append({ "frame": 1400, "do": "shot", "name": "weir_cascade_full" })
			steps.append({ "frame": 1401, "do": "log", "name": "cascade_full" })
			steps.append({ "frame": 1600, "do": "shot", "name": "weir_lake_falling" })
			steps.append({ "frame": 1601, "do": "log", "name": "lake_falling" })
			# stage_3 后对湖下雨被拒（站在 step_i1 顶面——湖床本身被台阶占满、竖井太窄站不住）
			steps.append({ "frame": 1760, "do": "teleport", "to": Vector2(7050, -200) })
			steps.append({ "frame": 1800, "do": "weather", "weather": Weather.Type.RAIN })
			steps.append({ "frame": 1806, "do": "cast" })
			steps.append({ "frame": 1850, "do": "shot", "name": "weir_blocked_rain" })
			return steps
		"weir_wrong":
			# 错序放倒：中段先放 → 被冲开的板保持 -60° 半透明画法，示意图红闪
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(4500, -450) },
				{ "frame": 90, "do": "prop", "id": "weir", "prop": "selection", "value": 1 },
				{ "frame": 92, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 140, "do": "shot", "name": "weir_collapse" },
			]
		"weir_stages":
			# 同一视角看 G-J 堰区四态：小猫站上段台阶顶，镜头定住；每段演出播完再截图
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(6550, -350) },
				{ "frame": 60, "do": "shot", "name": "stage_0_dammed" },
				{ "frame": 80, "do": "prop", "id": "weir", "prop": "selection", "value": 0 },
				{ "frame": 82, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 680, "do": "shot", "name": "stage_1_low" },
				{ "frame": 700, "do": "prop", "id": "weir", "prop": "selection", "value": 1 },
				{ "frame": 702, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 1280, "do": "shot", "name": "stage_2_mid" },
				{ "frame": 1300, "do": "prop", "id": "weir", "prop": "selection", "value": 2 },
				{ "frame": 1302, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 1900, "do": "shot", "name": "stage_3_top" },
				{ "frame": 1901, "do": "log", "name": "stage_3_done" },
			]
		"weir_walk":
			# stage_3 后真实移动 E→水文站：step_h → H 岩架 → 上段台阶 → 浅湖涉水 → I 台阶 → 平台
			# 三次 confirm 走真实联动（basin 放干、湖降到 1、岩架 reveal），等镜头队列播完再走
			return [
				{ "frame": 30, "do": "teleport", "to": Vector2(4620, -620) },
				{ "frame": 60, "do": "prop", "id": "weir", "prop": "selection", "value": 0 },
				{ "frame": 62, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 120, "do": "prop", "id": "weir", "prop": "selection", "value": 1 },
				{ "frame": 122, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 180, "do": "prop", "id": "weir", "prop": "selection", "value": 2 },
				{ "frame": 182, "do": "call", "id": "weir", "method": "confirm" },
				{ "frame": 1400, "do": "log", "name": "pre_walk" },
				# step_h 顶 → 跳过 100px 空隙上 ledge_h（顶 -800，落差 180）
				{ "frame": 1410, "do": "press", "action": "move_right" },
				{ "frame": 1420, "do": "press", "action": "jump" },
				{ "frame": 1455, "do": "release", "action": "jump" },
				# 沿岩架向东 ~1700px；到东端前松开，直落上段台阶顶（-350）
				{ "frame": 1635, "do": "release", "action": "move_right" },
				{ "frame": 1670, "do": "log", "name": "ledge_end" },
				{ "frame": 1675, "do": "shot", "name": "walk_crest" },
				# 走下台阶东缘，跌进浅湖（床 -50，60 深），涉水到 step_i1 西壁跳上去
				{ "frame": 1690, "do": "press", "action": "move_right" },
				{ "frame": 1720, "do": "log", "name": "in_lake" },
				{ "frame": 1722, "do": "shot", "name": "walk_wade" },
				{ "frame": 1795, "do": "press", "action": "jump" },
				{ "frame": 1830, "do": "release", "action": "jump" },
				{ "frame": 1840, "do": "log", "name": "on_step_i1" },
				# 逐级跳 i2(-370)、i3(-540)、platform_i(-700)，每级落差 ~170；
				# 实测一个 300px 的跳能跨过整级 130px 台阶，间隔放宽到 ~60f
				{ "frame": 1855, "do": "press", "action": "jump" },
				{ "frame": 1890, "do": "release", "action": "jump" },
				{ "frame": 1915, "do": "press", "action": "jump" },
				{ "frame": 1950, "do": "release", "action": "jump" },
				{ "frame": 1965, "do": "log", "name": "mid_i_steps" },
				# 一跳 ~450px：从 i3 顶起跳空中松右减速，落在 platform_i 上再按左刹停
				{ "frame": 1970, "do": "release", "action": "move_right" },
				{ "frame": 1995, "do": "press", "action": "move_left" },
				{ "frame": 2025, "do": "release", "action": "move_left" },
				{ "frame": 2045, "do": "log", "name": "on_platform_i" },
				{ "frame": 2050, "do": "shot", "name": "walk_platform" },
				# 落点 ~7470 就在守河人（7450）旁边，按 E 护送起步后跟着他向右走
				{ "frame": 2065, "do": "press", "action": "interact" },
				{ "frame": 2067, "do": "release", "action": "interact" },
				{ "frame": 2095, "do": "press", "action": "move_right" },
				{ "frame": 2420, "do": "shot", "name": "walk_escort" },
				{ "frame": 2421, "do": "log", "name": "escort" },
				{ "frame": 2440, "do": "release", "action": "move_right" },
			]
		"spots":
			# 远程天气目标：A 区无可见框；施放后镜头切到真实地点看特效再回来
			# 只施放一次（水尺 3→4），避免第二次施放触发溃泄抢走镜头焦点
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(0, -700) },
				{ "frame": 90, "do": "shot", "name": "spots_a" },
				{ "frame": 100, "do": "weather", "weather": Weather.Type.RAIN },
				{ "frame": 105, "do": "cast" },
				{ "frame": 170, "do": "shot", "name": "lake_rain" },
				{ "frame": 400, "do": "shot", "name": "spots_back" },
			]
		"telescope":
			# A 起点两个望远镜：真实按键走过去按 E 看真实地点（锁住不能动不能施放），再按 E 返回
			return [
				{ "frame": 40, "do": "press", "action": "move_left" },
				{ "frame": 70, "do": "release", "action": "move_left" },
				{ "frame": 110, "do": "shot", "name": "scope_lake_prompt" },
				{ "frame": 120, "do": "press", "action": "interact" },
				{ "frame": 122, "do": "release", "action": "interact" },
				{ "frame": 170, "do": "shot", "name": "scope_lake_view" },
				{ "frame": 190, "do": "press", "action": "move_left" },
				{ "frame": 200, "do": "release", "action": "move_left" },
				{ "frame": 205, "do": "press", "action": "cast" },
				{ "frame": 207, "do": "release", "action": "cast" },
				{ "frame": 230, "do": "shot", "name": "scope_lake_locked" },
				{ "frame": 250, "do": "press", "action": "interact" },
				{ "frame": 252, "do": "release", "action": "interact" },
				{ "frame": 320, "do": "shot", "name": "scope_back" },
				{ "frame": 330, "do": "press", "action": "move_right" },
				{ "frame": 405, "do": "release", "action": "move_right" },
				{ "frame": 440, "do": "shot", "name": "scope_snow_prompt" },
				{ "frame": 450, "do": "press", "action": "interact" },
				{ "frame": 452, "do": "release", "action": "interact" },
				{ "frame": 500, "do": "shot", "name": "scope_snow_view" },
				{ "frame": 520, "do": "press", "action": "interact" },
				{ "frame": 522, "do": "release", "action": "interact" },
				{ "frame": 590, "do": "shot", "name": "scope_snow_back" },
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
		"npc":
			# NPC 贴地走：守河人跳 K 台阶（护送跟随，绕过堰板前置直接启动）；村民救援跳 step_c；撤离在 platform_c 边缘淡出、从 L 右侧淡入
			return [
				{ "frame": 40, "do": "teleport", "to": Vector2(7450, -700) },
				{ "frame": 50, "do": "prop", "id": "keeper", "prop": "_is_following", "value": true },
				{ "frame": 52, "do": "call", "id": "keeper", "method": "_follow_path" },
				{ "frame": 120, "do": "teleport", "to": Vector2(8010, -850) },
				{ "frame": 133, "do": "shot", "name": "keeper_hop_gap" },
				{ "frame": 215, "do": "shot", "name": "keeper_hop_k1" },
				{ "frame": 346, "do": "shot", "name": "keeper_hop_k2" },
				{ "frame": 450, "do": "teleport", "to": Vector2(3100, -350) },
				{ "frame": 430, "do": "call", "id": "sandbar", "method": "do_set", "args": [{ "frozen": true }] },
				{ "frame": 460, "do": "call", "id": "villager_1", "method": "do_rescue", "args": [{}] },
				{ "frame": 484, "do": "call", "id": "villager_2", "method": "do_rescue", "args": [{}] },
				{ "frame": 508, "do": "call", "id": "villager_3", "method": "do_rescue", "args": [{}] },
				{ "frame": 532, "do": "call", "id": "dog", "method": "do_rescue", "args": [{}] },
				{ "frame": 662, "do": "shot", "name": "rescue_hop_step" },
				{ "frame": 718, "do": "shot", "name": "rescue_hop_platform" },
				{ "frame": 780, "do": "teleport", "to": Vector2(3450, -450) },
				{ "frame": 800, "do": "call", "id": "villager_1", "method": "do_evacuate", "args": [{}] },
				{ "frame": 830, "do": "call", "id": "villager_2", "method": "do_evacuate", "args": [{}] },
				{ "frame": 860, "do": "call", "id": "villager_3", "method": "do_evacuate", "args": [{}] },
				{ "frame": 890, "do": "call", "id": "dog", "method": "do_evacuate", "args": [{}] },
				{ "frame": 885, "do": "shot", "name": "evacuee_fade" },
				{ "frame": 1560, "do": "teleport", "to": Vector2(9600, -1150) },
				{ "frame": 1660, "do": "shot", "name": "arrive_fadein" },
				{ "frame": 1900, "do": "shot", "name": "all_arrived" },
			]
		"npc2_ice":
			# 冰路救援：冻住沙洲（L1 冰面 -150），村民跳下岛缘、翻越冻住的木排、走上冰面、跳上 step_c
			return [
				{ "frame": 30, "do": "teleport", "to": Vector2(3150, -350) },
				{ "frame": 30, "do": "call", "id": "sandbar", "method": "do_set", "args": [{ "frozen": true }] },
				{ "frame": 157, "do": "shot", "name": "ice_hop_raft" },
				{ "frame": 240, "do": "shot", "name": "ice_walk" },
				{ "frame": 279, "do": "shot", "name": "ice_hop_step" },
			]
		"npc2_raft":
			# 木排救援：沙洲升到 L2 再吹风把木排推到靠岸（dock_1，甲板 -300），村民跳过水面落在木排上
			return [
				{ "frame": 30, "do": "teleport", "to": Vector2(3150, -350) },
				{ "frame": 30, "do": "call", "id": "sandbar", "method": "do_set", "args": [{ "level": 2 }] },
				{ "frame": 90, "do": "call", "id": "sandbar", "method": "_blow_rafts", "args": [1] },
				{ "frame": 242, "do": "shot", "name": "raft_hop_water" },
				{ "frame": 290, "do": "shot", "name": "raft_on_deck" },
				{ "frame": 324, "do": "shot", "name": "raft_hop_step" },
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
