import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { collectProjectCharacters } from './characters.ts';

const ROOT = path.resolve(import.meta.dirname, '../..');
const MANIFEST = 'game/assets/fonts/ui_font_chars.txt';

describe('font subset coverage', () => {
  it('every project character is covered by the built font manifest', async () => {
    const collected = await collectProjectCharacters(ROOT);
    const manifest = await readFile(path.join(ROOT, MANIFEST), 'utf8');
    const covered = new Set(manifest);
    const missing = [...collected].filter((character) => !covered.has(character));
    expect(missing, `ui_font.ttf 缺少字符：${missing.join('')}，跑 pnpm run fonts`).toEqual([]);
  });
});
