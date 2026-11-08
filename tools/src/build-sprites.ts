import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import sharp, { type ResizeOptions } from 'sharp';
import { type Bounds, findOpaqueBounds, padBounds, unionBounds } from './bounds.ts';

interface FrameGroup {
  sourceDir: string;
  outputDir: string;
  targetHeight: number;
  frames: Record<string, string>;
}

interface SingleImage {
  source: string;
  output: string;
  /** 裁掉透明边后，按最长边缩放到这个尺寸（不放大） */
  maxSize: number;
}

const ROOT = path.resolve(import.meta.dirname, '../..');
const CROP_PADDING = 16;

// 同组帧共用一个裁切框，保证动画帧之间不抖动；targetHeight 是裁切后整组的像素高度
const FRAME_GROUPS: FrameGroup[] = [
  {
    sourceDir: 'art/cat',
    outputDir: 'game/assets/sprites/cat',
    targetHeight: 330,
    frames: {
      stand: 'cat_stand.png',
      walk_01: 'cat_walk_01.png',
      walk_02: 'cat_walk_02.png',
      jump_01: 'cat_jump_01.png.png',
      jump_02: 'cat_jump_02.png',
      cast: 'cat_cast.png',
      dead: 'cat_dead.png',
    },
  },
];

// 尺寸约为游戏里最大显示尺寸（1920×1080 视口）的 1.5 倍，兼顾高分屏清晰度和包体
const SINGLE_IMAGES: SingleImage[] = [
  // 序章/标题显示约 380px 高
  { source: 'art/cat/cat.png', output: 'game/assets/portraits/cat.png', maxSize: 560 },
  // 关卡里显示 240px 高
  { source: 'art/npc/大叔.png', output: 'game/assets/sprites/npc/uncle.png', maxSize: 360 },
  { source: 'art/npc/老奶奶.png', output: 'game/assets/sprites/npc/granny.png', maxSize: 360 },
  // HUD 显示 210px
  { source: 'art/ui/ui/轮盘.png', output: 'game/assets/ui/weather_wheel.png', maxSize: 320 },
  // 轮盘中心 72px、触屏按钮约 95px
  { source: 'art/ui/ui/rain.png', output: 'game/assets/ui/weather_rain.png', maxSize: 144 },
  { source: 'art/ui/ui/wind.png', output: 'game/assets/ui/weather_wind.png', maxSize: 144 },
  { source: 'art/ui/ui/snow.png', output: 'game/assets/ui/weather_snow.png', maxSize: 144 },
  { source: 'art/ui/ui/sun.png', output: 'game/assets/ui/weather_sun.png', maxSize: 144 },
  // 序章显示约 56px
  { source: 'art/ui/ui/seed.png', output: 'game/assets/ui/seed.png', maxSize: 96 },
  // 序章显示约 46px；同时是项目图标，Web 导出会生成 180px 的 apple-touch-icon
  { source: 'art/ui/ui/嫩芽印记.png', output: 'game/assets/ui/sprout_mark.png', maxSize: 192 },
  // 对话框九宫格：边角按贴图像素 1:1 绘制，所以按显示尺寸出图，不留 1.5 倍
  { source: 'art/ui/dialogue/name_box.png', output: 'game/assets/ui/name_box.png', maxSize: 400 },
  { source: 'art/ui/dialogue/text_box.png', output: 'game/assets/ui/text_box.png', maxSize: 1200 },
  // 雪片纹理：施放雪时叠在水域上方（美术的雨丝纹理是给 4K 画的，1080p 下几乎看不见，没有使用）
  { source: 'art/effects/snow_overlay.png', output: 'game/assets/effects/snow_overlay.png', maxSize: 1920 },
  // 风的笔触，施放风时显示约 180px
  { source: 'art/effects/wind_swirl_1.png', output: 'game/assets/effects/wind_swirl_1.png', maxSize: 256 },
  { source: 'art/effects/wind_swirl_2.png', output: 'game/assets/effects/wind_swirl_2.png', maxSize: 256 },
  { source: 'art/effects/wind_swirl_3.png', output: 'game/assets/effects/wind_swirl_3.png', maxSize: 256 },
];

async function readBounds(file: string): Promise<{ bounds: Bounds; width: number; height: number }> {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const bounds = findOpaqueBounds({ data, width: info.width, height: info.height, channels: info.channels });
  if (!bounds) throw new Error(`${file} is fully transparent`);
  return { bounds, width: info.width, height: info.height };
}

async function cropAndResize(file: string, bounds: Bounds, resize: ResizeOptions, output: string): Promise<void> {
  await sharp(file)
    .extract({
      left: bounds.left,
      top: bounds.top,
      width: bounds.right - bounds.left,
      height: bounds.bottom - bounds.top,
    })
    .resize(resize)
    .png({ compressionLevel: 9 })
    .toFile(output);
  console.log(`  ${path.relative(ROOT, output)}`);
}

async function buildFrameGroup(group: FrameGroup): Promise<void> {
  const entries = Object.entries(group.frames).map(([name, file]) => ({
    name,
    file: path.join(ROOT, group.sourceDir, file),
  }));
  const measured = await Promise.all(entries.map((entry) => readBounds(entry.file)));
  const { width, height } = measured[0];
  if (measured.some((item) => item.width !== width || item.height !== height)) {
    throw new Error(`${group.sourceDir}: frames must share the same canvas size`);
  }
  const bounds = padBounds(unionBounds(measured.map((item) => item.bounds)), CROP_PADDING, width, height);
  const outputDir = path.join(ROOT, group.outputDir);
  await mkdir(outputDir, { recursive: true });
  console.log(`${group.sourceDir} → crop ${JSON.stringify(bounds)}`);
  await Promise.all(
    entries.map((entry) =>
      cropAndResize(entry.file, bounds, { height: group.targetHeight }, path.join(outputDir, `${entry.name}.png`)),
    ),
  );
}

async function buildSingleImage(image: SingleImage): Promise<void> {
  const file = path.join(ROOT, image.source);
  const { bounds, width, height } = await readBounds(file);
  const output = path.join(ROOT, image.output);
  await mkdir(path.dirname(output), { recursive: true });
  const padding = Math.min(CROP_PADDING, Math.round(Math.max(width, height) * 0.02));
  await cropAndResize(
    file,
    padBounds(bounds, padding, width, height),
    { width: image.maxSize, height: image.maxSize, fit: 'inside', withoutEnlargement: true },
    output,
  );
}

for (const group of FRAME_GROUPS) await buildFrameGroup(group);
for (const image of SINGLE_IMAGES) await buildSingleImage(image);
