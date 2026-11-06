import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
import { type Bounds, findOpaqueBounds, padBounds, unionBounds } from './bounds.ts';

interface FrameGroup {
  sourceDir: string;
  outputDir: string;
  targetHeight: number;
  frames: Record<string, string>;
}

interface Portrait {
  source: string;
  output: string;
  targetHeight: number;
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
      walk_01: 'cat_walk_01.png',
      walk_02: 'cat_walk_02.png',
      jump_01: 'cat_jump_01.png.png',
      jump_02: 'cat_jump_02.png',
      cast: 'cat_cast.png',
      dead: 'cat_dead.png',
    },
  },
];

const PORTRAITS: Portrait[] = [
  { source: 'art/cat/cat.png', output: 'game/assets/portraits/cat.png', targetHeight: 900 },
];

async function readBounds(file: string): Promise<{ bounds: Bounds; width: number; height: number }> {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const bounds = findOpaqueBounds({ data, width: info.width, height: info.height, channels: info.channels });
  if (!bounds) throw new Error(`${file} is fully transparent`);
  return { bounds, width: info.width, height: info.height };
}

async function cropAndResize(file: string, bounds: Bounds, targetHeight: number, output: string): Promise<void> {
  await sharp(file)
    .extract({
      left: bounds.left,
      top: bounds.top,
      width: bounds.right - bounds.left,
      height: bounds.bottom - bounds.top,
    })
    .resize({ height: targetHeight })
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
      cropAndResize(entry.file, bounds, group.targetHeight, path.join(outputDir, `${entry.name}.png`)),
    ),
  );
}

async function buildPortrait(portrait: Portrait): Promise<void> {
  const file = path.join(ROOT, portrait.source);
  const { bounds, width, height } = await readBounds(file);
  const output = path.join(ROOT, portrait.output);
  await mkdir(path.dirname(output), { recursive: true });
  await cropAndResize(file, padBounds(bounds, CROP_PADDING, width, height), portrait.targetHeight, output);
}

for (const group of FRAME_GROUPS) await buildFrameGroup(group);
for (const portrait of PORTRAITS) await buildPortrait(portrait);
