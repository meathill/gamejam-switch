import { glob, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import subsetFont from 'subset-font';
import { collectCharacters } from './characters.ts';

const ROOT = path.resolve(import.meta.dirname, '../..');
const SOURCE_FONT = 'art/fonts/LXGWWenKai-Medium.ttf';
const OUTPUT_FONT = 'game/assets/fonts/ui_font.ttf';
const TEXT_SOURCES = ['game/**/*.gd', 'game/**/*.tscn', 'game/data/**/*.json'];
const IGNORED_DIRS = ['game/addons/', 'game/.godot/'];

const files: string[] = [];
for (const pattern of TEXT_SOURCES) {
  for await (const file of glob(pattern, { cwd: ROOT })) {
    if (!IGNORED_DIRS.some((dir) => file.startsWith(dir))) files.push(file);
  }
}
const texts = await Promise.all(files.map((file) => readFile(path.join(ROOT, file), 'utf8')));
const characters = collectCharacters(texts);
const subset = await subsetFont(await readFile(path.join(ROOT, SOURCE_FONT)), characters, {
  targetFormat: 'truetype',
});
await writeFile(path.join(ROOT, OUTPUT_FONT), subset);
console.log(
  `${files.length} files → ${characters.length} characters → ${OUTPUT_FONT} (${(subset.length / 1024).toFixed(0)} KB)`,
);
