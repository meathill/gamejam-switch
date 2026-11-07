# Weather Shift（暂定名）

GitHub Game Off 2026（主题 **SHIFT**）参赛作品。被神明托付最后神力的流浪猫，在洪水淹没的城市里切换雨、风、雪、日照四种天气，改变水的状态，救出被困的人。

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
| 救援     | E / K                | Y       |
| 重开     | R                    | Select  |
| 暂停     | Esc                  | Start   |

手机（横屏）：左下角左右按钮移动，右下角跳跃 / 施放（魔杖）/ 切换天气（显示当前天气），靠近居民时出现救援按钮，右上角暂停。对话点屏幕推进，右下角“跳过”。

## 开发

需要 Node.js ≥ 24、pnpm、Godot 4.7（`brew install --cask godot`）、git-lfs。

```bash
pnpm install
pnpm run dev          # 运行游戏（从标题开始）
pnpm run editor       # 打开 Godot 编辑器
pnpm test             # tools(vitest) + 游戏逻辑(GUT)
pnpm run sprites      # art/ 原画 → game/assets/sprites（裁切缩放）
pnpm run fonts        # 重新生成中文字体子集（新增文案后必须跑）
pnpm run export:web   # 导出 Web 到 build/web
pnpm run serve:web    # 本地试玩 Web 版 http://localhost:8060
pnpm run format && pnpm run lint && pnpm run typecheck
```

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
