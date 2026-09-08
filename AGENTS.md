žée

## Organization-Wide Finish-First Workspace Policy

This policy is mandatory for every human and agent working in this repository.

- Leave the repository, its worktree registry, branches, and runtime files in a better state than you found them. Finish admitted work before starting more.
- The normal maximum is **three total local worktrees/checkouts per repository**, including the primary checkout, and **three active non-default branches/workstreams**. Resource, conflict, or host limits may reduce this. Exceeding it requires a recorded owner, concrete concurrent purpose, recovery/finish action, and expiry; nested agents or worktrees never bypass the limit.
- Before creating a branch, worktree, or checkout, fetch the remote default branch and audit existing registered and external worktrees. Reuse, finish, or retire an existing lane when safe. Do not create standalone duplicate clones when a Git worktree will do.
- Prefer useful completion in this order: eligible cleanup, review-ready delivery, unblockable active work, then new work. A completed useful increment should be accepted and merged into the default branch before its workspace is released; link remaining scope to a successor milestone or issue.
- A genuinely blocked effort may be paused without occupying local capacity only after its valuable state is committed and pushed to a named branch, its blocker/owner/next action is recorded, and its local workspace is clean and recoverable. Never merge incomplete or failing work merely to reclaim a slot.
- After a Sam-owned PR merges, promptly fetch the default branch; verify the candidate, merge result (including squash/rebase variants), validation/release evidence, cleanliness, ownership, active executions, and runtime dependencies; then remove the eligible worktree through Git, delete its merged local and remote source branches, and prune stale metadata.
- Before any deletion, discover worktrees through Git (including external paths) and recheck exact `HEAD`, merge evidence, tracked/untracked changes, process activity, and runtime dependencies. Dirty, unmerged, ambiguous, active, runtime-dependent, or another person's work stays protected with an explicit disposition.
- Every PR review finding, including outdated or merged-PR threads, needs an explicit public reply with the disposition and validation before resolution. Do not make anyone infer whether feedback was handled.
- Report only measured storage reclaimed from filesystem capacity changes. Cleanup is operational hygiene, not delivery credit; do not invent or game metrics.
