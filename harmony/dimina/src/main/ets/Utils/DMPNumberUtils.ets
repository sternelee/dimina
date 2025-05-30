export class NumberUtils {
  public static getNumber(num: number | undefined, def: number): number {
    if (num) {
      return num
    }
    return def
  }

  public static toInt(num: number): number {
    return Math.floor(num)
  }
  //保留2位小数
  public static round2(num: number): number {
    return Math.round(num * 100) / 100
  }
}