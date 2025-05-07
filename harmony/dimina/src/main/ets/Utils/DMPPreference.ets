import preferences from '@ohos.data.preferences';
import dataPreferences from '@ohos.data.preferences';
import { DMPContextUtils } from './DMPContextUtils';


export class DMPPreference {
  public static PREFERENCE_VERSION_NAME_KEY  = "dimina_store_version_name"
  public static PREFERENCE_VERSION_CODE_KEY  = "dimina_store_version_code"
  private static instance: DMPPreference;
  private preference: dataPreferences.Preferences | null = null;

  private constructor() {
  }

  public static getInstance(): DMPPreference {
    if (!DMPPreference.instance) {
      DMPPreference.instance = new DMPPreference();
    }
    return DMPPreference.instance;
  }

  public async put(key: string, value: preferences.ValueType) {
    await this.checkPreferenceInit();
    this.preference!.putSync(key, value);
    this.preference!.flush();
  }

  public async get<T>(key: string, defaultValue: preferences.ValueType): Promise<T> {
    await this.checkPreferenceInit();
    return await this.preference!.get(key, defaultValue) as T;
  }

  private async checkPreferenceInit() {
    if (this.preference == null) {
      this.preference = await dataPreferences.getPreferences(DMPContextUtils.getUIAbilityContext(), "dimina_preference");
    }
  }
}
