@tool
class_name LevelObjectFactory
extends RefCounted
## 把关卡数据里的一个对象转成节点。create 只设置自身字段，引用其他对象的字段在 link 里连接。
## 新增类型：在 LevelSchema.TYPES 登记字段，再在这里加 create/link 分支。


static func create(entry: Dictionary) -> Node2D:
	var node: Node2D = _create_by_type(entry)
	assert(node != null, "未实现的关卡对象类型：" + str(entry["type"]))
	if entry.has("pos"):
		node.position = LevelData.to_vector(entry["pos"])
	if entry.has("id"):
		node.name = (entry["id"] as String).to_pascal_case()
	return node


static func link(node: Node2D, entry: Dictionary, nodes: Dictionary[String, Node2D]) -> void:
	if entry.has("requires"):
		var requirements: Array[Requirement] = []
		for condition: Dictionary in entry["requires"]:
			requirements.append(Requirement.new(nodes[condition["target"]], condition))
		node.set("requirements", requirements)
	match entry["type"]:
		"field":
			if entry.has("wheel"):
				var field := node as Field
				field.wheel = nodes[entry["wheel"]]
				field.wheel.add_pipe(field.irrigation_gear, field.position + Vector2(field.width / 2.0, field.depth))
		"elevator":
			(node as Elevator).wheel = nodes[entry["wheel"]]
		"pump":
			if entry.has("wheel"):
				(node as Pump).wheel = nodes[entry["wheel"]]
		"gauge":
			(node as Gauge).weir = nodes[entry["weir"]]
		"weir":
			var weir := node as Weir
			var safe_points: Array[Dictionary] = []
			for point: Dictionary in entry["safe_points"]:
				safe_points.append({ "route": nodes[point["route"]], "from_x": point["from_x"] })
			weir.safe_points = safe_points


