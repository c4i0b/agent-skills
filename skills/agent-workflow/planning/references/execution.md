# Execution protocol

How an agent executes a plan or task graph once planning is done. Adapted
from a validated external pattern (subagent-per-task with rulings and
stop conditions), reshaped for how this repo's orchestration already
works.

## Continuous execution

Execute the plan without pausing to check in. Progress summaries and
"should I continue?" prompts cost the user time and buy nothing. The plan
and the ledger carry the record.

## Rulings, not stalls

A running plan does not wait on the human. Conflicts, ambiguities and
plan defects get decided, not escalated: the spec is the binding
authority, the plan is its argument, and judgment settles what neither
answers. Record every decision in the ledger:

`Ruling: <what was decided> — <why> — <what it costs if wrong>`

A wrong ruling costs visible, undoable rework. A session parked on a
question costs the whole day.

## The four stops

Only these stop execution:

1. An irreversible or destructive operation.
2. A security-sensitive action.
3. A side effect outside the worktree that norms say to ask about first
   (merge, push to a shared branch, publish).
4. A plan so broken every path forward is a guess.

Everything else is a ruling.

## Verify at the end

An agent's "done" is a hypothesis (see
[agent-orchestration](../../agent-orchestration/SKILL.md)): gates re-run,
repo state checked, handoff states open and blocked items.
