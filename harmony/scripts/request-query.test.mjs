// Node regression for ArkTS HTTP dispatch; NetworkKit is mocked (no device traffic).
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { createRequire } from 'node:module'
import { test } from 'node:test'
import vm from 'node:vm'

const require = createRequire(new URL('../../fe/packages/compiler/package.json', import.meta.url))
const { transformSync } = require('esbuild')
const root = new URL('../dimina/src/main/ets/', import.meta.url)

function load(path, dependencies) {
  const { code } = transformSync(fs.readFileSync(new URL(path, root), 'utf8'), {
    loader: 'ts', format: 'cjs', target: 'es2022',
  })
  const module = { exports: {} }
  vm.runInNewContext(code, { module, exports: module.exports, require: name => {
    assert.ok(name in dependencies, `Unexpected dependency: ${name}`)
    return dependencies[name]
  } })
  return module.exports
}

function fixture(result = '') {
  const calls = []
  const { DMPMap } = load('Utils/DMPMap.ts', { '@kit.ArkTS': { ArrayList: class {} } })
  const network = { http: {
    RequestMethod: { GET: 'GET', HEAD: 'HEAD', DELETE: 'DELETE', POST: 'POST' },
    createHttp: () => ({ request: async (url, options) => {
      calls.push({ url, options })
      return { responseCode: 200, header: {}, result }
    } }),
  } }
  const params = load('HttpManager/DMPHttpParamsNext.ets', { '../Utils/DMPMap': { DMPMap } })
  const transport = load('HttpManager/DMPHttp.ets', { '@kit.NetworkKit': network })
  const { DMPNetServiceNext } = load('HttpManager/DMPNetServiceNext.ets', {
    './DMPHttpParamsNext': params, '../Utils/DMPMap': { DMPMap },
    '../EventTrack/DMPLogger': { DMPLogger: { d() {} } },
    '@kit.NetworkKit': network, './DMPHttp': transport,
  })
  return { calls, run: options => new DMPNetServiceNext(new DMPMap(options), 'test', '1').request() }
}

for (const method of ['GET', 'HEAD', 'DELETE']) {
  test(`${method} forwards normalized query without a JSON body and resolves an empty response`, async () => {
    const f = fixture()
    const url = 'https://example.com/api?old=1&transType=20%2C30&list=a&list=b'
    const pending = f.run({ url, method })
    assert.equal(f.calls.length, 1)
    assert.equal(f.calls[0].url, url)
    assert.equal(f.calls[0].options.method, method)
    assert.equal(f.calls[0].options.extraData, undefined)
    const response = await pending
    assert.equal(response.get('data'), '')
    assert.equal(response.get('statusCode'), 200)
  })
}

test('POST still sends its JSON body and parses JSON responses', async () => {
  const f = fixture('{"ok":true}')
  const response = await f.run({ url: 'https://example.com', method: 'POST', data: { page: 1 } })
  assert.equal(f.calls[0].options.method, 'POST')
  assert.equal(f.calls[0].options.extraData, '{"page":1}')
  assert.equal(response.get('data').ok, true)
})

test('unsupported methods reject instead of leaving the callback pending', async () => {
  const f = fixture()
  await assert.rejects(f.run({ url: 'https://example.com', method: 'INVALID' }), /unsupported method/)
  assert.equal(f.calls.length, 0)
})
