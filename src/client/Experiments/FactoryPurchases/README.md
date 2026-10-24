# Factory purchase interaction and presentation

`Controller.luau` starts the walk-on HUD variant and replies to entry offers only
with panels/menu closed, prompt input enabled and window focused. It owns the local
Roblox-bundled purchase tone and cleanup. `Activity.luau` owns cosmetic assembly,
machine benefit text above the output block, one rotor/two simulated output parts
per machine, owner/idle state, distance/30 Hz update bounds and reduced motion.
Decorations never collide/touch/query or calculate income. Existing colliders do
not move. Bootstrap selects this controller for Factory by default. Modes is a
modal input gate alongside Factory/Settings, native menu, text focus and window
focus. Closing a panel never retriggers a consumed pad visit; step off and re-enter.

`VisitGate.luau` remembers locally occupied pads entered while input is blocked,
until the character actually leaves the exit hysteresis. Controller samples only
the assigned plot at 20 Hz and also checks immediately on an offer. This handles
position/offer replication arriving after a menu closes. The server offers
`(nonce, plotId, upgradeId)`; target metadata only suppresses inappropriate client
acknowledgements. Only the nonce returns, and all server character, ownership,
position, expiry and transaction checks remain authoritative. A stale offer for a
different/left pad is never acknowledged; character replacement clears local visits.
