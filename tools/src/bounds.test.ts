import { describe, expect, it } from 'vitest';
import { findOpaqueBounds, padBounds, type RawImage, unionBounds } from './bounds.ts';

function makeImage(width: number, height: number, opaquePixels: Array<[number, number]>): RawImage {
  const data = new Uint8Array(width * height * 4);
  for (const [x, y] of opaquePixels) data[(y * width + x) * 4 + 3] = 255;
  return { data, width, height, channels: 4 };
}

describe('findOpaqueBounds', () => {
  it('returns null for a fully transparent image', () => {
    expect(findOpaqueBounds(makeImage(4, 4, []))).toBeNull();
  });

  it('returns exclusive right/bottom edges around opaque pixels', () => {
    const image = makeImage(10, 8, [
      [2, 3],
      [6, 5],
    ]);
    expect(findOpaqueBounds(image)).toEqual({ left: 2, top: 3, right: 7, bottom: 6 });
  });

  it('ignores nearly transparent pixels below the threshold', () => {
    const image = makeImage(4, 4, [[1, 1]]);
    image.data[(0 * 4 + 3) * 4 + 3] = 5;
    expect(findOpaqueBounds(image)).toEqual({ left: 1, top: 1, right: 2, bottom: 2 });
  });
});

describe('unionBounds', () => {
  it('covers every input', () => {
    expect(
      unionBounds([
        { left: 2, top: 5, right: 10, bottom: 20 },
        { left: 4, top: 1, right: 12, bottom: 18 },
      ]),
    ).toEqual({ left: 2, top: 1, right: 12, bottom: 20 });
  });

  it('throws on empty input', () => {
    expect(() => unionBounds([])).toThrow();
  });
});

describe('padBounds', () => {
  it('clamps to the canvas', () => {
    expect(padBounds({ left: 2, top: 2, right: 98, bottom: 50 }, 5, 100, 52)).toEqual({
      left: 0,
      top: 0,
      right: 100,
      bottom: 52,
    });
  });
});
