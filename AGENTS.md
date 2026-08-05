# Agent instructions

This Flutter app (`meroapp`) talks to a separate backend (`socketTest`, in
the sibling directory), being built independently by another agent (Cline).
Neither agent can see the other's session — the only shared context is
written files.

**Before starting work**, read `docs/coordination.md`. It documents the
live API contract as actually implemented by the backend (auth token model,
cookies, CSRF, routes) — this can and will drift from
`docs/implementation-plan.md`, which only reflects the plan at the time it
was written. When the two disagree, trust `docs/coordination.md`.

**Before ending a session**, if you changed anything that affects how this
app talks to the backend, or if you discovered the backend's actual
behavior differs from what's documented, append a dated bullet to the
Session Log section at the bottom of `docs/coordination.md`. If you
resolved one of the numbered issues in the table there, update its Status
column instead of leaving it stale.

Keep `flutter analyze` clean (or at least not regressing) before ending a
session.
