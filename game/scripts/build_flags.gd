class_name BuildFlags
extends RefCounted
## 发布相关的功能开关。Web 运行时读不到环境变量，开关由 addons/build_flags
## 导出插件在导出时注入的 custom feature 决定（默认注入，显式关闭时去掉）。

const LEVEL_SELECT_FEATURE := "level_select"


## 编辑器里运行（pnpm run dev / 编辑器 F5）永远开启；导出包按导出时的 feature 决定
static func is_level_select_enabled() -> bool:
	return OS.has_feature("editor") or OS.has_feature(LEVEL_SELECT_FEATURE)
