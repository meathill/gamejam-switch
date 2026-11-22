import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import subsetFont from 'subset-font';
import { collectProjectCharacters } from './characters.ts';

const ROOT = path.resolve(import.meta.dirname, '../..');
const SOURCE_FONT = 'art/fonts/LXGWWenKai-Medium.ttf';
const OUTPUT_FONT = 'game/assets/fonts/ui_font.ttf';
const CHARS_MANIFEST = 'game/assets/fonts/ui_font_chars.txt';

const characters = await collectProjectCharacters(ROOT);
const subset = await subsetFont(await readFile(path.join(ROOT, SOURCE_FONT)), characters, {
  targetFormat: 'truetype',
});
await writeFile(path.join(ROOT, OUTPUT_FONT), subset);
await writeFile(path.join(ROOT, CHARS_MANIFEST), `${characters}\n`);
console.log(
  `${characters.length} characters → ${OUTPUT_FONT} (${(subset.length / 1024).toFixed(0)} KB), 清单 ${CHARS_MANIFEST}`,
);
