import path from 'node:path'

const WATCH_FILE_EVENTS = new Set(['add', 'change', 'unlink'])

function createWatchRebuildScheduler({ rebuild, onRebuild = () => {}, onError = () => {} }) {
	let pendingChange
	let running = false
	let idlePromise = Promise.resolve()
	let resolveIdle

	const drain = async () => {
		while (pendingChange) {
			const change = pendingChange
			pendingChange = undefined
			try {
				onRebuild(change)
				await rebuild(change)
			}
			catch (error) {
				onError(error, change)
			}
		}

		running = false
		resolveIdle?.()
		resolveIdle = undefined
	}

	return {
		schedule(event, filePath) {
			if (!WATCH_FILE_EVENTS.has(event)) {
				return false
			}

			pendingChange = {
				event,
				filePath,
				count: (pendingChange?.count || 0) + 1,
			}
			if (!running) {
				running = true
				idlePromise = new Promise((resolve) => {
					resolveIdle = resolve
				})
				void drain()
			}
			return true
		},
		waitForIdle() {
			return idlePromise
		},
	}
}

function getPublishedOutputPath(targetPath, useAppIdDir, appId) {
	return path.resolve(targetPath, useAppIdDir ? appId : '.')
}

function isSameOrDescendantPath(candidatePath, directoryPath) {
	const relativePath = path.relative(directoryPath, candidatePath)
	return relativePath === ''
		|| (!relativePath.startsWith(`..${path.sep}`) && relativePath !== '..' && !path.isAbsolute(relativePath))
}

function createIgnoredPathMatcher(ignoredPaths) {
	return (watchedPath) => {
		const absolutePath = path.resolve(watchedPath)
		for (const ignoredPath of ignoredPaths) {
			if (isSameOrDescendantPath(absolutePath, ignoredPath)) {
				return true
			}
		}
		return false
	}
}

export {
	createIgnoredPathMatcher,
	createWatchRebuildScheduler,
	getPublishedOutputPath,
}
