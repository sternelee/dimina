const componentsInfo = import.meta.glob('./component/**/index.js', { eager: true })
const components = Object.values(componentsInfo).map((module) => {
	return module.default
})

export default components
