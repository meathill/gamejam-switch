@tool
extends EditorPlugin
## 导出插件装载器：导出时按环境变量给导出包注入 custom feature。
## 运行时读不到环境变量（尤其 Web），所以开关在导出这一刻定死。

var _export_plugin := LevelSelectExportPlugin.new()


func _enter_tree() -> void:
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)


class LevelSelectExportPlugin extends EditorExportPlugin:
	## WEATHER_SHIFT_LEVEL_SELECT 显式设成 "0"/"false" 时不带 level_select feature，否则默认带上
	func _get_name() -> String:
		return "BuildFlagsExportPlugin"


	func _get_export_features(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		var flag := OS.get_environment("WEATHER_SHIFT_LEVEL_SELECT").to_lower()
		if flag == "0" or flag == "false":
			return PackedStringArray()
		return PackedStringArray(["level_select"])
