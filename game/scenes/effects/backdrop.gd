class_name Backdrop
extends Node2D
## 关卡远景：天空固定在屏幕上，其余图层按配置做视差，可横向平铺。配置来自关卡数据的 backdrop：
##   manifest：data/backdrops/<manifest>.json（tools/src/build-backgrounds.ts 生成）
##   horizon_offset：设计稿地平线相对关卡地面（y = 0）的偏移，略低一点让楼群底部藏在地形后面
##   layers[]：{ name, scroll: [x, y]（跟随镜头的比例）, tiled }

var _config: Dictionary


func _init(config: Dictionary) -> void:
	_config = config


func _ready() -> void:
	var manifest := BackdropManifest.new("res://data/backdrops/%s.json" % _config["manifest"])
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := TextureRect.new()
	sky.texture = manifest.get_texture(_config.get("sky", "sky"))
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky_layer.add_child(sky)
	add_child(sky_layer)
	var origin_y: float = _config.get("horizon_offset", 0.0) - manifest.horizon_y
	for layer: Dictionary in _config.get("layers", []):
		_add_layer(manifest, layer, origin_y)


func _add_layer(manifest: BackdropManifest, layer: Dictionary, origin_y: float) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = LevelData.to_vector(layer["scroll"])
	var sprite := manifest.make_sprite(layer["name"])
	sprite.position.y += origin_y
	parallax.add_child(sprite)
	if layer.get("tiled", false):
		parallax.repeat_size = Vector2(sprite.texture.get_width(), 0)
		parallax.repeat_times = 2
	add_child(parallax)
