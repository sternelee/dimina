import { BasicDataSource } from "./BasicDataSource";

export class MiniProgramDataSource extends BasicDataSource {
  private showDataList: MiniProgramModel[] = [];
  private originDataArray: MiniProgramModel[] = [];

  public totalCount(): number {
    return this.showDataList.length;
  }

  public getData(index: number): MiniProgramModel {
    return this.showDataList[index];
  }

  public pushData(data: MiniProgramModel): void {
    this.showDataList.push(data);
    this.originDataArray.push(data);
    this.notifyDataAdd(this.showDataList.length - 1);
  }

  public search(name: string): void {
    if (name == undefined || name == null || name.length == 0) {
      this.showDataList = this.originDataArray;
      this.notifyDatasetChange([{ type: DataOperationType.ADD, index: 0, count: this.showDataList.length }])
    } else {
      const deleteCount = this.showDataList.length;
      this.showDataList = [];
      this.notifyDatasetChange([{ type: DataOperationType.DELETE, index: 0, count: deleteCount }])
      for (let i = 0; i < this.originDataArray.length; i++) {
        let e = this.originDataArray[i];
        if (e.name.toLowerCase().includes(name.toLowerCase())) {
          console.log("victor search", e.name)
          this.showDataList.push(e)
        }
      }
      this.notifyDatasetChange([{ type: DataOperationType.ADD, index: 0, count: this.showDataList.length }])
    }
  }
}

export class MiniProgramModel {
  appId: string
  name: string
  iconColor: string

  constructor(appId: string, name: string, iconColor: string) {
    this.appId = appId;
    this.name = name;
    this.iconColor = iconColor;
  }
}