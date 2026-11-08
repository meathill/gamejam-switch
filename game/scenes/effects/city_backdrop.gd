class_name CityBackdrop
extends Node2D
## 关卡远景：天空固定在屏幕上，远景楼群只随镜头上下移动，中景楼群横向视差平铺。
## 设计稿的地平线对齐关卡地面（y = 0）附近。

const MANIFEST_PATH := "res://data/backdrops/city_far.json"
## 地平线比地面略低一点，让楼群底部藏在地形后面
const HORIZON_OFFSET := 60.0
const MID_SCROLL := 0.15


func _ready() -> void:
	var manifest := BackdropManifest.new(MANIFEST_PATH)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := TextureRect.new()
	sky.texture = manifest.get_texture("sky")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky_layer.add_child(sky)
	add_child(sky_layer)
	var origin_y := HORIZON_OFFSET - manifest.horizon_y
	_add_layer(manifest, "far", Vector2(0.0, 1.0), origin_y, false)
	_add_layer(manifest, "mid", Vector2(MID_SCROLL, 1.0), origin_y, true)


func _add_layer(manifest: BackdropManifest, layer_name: String, scroll: Vector2, origin_y: float, is_tiled: bool) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = scroll
	var sprite := manifest.make_sprite(layer_name)
	sprite.position.y += origin_y
	parallax.add_child(sprite)
	if is_tiled:
		parallax.repeat_size = Vector2(sprite.texture.get_width(), 0)
		parallax.repeat_times = 2
	add_child(parallax)
