// @vitest-environment jsdom

import { beforeEach, describe, expect, it, vi } from 'vitest'

const { getAppList } = vi.hoisted(() => ({
	getAppList: vi.fn(() => new Promise(() => {})),
}))

vi.mock('@/services', () => ({
	getAppList,
	getMiniAppInfo: vi.fn(),
}))

import { AppList } from '../src/pages/appList/appList.js'

describe('app list navigation', () => {
	let page
	let list
	let navigation

	beforeEach(() => {
		getAppList.mockClear()
		page = new AppList({ openApp: vi.fn() })
		page.parent = { updateStatusBarColor: vi.fn() }
		page.viewDidLoad()
		list = page.el.querySelector('.dimina-app__mini-used-list')
		navigation = page.el.querySelector('.dimina-app-navigation')
	})

	it('reveals the navigation after the list leaves its top edge', () => {
		expect(navigation.classList.contains('dimina-app-navigation--visible')).toBe(false)

		list.scrollTop = 24
		list.dispatchEvent(new Event('scroll'))

		expect(navigation.classList.contains('dimina-app-navigation--visible')).toBe(true)
	})

	it('hides the navigation again when the list returns to the top', () => {
		list.scrollTop = 24
		list.dispatchEvent(new Event('scroll'))
		list.scrollTop = 0
		list.dispatchEvent(new Event('scroll'))

		expect(navigation.classList.contains('dimina-app-navigation--visible')).toBe(false)
	})

	it('restores the navigation state when the list page is presented again', () => {
		list.scrollTop = 24
		page.onPresentIn()

		expect(navigation.classList.contains('dimina-app-navigation--visible')).toBe(true)
		expect(page.parent.updateStatusBarColor).toHaveBeenCalledWith('black')
	})
})
