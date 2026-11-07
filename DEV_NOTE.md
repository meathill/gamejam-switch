# DEV_NOTE

## 决策

- **GDScript 而不是 C#**：Godot 4 的 C# 项目不能导出 Web（截至 4.7.2），Web 是 jam 评审主渠道。
- **Compatibility 渲染器 + 单线程 Web 导出**：Web 只支持 WebGL2；单线程不需要 COOP/COEP 头，itch.io 兼容最好。
- **污染水不能结冰**：否则广场和浮箱水道都能被雪直接绕过，排水站和风失去意义。规则表见 TECH_SPEC 5.3。
- **深水水面与地面齐平**：低 20px 时冰面边缘会形成角色跨不过去的台阶。
- **输入映射写在代码里**（`scripts/input_bindings.gd`），不写进 project.godot，便于 review。
- **HUD/对话框/暂停菜单用代码构建**，不手写 Control 布局的 .tscn。关卡几何用 `@tool` 脚本（`SolidBlock`、`WaterZone`）在编辑器里可见可调。

## Godot 踩坑

- `-s` 运行的脚本（如 `tests/capture.gd`）编译时 autoload 还没注册：不能直接写 `GameState`，也不能引用依赖 autoload 的 `class_name`（会连带编译失败）。用 `root.get_node("GameState")` 和 `Node.call()`。
- `SceneTree._process` 的帧数不等于时间：渲染不锁帧时一帧远小于 1/60 秒。脚本化测试要用 `_physics_process` 计时。
- 协程（函数里有 `await`）不 `await` 调用时拿不到返回值。需要返回值的逻辑先同步算完，动画放进单独的协程里“发射后不管”。
- 子节点 `_ready` 先于父节点：关卡里居民在 `_ready` 注册，所以关卡状态要在根节点的 `_enter_tree` 里重置。
- 子节点默认绘制在父节点 `_draw` 之上；要当背景用的子节点设 `show_behind_parent = true`。
- `@tool` 脚本在编辑器里 `add_child` 的节点没有 owner，不会被保存进场景，可以放心生成碰撞体/Label 用于预览；只在运行时需要的逻辑用 `Engine.is_editor_hint()` 挡住。
- 非资源文件（`.json`）默认不进导出包，要在导出预设 `include_filter` 里加。
- Godot 默认字体没有 CJK，桌面靠系统字体回退，Web 上会全是方块。必须打包中文字体。
- 改 `project.godot` 的自定义字体后，第一次 `--import` 会报找不到字体（还没导入），再跑一次即可。

## 环境

- 导出模板 1.2GB，从 GitHub 下载经常卡住：用 `curl -C -` 断点续传 + `--speed-limit` 自动重试。
- `git lfs install` 会改全局 git config，需要开发者自己执行一次。
