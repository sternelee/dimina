const DEFAULT_WARMUP = 10
const DEFAULT_ITERATIONS = 50

function now() {
	if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
		return performance.now()
	}
	return Date.now()
}

function createItems(count, prefix = 'item', selected = false) {
	return Array.from({ length: count }, (_, id) => ({
		id,
		name: `${prefix}-${id}`,
		label: `${prefix}-${id}`,
		selected,
		value: 0,
	}))
}

function createComponents(count, version = 0) {
	return Array.from({ length: count }, (_, id) => ({
		id,
		value: version,
	}))
}

function setDataAsync(page, patch) {
	return new Promise((resolve) => {
		page.setData(patch, resolve)
	})
}

function report(report) {
	if (typeof wx.benchmarkReport !== 'function') {
		console.error('[benchmark] wx.benchmarkReport is not registered', report)
		return
	}
	wx.benchmarkReport({ report })
}

const CASES = {
	'mount-1000-nodes': {
		async setup(page) {
			page._mountItems = createItems(1000, 'node')
			await setDataAsync(page, {
				activeCase: 'mount-1000-nodes',
				mountItems: [],
			})
		},
		async beforeEach(page) {
			if (page.data.mountItems.length !== 0) {
				await setDataAsync(page, { mountItems: [] })
			}
		},
		async run(page) {
			await setDataAsync(page, { mountItems: page._mountItems })
		},
	},

	'set-data-primitive': {
		async setup(page) {
			await setDataAsync(page, {
				activeCase: 'set-data-primitive',
				count: 0,
			})
		},
		async beforeEach(page) {
			if (page.data.count !== 0) {
				await setDataAsync(page, { count: 0 })
			}
		},
		async run(page) {
			await setDataAsync(page, { count: 1 })
		},
	},

	'set-data-deep-path': {
		async setup(page) {
			await setDataAsync(page, {
				activeCase: 'set-data-deep-path',
				user: {
					profile: {
						name: 'before',
					},
				},
			})
		},
		async beforeEach(page) {
			if (page.data.user.profile.name !== 'before') {
				await setDataAsync(page, { 'user.profile.name': 'before' })
			}
		},
		async run(page) {
			await setDataAsync(page, { 'user.profile.name': 'after' })
		},
	},

	'set-data-batch-100': {
		async setup(page) {
			page._batchReset = createItems(100, 'batch', false)
			page._batchPatch = {}
			for (let i = 0; i < 100; i += 1) {
				page._batchPatch[`batchItems[${i}].selected`] = true
			}
			await setDataAsync(page, {
				activeCase: 'set-data-batch-100',
				batchItems: page._batchReset,
			})
		},
		async beforeEach(page) {
			await setDataAsync(page, {
				batchItems: createItems(100, 'batch', false),
			})
		},
		async run(page) {
			await setDataAsync(page, page._batchPatch)
		},
	},

	'list-create-1000': {
		async setup(page) {
			page._listCreateItems = createItems(1000, 'created')
			await setDataAsync(page, {
				activeCase: 'list-create-1000',
				listItems: [],
			})
		},
		async beforeEach(page) {
			if (page.data.listItems.length !== 0) {
				await setDataAsync(page, { listItems: [] })
			}
		},
		async run(page) {
			await setDataAsync(page, { listItems: page._listCreateItems })
		},
	},

	'list-update-one-1000': {
		async setup(page) {
			await setDataAsync(page, {
				activeCase: 'list-update-one-1000',
				listItems: createItems(1000, 'stable'),
			})
		},
		async run(page) {
			const next = !page.data.listItems[500].selected
			await setDataAsync(page, {
				'listItems[500].selected': next,
			})
		},
	},

	'list-replace-1000': {
		async setup(page) {
			page._replaceVersion = 0
			page._replaceA = createItems(1000, 'replace-a')
			page._replaceB = createItems(1000, 'replace-b', true)
			await setDataAsync(page, {
				activeCase: 'list-replace-1000',
				listItems: page._replaceA,
			})
		},
		async run(page) {
			page._replaceVersion += 1
			await setDataAsync(page, {
				listItems: page._replaceVersion % 2 === 0
					? page._replaceA
					: page._replaceB,
			})
		},
	},

	'wx-if-toggle-1000': {
		async setup(page) {
			await setDataAsync(page, {
				activeCase: 'wx-if-toggle-1000',
				conditionalVisible: false,
				conditionalItems: createItems(1000, 'conditional'),
			})
		},
		async beforeEach(page) {
			if (page.data.conditionalVisible) {
				await setDataAsync(page, { conditionalVisible: false })
			}
		},
		async run(page) {
			await setDataAsync(page, { conditionalVisible: true })
		},
	},

	'component-500-update': {
		async setup(page) {
			page._componentVersion = 0
			await setDataAsync(page, {
				activeCase: 'component-500-update',
				componentItems: createComponents(500, 0),
			})
		},
		async run(page) {
			page._componentVersion += 1
			await setDataAsync(page, {
				componentItems: createComponents(500, page._componentVersion),
			})
		},
	},
}

Page({
	data: {
		activeCase: 'idle',
		count: 0,
		user: {
			profile: {
				name: 'before',
			},
		},
		batchItems: [],
		mountItems: [],
		listItems: [],
		conditionalVisible: false,
		conditionalItems: [],
		componentItems: [],
	},

	onLoad(options = {}) {
		this._benchmarkOptions = {
			name: options.case || 'set-data-primitive',
			mode: options.mode || 'baseline',
			warmup: clampInt(options.warmup, DEFAULT_WARMUP, 0, 1000),
			iterations: clampInt(options.iterations, DEFAULT_ITERATIONS, 1, 10000),
		}
	},

	onReady() {
		const options = this._benchmarkOptions

		if (options.name === 'cold-start') {
			report({
				name: 'cold-start',
				ready: true,
				metadata: this.createMetadata(),
			})
			return
		}

		Promise.resolve()
			.then(() => this.runBenchmark())
			.catch((error) => {
				report({
					name: options.name,
					error: error?.stack || error?.message || String(error),
					metadata: this.createMetadata(),
				})
			})
	},

	async runBenchmark() {
		const options = this._benchmarkOptions
		const benchmark = CASES[options.name]

		if (!benchmark) {
			throw new Error(`Unknown benchmark case: ${options.name}`)
		}

		await benchmark.setup?.(this)

		for (let i = 0; i < options.warmup; i += 1) {
			await benchmark.beforeEach?.(this)
			await benchmark.run(this)
		}

		const samples = []

		for (let i = 0; i < options.iterations; i += 1) {
			await benchmark.beforeEach?.(this)

			const start = now()
			await benchmark.run(this)
			samples.push(now() - start)
		}

		report({
			name: options.name,
			samples,
			metadata: this.createMetadata(),
		})
	},

	createMetadata() {
		return {
			mode: this._benchmarkOptions.mode,
			warmup: this._benchmarkOptions.warmup,
			iterations: this._benchmarkOptions.iterations,
		}
	},
})

function clampInt(value, fallback, min, max) {
	const parsed = Number.parseInt(value ?? '', 10)
	if (!Number.isFinite(parsed)) return fallback
	return Math.min(max, Math.max(min, parsed))
}
