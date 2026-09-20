// Exercise production ArkTS loader/app methods with filesystem and platform services replaced.
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { createRequire } from 'node:module'
import { test } from 'node:test'
import vm from 'node:vm'
const require = createRequire(new URL('../../fe/packages/compiler/package.json', import.meta.url))
const { transformSync } = require('esbuild')
const root = new URL('../dimina/src/main/ets/', import.meta.url)
function load(file, dependencies = {}) {
  const override = process.env.LAUNCH_SOURCE_ROOT
  const path = override && ['DApp/DMPApp.ets', 'Bundle/Loader/DMPReleaseBundleLoader.ets'].includes(file)
    ? `${override}/${file}` : new URL(file, root)
  const { code } = transformSync(fs.readFileSync(path, 'utf8'), { loader: 'ts', format: 'cjs' })
  const module = { exports: {} }
  vm.runInNewContext(code, { module, exports: module.exports, require: name => dependencies[name] ?? {} })
  return module.exports
}
const logger = { i() {}, d() {}, e() {} }
const context = { debugMode: false, init() {}, getUIAbilityContext() { return {} } }
const { EngineStatus, StatusMonitor } = load('DApp/utils/DMPStatusMonitor.ets')
function loaderFixture({ debug = true, hostDebug = false, appConfig = { versionCode: 7 }, sdkConfig = { versionCode: 50 } } = {}) {
  const disk = { appConfig, sdkConfig }
  const calls = { cleanup: 0, ready: 0, errors: [], install: 0 }
  const files = {
    initRootDir() {}, loadJSAppConfig: () => disk.appConfig, loadJSSdkConfig: () => disk.sdkConfig,
    async clearJSAppHistoryBundle() { calls.cleanup++ }, async clearJSSdkHistoryBundle() { calls.cleanup++ },
  }
  const configParser = { fromJson: x => x }
  const { DMPBundleLoadInfo } = load('Bundle/Model/DMPBundleLoadInfo.ets')
  const remote = { async installInitialPackageIfNeeded() { calls.install++; return false } }
  const { DMPReleaseBundleLoader } = load('Bundle/Loader/DMPReleaseBundleLoader.ets', {
    '../Model/DMPBundleLoadInfo': { DMPBundleLoadInfo },
    '../Util/DMPFileManager': { DMPFileManager: { sharedInstance: () => files } },
    '../Model/DMJSAppBundleConfig': { DMJSAppBundleConfig: configParser },
    '../Model/DMPJSSdkBundleConfig': { DMPJSSdkBundleConfig: configParser },
    '../../Utils/DMPContextUtils': { DMPContextUtils: { ...context, debugMode: hostDebug } },
    '../../Utils/DMPRawFileUtils': { DMPRawFileUtils: { loadFile: () => '' } },
    '../../Utils/DMPStringUtils': { DMPStringUtils: { isNotEmpty: Boolean } },
    '../../EventTrack/DMPLogger': { DMPLogger: logger }, '../../EventTrack/Tags': { Tags: {} },
    '../../Utils/DMPPreference': { DMPPreference: { getInstance: () => ({ get: async (_key, fallback) => fallback, put() {} }) } },
    '../Model/DMPBundleError': { ErrorCode: { LAUNCH_FAILED: 1, LOAD_LOCAL_BUNDLE_FAILED: 2 } },
    '../DMPRemoteUpdateManager': { DMPRemoteUpdateManager: { sharedInstance: () => remote } },
    '@ohos.bundle.bundleManager': { BundleFlag: {}, getBundleInfoForSelf: async () => ({ versionCode: 1, versionName: '1' }) },
  })
  const app = { appConfig: { isDebugMode: debug } }
  const make = () => new DMPReleaseBundleLoader(app)
  const install = loader => loader.install({ appId: 'remote-app', appIndex: 1 }, info => {
    calls.ready++
    assert.equal(info.currentJsAppBundleConfig, disk.appConfig)
    assert.equal(info.currentJsSdkBundleConfig, disk.sdkConfig)
  }, undefined, (code, message) => calls.errors.push({ code, message }))
  return { disk, files, calls, remote, make, install }
}
for (const mode of [{ debug: true }, { debug: false, hostDebug: true }, { debug: false }]) {
  test(`remote-only cached package survives reopening and cold restart ${JSON.stringify(mode)}`, async () => {
    const f = loaderFixture(mode)
    await f.install(f.make())
    await f.install(f.make())
    assert.equal(f.calls.ready, 2)
    assert.equal(f.calls.errors.length, 0)
    assert.equal(f.disk.appConfig.versionCode, 7)
  })
}
test('incomplete configuration reports failure once and skips history cleanup', async () => {
  const f = loaderFixture({ sdkConfig: null })
  await f.install(f.make())
  assert.equal(f.calls.ready, 0)
  assert.equal(f.calls.errors.length, 1)
  assert.equal(f.calls.cleanup, 0)
})
test('version lookup exception reaches the loadError callback', async () => {
  const f = loaderFixture()
  const loader = f.make()
  loader.loadAppVersion = async () => { throw new Error('version lookup failed') }
  await f.install(loader)
  assert.equal(f.calls.errors.length, 1)
  assert.equal(f.calls.cleanup, 0)
})
test('successful first manifest installation reloads config from disk', async () => {
  const f = loaderFixture({ appConfig: null })
  f.remote.installInitialPackageIfNeeded = async () => { f.disk.appConfig = { versionCode: 9 }; return true }
  await f.install(f.make())
  assert.equal(f.calls.ready, 1)
  assert.equal(f.calls.errors.length, 0)
})
test('failed manifest installation can retry on the same loader without deleting cached packages', async () => {
  const f = loaderFixture()
  const loader = f.make()
  f.remote.installInitialPackageIfNeeded = async () => { throw new Error('download failed') }
  await f.install(loader)
  assert.equal(f.calls.errors.length, 1)
  assert.equal(f.calls.cleanup, 0)
  assert.equal(f.disk.appConfig.versionCode, 7)
  f.remote.installInitialPackageIfNeeded = async () => false
  await f.install(loader)
  assert.equal(f.calls.ready, 1)
  assert.equal(f.calls.errors.length, 1)
})
function appFixture() {
  const manager = { async collectRetainedApps() {}, isDestroyingAllMiniPrograms: () => false, observeMemoryPressure() {} }
  const { DMPApp } = load('DApp/DMPApp.ets', {
    './utils/DMPStatusMonitor': { EngineStatus, StatusMonitor },
    './DMPAppManager': { DMPAppManager: { sharedInstance: () => manager } },
    '../Utils/DMPContextUtils': { DMPContextUtils: context },
    '../EventTrack/DMPLogger': { DMPLogger: logger }, '../EventTrack/Tags': { Tags: {} },
    '../Bundle/Util/DMPFileManager': { DMPFileManager: { sharedInstance: () => ({ createLocalBundleDirectoryForApp() {} }) } },
    '../Bundle/Model/DMPBundleInstallConfig': { DMPBundleInstallConfig: class {} },
    '../Bundle/DMPRemoteUpdateManager': { DMPRemoteUpdateManager: { sharedInstance: () => ({ isPackageOperationInProgress: () => false }) } },
  })
  const app = Object.create(DMPApp.prototype)
  Object.assign(app, { _runtimeGeneration: 1, _engineStatus: new StatusMonitor(), appConfig: { appId: 'remote' }, restoreRuntimeIfDestroyed() {}, _bundleManager: {} })
  return app
}
test('loadError settles separate launch waiters and late launch, then permits retry', async () => {
  const app = appFixture(), results = []
  let installs = 0, launches = 0
  app.launchInner = () => launches++
  app._bundleManager.install = async (_config, _ready, _complete, error) => { installs++; error(1, 'incomplete') }
  app.launchWhenRuntimeReady({ completion: result => results.push(result) })
  await app.startPackageLoader({})
  app.launchWhenRuntimeReady({ completion: result => results.push(result) })
  assert.deepEqual(results, [false, false])
  assert.equal(app.engineStatus.currentStatus, EngineStatus.STOP)
  app._bundleManager.install = async () => { installs++; app.engineStatus.setStatus(EngineStatus.RUN) }
  const retry = app.startPackageLoader({})
  app.launchWhenRuntimeReady({})
  await retry
  assert.equal(installs, 2)
  assert.equal(launches, 1)
})
test('installer rejection settles completion exactly once and clears waiters', async () => {
  const app = appFixture(), results = []
  const config = { completion: result => results.push(result) }
  app._bundleManager.install = async () => { throw new Error('installer failure') }
  app.launchWhenRuntimeReady(config)
  await app.startPackageLoader({}, config)
  app.engineStatus.setStatus(EngineStatus.RUN)
  assert.deepEqual(results, [false])
  assert.equal(app._engineStatus.statusListeners.size, 0)
})
