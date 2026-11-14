class_name LevelData
extends RefCounted
## 一关的数据：元数据 + 对象列表（data/levels/<id>.json）。纯数据，不依赖节点。
## 对象字段约定见 LevelSchema，坐标都是 [x, y] 数组。

const LEVEL_DIR := "res://data/levels/"

var id: String = ""
## 标题卡：“第一关” + “被淹没的城市”
var chapter: String = ""
var title: String = ""
var intro_dialogue: String = ""
var outro_dialogue: String = ""
## 通关文案，{rescued} 会替换为救出的居民数
var complete_text: String = ""
var camera_limits: Rect2i = Rect2i()
var player_start: Vector2 = Vector2.ZERO
## 远景配置，见 Backdrop
var backdrop: Dictionary = {}
## 小猫低于这个高度时视为在地下，不显示雨幕
var underground_y: float = INF
var objects: Array[Dictionary] = []


static func get_path_for(level_id: String) -> String:
	return LEVEL_DIR + level_id + ".json"


static func load_level(level_id: String) -> LevelData:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(get_path_for(level_id)))
	assert(parsed is Dictionary, "关卡数据读取失败：" + level_id)
	return from_dict(level_id, parsed)


static func from_dict(level_id: String, data: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.id = level_id
	level.chapter = data.get("chapter", "")
	level.title = data.get("title", "")
	level.intro_dialogue = data.get("intro_dialogue", "")
	level.outro_dialogue = data.get("outro_dialogue", "")
	level.complete_text = data.get("complete_text", "")
	level.camera_limits = Rect2i(to_rect(data.get("camera_limits", [0, 0, 0, 0])))
	level.player_start = to_vector(data.get("player_start", [0, 0]))
	level.backdrop = data.get("backdrop", {})
	level.underground_y = data.get("underground_y", INF)
	level.objects.assign(data.get("objects", []))
	return level


static func to_vector(value: Array) -> Vector2:
	return Vector2(value[0], value[1])


static func to_rect(value: Array) -> Rect2:
	return Rect2(value[0], value[1], value[2], value[3])


## 支持 "#rrggbb" 和 [r, g, b(, a)]（0~1）
static func to_color(value: Variant) -> Color:
	if value is String:
		return Color.html(value)
	var array: Array = value
	return Color(array[0], array[1], array[2], array[3] if array.size() > 3 else 1.0)


## 引用字段可以是单个 id，也可以是 id 数组
static func to_ids(value: Variant) -> Array[String]:
	var ids: Array[String] = []
	if value is Array:
		ids.assign(value)
	elif value is String:
		ids.append(value)
	return ids


func find_object(object_id: String) -> Dictionary:
	for entry in objects:
		if entry.get("id", "") == object_id:
			return entry
	return {}


func count_type(type: String) -> int:
	return objects.filter(func(entry: Dictionary) -> bool: return entry.get("type", "") == type).size()


## 返回所有问题；为空表示数据有效
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var types_by_id: Dictionary[String, String] = {}
	for index in objects.size():
		var entry := objects[index]
		var type: String = entry.get("type", "")
		if not LevelSchema.TYPES.has(type):
			errors.append("%s：未知类型 \"%s\"" % [_label(entry, index), type])
			continue
		for field: String in LevelSchema.TYPES[type]["required"]:
			if not entry.has(field):
				errors.append("%s：缺少字段 %s" % [_label(entry, index), field])
		var object_id: String = entry.get("id", "")
		if object_id.is_empty():
			continue
		if types_by_id.has(object_id):
			errors.append("%s：id 重复" % _label(entry, index))
		types_by_id[object_id] = type
	for index in objects.size():
		var entry := objects[index]
		if LevelSchema.TYPES.has(entry.get("type", "")):
			_validate_object(entry, _label(entry, index), types_by_id, errors)
	if count_type("goal") != 1:
		errors.append("终点 goal 必须恰好一个，现在有 %d 个" % count_type("goal"))
	var objective_count := 0
	for type in LevelSchema.OBJECTIVE_TYPES:
		objective_count += count_type(type)
	if objective_count == 0:
		errors.append("没有任何通关目标（%s）" % ", ".join(LevelSchema.OBJECTIVE_TYPES))
	if not Rect2(camera_limits).has_point(player_start):
		errors.append("player_start 超出镜头范围")
	return errors


func _validate_object(entry: Dictionary, label: String, types_by_id: Dictionary[String, String], errors: PackedStringArray) -> void:
	var type: String = entry["type"]
	var refs := LevelSchema.get_refs(type)
	for field: String in refs:
		for ref_id in to_ids(entry.get(field)):
			if not types_by_id.has(ref_id):
				errors.append("%s：%s 引用的 \"%s\" 不存在" % [label, field, ref_id])
			elif not (refs[field] as Array).has(types_by_id[ref_id]):
				errors.append("%s：%s 只能引用 %s，\"%s\" 是 %s" % [label, field, refs[field], ref_id, types_by_id[ref_id]])
	if entry.has("pos") and not _is_in_camera(entry):
		errors.append("%s：超出镜头范围" % label)
	match type:
		"water":
			_validate_water(entry, label, errors)
		"raft":
			_validate_raft(entry, label, errors)
		"field":
			if not FarmRules.FieldState.has((entry.get("state", "dry") as String).to_upper()):
				errors.append("%s：未知的田地状态 %s" % [label, entry["state"]])
			if not entry.get("pump_only", false) and not entry.has("wheel"):
				errors.append("%s：不是 pump_only 的田必须连接水车 wheel" % label)
			_validate_gear(entry, label, errors)
		"elevator", "pump":
			_validate_gear(entry, label, errors)
		"weather_rule_area":
			for key: String in entry["disabled"]:
				if not Weather.Type.has(key.to_upper()):
					errors.append("%s：disabled 里的 \"%s\" 不是天气" % [label, key])
		"seed_cart":
			if not find_object(entry["goal"]).get("by_cart", false):
				errors.append("%s：终点要设置 by_cart，种子车送达才结算" % label)


func _validate_water(entry: Dictionary, label: String, errors: PackedStringArray) -> void:
	var level: int = entry.get("level", 2)
	if level < 0 or level > WaterRules.MAX_LEVEL:
		errors.append("%s：水位必须在 0~%d" % [label, WaterRules.MAX_LEVEL])
	for key: String in entry.get("blocked_weathers", {}):
		if not Weather.Type.has(key.to_upper()):
			errors.append("%s：blocked_weathers 里的 \"%s\" 不是天气" % [label, key])
	var width: float = to_vector(entry["size"]).x
	var previous := -INF
	for dock: float in entry.get("docks", []):
		if dock < 0.0 or dock > width:
			errors.append("%s：停靠点 %s 超出水域宽度" % [label, dock])
		if dock <= previous:
			errors.append("%s：停靠点必须从左到右递增" % label)
		previous = dock


func _validate_raft(entry: Dictionary, label: String, errors: PackedStringArray) -> void:
	var zone := find_object(entry.get("zone", ""))
	if zone.is_empty():
		return
	var dock: int = entry.get("dock", 0)
	if dock < 0 or dock >= (zone.get("docks", []) as Array).size():
		errors.append("%s：停靠点序号 %d 不存在" % [label, dock])
	var same_dock := objects.filter(func(other: Dictionary) -> bool:
		return other.get("type") == "raft" and other.get("zone") == entry["zone"] and other.get("dock", 0) == dock
	)
	if same_dock.size() > 1:
		errors.append("%s：和其他浮箱停在同一个停靠点" % label)


func _validate_gear(entry: Dictionary, label: String, errors: PackedStringArray) -> void:
	var gear: int = entry.get("gear", 1)
	if gear < 1 or gear > FarmRules.GEAR_COUNT:
		errors.append("%s：档位必须在 1~%d" % [label, FarmRules.GEAR_COUNT])


## 有 size 的对象只要和镜头范围相交即可（左右边界墙在镜头外）
func _is_in_camera(entry: Dictionary) -> bool:
	var camera := Rect2(camera_limits)
	var position := to_vector(entry["pos"])
	if entry.has("size"):
		return camera.intersects(Rect2(position, to_vector(entry["size"])), true)
	return camera.grow(1.0).has_point(position)


func _label(entry: Dictionary, index: int) -> String:
	return "#%d %s%s" % [index, entry.get("type", "?"), " \"%s\"" % entry["id"] if entry.has("id") else ""]
