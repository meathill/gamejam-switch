class_name WalkPath
extends RefCounted
## NPC 贴地行走：相邻两点 y 几乎相同算平走（匀速），否则按抛物线跳过去；
## 数据里给目标点标 "jump" 可以强制跳（force_hop），比如跳过一段水面。
## 不走物理、不会卡住；台阶处在数据里放一对点（边缘点 + 上/下一级边缘点）就是一跳。

const WALK_SPEED := 220.0
const HOP_HEIGHT := 50.0
const HOP_SECONDS := 0.45
## 跳跃水平速度：跨度大时按时长 = 跨度 / HOP_SPEED 延长
const HOP_SPEED := 330.0
## 跳跃顶点在两端较高点之上再抬高：基础高度 + 水平跨度比例
const HOP_SPAN_RISE := 0.25
const FLAT_EPSILON := 2.0


static func is_flat(a: Vector2, b: Vector2) -> bool:
	return absf(a.y - b.y) < FLAT_EPSILON


static func is_hop(a: Vector2, b: Vector2, force_hop := false) -> bool:
	return force_hop or not is_flat(a, b)


static func get_duration(a: Vector2, b: Vector2, force_hop := false) -> float:
	if not is_hop(a, b, force_hop):
		return a.distance_to(b) / WALK_SPEED
	return maxf(HOP_SECONDS, absf(b.x - a.x) / HOP_SPEED)


## t 取 0..1，返回这一段上 t 时刻的位置
static func sample(a: Vector2, b: Vector2, t: float, force_hop := false) -> Vector2:
	if not is_hop(a, b, force_hop):
		return a.lerp(b, t)
	# 抛物线：x 匀速，y 在两端线性插值上再抬 rise；t=0.5 时正好到顶点 min(y)-HOP_HEIGHT-dx*HOP_SPAN_RISE
	var rise := absf(a.y - b.y) / 2.0 + HOP_HEIGHT + absf(b.x - a.x) * HOP_SPAN_RISE
	return Vector2(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t) - 4.0 * t * (1.0 - t) * rise)
