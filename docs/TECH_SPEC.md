# TECH_SPEC

> 需求见 [PRD.md](./PRD.md)。本文记录技术决策与实现约定；标记 **【待确认】** 的为未定事项。

## 1. 技术选型

| 项目           | 选择                                                        | 理由                                                                                      |
| -------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 引擎           | Godot **4.7.x stable**（当前 4.7.2）                        | 开源、2D 能力完整、一键导出 Web/Win/Mac/Linux                                             |
| 脚本           | **GDScript**（全静态类型）                                  | Godot 4 的 C# 项目**仍无法导出 Web**（官方文档 + issue #70796），而 Web 是 jam 评审主渠道 |
| 渲染器         | **Compatibility**（OpenGL / WebGL 2）                       | Web 只支持该渲染器；统一渲染器避免桌面和 Web 表现不一致                                   |
| Web 导出       | 单线程（Thread Support 关闭）                               | 4.3 起的默认方式，不需要 COOP/COEP 头，itch.io 兼容最好                                   |
| 游戏内单元测试 | **GUT**（Godot Unit Test）                                  | 纯 GDScript、支持命令行 headless 运行                                                     |
| 工具脚本       | TypeScript + Node 24（直接运行 `.ts`）、pnpm、vitest、biome | 遵循 AGENTS.md 环境约定                                                                   |
| 图片处理       | `sharp`                                                     | 批量裁切、缩放原画                                                                        |
| 发布           | itch.io + `butler`；后续可加 GitHub Actions 自动导出        |                                                                                           |

## 2. Monorepo 结构

```text
gamejam-switch/
├── game/                     # Godot 工程（project.godot 所在）
│   ├── project.godot
│   ├── export_presets.cfg
│   ├── addons/gut/           # 测试框架
│   ├── autoload/             # 全局单例
│   ├── scenes/               # .tscn，按功能分目录
│   │   ├── player/
│   │   ├── water/
│   │   ├── props/            # 浮箱、居民、排水站
│   │   ├── ui/               # HUD、对话框、天气轮
│   │   ├── story/            # 序章文游
│   │   └── levels/
│   ├── scripts/              # 与场景无关的纯逻辑（规则、数据结构）
│   ├── data/dialogue/        # 对白数据（JSON）
│   ├── assets/               # 入库的游戏用资源（已处理过的小图）
│   │   ├── sprites/  backgrounds/  audio/  fonts/
│   └── tests/                # GUT 测试
├── art/                      # 美术原画（大图，不被 Godot 导入，见第 3 节）
├── tools/                    # TS 工具脚本：资源管线、导出、上传
│   ├── package.json
│   └── src/
├── docs/                     # PRD、TECH_SPEC、原始材料
├── package.json              # 根脚本：pnpm run sprites / export:web / test
├── pnpm-workspace.yaml       # packages: [tools]
└── biome.json
```

要点：

- `game/` 是唯一的 Godot 工程。Godot 会扫描工程目录下的所有图片，所以**原画不能放在 `game/` 下**，否则导入大图会拖慢编辑器、塞满 `.godot/` 缓存。
- `art/` 放美术原画，`tools` 的资源管线把它处理成小图，输出到 `game/assets/`。
- 在 `art/` 放一个空的 `.gdignore`（防止有人把 `art/` 挪进工程）；`node_modules`、`tools/` 不在 `game/` 下，Godot 天然看不到。
- 根目录 `package.json` 统一入口，Godot 命令也通过 pnpm script 封装，不用记 CLI 参数。

## 3. Git 与大文件

Game Off 要求源码在**公开 GitHub 仓库**。

| 内容                                  | 策略                                                                         |
| ------------------------------------- | ---------------------------------------------------------------------------- |
| `game/assets/**` 处理后的资源         | 普通 git（单张控制在几百 KB 内）                                             |
| `art/**` 原画（PNG/PSD，单张 4～6MB） | **Git LFS**：免费额度为 10 GiB 存储 + 10 GiB/月 下载流量，对一个 jam 足够    |
| `cat.rar` 等压缩包                    | 不入库（`.gitignore`），已解压的内容进 `art/`                                |
| `*.docx` 原始文档                     | 已转为 `docs/materials/*.md`；docx 本身可入 LFS 存档或不入库，**【待确认】** |
| `.godot/`、导出产物 `build/`          | `.gitignore`                                                                 |
| `*.import`、`*.uid`                   | **入库**（Godot 4 要求，保证导入设置和 UID 引用一致）                        |

