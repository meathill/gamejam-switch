# TECH_SPEC

> 需求见 [PRD.md](./PRD.md)。本文记录技术决策与实现约定；标记 **【待确认】** 的为未定事项。

## 1. 技术选型

| 项目 | 选择 | 理由 |
| --- | --- | --- |
| 引擎 | Godot **4.7.x stable**（当前 4.7.2） | 开源、2D 能力完整、一键导出 Web/Win/Mac/Linux |
| 脚本 | **GDScript**（全静态类型） | Godot 4 的 C# 项目**仍无法导出 Web**（官方文档 + issue #70796），而 Web 是 jam 评审主渠道 |
| 渲染器 | **Compatibility**（OpenGL / WebGL 2） | Web 只支持该渲染器；统一渲染器避免桌面和 Web 表现不一致 |
| Web 导出 | 单线程（Thread Support 关闭） | 4.3 起的默认方式，不需要 COOP/COEP 头，itch.io 兼容最好 |
| 游戏内单元测试 | **GUT**（Godot Unit Test） | 纯 GDScript、支持命令行 headless 运行 |
| 工具脚本 | TypeScript + Node 24（直接运行 `.ts`）、pnpm、vitest、biome | 遵循 AGENTS.md 环境约定 |
| 图片处理 | `sharp` | 批量裁切、缩放原画 |
| 发布 | itch.io + `butler`；后续可加 GitHub Actions 自动导出 | |

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

| 内容 | 策略 |
| --- | --- |
| `game/assets/**` 处理后的资源 | 普通 git（单张控制在几百 KB 内） |
| `art/**` 原画（PNG/PSD，单张 4～6MB） | **Git LFS**：免费额度为 10 GiB 存储 + 10 GiB/月 下载流量，对一个 jam 足够 |
| `cat.rar` 等压缩包 | 不入库（`.gitignore`），已解压的内容进 `art/` |
| `*.docx` 原始文档 | 已转为 `docs/materials/*.md`；docx 本身可入 LFS 存档或不入库，**【待确认】** |
| `.godot/`、导出产物 `build/` | `.gitignore` |
| `*.import`、`*.uid` | **入库**（Godot 4 要求，保证导入设置和 UID 引用一致） |

`.gitattributes`（草案）：

```gitattributes
art/** filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text
*.kra filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
```

## 4. Godot 工程配置

| 设置 | 值 |
| --- | --- |
| 基准分辨率 | 1920×1080 |
| Stretch | mode = `canvas_items`，aspect = `expand` |
| 纹理过滤 | Linear（水彩风格，不是像素风） |
| 物理 | Godot Physics 2D，60 tick |
| 默认重力 | 2400 px/s²（平台跳跃手感从这里调） |

### 4.1 物理层

| 层 | 名称 | 说明 |
| --- | --- | --- |
| 1 | `world` | 地面、墙、建筑 |
| 2 | `player` | 小猫 |
| 3 | `ice` | 冰面碰撞体（结冰时启用） |
| 4 | `raft` | 浮箱 |
| 5 | `water_area` | 水体 Area2D（检测浅水/深水） |
| 6 | `interact` | 居民、机关等可交互区域 |

### 4.2 输入映射

动作名：`move_left`、`move_right`、`jump`、`weather_next`（Shift / RB）、`weather_prev`（LB）、`weather_rain`、`weather_snow`、`weather_wind`、`weather_sun`（1～4）、`cast`（F / X）、`interact`（E / Y）、`restart`（R）、`pause`（Esc / Start）。

## 5. 架构

### 5.1 Autoload

| 单例 | 职责 |
| --- | --- |
| `GameState` | 当前天气、救援进度、检查点、关卡完成标记；发出 `weather_changed`、`resident_rescued`、`level_completed` 信号 |
| `SceneRouter` | 场景切换 + 淡入淡出转场；保证“第一关开场保留序章最后画面” |
| `AudioDirector` | BGM、环境音（雨声随天气淡入淡出）、一次性音效 |

