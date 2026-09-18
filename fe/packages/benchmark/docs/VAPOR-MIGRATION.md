# Vue 3.6 / Vapor comparison workflow

Recommended order:

```text
A. current main + current Vue VDOM
B. Vue 3.6 + VDOM
C. Vue 3.6 + Vapor
```

Run exactly the same benchmark package from each worktree:

```bash
# A
pnpm --filter @dimina/benchmark bench -- --mode baseline

# B
pnpm --filter @dimina/benchmark bench -- --mode vue36-vdom

# C
pnpm --filter @dimina/benchmark bench -- --mode vue36-vapor
```

Copy the JSON files to one location and compare them.

This three-way split is important because otherwise improvements from the Vue
version bump are incorrectly attributed to Vapor.

Keep semantic compatibility tests separate from performance benchmarks.
Vapor migration in Dimina is not only a package version change: the existing
render runtime uses VNode-oriented APIs and VNode internals for some
mini-program semantics. Performance results are meaningful only after those
semantics remain correct.