`.gitattributes`（草案）：

```gitattributes
art/** filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text
*.kra filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
```

## 4. Godot 工程配置

| 设置       | 值                                       |
| ---------- | ---------------------------------------- |
| 基准分辨率 | 1920×1080                                |
| Stretch    | mode = `canvas_items`，aspect = `expand` |
| 纹理过滤   | Linear（水彩风格，不是像素风）           |
| 物理       | Godot Physics 2D，60 tick                |
| 默认重力   | 2400 px/s²（平台跳跃手感从这里调）       |

### 4.1 物理层

实际只用到两层，保持简单：

| 层  | 名称     | 成员                                                  |
| --- | -------- | ----------------------------------------------------- |
| 1   | `world`  | 地面块、池底、冰面（group `ice`，用于判断滑行）、浮箱 |
| 2   | `player` | 小猫；居民和避难所的 Area2D 只检测这一层              |

水体不用 Area2D：小猫每帧按 x 范围查询所在 `WaterZone`，比较脚底与水面高度判断浅水/落水。

### 4.2 输入映射

在 `game/scripts/input_bindings.gd` 里用代码注册（便于 review/diff，不写进 project.godot）。动作名：`move_left`、`move_right`、`jump`、`weather_next`（Shift / RB）、`weather_prev`（LB）、`weather_rain`/`weather_wind`/`weather_snow`/`weather_sun`（1～4，与圆环顺序一致）、`cast`（F / J / X）、`interact`（E / K / Y）、`advance`（对话推进）、`restart`（R）、`pause`（Esc / Start）。

## 5. 架构

### 5.1 Autoload

| 单例          | 职责                                                                                                                                                           |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GameState`   | 当前天气、救援进度、检查点、关卡完成；信号 `weather_changed`、`target_changed`、`weather_cast`、`message_posted`、`rescue_progress_changed`、`level_completed` |
| `SceneRouter` | 场景切换 + 淡入淡出                                                                                                                                            |

音频接入时再加 `AudioDirector`（见 TODO）。HUD、对话框、暂停菜单、雨幕都由场景脚本 `new()` 出来，不做成 autoload。

### 5.2 核心模块

```text
scripts/                      纯逻辑，无节点依赖
  Weather                     天气枚举（顺序 = 圆环四段）、名称/颜色/图标
  WaterState                  (level, is_frozen, is_polluted)
  WaterRules                  apply(weather, state) -> Result{is_success, state, reason}；find_next_dock()
  InputBindings               输入映射注册

scenes/water/WaterZone        @tool Node2D，原点 = 洼地左上角（地面高度）
  导出：zone_name, size, level, is_frozen, is_polluted, dock_positions(PackedFloat32Array)
  运行时生成池底和冰面 StaticBody2D；_draw 画水/冰/污染/高亮
  apply_weather(weather, direction) / transition_to(state)，动画期间返回 BUSY
  子节点中的 Raft 由它摆放：x = 停靠点，y = 随水面（L0/L1 搁浅在池底）

scenes/props/
  Raft                        AnimatableBody2D，可承载小猫；结冰时显示冰霜
  SolidBlock                  @tool 灰盒地形块（可画成楼房）
  Resident / GoalArea         Area2D：E 救援 / 救齐后通关
  DrainageStation             排水槽变成液态深水 → 关联水域 -1 级并净化
  HintSign / Checkpoint       提示牌 / 检查点（越过 x 坐标后生效）

scenes/player/
  Player                      CharacterBody2D，原点在脚底；NORMAL/CASTING/DROWNING
  WeatherCaster               选中目标水域（影响范围内离小猫最近的），cast 时调用 apply_weather

