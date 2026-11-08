class_name BackdropManifest
extends RefCounted
## 读取 tools/src/build-backgrounds.ts 生成的背景清单（data/backdrops/*.json）。
## 坐标都是 1920×1080 设计稿坐标，horizon_y 是地平线（建筑底部）。

var horizon_y: float
var _texture_dir: String
var _layers: Dictionary[String, Dictionary] = {}


func _init(path: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	horizon_y = data["horizon_y"]
	_texture_dir = data["texture_dir"]
	for layer: Dictionary in data["layers"]:
		_layers[layer["name"]] = layer


func get_texture(layer_name: String) -> Texture2D:
	return load(_texture_dir + _layers[layer_name]["file"])


func get_top(layer_name: String) -> float:
	return _layers[layer_name]["top"]


## 生成一个左上角对齐设计稿位置的 Sprite2D
func make_sprite(layer_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = get_texture(layer_name)
	sprite.centered = false
	sprite.position = Vector2(0, get_top(layer_name))
	return sprite
