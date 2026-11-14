@tool
class_name LevelSchema
extends RefCounted
## 关卡 JSON 里每种对象的字段约定。LevelData 用它校验，LevelMap 用它决定节点放在哪一层。
##   required：必填字段
##   refs：引用其他对象 id 的字段 → 允许引用的类型（值可以是 id 或 id 数组）
##   layer：默认放进哪一层（对象可以用 "layer" 字段覆盖）；parent：改为挂在这个引用字段指向的对象下面

## 从后往前绘制
const LAYERS: Array[String] = ["background", "terrain", "water", "props", "signs", "checkpoints", "front"]

## 会发出 triggered 信号、可以被 rescued_by / revealed_by / cleared_by 引用的类型
const TRIGGER_TYPES: Array[String] = ["lever", "drainage_station", "pump", "fan", "dark_zone"]

const TYPES: Dictionary[String, Dictionary] = {
	"block": { "required": ["pos", "size"], "refs": { "revealed_by": TRIGGER_TYPES }, "layer": "terrain" },
	"decor": { "required": ["pos"], "layer": "background" },
	"water": { "required": ["pos", "size", "name"], "layer": "water" },
	"raft": { "required": ["zone"], "refs": { "zone": ["water"] }, "parent": "zone" },
	"lever": { "required": ["pos"], "refs": { "requires_deep": ["water"] }, "layer": "props" },
	"drainage_station": {
		"required": ["pos", "switch", "drains"],
		"refs": { "switch": ["lever"], "drains": ["water"] },
		"layer": "props",
	},
	"resident": { "required": ["pos", "name"], "refs": { "rescued_by": TRIGGER_TYPES }, "layer": "props" },
	"npc": { "required": ["pos", "name"], "layer": "props" },
	"planting_spot": { "required": ["pos"], "layer": "props" },
	"waterwheel": { "required": ["pos"], "layer": "props" },
	"field": { "required": ["pos", "name", "width"], "refs": { "wheel": ["waterwheel"] }, "layer": "props" },
	"elevator": { "required": ["pos", "travel", "wheel"], "refs": { "wheel": ["waterwheel"] }, "layer": "props" },
	"ladder": { "required": ["pos", "height", "lever"], "refs": { "lever": ["lever"] }, "layer": "props" },
	"pump": {
		"required": ["pos", "wheel"],
		"refs": { "wheel": ["waterwheel"], "lever": ["lever"], "drains": ["water"], "irrigates": ["field"] },
		"layer": "props",
	},
	"fan": { "required": ["pos"], "layer": "props" },
	"fog": { "required": ["pos", "size", "cleared_by"], "refs": { "cleared_by": TRIGGER_TYPES }, "layer": "terrain" },
	"dark_zone": { "required": ["pos", "size"], "layer": "front" },
	"weather_rule_area": { "required": ["pos", "size", "disabled", "reason"], "layer": "props" },
	"seed_cart": { "required": ["pos", "goal"], "refs": { "goal": ["goal"] }, "layer": "props" },
	"goal": { "required": ["pos"], "layer": "props" },
	"sign": { "required": ["pos", "text"], "layer": "signs" },
	"checkpoint": { "required": ["pos"], "layer": "checkpoints" },
}

## 计入通关目标的类型
const OBJECTIVE_TYPES: Array[String] = ["resident", "field"]


static func get_refs(type: String) -> Dictionary:
	return TYPES[type].get("refs", {})


static func get_layer(entry: Dictionary) -> String:
	return entry.get("layer", TYPES[entry["type"]].get("layer", ""))


static func get_parent_field(type: String) -> String:
	return TYPES[type].get("parent", "")
