import { describe, expect, it } from 'vitest';
import { collectCharacters } from './characters.ts';

describe('collectCharacters', () => {
  it('deduplicates characters across texts', () => {
    const result = collectCharacters(['小猫小猫', '猫雨']);
    expect([...result].filter((character) => character === '猫')).toHaveLength(1);
    expect(result).toContain('雨');
  });

  it('always includes printable ascii and drops control characters', () => {
    const result = collectCharacters(['\n\t']);
    expect(result).toContain('A');
    expect(result).toContain('~');
    expect(result).not.toContain('\n');
  });

  it('keeps astral characters intact', () => {
    expect(collectCharacters(['𠀀'])).toContain('𠀀');
  });
});
