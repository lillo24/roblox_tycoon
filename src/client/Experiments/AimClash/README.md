# Aim clash presentation

`View.luau` owns whole-viewport normalized aim coordinates, centered responsive
circle/targets, two faint future hints and trail, perimeter-only performance heat,
controls and final score/precision breakdown. `Controller.luau` owns mouse/touch
begin input, focus/menu/text-input gates, shared server time, immediate provisional
hit feedback, private server corrections, replay/queue and connection cleanup.
It honors system/session/local reduced motion. Player list is temporarily hidden
and restored on teardown. No keyboard-letter targets or rhythm/audio dependency;
controller cursor aiming requires separate platform assessment.

The ScreenGui keeps whole-screen input coordinates. Layout subtracts the
`GetInsetArea(None)` origin from the `CoreUISafeInsets` rectangle, placing controls
below Roblox's top bar and reserving notch/home-indicator margins. It refreshes
on viewport and top-bar changes. This avoids fixed desktop padding on portrait
phones; the arena and target radius scale within the same usable area.
