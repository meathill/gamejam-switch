class_name LevelObjectFactory
extends RefCounted
## 把关卡数据里的一个对象转成节点。create 只设置自身字段，引用其他对象的字段在 link 里连接。
## 新增类型：在 LevelSchema.TYPES 登记字段，再在这里加 create/link 分支。


static func create(entry: Dictionary) -> Node2D:
	var node: Node2D
	match entry["type"]:
		"block":
			var block := SolidBlock.new()
			block.size = LevelData.to_vector(entry["size"])
			if entry.has("color"):
				block.color = LevelData.to_color(entry["color"])
			block.is_building = entry.get("building", false)
			node = block
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
			node = zone
		"raft":
			var raft := Raft.new()
			raft.dock_index = entry.get("dock", 0)
			node = raft
		"lever":
			var lever := Lever.new()
			lever.action_name = entry.get("action", lever.action_name)
			lever.locked_text = entry.get("locked_text", lever.locked_text)
			lever.pulled_text = entry.get("pulled_text", "")
			node = lever
		"planting_spot":
			var spot := PlantingSpot.new()
			spot.trash_count = entry.get("trash", spot.trash_count)
			spot.planted_text = entry.get("planted_text", spot.planted_text)
			node = spot
		"drainage_station":
			var station := DrainageStation.new()
			station.message = entry.get("message", station.message)
			node = station
		"resident":
			var resident := Resident.new()
			resident.resident_name = entry["name"]
			resident.thanks_text = entry.get("thanks", resident.thanks_text)
			if entry.has("texture"):
				resident.texture = load(entry["texture"])
			resident.has_flashlight = entry.get("flashlight", false)
			resident.is_rescued_by_trigger = entry.has("rescued_by")
			resident.dialogue = entry.get("dialogue", "")
			node = resident
		"goal":
			node = GoalArea.new()
		"sign":
			var hint := HintSign.new()
			hint.text = entry["text"]
			hint.touch_text = entry.get("touch_text", "")
			node = hint
		"checkpoint":
			node = Checkpoint.new()
	assert(node != null, "未实现的关卡对象类型：" + str(entry["type"]))
	if entry.has("pos"):
		node.position = LevelData.to_vector(entry["pos"])
	if entry.has("id"):
		node.name = (entry["id"] as String).to_pascal_case()
	return node


static func link(node: Node2D, entry: Dictionary, nodes: Dictionary[String, Node2D]) -> void:
	match entry["type"]:
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