只做这三个，其他逻辑都在场景里，避免全局状态膨胀。

### 5.2 核心模块

```text
WaterRules (scripts/water_rules.gd, RefCounted, 纯函数)
    apply(weather, state) -> WeatherResult { changed, next_state, reason }

WaterZone (scenes/water/water_zone.tscn, Node2D)
    导出属性：zone_name, level(0..2), is_frozen, is_polluted, level_heights[3]
    子节点：WaterBody(视觉) / DeepWaterArea(Area2D) / IceBody(StaticBody2D) / TargetArea(Area2D)
    apply_weather(weather) -> WeatherResult   # 调 WaterRules，再驱动表现
    signal state_changed(zone)

Raft (scenes/props/raft.tscn, AnimatableBody2D)
    属于一个 DockLane；Y 跟随所在 WaterZone 的水面；冻结时锁定

DockLane (Node2D)
    有序的 Marker2D 停靠点；move(raft, direction) -> bool

WeatherCaster (挂在 Player 下)
    跟踪 TargetArea 内最近的 WaterZone 作为 target；cast() 时调用 target.apply_weather()

Player (CharacterBody2D)
    状态机：idle / run / jump / fall / cast / drown
    读取所在 WaterZone 状态：浅水减速、冰面低摩擦、深水 → drown → 回检查点

Resident (Area2D)          按 interact 触发救援
DrainageStation (Node2D)   监听排水槽 WaterZone，水位达到 2 时启动，修改关联广场 WaterZone
```

原则：

- **规则与表现分离**。`WaterRules` 不依赖任何节点，可以 100% 单元测试；`WaterZone` 只负责把状态变化转成 Tween、碰撞开关和信号。
- **一次施放 = 一次状态变化**。`WaterZone` 在 Tween 播放期间拒绝新的施放，防止连按造成状态与表现不同步。
- 机关之间的联动（排水站 → 广场）通过信号连接，不互相持有引用。

### 5.3 水域状态机

状态 = `(level: 0|1|2, frozen: bool, polluted: bool)`。

| 当前 | 雨 | 雪 | 日照 | 风 |
| --- | --- | --- | --- | --- |
| 液态 L0 | → L1 | ✗ 没有水 | ✗ 已经干了 | ✗ 水太浅 |
| 液态 L1 | → L2 | → 冰面 L1 | → L0 | ✗ 水太浅 |
| 液态 L2 | ✗ 水位已满 | → 冰面 L2 | → L1 | 推浮箱一格 |
| 冰面 L1/L2 | ✗ 冰面无法涨水 | ✗ 已经结冰 | → 液态同水位 | ✗ 浮箱被冻住 |
| 污染（液态） | 同液态 | 同液态 | ✗ 污染水无法蒸发 | 同液态 |

风的额外失败原因：区域内无浮箱、面朝方向没有下一个停靠点。

### 5.4 表现同步

一次状态变化同时更新（PRD 要求 0.5 秒内完成）：

1. 水面高度 Tween（`level_heights[level]`）
2. 冰面 `StaticBody2D` 的碰撞启用/禁用 + 冰面贴图/着色
3. `DeepWaterArea` 仅在“液态 L2”时启用
4. 浮箱 Y 坐标跟随水面；冻结标记
5. HUD 区域面板刷新
6. 天气施法音效 + 粒子

## 6. 对白数据

`game/data/dialogue/prologue.json`：

```json
{
  "id": "prologue",
  "lines": [
    { "type": "narration", "text": "浑浊的洪水淹过街道……" },
    { "type": "line", "speaker": "ilda", "text": "你还要留在这里？" },
    { "type": "choice", "text": "是否接受伊尔妲的力量？", "options": [{ "label": "接受", "next": "accept" }, { "label": "拒绝", "next": "refuse" }] },
    { "type": "event", "name": "weather_demo_rain" }
  ]
}
```

