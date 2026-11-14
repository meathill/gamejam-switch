class_name LevelEvents
extends RefCounted
## 执行关卡数据里的 links：对象发出 level_event(event) 时，按 “当 when 发生 event，就对 target 执行 do” 调用。
## 有 target 的动作调用目标的 do_<动作>(link)，link 本身就是参数；没有 target 的是全局动作（LevelSchema.GLOBAL_ACTIONS）。

## 来源 id → 这个对象触发的 links
var _links: Dictionary[String, Array] = {}
var _nodes: Dictionary[String, Node2D]


func _init(links: Array[Dictionary], nodes: Dictionary[String, Node2D]) -> void:
	_nodes = nodes
	for link in links:
		var source: String = link["when"]
		if not _links.has(source):
			_links[source] = []
		_links[source].append(link)
	for source: String in _links:
		_nodes[source].connect("level_event", _on_event.bind(source))


func _on_event(event: String, source: String) -> void:
	for link: Dictionary in _links[source]:
		if link["event"] == event:
			_run(link)


func _run(link: Dictionary) -> void:
	var delay: float = link.get("delay", 0.0)
	if delay > 0.0:
		await (Engine.get_main_loop() as SceneTree).create_timer(delay, false).timeout
	if link.has("target"):
		_nodes[link["target"]].call("do_" + link["do"], link)
		return
	match link["do"]:
		"message":
			GameState.post_message(link["text"])
		"warning":
			GameState.post_warning(link["text"])
		"dialogue":
			GameState.play_dialogue(link["path"])
		"complete_level":
			GameState.complete_level()
