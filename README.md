# Weather Shift（暂定名）

GitHub Game Off 2026（主题 **SHIFT**）参赛作品。被神明托付最后神力的流浪猫，在洪水淹没的城市和农田里切换雨、风、雪、日照四种天气，改变水的状态，救出被困的人。

- 在线试玩：<https://meathill.github.io/gamejam-switch/>（push 到 master 后由 GitHub Actions 自动部署）
- 需求：[docs/PRD.md](docs/PRD.md)
- 技术方案：[docs/TECH_SPEC.md](docs/TECH_SPEC.md)
- 原始策划材料：[docs/materials/](docs/materials/)

## 操作

| 动作     | 键盘                 | 手柄    |
| -------- | -------------------- | ------- |
| 移动     | A / D、← / →         | 左摇杆  |
| 跳跃     | Space / W / ↑        | A       |
| 切换天气 | Shift（下一个）、1-4 | LB / RB |
| 施放天气 | F / J                | X       |
| 互动     | E / K                | Y       |
| 重开     | R                    | Select  |
| 暂停     | Esc                  | Start   |

手机（横屏）：左下角左右按钮移动，右下角跳跃 / 施放（魔杖）/ 切换天气（显示当前天气），靠近居民或机关时出现互动按钮，右上角暂停。对话点屏幕推进，右下角“跳过”。

## 开发

需要 Node.js ≥ 24、pnpm、Godot 4.7（`brew install --cask godot`）、git-lfs。

```bash
pnpm install
pnpm run dev          # 运行游戏（从标题开始）
pnpm run editor       # 打开 Godot 编辑器
pnpm test             # tools(vitest) + 游戏逻辑(GUT)
pnpm run sprites      # art/ 原画 → game/assets/sprites（裁切缩放）
pnpm run backgrounds  # art/backgrounds 分层原画 → 背景贴图 + data/backdrops/*.json
pnpm run fonts        # 重新生成中文字体子集（新增文案后必须跑）
pnpm run export:web   # 导出 Web 到 build/web
pnpm run serve:web    # 本地试玩 Web 版 http://localhost:8060
pnpm run format && pnpm run lint && pnpm run typecheck
```

## 新增一关

1. 在 `game/data/levels/` 新建 `<id>.json`（参考已有关卡；字段约定见 `game/scripts/level_schema.gd` 和 [TECH_SPEC 5.5](docs/TECH_SPEC.md)），并把 id 加进 `levels.json`。
2. 在编辑器里打开 `scenes/levels/level.tscn`，选中 `LevelMap` 把 `level_id` 改成新关卡即可预览；改 JSON 后点“重新加载关卡数据”。
3. 机关之间的联动（拉下开关后排水、获救后解禁天气、发提示等）写在 `links`，拉杆、升降梯、机器的前置条件写在 `requires`，可用的事件和动作见 [TECH_SPEC 5.5](docs/TECH_SPEC.md)。
4. 在 `game/tests/solutions/<id>.json` 写解法（传送、施放、互动与断言），`pnpm run test:game` 会校验数据并回放解法，要求能通关。
5. 新增了中文文案就跑 `pnpm run fonts`。

## 目录

```text
game/    Godot 工程（GDScript）
art/     美术原画与字体源文件（Git LFS，不被 Godot 导入）
tools/   TS 工具：资源管线、字体子集、本地 Web 服务
docs/    PRD、TECH_SPEC、原始材料
```

## 第三方资源

- 字体：[霞鹜文楷 LXGW WenKai](https://github.com/lxgw/LxgwWenKai)，SIL OFL 1.1
- 图标：[Phosphor Icons](https://phosphoricons.com)，MIT
- 测试框架：[GUT](https://github.com/bitwes/Gut)，MIT