scenes/ui/  Hud, WeatherRing, DialogueBox, PauseMenu
scenes/story/  title, prologue, StoryBackdrop, IldaRing
scenes/levels/  Level（根脚本）+ level_01.tscn（关卡拼装）
```

原则：

- **规则与表现分离**。`WaterRules` 不依赖任何节点，可以 100% 单元测试；`WaterZone` 只负责把状态变化转成 Tween、碰撞开关和信号。
- **一次施放 = 一次状态变化**。`WaterZone` 在 Tween 播放期间拒绝新的施放，防止连按造成状态与表现不同步。
- 机关之间的联动（排水站 → 广场）通过信号连接，不互相持有引用。

### 5.3 水域状态机

状态 = `(level: 0|1|2, frozen: bool, polluted: bool)`。

| 当前         | 雨             | 雪               | 日照             | 风           |
| ------------ | -------------- | ---------------- | ---------------- | ------------ |
| 液态 L0      | → L1           | ✗ 没有水         | ✗ 已经干了       | ✗ 水太浅     |
| 液态 L1      | → L2           | → 冰面 L1        | → L0             | ✗ 水太浅     |
| 液态 L2      | ✗ 水位已满     | → 冰面 L2        | → L1             | 推浮箱一格   |
| 冰面 L1/L2   | ✗ 冰面无法涨水 | ✗ 已经结冰       | → 液态同水位     | ✗ 浮箱被冻住 |
| 污染（液态） | 同液态         | ✗ 污染水结不了冰 | ✗ 污染水无法蒸发 | 同液态       |

风的额外失败原因：区域内无浮箱、面朝方向没有下一个停靠点。

### 5.4 表现同步

一次状态变化同时更新（0.45 秒 Tween）：

1. 水面高度（L0 = 池底，L1 = 池底上 60px，L2 = 与地面齐平，结冰后可直接走上去）
2. 冰面碰撞启用/禁用；结冰瞬间把泡在水里的小猫抬到冰面上，避免卡进碰撞体
3. 浮箱 y 跟随水面、冰霜标记；风推浮箱时 x 移动到下一个停靠点
4. 动画结束后发出 `state_changed`，HUD 和排水站据此刷新
5. 施放成功时在水域上方生成一次性粒子（`WeatherEffect`）

## 6. 对白数据

`game/data/dialogue/*.json`，由 `DialogueBox` 播放：

| type        | 字段                                       | 说明                                                 |
| ----------- | ------------------------------------------ | ---------------------------------------------------- |
| `narration` | `text`                                     | 旁白，无说话人                                       |
| `line`      | `speaker`（`ilda`/`cat`/`system`）, `text` | 对白                                                 |
| `choice`    | `text`, `options[{label, next}]`           | 选项，`next` 跳到对应 `id`                           |
| `goto`      | `target`                                   | 跳转                                                 |
| `event`     | `name`, `wait?`, `on_skip?`                | 发出 `event_triggered`；`on_skip` 为真时跳过也会触发 |

任意行可带 `id`。导出预设的 `include_filter` 已加入 `data/*.json`（非资源文件默认不会打包）。

新增中文文案后要跑 `pnpm run fonts` 重新生成字体子集，否则 Web 版会缺字。

## 7. 资源管线

`pnpm run sprites` → `tools/src/build-sprites.ts`：

1. 读取 `art/cat/*.png`
2. 对同一套动画帧（walk/jump/cast/dead）计算**所有帧非透明区域的并集**，统一裁切，保证帧间对齐不抖动
3. 缩放到目标高度（小猫游戏内约 220px 高，按 1.5 倍存 ≈ 330px，兼顾清晰与体积）
4. 输出 PNG 到 `game/assets/sprites/cat/`，命名规范化（如 `cat_jump_01.png.png` → `jump_01.png`）
5. 立绘（序章用）单独缩放到 900px 高

缩放参数集中在一个配置对象里，美术换图后重跑即可。

`pnpm run fonts` → `tools/src/build-font.ts`：扫描 `game/` 下 `.gd`/`.tscn`/`.json` 用到的字符，从 `art/fonts/LXGWWenKai-Medium.ttf`（霞鹜文楷，OFL）生成子集 `game/assets/fonts/ui_font.ttf`（约 250KB），并设为项目默认字体。Godot 默认字体没有 CJK，Web 上也没有系统字体可回退。

图标用 Phosphor（fill 风格）SVG，`currentColor` 替换为白色后由代码着色。

## 8. 测试

| 范围                                      | 工具         | 命令                                                                                |
| ----------------------------------------- | ------------ | ----------------------------------------------------------------------------------- |
| `WaterRules` 全状态 × 全天气              | GUT          | `pnpm run test:game`（= `godot --headless --path game -s addons/gut/gut_cmdln.gd`） |
| WaterZone 浮箱/风/结冰/施放锁、排水站联动 | GUT          | 同上                                                                                |
| tools 脚本                                | vitest       | `pnpm run test:tools`                                                               |
| 画面与流程                                | 截图脚本     | 见下                                                                                |
| 关卡可通关性                              | 人工试玩清单 | 见 PRD 7.3                                                                          |

修 bug 时先写能复现的 GUT 用例（遵循 AGENTS.md）。

截图脚本 `game/tests/capture.gd` 按物理帧执行脚本化操作（传送、切天气、施放、按键）并截图，用于不开编辑器检查画面：

```bash
godot --path game --resolution 1280x720 -s res://tests/capture.gd -- res://scenes/levels/level_01.tscn /tmp/cap level
```

场景：`level`（主流程机制）、`finale`（救援与通关）、`prologue`（序章）。

## 9. 代码规范补充（GDScript）

GDScript 遵循 [官方风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)，**与 AGENTS.md 的 TS 规范有两处不同**：

- 函数和变量使用 `snake_case`（GDScript 和引擎 API 的惯例），类名 `PascalCase`，常量 `UPPER_SNAKE_CASE`。
- 文件和目录使用 `snake_case`（Godot 官方建议，避免大小写不敏感的文件系统和导出后 PCK 路径出问题）。

其余遵循 AGENTS.md：全部写静态类型（`var level: int`、`func apply(weather: Weather) -> WeatherResult`），单文件不超过 400 行，用信号解耦。

## 10. 构建与发布

| 目标    | 预设名            | 输出                                 |
| ------- | ----------------- | ------------------------------------ |
| Web     | `Web`             | `build/web/index.html`               |
| Windows | `Windows Desktop` | `build/windows/`                     |
| macOS   | `macOS`           | `build/macos/`（未签名，jam 可接受） |

- `pnpm run export:web` 导出 Web；`pnpm run serve:web` 在 <http://localhost:8060> 本地试玩（单线程导出，不需要 COOP/COEP 头）。
- 当前体积：`index.pck` ≈ 1.1MB，`index.wasm` ≈ 39MB（引擎本体，itch.io 会 gzip）。
- 上传：`butler push build/web <user>/<game>:html5`。
- Linux 预设尚未添加，需要时在编辑器里加。

## 11. 环境准备

```bash
brew install --cask godot   # 4.7.2，提供 godot CLI
brew install git-lfs && git lfs install
pnpm install
```

- 导出模板：编辑器 _Manage Export Templates_ 下载，或手动把 `Godot_v4.7.2-stable_export_templates.tpz` 解压到 `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`（约 1.2GB）。
- `butler` 需从 itch.io 官方下载（Homebrew 里的 `butler` 是另一个同名 macOS 软件，不要装错）。

## 12. 风险

| 风险                       | 应对                                                                           |
| -------------------------- | ------------------------------------------------------------------------------ |
| Web 包体积过大（水彩大图） | 资源管线强制缩放；纹理导入用 Lossy/WebP；控制总包 < 50MB                       |
| 移动端浏览器性能           | 不作为目标；粒子数量设上限                                                     |
| 规则与表现不同步导致卡关   | 规则纯函数 + 测试；Tween 期间锁定施放；R 键随时重开                            |
| 关卡设计未定稿             | 灰盒 + 可配置的 `WaterZone`/`DockLane`，关卡用场景拼装，改设计只改场景不改代码 |