- `event` 用于驱动演出（背景切换、天气演示、圆环亮起），由序章场景监听。
- 可选：写一个 `tools` 脚本，把 `docs/materials/dialogue.md` 的 `【说话人】台词` 格式转成 JSON，让文案直接改 Markdown。先手写 JSON，量大了再做。

## 7. 资源管线

`pnpm run sprites` → `tools/src/build-sprites.ts`：

1. 读取 `art/cat/*.png`
2. 对同一套动画帧（walk/jump/cast/dead）计算**所有帧非透明区域的并集**，统一裁切，保证帧间对齐不抖动
3. 缩放到目标高度（小猫游戏内约 220px 高，按 1.5 倍存 ≈ 330px，兼顾清晰与体积）
4. 输出 PNG 到 `game/assets/sprites/cat/`，命名规范化（如 `cat_jump_01.png.png` → `jump_01.png`）
5. 立绘（序章用）单独缩放到 1080px 高

缩放参数集中在一个配置对象里，美术换图后重跑即可。

## 8. 测试

| 范围 | 工具 | 命令 |
| --- | --- | --- |
| `WaterRules` 全状态 × 全天气 | GUT | `pnpm run test:game`（= `godot --headless --path game -s addons/gut/gut_cmdln.gd`） |
| 浮箱停靠逻辑、居民救援计数 | GUT | 同上 |
| tools 脚本 | vitest | `pnpm run test:tools` |
| 关卡可通关性 | 人工试玩清单 | 见 PRD 7.3 |

修 bug 时先写能复现的 GUT 用例（遵循 AGENTS.md）。

## 9. 代码规范补充（GDScript）

GDScript 遵循 [官方风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)，**与 AGENTS.md 的 TS 规范有两处不同**：

- 函数和变量使用 `snake_case`（GDScript 和引擎 API 的惯例），类名 `PascalCase`，常量 `UPPER_SNAKE_CASE`。
- 文件和目录使用 `snake_case`（Godot 官方建议，避免大小写不敏感的文件系统和导出后 PCK 路径出问题）。

其余遵循 AGENTS.md：全部写静态类型（`var level: int`、`func apply(weather: Weather) -> WeatherResult`），单文件不超过 400 行，用信号解耦。

## 10. 构建与发布

| 目标 | 预设名 | 输出 |
| --- | --- | --- |
| Web | `Web` | `build/web/index.html` |
| Windows | `Windows Desktop` | `build/windows/` |
| macOS | `macOS` | `build/macos/`（未签名，jam 可接受） |
| Linux | `Linux` | `build/linux/` |

- 命令：`godot --headless --path game --export-release "Web" ../build/web/index.html`，封装为 `pnpm run export:web`。
- 上传：`butler push build/web <user>/<game>:html5`。
- 首次需在编辑器 *Manage Export Templates* 下载 4.7.2 导出模板（约 1.2GB）。

## 11. 环境准备

```bash
brew install --cask godot   # 4.7.2，提供 godot CLI
brew install git-lfs && git lfs install
```

`butler` 需从 itch.io 官方下载（Homebrew 里的 `butler` 是另一个同名 macOS 软件，不要装错）。

当前机器上都未安装。

## 12. 风险

| 风险 | 应对 |
| --- | --- |
| Web 包体积过大（水彩大图） | 资源管线强制缩放；纹理导入用 Lossy/WebP；控制总包 < 50MB |
| 移动端浏览器性能 | 不作为目标；粒子数量设上限 |
| 规则与表现不同步导致卡关 | 规则纯函数 + 测试；Tween 期间锁定施放；R 键随时重开 |
| 关卡设计未定稿 | 灰盒 + 可配置的 `WaterZone`/`DockLane`，关卡用场景拼装，改设计只改场景不改代码 |
