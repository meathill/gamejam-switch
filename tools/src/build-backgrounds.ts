import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
import { findOpaqueBounds } from './bounds.ts';

interface LayerGroup {
  name: string;
  /** 从后往前叠加的图层文件 */
  layers: string[];
  /** 横向拼接一份水平镜像，得到首尾无缝的可平铺贴图 */
  isMirrored: boolean;
}

interface Backdrop {
  name: string;
  sourceDir: string;
  /** 原画画布尺寸（所有图层一致） */
  canvas: { width: number; height: number };
  /** 设计稿中地平线（建筑底部）的 y 坐标，游戏里对齐地面 */
  horizonY: number;
  groups: LayerGroup[];
}

export interface ManifestLayer {
  name: string;
  file: string;
  top: number;
  width: number;
  height: number;
}

const ROOT = path.resolve(import.meta.dirname, '../..');
const DESIGN_WIDTH = 1920;
const ALPHA_THRESHOLD = 4;

// 高楼远景：图层文件名的序号 = 原 PSD 图层顺序（00 合成预览，数字越大越靠后）
const BACKDROPS: Backdrop[] = [
  {
    name: 'city_far',
    sourceDir: 'art/backgrounds/city_far',
    canvas: { width: 5120, height: 2880 },
    horizonY: 2250,
    groups: [
      { name: 'sky', layers: ['15_sky.png'], isMirrored: false },
      // 贴着右边缘被裁掉的图层（云、淡色楼群、09）放进 far，关卡里横向不随镜头移动，不需要平铺
      {
        name: 'far',
        layers: ['12_cloud.png', '11_far_buildings_pale.png', '10_far_buildings.png', '09_mid_buildings_d.png'],
        isMirrored: false,
      },
      // 完整落在画面内的楼群做镜像平铺，拼接处是空白，看不出接缝
      {
        name: 'mid',
        layers: ['08_mid_buildings_c.png', '06_mid_buildings_b.png', '05_mid_buildings_a.png'],
        isMirrored: true,
      },
      // 近景只在序章里静态使用
      { name: 'near', layers: ['14_water.png', '13_rubble.png', '04_debris.png'], isMirrored: false },
      { name: 'building_front', layers: ['03_building_front.png'], isMirrored: false },
    ],
  },
  // 第二关农田：只取天空和云做远景，农舍、风向标等近景用 build-sprites 出单图，在关卡里摆放
  {
    name: 'farm',
    sourceDir: 'art/backgrounds/farm',
    canvas: { width: 5120, height: 2880 },
    horizonY: 2440,
    groups: [
      { name: 'sky', layers: ['14_sky.png'], isMirrored: false },
      { name: 'clouds', layers: ['13_cloud_right.png', '12_cloud_big.png', '11_cloud_left.png'], isMirrored: true },
    ],
  },
];

async function buildGroup(backdrop: Backdrop, group: LayerGroup, outputDir: string): Promise<ManifestLayer> {
  const scale = DESIGN_WIDTH / backdrop.canvas.width;
  const designHeight = Math.round(backdrop.canvas.height * scale);
  const composite = await sharp({
    create: { ...backdrop.canvas, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite(group.layers.map((layer) => ({ input: path.join(ROOT, backdrop.sourceDir, layer) })))
    .png()
    .toBuffer();
  const scaled = await sharp(composite).resize(DESIGN_WIDTH, designHeight).ensureAlpha().raw().toBuffer();
  const bounds = findOpaqueBounds(
    { data: scaled, width: DESIGN_WIDTH, height: designHeight, channels: 4 },
    ALPHA_THRESHOLD,
  );
  if (!bounds) throw new Error(`${backdrop.name}/${group.name} is empty`);
  const raw = { raw: { width: DESIGN_WIDTH, height: designHeight, channels: 4 as const } };
  const cropped = await sharp(scaled, raw)
    .extract({ left: 0, top: bounds.top, width: DESIGN_WIDTH, height: bounds.bottom - bounds.top })
    .png()
    .toBuffer();
  const height = bounds.bottom - bounds.top;
  const width = group.isMirrored ? DESIGN_WIDTH * 2 : DESIGN_WIDTH;
  const file = `${group.name}.png`;
  const tile = group.isMirrored
    ? sharp({ create: { width, height, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } }).composite([
        { input: cropped, left: 0, top: 0 },
        { input: await sharp(cropped).flop().toBuffer(), left: DESIGN_WIDTH, top: 0 },
      ])
    : sharp(cropped);
  await tile.png({ compressionLevel: 9 }).toFile(path.join(outputDir, file));
  console.log(`  ${backdrop.name}/${file} ${width}×${height} top=${bounds.top}`);
  return { name: group.name, file, top: bounds.top, width, height };
}

for (const backdrop of BACKDROPS) {
  const outputDir = path.join(ROOT, 'game/assets/backgrounds', backdrop.name);
  await mkdir(outputDir, { recursive: true });
  const layers: ManifestLayer[] = [];
  for (const group of backdrop.groups) layers.push(await buildGroup(backdrop, group, outputDir));
  const scale = DESIGN_WIDTH / backdrop.canvas.width;
  const manifest = {
    texture_dir: `res://assets/backgrounds/${backdrop.name}/`,
    design_size: [DESIGN_WIDTH, Math.round(backdrop.canvas.height * scale)],
    horizon_y: Math.round(backdrop.horizonY * scale),
    layers,
  };
  const manifestPath = path.join(ROOT, 'game/data/backdrops', `${backdrop.name}.json`);
  await mkdir(path.dirname(manifestPath), { recursive: true });
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(`  → ${path.relative(ROOT, manifestPath)}`);
}
