import { filterData } from '../../core/utils'

export class PageModule {
	static type = 'page'

	constructor(moduleInfo, extraInfo) {
		this.moduleInfo = moduleInfo
		this.extraInfo = extraInfo
		this.type = PageModule.type
		this.usingComponents = this.extraInfo.usingComponents
		this.noReferenceData = filterData(this.moduleInfo.data || {})
	}
}
