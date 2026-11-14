# DEV_NOTE

## 决策

- **GDScript 而不是 C#**：Godot 4 的 C# 项目不能导出 Web（截至 4.7.2），Web 是 jam 评审主渠道。
- **Compatibility 渲染器 + 单线程 Web 导出**：Web 只支持 WebGL2；单线程不需要 COOP/COEP 头，itch.io 兼容最好。
- **污染水不能结冰**：否则广场和浮箱水道都能被雪直接绕过，排水站和风失去意义。规则表见 TECH_SPEC 5.3。
- **深水水面与地面齐平**：低 20px 时冰面边缘会形成角色跨不过去的台阶。
- **固定 16:9 横屏**：`aspect=expand` 在竖屏下会把视口拉高，字挤在下方变得很小。改为 `keep` 加黑边；Web 竖屏用 CSS（`body::after` + `@media (orientation: portrait)`）盖一层提示，比在 Godot 里画更清晰，也不用等引擎加载。headless Chrome 截图有约 500px 的最小窗口宽度，390px 宽的截图会被裁切，看起来像没居中。
- **触屏用左右按钮而不是虚拟摇杆**：动作性不强，按钮更准；`TouchScreenButton` 原生支持多点触控和 `action`，会同时调用 `Input.action_press` 并推送 `InputEventAction`，轮询和 `_unhandled_input` 两种写法都能收到。
- **贴图用 Lossy 导入 + 按显示尺寸 1.5 倍出图**：贴图导入体积从 1.75MB 降到 240KB，游戏包 gzip 后从 1.8MB 降到 0.58MB。加载大头是引擎 wasm（gzip 后约 10MB），要再降只能自编译裁剪模块的导出模板，jam 阶段不做。
- **输入映射写在代码里**（`scripts/input_bindings.gd`），不写进 project.godot，便于 review。
- **HUD/对话框/暂停菜单用代码构建**，不手写 Control 布局的 .tscn。
- **关卡用 JSON 数据而不是 .tscn**（`data/levels/`）：方便写校验和解法回放测试、策划不开 Godot 也能改、AI 能直接读写和 diff。代价是编辑器里不能拖拽改图，只能改 JSON 后在 `LevelMap` 上点“重新加载关卡数据”预览。迁移时先原样转换并截图对比，再改布局。
- **解法回放用传送 + 施放 + 断言**（`tests/solutions/`），稳定但验证不了跳跃可达性；可达性用 `capture.gd` 的真实按键场景检查。
- **机关联动统一用 `triggered` 信号**，被触发方在数据里写 `rescued_by` / `revealed_by` / `cleared_by`，不另做条件 DSL。
- **第二关的拉杆同时接上排水泵动力**：否则玩家能不下井直接把水车 1→2→3，跳过整个地下流程。
- **检查点改为“最近经过的”**（原来是“x 最大的”）：第二关地下是往左走的。

## Godot 踩坑

- GUT 里 `get_tree().current_scene` 是 null，节点不要把东西挂到 current_scene 上（施放特效改挂到目标的父节点）。
- macOS 上截图脚本要加 `--always-on-top`：窗口被其他窗口遮住后不再渲染，截出来全是同一帧。
- `@tool` 脚本在编辑器里用到的纯逻辑类（`LevelData`、`LevelObjectFactory` 等）也要标 `@tool`，否则在编辑器里是占位实例，代码不执行。
- `-s` 运行的脚本（如 `tests/capture.gd`）编译时 autoload 还没注册：不能直接写 `GameState`，也不能引用依赖 autoload 的 `class_name`（会连带编译失败）。用 `root.get_node("GameState")` 和 `Node.call()`。
- `SceneTree._process` 的帧数不等于时间：渲染不锁帧时一帧远小于 1/60 秒。脚本化测试要用 `_physics_process` 计时。
- 协程（函数里有 `await`）不 `await` 调用时拿不到返回值。需要返回值的逻辑先同步算完，动画放进单独的协程里“发射后不管”。
- 子节点 `_ready` 先于父节点：关卡里居民在 `_ready` 注册，所以关卡状态要在根节点的 `_enter_tree` 里重置。
- 子节点默认绘制在父节点 `_draw` 之上；要当背景用的子节点设 `show_behind_parent = true`。
- `@tool` 脚本在编辑器里 `add_child` 的节点没有 owner，不会被保存进场景，可以放心生成碰撞体/Label 用于预览；只在运行时需要的逻辑用 `Engine.is_editor_hint()` 挡住。
- 非资源文件（`.json`）默认不进导出包，要在导出预设 `include_filter` 里加。
- Godot 默认字体没有 CJK，桌面靠系统字体回退，Web 上会全是方块。必须打包中文字体。
- 隐藏的 `TouchScreenButton`（自身或祖先 `visible = false`）不处理触摸，可以直接用可见性控制按键是否可用。
- 暂停时 `TouchScreenButton` 也停止处理，所以暂停菜单里必须有“继续”按钮，不能只靠暂停键恢复。
- 改 `project.godot` 的自定义字体后，第一次 `--import` 会报找不到字体（还没导入），再跑一次即可。

## 环境

- 导出模板 1.2GB，从 GitHub 下载经常卡住：用 `curl -C -` 断点续传 + `--speed-limit` 自动重试。
- `git lfs install` 会改全局 git config，需要开发者自己执行一次。未安装时可临时用 `git -c filter.lfs.clean="git-lfs clean -- %f" -c filter.lfs.process="git-lfs filter-process" -c filter.lfs.required=true add art`，push 前先 `git lfs push --all origin`（没有 pre-push hook，GitHub 会拒绝缺 LFS 对象的 push）。
- GitHub Pages 对所有静态文件返回 `Cache-Control: max-age=600`，F5 只会重新验证 HTML，`index.pck` 仍可能走缓存，看到旧版本。CI 里把它改名为 `index-<sha>.pck` 并在 `GODOT_CONFIG` 写入 `mainPack`（Godot 引擎加载器原生支持这个配置）。
- `actions/deploy-pages` 偶尔长时间停在 `syncing_files`（Pages 拥堵，与站点大小无关），超时已放宽到 30 分钟。
- GitHub Pages 需要在仓库设置里把 Source 设为 GitHub Actions（或 `gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow`）。
