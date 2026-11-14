@tool
class_name LevelSchema
extends RefCounted
## 关卡 JSON 的字段约定。LevelData 用它校验，LevelMap / LevelEvents 用它构建和联动。
##
## 每种对象：
##   required：必填字段
##   refs：引用其他对象 id 的字段 → 允许引用的类型
##   layer：默认放进哪一层（对象可以用 "layer" 字段覆盖）；parent：改为挂在这个引用字段指向的对象下面
##   events：会发出的事件，links 的 "when" + "event" 引用它
##   actions：能执行的动作 → 必填参数，links 的 "do" + "target" 引用它
##   conditions：能被 requires 检查的状态 → 允许的取值（"gear" 为数字）
##   requires：是否支持 "requires" 前置条件
##
## links：{ "when": 对象 id, "event": 事件, "do": 动作, "target": 对象 id（全局动作不填）, "delay": 秒, ...参数 }
## requires：[{ "target": 对象 id, 条件名: 取值, "hint": 覆盖自动生成的提示 }]，全部满足才算满足

## 从后往前绘制
const LAYERS: Array[String] = ["background", "terrain", "water", "props", "signs", "checkpoints", "front"]

## 不需要 target 的动作
const GLOBAL_ACTIONS: Dictionary[String, Array] = {
	"message": ["text"],
	"warning": ["text"],
	"dialogue": ["path"],
	"complete_level": [],
}

const WATER_STATES: Array[String] = ["deep", "shallow", "dry", "frozen", "liquid", "clean", "polluted"]

const TYPES: Dictionary[String, Dictionary] = {
	"block": { "required": ["pos", "size"], "layer": "terrain", "actions": { "reveal": [], "hide": [] } },
	"decor": { "required": ["pos"], "layer": "background" },
	"water": {
		"required": ["pos", "size", "name"],
		"layer": "water",
		"events": ["deep", "shallow", "dry", "frozen"],
		"actions": { "unblock": ["weather"], "block": ["weather", "reason"], "lower": [], "set": [] },
		"conditions": { "is": WATER_STATES },
	},
	"raft": { "required": ["zone"], "refs": { "zone": ["water"] }, "parent": "zone" },
	"lever": { "required": ["pos"], "layer": "props", "events": ["pulled"], "conditions": { "is": ["pulled"] }, "requires": true },
	"drainage_station": { "required": ["pos"], "layer": "props", "events": ["started"], "conditions": { "is": ["started"] }, "requires": true },
	"pump": {
		"required": ["pos"],
		"refs": { "wheel": ["waterwheel"] },
		"layer": "props",
		"events": ["started"],
		"conditions": { "is": ["started"] },
		"requires": true,
	},
	"resident": {
		"required": ["pos", "name"],
		"layer": "props",
		"events": ["rescued"],
		"actions": { "rescue": [] },
		"conditions": { "is": ["rescued"] },
	},
	"npc": { "required": ["pos", "name"], "layer": "props" },
	"planting_spot": { "required": ["pos"], "layer": "props", "events": ["cleared", "planted"] },
	"waterwheel": { "required": ["pos"], "layer": "props", "events": ["gear_1", "gear_2", "gear_3"], "conditions": { "gear": [] } },
	"field": {
		"required": ["pos", "name", "width"],
		"refs": { "wheel": ["waterwheel"] },
		"layer": "props",
		"events": ["restored", "flooded"],
		"actions": { "irrigate": [] },
		"conditions": { "is": ["restored", "dry", "waterlogged"] },
	},
	"elevator": {
		"required": ["pos", "travel", "wheel"],
		"refs": { "wheel": ["waterwheel"] },
		"layer": "props",
		"events": ["powered"],
		"requires": true,
	},
	"ladder": { "required": ["pos", "height"], "layer": "props", "actions": { "enable": [] }, "requires": true },
	"fan": { "required": ["pos"], "layer": "props", "events": ["started"], "conditions": { "is": ["running"] } },
	"fog": { "required": ["pos", "size"], "layer": "terrain", "actions": { "clear": [] } },
	"dark_zone": { "required": ["pos", "size"], "layer": "front", "events": ["lit"], "conditions": { "is": ["lit"] } },
	"weather_rule_area": {
		"required": ["pos", "size", "disabled", "reason"],
		"layer": "props",
		"actions": { "enable": [], "disable": [] },
	},
	"seed_cart": { "required": ["pos", "to_x"], "layer": "props", "events": ["departed", "arrived"], "requires": true },
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


static func get_events(type: String) -> Array:
	return TYPES[type].get("events", [])


static func get_actions(type: String) -> Dictionary:
	return TYPES[type].get("actions", {})


static func get_conditions(type: String) -> Dictionary:
	return TYPES[type].get("conditions", {})


static func supports_requires(type: String) -> bool:
	return TYPES[type].get("requires", false)
