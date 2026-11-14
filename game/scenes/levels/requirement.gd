@tool
class_name Requirement
extends RefCounted
## 一条前置条件（关卡数据的 requires 里的一项）：检查目标对象的状态，不满足时给出提示。
## 目标对象实现 get_unmet_reason(condition: Dictionary) -> String，满足时返回空字符串。

var target: Node
var condition: Dictionary
## 关卡数据里写的提示，覆盖目标对象自动生成的
var hint: String


func _init(target_node: Node, data: Dictionary) -> void:
	target = target_node
	condition = data
	hint = data.get("hint", "")


func get_unmet_reason() -> String:
	var reason: String = target.call("get_unmet_reason", condition)
	return hint if reason and hint else reason


## 第一条没满足的条件的提示；全部满足时为空
static func first_unmet(list: Array[Requirement]) -> String:
	for requirement in list:
		var reason := requirement.get_unmet_reason()
		if reason:
			return reason
	return ""
