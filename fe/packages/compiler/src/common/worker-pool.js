import fs from 'node:fs'
import os from 'node:os'

function getCGroupCPUCount() {
	try {
		// 尝试读取容器的CPU quota和period
		const quotaPath = '/sys/fs/cgroup/cpu/cpu.cfs_quota_us'
		const periodPath = '/sys/fs/cgroup/cpu/cpu.cfs_period_us'

		if (fs.existsSync(quotaPath) && fs.existsSync(periodPath)) {
			const quota = Number.parseInt(fs.readFileSync(quotaPath, 'utf8'))
			const period = Number.parseInt(fs.readFileSync(periodPath, 'utf8'))

			if (quota > 0) {
				return Math.max(1, Math.floor(quota / period))
			}
		}
	}
	catch (e) {
		// 如果读取失败，回退到os.cpus()
		console.warn('Failed to read CPU limits from cgroup:', e.message)
	}

	return os.cpus().length
}

function getCGroupMemoryLimit() {
	try {
		// 尝试读取容器的内存限制
		const memLimitPath = '/sys/fs/cgroup/memory/memory.limit_in_bytes'

		if (fs.existsSync(memLimitPath)) {
			const memLimit = Number.parseInt(fs.readFileSync(memLimitPath, 'utf8'))
			if (memLimit < Number.Infinity && memLimit > 0) {
				return memLimit
			}
		}
	}
	catch (e) {
		// 如果读取失败，回退到os.totalmem()
		console.warn('Failed to read memory limits from cgroup:', e.message)
	}

	return os.totalmem()
}

// 默认使用CPU核心数的1/4，减少内存压力
export const MAX_WORKERS = Math.max(1, Math.floor(getCGroupCPUCount() / 4))

// 工作线程池
class WorkerPool {
	constructor(maxWorkers = MAX_WORKERS) {
		this.maxWorkers = maxWorkers
		this.activeWorkers = 0
		this.queue = []
		this.memoryLimit = Math.floor(getCGroupMemoryLimit() * 0.7 / maxWorkers) // 70% of total memory divided by workers
	}

	async runWorker(workerCreator) {
		if (this.activeWorkers >= this.maxWorkers) {
			// 如果活跃工作线程达到上限，加入队列等待
			await new Promise(resolve => this.queue.push(resolve))
		}

		this.activeWorkers++
		try {
			return await workerCreator()
		}
		finally {
			this.activeWorkers--
			if (this.queue.length > 0) {
				// 当前工作线程完成，从队列中释放一个等待的任务
				const next = this.queue.shift()
				next()
			}
		}
	}

	getWorkerOptions() {
		return {
			resourceLimits: {
				maxOldGenerationSizeMb: Math.floor(this.memoryLimit / (1024 * 1024)), // Convert bytes to MB
				maxYoungGenerationSizeMb: Math.floor(this.memoryLimit / (1024 * 1024) / 4),
				codeRangeSizeMb: 128,
			},
		}
	}
}

export const workerPool = new WorkerPool()
