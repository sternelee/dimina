// Runs real loading bridge and callback code on Node; ArkUI rendering needs device acceptance.
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { createRequire } from 'node:module'
import { test } from 'node:test'
import vm from 'node:vm'

const require = createRequire(new URL('../../fe/packages/compiler/package.json', import.meta.url))
const { transformSync } = require('esbuild')
const sourceRoot = new URL('../dimina/src/main/ets/', import.meta.url)
function load(path, deps = {}) {
  const { code } = transformSync(fs.readFileSync(new URL(path, sourceRoot), 'utf8'), {
    loader: 'ts', format: 'cjs', target: 'es2022',
  })
  const module = { exports: {} }
  vm.runInNewContext(code, { module, exports: module.exports,
    AppStorage: { setOrCreate() {} },
    require(name) {
      assert.ok(name in deps, `Unexpected dependency: ${name}`)
      return deps[name]
    },
  })
  return module.exports
}
const map = load('Utils/DMPMap.ts', { '@kit.ArkTS': {} })
const base = load('Bridges/DMPContainerBridgesModule.ets', {
  '../Service/DMPSendableObjects': { AppData: class {} },
  './DMPTSUtil': { isMainThread: () => true,
    DMPBridgeCallbackType: { Success: 'success', Complete: 'complete', Fail: 'fail' } },
  '../EventTrack/DMPLogger': { DMPLogger: { d() {} } },
  '../Utils/DMPMap': map,
  '../Bundle/Util/DMPFileUrlConvertor': {},
})
const { default: Loading } = load('Bridges/DMPContainerBridgesModule+Loading.ets', {
  '../Utils/DMPMap': map, './DMPContainerBridgesModule': base,
})
function fixture() {
  const records = new Map([1, 2].map(id => [id, { isShowLoading: false, showLoadingTitle: '' }]))
  const loading = new Loading({ navigatorManager: { getPageRecordById: id => records.get(id) } })
  return { loading, records, data: title => new map.DMPMap({ title }) }
}

test('two loading cycles update the page and complete every bridge call', () => {
  const { loading, records, data } = fixture()
  const results = []
  for (const method of ['showLoading', 'hideLoading', 'showLoading', 'hideLoading']) {
    const start = results.length
    loading[method](data(method), (result, type) => results.push([type, result.get('errMsg')]), 1)
    assert.equal(records.get(1).isShowLoading, method === 'showLoading')
    assert.deepEqual(results.slice(start), [['success', `${method}:ok`], ['complete', `${method}:ok`]])
    assert.equal(records.get(2).isShowLoading, false)
  }
})

test('success callbacks can drive show-hide-show-hide without getting stuck', () => {
  const { loading, records, data } = fixture()
  const methods = ['showLoading', 'hideLoading', 'showLoading', 'hideLoading']
  const states = []
  let complete = 0
  const step = index => {
    if (index === methods.length) return
    loading[methods[index]](data(`step-${index}`), (_result, type) => {
      if (type === 'complete') complete++
      if (type === 'success') {
        states.push(records.get(1).isShowLoading)
        step(index + 1)
      }
    }, 1)
  }
  step(0)
  assert.deepEqual(states, [true, false, true, false])
  assert.equal(complete, 4)
})

test('repeated shows update the title, repeated hides are safe, other pages remain unchanged', () => {
  const { loading, records, data } = fixture()
  loading.showLoading(data('first'), null, 1)
  loading.showLoading(data('second'), null, 1)
  assert.equal(records.get(1).showLoadingTitle, 'second')
  loading.showLoading(data('other page'), null, 2)
  loading.hideLoading(data(''), null, 1)
  loading.hideLoading(data(''), null, 1)
  assert.equal(records.get(1).isShowLoading, false)
  assert.equal(records.get(2).isShowLoading, true)
})

test('a removed page reports failure and completion without touching a different page', () => {
  const { loading, records, data } = fixture()
  records.delete(1)
  for (const method of ['showLoading', 'hideLoading']) {
    const results = []
    loading[method](data('gone'), (result, type) => results.push([type, result.get('errMsg')]), 1)
    assert.deepEqual(results, [['fail', `${method}:fail page not found`], ['complete', `${method}:fail page not found`]])
  }
  assert.equal(records.get(2).isShowLoading, false)
})
