import { glob, readFile } from 'node:fs/promises';
import path from 'node:path';

const PRINTABLE_ASCII = Array.from({ length: 95 }, (_, index) => String.fromCharCode(32 + index)).join('');
const EXTRA_PUNCTUATION = '，。、；：？！…—～·「」『』（）《》【】“”‘’←→↑↓×／';
const TEXT_SOURCES = ['game/**/*.gd', 'game/**/*.tscn', 'game/data/**/*.json'];
const IGNORED_DIRS = ['game/addons/', 'game/.godot/'];

/** 去重并排序，结果总是包含可打印 ASCII 和常用中文标点 */
export function collectCharacters(texts: string[]): string {
  const characters = new Set<string>([...PRINTABLE_ASCII, ...EXTRA_PUNCTUATION]);
  for (const text of texts) {
    for (const character of text) {
      if ((character.codePointAt(0) ?? 0) >= 32) characters.add(character);
    }
  }
  return [...characters].sort().join('');
}

/** 收集项目源码文件里出现过的全部字符（生成字体子集时以此为全集，清单同时落盘做防回归） */
export async function collectProjectCharacters(root: string): Promise<string> {
  const files: string[] = [];
  for (const pattern of TEXT_SOURCES) {
    for await (const file of glob(pattern, { cwd: root })) {
      if (!IGNORED_DIRS.some((dir) => file.startsWith(dir))) files.push(file);
    }
  }
  const texts = await Promise.all(files.map((file) => readFile(path.join(root, file), 'utf8')));
  return collectCharacters(texts);
}
