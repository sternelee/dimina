export const config = {
	url: process.env.DIMINA_BENCH_URL || 'http://127.0.0.1:5174/',
	warmup: Number(process.env.DIMINA_BENCH_WARMUP || 10),
	iterations: Number(process.env.DIMINA_BENCH_ITERATIONS || 50),
	timeout: Number(process.env.DIMINA_BENCH_TIMEOUT || 60_000),
	outputDir: process.env.DIMINA_BENCH_OUTPUT || './results',
}

export const modes = ['baseline', 'vue36-vdom', 'vue36-vapor']
