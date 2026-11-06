declare module 'subset-font' {
  interface SubsetFontOptions {
    targetFormat?: 'sfnt' | 'truetype' | 'woff' | 'woff2';
    noHinting?: boolean;
  }

  export default function subsetFont(buffer: Buffer, text: string, options?: SubsetFontOptions): Promise<Buffer>;
}
