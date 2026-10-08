# Factory purchase interaction and presentation

`Controller.luau` starts the walk-on HUD variant and replies to entry offers only
with panels/menu closed, prompt input enabled and window focused. It owns the local
Roblox-bundled purchase tone and cleanup. `Activity.luau` owns cosmetic assembly,
machine benefit text above the output block, one rotor/two simulated output parts
per machine, owner/idle state, distance/30 Hz update bounds and reduced motion.
Decorations never collide/touch/query or calculate income. Existing colliders do
not move; normal factory bootstraps keep their native prompt path.
