# Methodology

## Update cases

Update timings start immediately before `Page.setData()` in the mini-program
logic layer and stop inside its callback.

That intentionally includes:

```text
logic/service
  -> bridge
  -> render runtime
  -> Vue
  -> DOM update
  -> nextTick/render completion
  -> callback
```

Fixture preparation is excluded from the measured interval.

## Cold start

For each sample the Playwright page is navigated to a fresh benchmark host URL.
The host creates a new container and starts timing immediately before
`container.openApp()`. The benchmark mini-program stops the measurement by
calling `wx.benchmarkReport` after `onReady`.

This is an app/runtime cold start with the browser process and HTTP cache kept
alive between samples. If a true browser-cold/cache-cold metric is needed, add a
separate suite that recreates the BrowserContext for every sample.

## Mode labels

`baseline`, `vue36-vdom`, and `vue36-vapor` do not dynamically switch Vue.
They identify the build/worktree under test.

That prevents a benchmark flag from accidentally changing code paths or
introducing an extra abstraction into the measured runtime.

## Statistics

- median: primary typical-latency metric
- P95: primary tail-latency metric
- P99: diagnostic tail metric
- mean: supporting metric only

Raw samples are also stored in the JSON result.

## Regression gates

Do not initially fail CI for small deltas on shared runners.

Suggested warning thresholds after enough historical runs exist:

- median update regression > 10%
- P95 update regression > 15%
- cold-start regression > 10%

Tighten only after measuring the normal variance of your runner fleet.