static func _create_by_type(entry: Dictionary) -> Node2D:
	match entry["type"]:
		"block":
			var block := SolidBlock.new()
			block.size = LevelData.to_vector(entry["size"])
			if entry.has("color"):
				block.color = LevelData.to_color(entry["color"])
			block.is_building = entry.get("building", false)
			if entry.has("texture"):
				block.texture = load(entry["texture"])
			if entry.has("top_color"):
				block.top_color = LevelData.to_color(entry["top_color"])
			block.is_hidden = entry.get("hidden", false)
			return block
		"decor":
			var decor := Decor.new()
			if entry.has("texture"):
				decor.texture = load(entry["texture"])
			decor.height = entry.get("height", decor.height)
			if entry.has("size"):
				decor.size = LevelData.to_vector(entry["size"])
			if entry.has("color"):
				decor.color = LevelData.to_color(entry["color"])
			decor.is_flipped = entry.get("flip", false)
			decor.is_hidden = entry.get("hidden", false)
			return decor
		"water":
			var zone := WaterZone.new()
			zone.zone_name = entry["name"]
			zone.size = LevelData.to_vector(entry["size"])
			zone.level = entry.get("level", 2)
			zone.is_frozen = entry.get("frozen", false)
			zone.is_polluted = entry.get("polluted", false)
			zone.dock_positions = PackedFloat32Array(entry.get("docks", []))
			zone.shallow_freeze_only = entry.get("shallow_freeze_only", false)
			zone.is_rapid = entry.get("rapid", false)
			zone.status_note = entry.get("status_note", "")
			zone.draw_basin = entry.get("basin", true)
			zone.blocked_weathers.assign(entry.get("blocked_weathers", {}))
			return zone
		"raft":
			var raft := Raft.new()
			raft.dock_index = entry.get("dock", 0)
			return raft
		"lever":
			var lever := Lever.new()
			lever.lever_name = entry.get("name", lever.lever_name)
			lever.action_name = entry.get("action", lever.action_name)
			return lever
		"drainage_station":
			var station := DrainageStation.new()
			station.machine_name = entry.get("name", station.machine_name)
			station.start_delay = entry.get("start_delay", station.start_delay)
			return station
		"resident":
			var resident := Resident.new()
			resident.resident_name = entry["name"]
			resident.thanks_text = entry.get("thanks", resident.thanks_text)
			if entry.has("texture"):
				resident.texture = load(entry["texture"])
			resident.has_flashlight = entry.get("flashlight", false)
			resident.is_rescued_by_trigger = not entry.get("rescue_on_interact", true)
			resident.dialogue = entry.get("dialogue", "")
			return resident
		"npc":
			var npc := Npc.new()
			npc.npc_name = entry["name"]
			if entry.has("texture"):
				npc.texture = load(entry["texture"])
			npc.dialogue = entry.get("dialogue", "")
			npc.is_flipped = entry.get("flip", false)
			return npc
		"planting_spot":
			var spot := PlantingSpot.new()
			spot.trash_count = entry.get("trash", spot.trash_count)
			spot.is_objective = entry.get("objective", false)
			return spot
		"waterwheel":
			var wheel := Waterwheel.new()
			wheel.gear = entry.get("gear", 0)
			wheel.display_name = entry.get("name", "")
			return wheel
		"field":
			var field := Field.new()
			field.field_name = entry["name"]
			field.width = entry["width"]
			field.depth = entry.get("depth", 0.0)
			field.is_pit = entry.get("pit", false)
			field.state = FarmRules.FieldState[(entry.get("state", "dry") as String).to_upper()]
			field.is_pump_only = entry.get("pump_only", false)
			field.can_flood = entry.get("can_flood", false)
			field.irrigation_gear = entry.get("gear", 1)
			return field
		"elevator":
			var elevator := Elevator.new()
			elevator.travel = entry["travel"]
			elevator.power_gear = entry.get("gear", 2)
			return elevator
		"ladder":
			var ladder := Ladder.new()
			ladder.height = entry["height"]
			ladder.is_enabled = entry.get("enabled", false)
			return ladder
		"pump":
			var pump := Pump.new()
			pump.machine_name = entry.get("name", pump.machine_name)
			pump.power_gear = entry.get("gear", 3)
			pump.start_delay = entry.get("start_delay", pump.start_delay)
			return pump
		"fan":
			var fan := Fan.new()
			fan.display_name = entry.get("name", "")
			return fan
		"fog":
			var fog := Fog.new()
			fog.size = LevelData.to_vector(entry["size"])
			return fog
		"dark_zone":
			var dark := DarkZone.new()
			dark.size = LevelData.to_vector(entry["size"])
			dark.display_name = entry.get("name", "")
			return dark
		"weather_rule_area":
			var area := WeatherRuleArea.new()
			area.size = LevelData.to_vector(entry["size"])
			for key: String in entry["disabled"]:
				area.disabled_weathers.append(Weather.from_key(key))
			area.reason = entry["reason"]
			area.is_active = entry.get("active", true)
			return area
		"seed_cart":
			var cart := SeedCart.new()
			cart.target_x = entry["to_x"]
			return cart
		"gondola":
			var gondola := Gondola.new()
			gondola.end = LevelData.to_vector(entry["to"])
			return gondola
		"evacuee":
			var evacuee := Evacuee.new()
			evacuee.evacuee_name = entry["name"]
			if entry.has("texture"):
				evacuee.texture = load(entry["texture"])
			evacuee.display_height = entry.get("height", evacuee.display_height)
			evacuee.rescue_path = _to_path(entry.get("rescue_path", []))
			evacuee.evacuate_path = _to_path(entry.get("evacuate_path", []))
			evacuee.is_escort = entry.get("escort", false)
			evacuee.dialogue = entry.get("dialogue", "")
			evacuee.is_flipped = entry.get("flip", false)
			return evacuee
		"passage":
			var passage := Passage.new()
			passage.is_enabled = entry.get("enabled", false)
			passage.path = _to_path(entry["path"])
			return passage
		"weather_spot":
			var spot := WeatherSpot.new()
			spot.display_name = entry["name"]
			spot.size = LevelData.to_vector(entry["size"])
			spot.status = entry.get("status", "")
			for key: String in entry["accepts"]:
				spot.accepts.append(Weather.from_key(key))
			return spot
		"gauge":
			return Gauge.new()
		"weir":
			var weir := Weir.new()
			weir.boards = _to_path(entry["boards"])
			weir.initial_pressure = entry.get("pressure", weir.initial_pressure)
			return weir
		"goal":
			var goal := GoalArea.new()
			goal.is_house_drawn = entry.get("house", true)
			return goal
		"sign":
			var hint := HintSign.new()
			hint.text = entry["text"]
			hint.touch_text = entry.get("touch_text", "")
			return hint
		"checkpoint":
			return Checkpoint.new()
	return null


static func _to_path(points: Array) -> PackedVector2Array:
	var path := PackedVector2Array()
	for point: Array in points:
		path.append(LevelData.to_vector(point))
	return path
