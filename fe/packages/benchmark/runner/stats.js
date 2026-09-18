export function percentile(values, p) {
	if (!values.length) return 0

	const sorted = [...values].sort((a, b) => a - b)
	const index = Math.min(
		sorted.length - 1,
		Math.max(0, Math.ceil((p / 100) * sorted.length) - 1),
	)
	return sorted[index]
}

export function summarize(values) {
	if (!values.length) {
		return {
			samples: 0,
			min: 0,
			max: 0,
			mean: 0,
			median: 0,
			p95: 0,
			p99: 0,
		}
	}

	const sorted = [...values].sort((a, b) => a - b)
	const sum = sorted.reduce((total, value) => total + value, 0)

	return {
		samples: sorted.length,
		min: sorted[0],
		max: sorted.at(-1),
		mean: sum / sorted.length,
		median: percentile(sorted, 50),
		p95: percentile(sorted, 95),
		p99: percentile(sorted, 99),
	}
}
