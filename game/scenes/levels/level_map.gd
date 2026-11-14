@tool
class_name LevelMap
extends Node2D
## 按关卡数据（data/levels/<id>.json）生成地形、水域、机关等节点。
## 编辑器里也会生成用于预览：这些节点没有 owner，不会被保存进场景。改了 JSON 点“重新加载”即可。

@export var level_id: String = "level_01":
	set(value):
		level_id = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export_tool_button("重新加载关卡数据", "Reload") var reload_button: Callable = rebuild

## 运行时由 Level 在 _enter_tree 里注入；为空时按 level_id 读取
var data: LevelData
var _nodes: Dictionary[String, Node2D] = {}


func _ready() -> void:
	rebuild()


func get_object(object_id: String) -> Node2D:
	return _nodes.get(object_id)


func rebuild() -> void:
	for child in get_children():
		child.free()
	_nodes.clear()
	if Engine.is_editor_hint() or not data:
		data = LevelData.load_level(level_id)
	if not Engine.is_editor_hint() and data.backdrop:
		add_child(Backdrop.new(data.backdrop))
	var layers: Dictionary[String, Node2D] = {}
	for layer_name in LevelSchema.LAYERS:
		var layer := Node2D.new()
		layer.name = layer_name.to_pascal_case()
		layers[layer_name] = layer
	var created: Array[Node2D] = []
	for entry in data.objects:
		var node := LevelObjectFactory.create(entry)
		created.append(node)
		if entry.has("id"):
			_nodes[entry["id"]] = node
	# 先在场景树外拼好（浮箱挂到水域下、连接引用），再整层加入，保证各节点 _ready 时引用已就绪
	for index in created.size():
		var entry := data.objects[index]
		var type: String = entry["type"]
		LevelObjectFactory.link(created[index], entry, _nodes)
		var parent_field := LevelSchema.get_parent_field(type)
		var parent: Node2D = _nodes[entry[parent_field]] if parent_field else layers[LevelSchema.get_layer(entry)]
		parent.add_child(created[index])
	for layer_name in LevelSchema.LAYERS:
		add_child(layers[layer_name])
