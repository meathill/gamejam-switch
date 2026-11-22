@tool
class_name WeirConsole
extends Interactable
## 活动堰的操作台：挂在 weir 原点作为子节点，按 E 确认放倒绞盘选中的堰板。

func _init() -> void:
	detect_size = Vector2(340, 340)
	prompt_height = 340.0


func _ready() -> void:
	super()
	# 风转绞盘、放倒演出结束时选中段和可否互动都会变，提示要跟着刷新
	if not Engine.is_editor_hint():
		_weir().state_changed.connect(func(_target: WeatherTarget) -> void: refresh_prompt())


func _weir() -> Weir:
	return get_parent() as Weir


func get_action_name() -> String:
	var weir := _weir()
	if not weir:
		return "放倒堰板"
	return "放倒%s堰板" % WeirRules.BOARD_NAMES[weir.selection]


func can_interact() -> bool:
	var weir := _weir()
	return weir != null and not weir.is_busy() and not weir.state.is_collapsed


func _interact() -> void:
	_weir().confirm()
