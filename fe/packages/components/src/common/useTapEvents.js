export function useTapEvents(elementRef, handler) {
	onMounted(() => {
		if (elementRef.value) {
			elementRef.value.addEventListener('click', handler)
		}
	})

	onUnmounted(() => {
		if (elementRef.value) {
			elementRef.value.removeEventListener('click', handler)
		}
	})
}
