# Aim clash authority

`Match.luau` owns supplied-time individual judgements, expiry, quality/bonus/penalty
accounting, input bounds and ties. It exposes only one actor's live projection;
comparison requires a finished battle. `Runtime.luau` authenticates actual Player
round membership, owns practice/duel queue/replay/disconnect and unicasts each
player's projection. Both totals appear only in the final result. No scores are
stored on replicated Player attributes. Normal factory startup remains dormant
only in the explicitly generated experiment preview.
