# TODO

Outstanding work on the package.

## TODO-1: Public reset

Make `reset()` public, or provide a public test-support target, so tests don't need `@testable import`.

## TODO-2: Scoped containers

Support scoped or child containers for per-feature or per-screen dependency lifetimes.

## TODO-3: Async factories

Support async factories. Factories are currently synchronous.

## TODO-4: Compile-time registration validation

Catch unregistered dependencies before runtime, for example with a macro or build plugin.

## TODO-5: Cycle detection

Trap with a clear message when factories form a cycle, instead of recursing infinitely.

## TODO-6: Simplify forwarding

Replace the `@retroactive` conformance pattern of forwarding with a registration-based API.

## TODO-7: TaskLocal instead of overrides

Explore `TaskLocal` as a replacement for overrides.

## TODO-8: Parallel testing

Allow multiple containers, so tests can run in parallel.
