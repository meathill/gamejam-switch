export interface Bounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface RawImage {
  data: Uint8Array;
  width: number;
  height: number;
  channels: number;
}

const DEFAULT_ALPHA_THRESHOLD = 8;

export function findOpaqueBounds(image: RawImage, alphaThreshold = DEFAULT_ALPHA_THRESHOLD): Bounds | null {
  const { data, width, height, channels } = image;
  let left = width;
  let top = height;
  let right = -1;
  let bottom = -1;
  for (let y = 0; y < height; y++) {
    const rowOffset = y * width * channels;
    for (let x = 0; x < width; x++) {
      if (data[rowOffset + x * channels + channels - 1] <= alphaThreshold) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  return right < 0 ? null : { left, top, right: right + 1, bottom: bottom + 1 };
}

export function unionBounds(list: Bounds[]): Bounds {
  if (list.length === 0) throw new Error('unionBounds: empty list');
  return list.reduce((union, item) => ({
    left: Math.min(union.left, item.left),
    top: Math.min(union.top, item.top),
    right: Math.max(union.right, item.right),
    bottom: Math.max(union.bottom, item.bottom),
  }));
}

export function padBounds(bounds: Bounds, padding: number, width: number, height: number): Bounds {
  return {
    left: Math.max(0, bounds.left - padding),
    top: Math.max(0, bounds.top - padding),
    right: Math.min(width, bounds.right + padding),
    bottom: Math.min(height, bounds.bottom + padding),
  };
}
