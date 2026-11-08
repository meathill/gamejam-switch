# 美术资源清单

> 所有原画在 `art/`（Git LFS），处理后的游戏用资源由 `pnpm run sprites` / `pnpm run backgrounds` 输出到 `game/assets/`。

## 主角（`art/cat/`）

> 来源：解压自 `cat.rar`，2026-11-07 盘点。全部为带 Alpha 通道的 PNG，水彩手绘风格。

## 角色形象

灰色小猫，穿带猫耳兜帽的黄绿色雨衣，大眼睛、细腿、长尾巴。水彩纹理，深灰描边。

> 注意：文案设定是“流浪狸花猫”，美术是“穿雨衣的灰猫”。雨衣贴合暴雨主题，建议以美术为准，同步修订文案。

## 文件

### 整帧（A4 画布 4961×3508，角色在画布中位置对齐，可直接做逐帧动画）

| 文件                  | 用途             | 备注                                    |
| --------------------- | ---------------- | --------------------------------------- |
| `cat_stand.png`       | 站立（待机）     | 2026-11-07 补充                         |
| `cat_walk_01.png`     | 行走帧 1         |                                         |
| `cat_walk_02.png`     | 行走帧 2         |                                         |
| `cat_jump_01.png.png` | 跳跃帧 1         | **文件名多了一个 `.png`，入库时需改名** |
| `cat_jump_02.png`     | 跳跃帧 2         |                                         |
| `cat_cast.png`        | 施法（释放天气） | 双手前伸                                |
| `cat_dead.png`        | 死亡/失败        |                                         |

### 立绘与部件（裁切好的，可做 cutout 骨骼动画）

| 文件                      | 尺寸      | 用途                     |
| ------------------------- | --------- | ------------------------ |
| `cat.png`                 | 2219×3053 | 完整立绘（序章文游可用） |
| `head_body.png`           | 2219×2699 | 头 + 身体                |
| `head.png`                | 2219×1828 | 头                       |
| `body.png`                | 1144×1105 | 身体                     |
| `arm_l.png` / `arm_r.png` | 453×794   | 左/右手臂                |
| `leg_left.png`            | 150×597   | 左腿                     |
| `leg_right.png`           | 120×726   | 右腿                     |
| `tail.png`                | 954×427   | 尾巴                     |
| `cat_dead_head.png`       | 2180×1948 | 死亡状态的头             |

## 其他美术素材（2026-11-07 补充）

| 源文件                               | 入库后                               | 用途                                       |
| ------------------------------------ | ------------------------------------ | ------------------------------------------ |
| `art/npc/大叔.png`                   | `game/assets/sprites/npc/uncle.png`  | 居民 2（公交站）                           |
| `art/npc/老奶奶.png`                 | `game/assets/sprites/npc/granny.png` | 居民 1（居民楼窗台，手持手电）             |
| `art/ui/ui/轮盘.png`                 | `game/assets/ui/weather_wheel.png`   | HUD 天气轮盘；象限顺时针为雨、风、雪、日照 |
| `art/ui/ui/{rain,wind,snow,sun}.png` | `game/assets/ui/weather_*.png`       | 轮盘中心、触屏天气按钮                     |
| `art/ui/ui/seed.png`                 | `game/assets/ui/seed.png`            | 序章落下的种子                             |
| `art/ui/ui/嫩芽印记.png`             | `game/assets/ui/sprout_mark.png`     | 序章猫额头印记、项目图标（Web favicon）    |

| `art/ui/dialogue/text_box.png` | `game/assets/ui/text_box.png` | 对话文字框（九宫格拉伸） |
| `art/ui/dialogue/name_box.png` | `game/assets/ui/name_box.png` | 对话姓名框、对话选项按钮 |

映射关系写在 `tools/src/build-sprites.ts` 的 `SINGLE_IMAGES`，换图后跑 `pnpm run sprites`。

## 入库前处理

- 原图分辨率远超游戏需要（角色在 1080p 画面中约 200～300px 高），需裁掉透明边并缩放，否则 Web 包体积和显存都会爆。
- 处理方案见 [TECH_SPEC.md](../TECH_SPEC.md#资源管线)。
- 缺口：落地、推/互动、额头嫩芽印记与尾巴发光版本、身后残缺圆环特效。

## 背景与特效（2026-11-08 补充，原 `art/new/`）

原画是 5120×2880 的 PSD 分层导出，已按用途归档并重命名。文件名序号 = 原图层顺序（`00` 为合成预览，数字越大越靠后）。

| 目录                                 | 内容                                                      | 使用情况                                                              |
| ------------------------------------ | --------------------------------------------------------- | --------------------------------------------------------------------- |
| `art/backgrounds/city_far/`          | 高楼远景：天空、云、远/中景楼群、前景楼、废墟、水面、地面 | **已用**：第一关视差背景；序章/标题背景（前景楼翻转后作为对面居民楼） |
| `art/effects/snow_overlay.png`       | 雪片纹理                                                  | **已用**：施放雪时叠加在水域上方                                      |
| `art/effects/wind_swirl_{1,2,3}.png` | 风的笔触                                                  | **已用**：施放风时顺风飘过                                            |
| `art/effects/rain_overlay.png`       | 雨丝纹理                                                  | 未用：按 4K 绘制，1080p 下雨丝只有 1~2px，几乎看不见；暴雨仍用粒子    |
| `art/backgrounds/suburb/`            | 郊景（雪地、冰面、郊区楼房）                              | 未用：留给后续关卡                                                    |
| `art/backgrounds/park_tree/`         | 老公园古树（带嫩芽）                                      | 未用：留给结局/绿化支路                                               |
| `art/backgrounds/storm_forest/`      | 暴雨山林（有/无水坑两版路面）                             | 未用：留给农田/河谷关卡                                               |

`07_mid_buildings_b_duplicate.png`、`wind_swirl_2_duplicate.png` 与前一张逐字节相同（LFS 只存一份）。

### 城市远景分组（`tools/src/build-backgrounds.ts`）

| 分组             | 图层                                   | 关卡里                                    | 序章/标题                                  |
| ---------------- | -------------------------------------- | ----------------------------------------- | ------------------------------------------ |
| `sky`            | 15                                     | 固定在屏幕上                              | ✓                                          |
| `far`            | 12、11、10、09（贴着右边缘被裁的图层） | 只随镜头上下移动，横向固定                | ✓                                          |
| `mid`            | 08、06、05（完整在画面内的楼群）       | 横向视差 0.15，镜像拼接成 3840px 无缝平铺 | 只用左半                                   |
| `near`           | 14、13、04                             | 不用（地形挡住）                          | ✓                                          |
| `building_front` | 03                                     | 不用                                      | 序章翻转到右侧（标题不显示，避免挡住按钮） |

脚本按 1920 宽缩放、裁掉上下透明区域，生成 `game/data/backdrops/city_far.json`（每层的 `top` 和设计稿地平线 `horizon_y`），游戏里用 `BackdropManifest` 读取定位，换图后重跑 `pnpm run backgrounds` 即可。
