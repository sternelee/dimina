export class DMPStringUtils {
  static isNotEmpty(str: string): Boolean {
    return (str !== null && str !== '' && str !== undefined)
  }

  static isEmpty(str: string): Boolean {
    return !DMPStringUtils.isNotEmpty(str)
  }

  static isNumberString(value: string): boolean {
    const numericRegex = /^[0-9]+$/;
    if (!numericRegex.test(value)) {
      return false;
    }
    const num = Number(value);
    if (Number.isNaN(num)) {
      return false;
    }
    return true;
  }

  static jsonToObject(json: string): object {
    return JSON.parse(json)
  }

  static stringToNumber(str: string | undefined | null): number {
    if (str == null || str === "" || str === undefined) {
      return 0;
    } else {
      return Number(str);
    }
  }

  static truncateString(str: string, maxLength: number = 25) {
    if (str.length > maxLength) {
      return str.substring(0, maxLength - 3) + '...';
    }
    return str;
  }
}