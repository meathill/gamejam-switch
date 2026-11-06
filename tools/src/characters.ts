const PRINTABLE_ASCII = Array.from({ length: 95 }, (_, index) => String.fromCharCode(32 + index)).join('');
const EXTRA_PUNCTUATION = '，。、；：？！…—～·「」『』（）《》【】“”‘’←→↑↓×／';

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
