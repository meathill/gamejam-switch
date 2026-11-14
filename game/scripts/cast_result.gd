class_name CastResult
extends RefCounted
## 一次天气施放的结果。失败时 reason_text 是给玩家看的原因；is_busy 表示目标还在播放上一次的动画（不提示）。

var is_success: bool = false
var is_busy: bool = false
var reason_text: String = ""


static func ok() -> CastResult:
	var result := CastResult.new()
	result.is_success = true
	return result


static func fail(reason: String) -> CastResult:
	var result := CastResult.new()
	result.reason_text = reason
	return result


static func busy() -> CastResult:
	var result := CastResult.new()
	result.is_busy = true
	return result
