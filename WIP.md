# WIP

## 当前任务：G–J 活动堰地形与水体重做（不提交，已完成待审）

最终布局（台阶东移 +140，湖西缘顶到上段板）：

- step_g1 [6200,-50]140 / step_g2 [6340,-200]140 / step_g3 [6480,-350]140
- bank_j 降为湖床暗坎 [6620,-50]360（东缘 6980 填掉旧竖井）；lake 西延 [6620,-450]1680（L2 面 -450 / L1 面 -110）
- 跌水潭收窄到真实峡谷 [6000,100]200×350；bank_g 抬到 [5840,90] 做潭西缘围堰
- basin_1 [6250,-110]90×60 L1 / basin_2 [6390,-260]90×60 L1（basin:false，浮在台阶顶上方 60 深）
- boards [[6220,-50],[6365,-200],[6595,-350]]；ledge_h [4800,-800]1760（东端 6560 悬在上段台阶顶上方）

已完成：

- [x] level_03.json 地形/水体/链接/焦点（basin 泄空、lake 2→1、basin 拒雨、lake_mouth.view）
- [x] weir_drawing.gd 水帘改新流向（湖→basin_2→basin_1→潭，落点=下一级实际水面）
- [x] weir.gd 去掉独立湖口水帘（并入上段水帘）
- [x] 回放断言 lake 0→1 + basin_1/basin_2 断言
- [x] capture：weir_stages 四张同视角 + weir_walk 真实步行 E→platform_i（落点 7469 守河人旁）
- [x] fonts（1061 字）+ pnpm test（vitest 10/10、GUT 115/115）/ format / lint / typecheck 全过

备注：stage_3 后护送守河人/种子的 planting_spot 不依赖天气，拒雨屏蔽无冲突。截图在 /tmp/cap_weir2026/。
