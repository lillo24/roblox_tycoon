# Parry Lab server

`Match.luau` owns supplied-time combat, commitment, guard recovery, damage, stagger
and counter windows. `Runtime.luau` owns temporary arena geometry, character setup,
the predictable solo opponent, optional two-player queue, range/facing checks,
bounded timestamp validation, private snapshots and disconnect/restart cleanup.
Both consume shared `ParryLab/Rules.luau`. No cash or persistent character state.
