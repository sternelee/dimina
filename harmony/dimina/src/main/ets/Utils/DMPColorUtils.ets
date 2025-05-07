export class DMPColorUtils {
  /**
   * 将颜色字符串转换为 bigint。
   * 颜色字符串可以是 "#RRGGBB"、"#AARRGGBB" 或 "#RRGGBBAA" 格式。
   * 如果缺少 alpha 通道，默认设置为完全不透明（0xFF）。
   *
   * @param colorString 颜色字符串，格式为 "#RRGGBB"、"#AARRGGBB" 或 "#RRGGBBAA"。
   * @param format 可选参数。指定 'ARGB' 表示 alpha 在前，或 'RGBA' 表示 alpha 在后。默认值为 'RGBA'。
   * @returns 表示颜色的 bigint 值。
   */
  static stringToBigInt(colorString: string, format: 'ARGB' | 'RGBA' = 'RGBA'): bigint {
    if (!/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(colorString)) {
      throw new Error(`无效的颜色格式: ${colorString}`);
    }

    let hex = '';

    if (colorString.length === 7) {
      // "#RRGGBB" 格式，在前面添加 "FF" 作为 alpha。
      hex = `FF${colorString.slice(1)}`;
    } else if (colorString.length === 9) {
      if (format === 'ARGB') {
        // "#AARRGGBB" 格式，alpha 在前。
        hex = colorString.slice(1);
      } else if (format === 'RGBA') {
        // "#RRGGBBAA" 格式，alpha 在后。重新排列为 AARRGGBB。
        hex = `${colorString.slice(7, 9)}${colorString.slice(1, 7)}`;
      } else {
        throw new Error(`不支持的格式: ${format}`);
      }
    } else {
      throw new Error(`无效的颜色格式长度: ${colorString}`);
    }

    // 转换为 bigint。
    return BigInt(`0x${hex}`);
  }

  /**
   * 将颜色字符串转换为数字（十六进制整数）。
   * 颜色字符串可以是 "#RRGGBB"、"#AARRGGBB" 或 "#RRGGBBAA" 格式。
   * 如果缺少 alpha 通道，默认设置为完全不透明（0xFF）。
   *
   * @param colorString 颜色字符串，格式为 "#RRGGBB"、"#AARRGGBB" 或 "#RRGGBBAA"。
   * @param format 可选参数。指定 'ARGB' 表示 alpha 在前，或 'RGBA' 表示 alpha 在后。默认值为 'RGBA'。
   * @returns 表示颜色的数字值。
   */
  static stringToHexNumber(colorString: string, format: 'ARGB' | 'RGBA' = 'RGBA'): number {
    if (!/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(colorString)) {
      throw new Error(`无效的颜色格式: ${colorString}`);
    }

    let hex = '';

    if (colorString.length === 7) {
      // "#RRGGBB" 格式，在前面添加 "FF" 作为 alpha。
      hex = `FF${colorString.slice(1)}`;
    } else if (colorString.length === 9) {
      if (format === 'ARGB') {
        // "#AARRGGBB" 格式，alpha 在前。
        hex = colorString.slice(1);
      } else if (format === 'RGBA') {
        // "#RRGGBBAA" 格式，alpha 在后。重新排列为 AARRGGBB。
        hex = `${colorString.slice(7, 9)}${colorString.slice(1, 7)}`;
      } else {
        throw new Error(`不支持的格式: ${format}`);
      }
    } else {
      throw new Error(`无效的颜色格式长度: ${colorString}`);
    }

    // 转换为数字。
    const hexNumber = parseInt(hex, 16);

    // 检查值是否在安全整数范围内。
    if (hexNumber > Number.MAX_SAFE_INTEGER) {
      throw new Error(`转换后的值超出安全整数范围: ${hexNumber}`);
    }

    return hexNumber;
  }


  static generateColorFromName(name: string): string {
    if (!name || name.length === 0) {
      return '#2196F3';
    }

    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = ((hash << 5) - hash) + name.charCodeAt(i);
      hash |= 0;
    }

    const hue = Math.abs(hash % 360);
    const saturation = 0.7 + (Math.abs(hash % 3000) / 10000);
    const value = 0.8 + (Math.abs(hash % 2000) / 10000);
    const rgbColor = DMPColorUtils.hsvToRgb(hue, saturation, value);
    return DMPColorUtils.rgbToHex(rgbColor[0], rgbColor[1], rgbColor[2]);
  }

  static hsvToRgb(h: number, s: number, v: number): Array<number> {
    let r: number = 0, g: number = 0, b: number = 0;
    const i = Math.floor(h / 60);
    const f = h / 60 - i;
    const p = v * (1 - s);
    const q = v * (1 - f * s);
    const t = v * (1 - (1 - f) * s);

    switch (i % 6) {
      case 0:
        r = v;
        g = t;
        b = p;
        break;
      case 1:
        r = q;
        g = v;
        b = p;
        break;
      case 2:
        r = p;
        g = v;
        b = t;
        break;
      case 3:
        r = p;
        g = q;
        b = v;
        break;
      case 4:
        r = t;
        g = p;
        b = v;
        break;
      case 5:
        r = v;
        g = p;
        b = q;
        break;
    }

    return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
  }

  static rgbToHex(r: number, g: number, b: number): string {
    return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
  }
}