class_name Weather
extends RefCounted

## 顺序与伊尔妲圆环的四段一致：雨 → 风 → 雪 → 日照
enum Type { RAIN, WIND, SNOW, SUN }

const _NAMES: Dictionary[Type, String] = {
	Type.RAIN: "雨",
	Type.WIND: "风",
	Type.SNOW: "雪",
	Type.SUN: "日照",
}

const _COLORS: Dictionary[Type, Color] = {
	Type.RAIN: Color(0.45, 0.65, 0.95),
	Type.WIND: Color(0.6, 0.9, 0.75),
	Type.SNOW: Color(0.9, 0.95, 1.0),
	Type.SUN: Color(1.0, 0.82, 0.35),
}

const _ICONS: Dictionary[Type, String] = {
	Type.RAIN: "res://assets/ui/weather_rain.png",
	Type.WIND: "res://assets/ui/weather_wind.png",
	Type.SNOW: "res://assets/ui/weather_snow.png",
	Type.SUN: "res://assets/ui/weather_sun.png",
}


## 关卡数据、解法文件里使用的名字："rain" / "wind" / "snow" / "sun"
static func get_key(type: Type) -> String:
	return (Type.find_key(type) as String).to_lower()


static func from_key(key: String) -> Type:
	return Type[key.to_upper()]


static func get_display_name(type: Type) -> String:
	return _NAMES[type]


static func get_color(type: Type) -> Color:
	return _COLORS[type]


static func get_icon_path(type: Type) -> String:
	return _ICONS[type]


static func cycle(type: Type, step: int) -> Type:
	return wrapi(type + step, 0, Type.size()) as Type
