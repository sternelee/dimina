import fs from 'node:fs/promises'

const [baselineFile, candidateFile] = process.argv.slice(2)

if (!baselineFile || !candidateFile) {
	throw new Error(
		'Usage: node runner/compare.js <baseline.json> <candidate.json>',
	)
}

const baseline = JSON.parse(await fs.readFile(baselineFile, 'utf8'))
const candidate = JSON.parse(await fs.readFile(candidateFile, 'utf8'))

console.log(`baseline:  ${baseline.mode}`)
console.log(`candidate: ${candidate.mode}`)
console.log('')
console.log('| case | baseline median | candidate median | diff | baseline p95 | candidate p95 |')
console.log('|---|---:|---:|---:|---:|---:|')

for (const [name, current] of Object.entries(candidate.cases)) {
	const previous = baseline.cases[name]
	if (!previous) continue

	const baselineMedian = previous.timingMs.median
	const candidateMedian = current.timingMs.median
	const diff = baselineMedian === 0
		? 0
		: ((candidateMedian - baselineMedian) / baselineMedian) * 100

	console.log(
		`| ${name} ` +
		`| ${baselineMedian.toFixed(3)} ms ` +
		`| ${candidateMedian.toFixed(3)} ms ` +
		`| ${formatDiff(diff)} ` +
		`| ${previous.timingMs.p95.toFixed(3)} ms ` +
		`| ${current.timingMs.p95.toFixed(3)} ms |`,
	)
}

function formatDiff(value) {
	const prefix = value > 0 ? '+' : ''
	return `${prefix}${value.toFixed(1)}%`
}
