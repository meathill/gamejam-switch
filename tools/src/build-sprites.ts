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
  /** 指定裁切范围（原画像素），用于图层里有离得很远的杂点、自动裁切不准的情况 */
  crop?: Bounds;
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
  { source: 'art/npc/农民.png', output: 'game/assets/sprites/npc/farmer.png', maxSize: 360 },
  { source: 'art/npc/一家人.png', output: 'game/assets/sprites/npc/family.png', maxSize: 360 },
  // 第二关机关（art/backgrounds/farm_surface、farm_underground、farm_end 的分层，按游戏内显示尺寸 1.5 倍出图）
  // 水车轮显示直径约 400px，支架与轮子同比例（400 / 1473）
  {
    source: 'art/backgrounds/farm_surface/17_waterwheel.png',
    output: 'game/assets/sprites/farm/waterwheel.png',
    maxSize: 600,
  },
  {
    source: 'art/backgrounds/farm_surface/16_waterwheel_stand.png',
    output: 'game/assets/sprites/farm/waterwheel_stand.png',
    maxSize: 515,
  },
  // 粮仓（含晾架、木箱）显示约 560px 高；种子车约 260px 宽，图层左上角有杂点，手动指定裁切
  {
    source: 'art/backgrounds/farm_surface/22_granary_full.png',
    output: 'game/assets/sprites/farm/granary.png',
    maxSize: 1420,
  },
  {
    source: 'art/backgrounds/farm_surface/20_cart.png',
    output: 'game/assets/sprites/farm/cart.png',
    maxSize: 390,
    crop: { left: 2905, top: 1905, right: 4012, bottom: 2629 },
  },
  {
    source: 'art/backgrounds/farm_surface/12_seed_sack.png',
    output: 'game/assets/sprites/farm/seed_sack.png',
    maxSize: 120,
  },
  // 农田三态：已恢复的嫩芽、积水和碎石（低洼田）、旱田，按约 40px 高横向平铺
  {
    source: 'art/backgrounds/farm_surface/02_sprouts.png',
    output: 'game/assets/sprites/farm/sprouts.png',
    maxSize: 560,
  },
  {
    source: 'art/backgrounds/farm_surface/04_field_water.png',
    output: 'game/assets/sprites/farm/field_water.png',
    maxSize: 600,
  },
  {
    source: 'art/backgrounds/farm_surface/03_field_rocks.png',
    output: 'game/assets/sprites/farm/field_rocks.png',
    maxSize: 500,
  },
  {
    source: 'art/backgrounds/farm_end/01_dry_field.png',
    output: 'game/assets/sprites/farm/dry_field.png',
    maxSize: 480,
  },
  // 地下：爬梯拉伸到实际高度，竖井拉伸到井的尺寸
  {
    source: 'art/backgrounds/farm_underground/01_ladder.png',
    output: 'game/assets/sprites/farm/ladder.png',
    maxSize: 1240,
  },
  {
    source: 'art/backgrounds/farm_underground/09_shaft.png',
    output: 'game/assets/sprites/farm/shaft.png',
    maxSize: 1400,
  },
  {
    source: 'art/backgrounds/farm_underground/10_elevator_platform.png',
    output: 'game/assets/sprites/farm/elevator_platform.png',
    maxSize: 390,
  },
  { source: 'art/backgrounds/farm_underground/08_fan.png', output: 'game/assets/sprites/farm/fan.png', maxSize: 240 },
  {
    source: 'art/backgrounds/farm_underground/03_lever.png',
    output: 'game/assets/sprites/farm/lever.png',
    maxSize: 150,
  },
  { source: 'art/backgrounds/farm_underground/04_pump.png', output: 'game/assets/sprites/farm/pump.png', maxSize: 330 },
  {
    source: 'art/backgrounds/farm_underground/24_trees.png',
    output: 'game/assets/sprites/farm/trees.png',
    maxSize: 720,
  },
  // 平铺纹理：按背景同样的 0.375 缩放（5120 → 1920），1:1 平铺时纸纹粗细和远景一致
  {
    source: 'art/backgrounds/farm_underground/21_earth.png',
    output: 'game/assets/textures/farm/earth.png',
    maxSize: 1920,
  },
  {
    source: 'art/backgrounds/farm_underground/25_room_wall.png',
    output: 'game/assets/textures/farm/room_wall.png',
    maxSize: 1920,
  },
  // 第二关近景（原画是 5120×2880 的整幅分层，裁掉透明边后单独摆放）：粮仓显示约 560px 高
  {
    source: 'art/backgrounds/farm/09_weathervane.png',
    output: 'game/assets/sprites/farm/weathervane.png',
    maxSize: 640,
  },
  { source: 'art/backgrounds/farm/06_fence.png', output: 'game/assets/sprites/farm/fence.png', maxSize: 400 },
  { source: 'art/backgrounds/farm/04_grass.png', output: 'game/assets/sprites/farm/grass.png', maxSize: 900 },
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
  const measured = await readBounds(file);
  const { width, height } = measured;
  const bounds = image.crop ?? measured.bounds;
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
