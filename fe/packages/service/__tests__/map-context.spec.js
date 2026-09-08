import { createMapContext } from '../src/api/core/map'
import router from '../src/core/router'
import message from '../src/core/message'
import { callback } from '@dimina/common'

beforeEach(() => {
	vi.spyOn(router, 'getPageInfo').mockReturnValue({ id: 'page-a', bridgeId: 'page-a', __id__: 'module-a' })
	vi.spyOn(message, 'send').mockImplementation(() => {})
})
afterEach(() => { callback.remove(); vi.restoreAllMocks() })

it('routes a retained context to its owner after navigation and preserves callbacks', () => {
	const context = createMapContext('map', { __id__: 'component-a' })
	vi.mocked(router.getPageInfo).mockReturnValue({ id: 'page-b' })
	const success = vi.fn()
	const complete = vi.fn()
	context.getScale({ success, complete, mapId: 'spoof', moduleId: 'spoof', mapBridgeId: 'spoof' })
	const msg = message.send.mock.calls[0][0]
	expect(msg.target).toBe('render')
	expect(msg.body.bridgeId).toBe('page-a')
	expect(msg.body.params).toMatchObject({ mapId: 'map', moduleId: 'component-a', command: 'getScale' })
	callback.invoke(msg.body.params.success, { scale: 17 })
	callback.invoke(msg.body.params.complete, { scale: 17 })
	expect(success).toHaveBeenCalledWith({ scale: 17 })
	expect(complete).toHaveBeenCalledWith({ scale: 17 })
})
it('returns a promise when no callbacks are supplied', async () => {
	const result = createMapContext('map').getRegion()
	const { params } = message.send.mock.calls[0][0].body
	expect(params.moduleId).toBe('module-a')
	callback.invoke(params.fail, { errMsg: 'getRegion:fail map not found' })
	await expect(result).rejects.toMatchObject({ errMsg: 'getRegion:fail map not found' })
})

it.each(['includePoints', 'getCenterLocation', 'moveToLocation'])('routes the demo command %s with the page module ID', (command) => {
	const context = createMapContext('places')
	vi.mocked(router.getPageInfo).mockReturnValue({ id: 'page-b', bridgeId: 'page-b', __id__: 'module-b' })
	context[command]({ fail: vi.fn() })
	expect(message.send.mock.calls[0][0].body).toMatchObject({
		bridgeId: 'page-a', params: { mapId: 'places', moduleId: 'module-a', command },
	})
})

it('uses an explicitly supplied component owner even when another page is current', () => {
	const context = createMapContext('places', { bridgeId: 'previous-page', __id__: 'previous-component' })
	context.getScale({ fail: vi.fn() })
	expect(message.send.mock.calls[0][0].body).toMatchObject({
		bridgeId: 'previous-page', params: { moduleId: 'previous-component' },
	})
})
