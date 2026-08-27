Component({
	data: {
		nothing: ''
	},
	methods: {
		selectIcon() {
			console.log('bar icon select')
			this.triggerEvent('selectIcon', {
				type: 'icon'
			})
		}
	},
	lifetimes: {
		created() {
		  console.log('[Lifecycle][Component:bar-icon] created')
		},
		ready() {
		  console.log('[Lifecycle][Component:bar-icon] ready')
		},
		attached() {
		  console.log('[Lifecycle][Component:bar-icon] attached')
		},
		moved() {
		  console.log('[Lifecycle][Component:bar-icon] moved')
		},
		detached() {
		  console.log('[Lifecycle][Component:bar-icon] detached')
		},
		error(error) {
		  console.log('[Lifecycle][Component:bar-icon] error', error)
		},
	  },
	  pageLifetimes: {
		show() {
		  console.log('[Lifecycle][Component:bar-icon] pageLifetimes.show')
		},
		hide() {
		  console.log('[Lifecycle][Component:bar-icon] pageLifetimes.hide')
		},
		resize(size) {
		  console.log('[Lifecycle][Component:bar-icon] pageLifetimes.resize', size)
		},
		routeDone() {
		  console.log('[Lifecycle][Component:bar-icon] pageLifetimes.routeDone')
		},
	  },
})
