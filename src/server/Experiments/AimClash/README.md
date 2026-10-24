# Aim clash authority

`Match.luau` owns supplied-time individual judgements, expiry, quality/bonus/penalty
accounting, input bounds and ties. It exposes only one actor's live projection;
comparison requires a finished battle. `Runtime.luau` authenticates actual Player
round membership, owns practice/duel queue/replay/disconnect and unicasts each
player's projection. Both totals appear only in the final result. No scores are
stored on replicated Player attributes. AppRuntime starts it only for the trusted
Clash destination; Factory, Infinite and Entry have no Clash remote or queue.
Routing blocks controls while travelling. A departing queued player cannot be
matched, and returning to modes cancels an unfinished duel without a winner.
