import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const packageRoot = path.resolve(here, '..')
const compilerModule = path.resolve(packageRoot, '../compiler/src/index.js')
const sourceDir = path.resolve(packageRoot, 'miniapp')
const targetDir = path.resolve(packageRoot, 'web/public/miniapp')

await fs.mkdir(targetDir, { recursive: true })

const { default: build } = await import(compilerModule)
const result = await build(targetDir, sourceDir, true)

console.log(`[benchmark] compiled ${result.appId} -> ${targetDir}`)
console.log(`[benchmark] entry: ${result.path}`)
