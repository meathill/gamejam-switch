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
	match entry["type"]:
		"block":
			if entry.has("revealed_by"):
				(node as SolidBlock).is_hidden = true
				nodes[entry["revealed_by"]].connect("triggered", (node as SolidBlock).reveal)
		"lever":
			if entry.has("requires_deep"):
				(node as Lever).requires_deep = nodes[entry["requires_deep"]]
		"drainage_station":
			var station := node as DrainageStation
			station.switch = nodes[entry["switch"]]
			station.drained_zone = nodes[entry["drains"]]
		"resident":
			if entry.has("rescued_by"):
				nodes[entry["rescued_by"]].connect("triggered", (node as Resident).rescue)
		"field":
			if entry.has("wheel"):
				var field := node as Field
				field.wheel = nodes[entry["wheel"]]
				field.wheel.add_pipe(field.irrigation_gear, field.position + Vector2(field.width / 2.0, field.depth))
		"elevator":
			(node as Elevator).wheel = nodes[entry["wheel"]]
		"ladder":
			nodes[entry["lever"]].connect("triggered", (node as Ladder).enable)
		"pump":
			var pump := node as Pump
			pump.wheel = nodes[entry["wheel"]]
			if entry.has("lever"):
				pump.lever = nodes[entry["lever"]]
			for zone_id in LevelData.to_ids(entry.get("drains")):
				pump.drained_zones.append(nodes[zone_id])
			if entry.has("irrigates"):
				pump.irrigated_field = nodes[entry["irrigates"]]
		"fog":
			nodes[entry["cleared_by"]].connect("triggered", (node as Fog).clear)
		"seed_cart":
			(node as SeedCart).goal = nodes[entry["goal"]]


static func _create_by_type(entry: Dictionary) -> Node2D:
	match entry["type"]:
		"block":
			var block := SolidBlock.new()
			block.size = LevelData.to_vector(entry["size"])
			if entry.has("color"):
				block.color = LevelData.to_color(entry["color"])
			block.is_building = entry.get("building", false)
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
			zone.blocked_weathers.assign(entry.get("blocked_weathers", {}))
			return zone
		"raft":
			var raft := Raft.new()
			raft.dock_index = entry.get("dock", 0)
			return raft
		"lever":
			var lever := Lever.new()
			lever.action_name = entry.get("action", lever.action_name)
			lever.locked_text = entry.get("locked_text", lever.locked_text)
			lever.pulled_text = entry.get("pulled_text", "")
			return lever
		"drainage_station":
			var station := DrainageStation.new()
			station.message = entry.get("message", station.message)
			return station
		"resident":
			var resident := Resident.new()
			resident.resident_name = entry["name"]
			resident.thanks_text = entry.get("thanks", resident.thanks_text)
			if entry.has("texture"):
				resident.texture = load(entry["texture"])
			resident.has_flashlight = entry.get("flashlight", false)
			resident.is_rescued_by_trigger = entry.has("rescued_by")
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
			spot.planted_text = entry.get("planted_text", spot.planted_text)
			return spot
		"waterwheel":
			var wheel := Waterwheel.new()
			wheel.gear = entry.get("gear", 0)
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
			return ladder
		"pump":
			var pump := Pump.new()
			pump.power_gear = entry.get("gear", 3)
			return pump
		"fan":
			return Fan.new()
		"fog":
			var fog := Fog.new()
			fog.size = LevelData.to_vector(entry["size"])
			return fog
		"dark_zone":
			var dark := DarkZone.new()
			dark.size = LevelData.to_vector(entry["size"])
			return dark
		"weather_rule_area":
			var area := WeatherRuleArea.new()
			area.size = LevelData.to_vector(entry["size"])
			for key: String in entry["disabled"]:
				area.disabled_weathers.append(Weather.from_key(key))
			area.reason = entry["reason"]
			return area
		"seed_cart":
			return SeedCart.new()
		"goal":
			var goal := GoalArea.new()
			goal.is_cart_goal = entry.get("by_cart", false)
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
