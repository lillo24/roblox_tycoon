# MAP-01 review checkpoint

Six equal inward-facing factories share a walkable central plaza. This checkpoint
requires visual founder review before merge. The economy, four catalogue entries,
Supply Cache schedule/reward and FIX-01 ordering behavior remain unchanged.

## Dimensions and ownership

| Element | Final dimensions |
| --- | --- |
| Lots | Six, 60×70 studs, 60° spacing |
| Lot-center ring | Radius 110 studs |
| Plaza | Diameter 70 studs |
| Spokes / circulation | 12 studs wide; circulation center radius 61 |
| Ground / visible border | Diameter 340 / rail radius 168 |
| Entrance / center | 75 studs |
| Minimum usable lot gap | 23.0385 studs between actual oriented foundations |
| Normal entrance-to-center approach | 5.34, 5.20, 5.17, 5.28, 5.08, 5.16 seconds (lots 1–6) |

Walking times use equivalent entrances to a 4-stud radial cache approach at the
normal 16-stud/sec speed, with the navigation controller's approximately one-stud
arrival tolerance. Final-source Heartbeat sampling observed gradual movement
(maximum sampled step 0.336 studs, horizontal speed 16.07 studs/sec; measured
travel 71.35–75.72 studs). Times include the navigation tool's arrival handling.
No teleport substituted for traversal. Curbs/markings stay
within lot footprints; planters/lamps are outside the lots and circulation.
Symmetry and these observations do not establish network or gameplay fairness.

The saved scene owns foundations, ground, plaza, paths, border, landscaping,
numbers, oriented anchors/pivots and one neutral spawn 15 studs from the cache.
Runtime owns signs, initial/purchased equipment, pads, cache and HUD. The current
map has 695 descendants (698 in Workspace in Edit); six owners with one purchased
booster each produced 264 runtime descendants. These counts are observations,
not a mobile performance benchmark.

## Scene replacement and recovery

Starting main: 29ee28cfad8f8d3abaf905962723945257886f54.
Original SHA256:
E68D11363B1C2BF10EF37C12EA566F6E8839940F07579BDCE9DBE57FB38C4B49.
It remains recoverable at that commit's place/tycoon.rbxlx and in the verified
local build/original-tycoon.rbxlx backup in the task worktree.

Removed: old mountains/terrain, architecture/foliage/VFX/material scene folders,
ball/platform/targets, reset bounds, template remotes/modules and reset/target/
runtime-insertion scripts. No template physics or obsolete terrain remains under
the hub. Retained: service/place settings and sky; lighting effects were reduced
to avoid fog/depth blur hiding rival factories. No Toolbox assets/scripts added.

Current canonical SHA256:
9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8.
See README.md here for native Studio serialization provenance and map contract.
Current code is captured in the scene, but Git/Rojo remains its authority.

## Automated and observed evidence

- Complete Validate-Project.ps1: formatting, lint, build/sourcemap, type analysis,
  existing structure/type failure probes, saved-map contract and seven malformed
  scene probes. Optional authoring CheckSnapshotCode verifies all mapped copies.
- Actual modules in Studio: Session 186, SupplyEvent 196, SupplyFeedback 65 and
  MapLayout 522 assertions, including six owners/seventh refusal and saved layout
  support, facing, footprint intersection, obstacle, reset and rotated equipment.
- Solo: all six entrance/production-zone walks, connected neighboring-lot route,
  all four normal prompt purchases, rate 12 and no health loss.
- Final committed-source real six-client session: unique lots, live independent
  income, six normal booster purchases, six exact -10 deductions, own-lot
  replicated equipment.
- Focused two-client session: funded non-owner rejection; Workshop -30 once,
  replay rejected without neighbor effects; competing normal claims produced
  one exact +10, matching public winner and requester-only private feedback.
- Real respawn retained assignment/purchases and same HUD; real disconnect
  released only its lot; AddPlayers replacement reused it with fresh progression.
- iPhone 17 Pro emulation: final-source portrait native Touch purchase (-10) and
  cache claims (+10 once per observed window), with matching private/public
  feedback. Portrait viewport 401×778, safe HUD area 401×720, centered panel
  344.86×300 at (28.07,12). Landscape Touch claim also passed after moving the
  wide HUD away from the center prompt (320×279 at (12,12), safe area 748×303).
  No physical phone or mobile performance claim.
- Task-owned Studio stop leaves the 698-descendant Edit scene, no runtime/events
  or QA modules. Device preferences are restored to default, LandscapeRight,
  ScaleToPhysicalSize. Switching orientation during Play previously stalled MCP
  capture; setting the profile before a fresh Play avoided that issue.

The committed behavior-bearing tree is
7f4478b3635b53d9471b5dd52db15bc613677a9a, based on main 29ee28c above.
A separate clean detached clone under build/restore-checkout reopened its tracked
scene in Studio, with matching SHA256, all 695 hub descendants/698 Workspace
descendants and pivots present in Edit. All 14 script classes and normalized
sources matched that checkout and were applied from it. The four actual module
tests passed again (969 assertions). A fresh real six-client session on this
commit gave six unique owners with independent live income.

A first hidden-window repeat could inspect assignments/income but reported a
1×1 camera viewport and did not activate normal prompts. It was stopped and
recorded as unsuccessful. The user then explicitly authorized Computer Use for
this task. Codex used the installed Windows skill to open the same clean-checkout
scene in a normal visible Studio window; the remaining checks used Studio MCP.

The successful visible repeat verified all 14 current script copies, all six
normal booster purchases (six exact -10 deductions), own-lot replicated parts,
funded non-owner rejection, Workshop -30 once/replay rejection, and competing
cache requests yielding one exact +10 to Player1 (window 17). Both clients had
the same public winner; only Player1 had private claimed feedback. Real respawn
retained the exact HUD object, lot 1, both purchases and rate 5. Real Player2
disconnect cleared only lot 2; Player7 reused it with rate 1/no purchases while
the map and Player1's equipment remained intact. The stopped Edit scene was
698 descendants with no runtime or QA residue.

A fresh default-device solo restart confirmed one HUD and fresh progression,
then repeated all six entrance/production-zone walks, connected circulation
between lots 6 and 1, the measured routes above, and all four normal purchases
to rate 12 with full health (246 runtime descendants). Final phone portrait and
world captures were repeated on this same committed source. Evidence-only
documentation/image commits leave the scene and
runtime tree unchanged; the PR records final-head CI separately.

## Actual Studio captures

Final-source world shots temporarily hide the HUD. Factory-eye uses the normal
first-person Custom camera; close-up uses a temporary capture camera. The images are actual
Studio renders, with no generated concept art.

![Saved Edit overhead](map-01/overhead.png)

Overhead orientation: 01 bottom, 02 lower right, 03 upper right, 04 top,
05 upper left and 06 lower left. Numbers also exist on the authored floors.

![Factory toward center](map-01/factoryEye.png)
![Shared plaza](map-01/plaza.png)
![Purchased Workshop](map-01/machine.png)
![Phone portrait](map-01/portrait.png)
![Phone landscape](map-01/landscape.png)

## Preview and remaining decision

Task checkout:
C:/Users/leona/Documents/GitHub/roblox_tycoon-worktrees/map-01.
Open place/tycoon.rbxlx there in Studio. The complete base is visible in Edit;
Play runs the captured current code. For later code edits, serve that checkout's
default.project.json and connect its three code folders through Rojo.

Retain the draft task worktree, verified original backup and clean detached
restore checkout under build/restore-checkout for review. The task-owned Studio
window is retained in Edit on that clean checkout's identical committed scene.
No temporary generator/export file is required by either preview. Earlier
policy-blocked leftovers and unrelated Studio work were not modified by this task.

Review scale/spacing, whether the starter equipment plus unused expansion floor
feels like a factory, and whether neighbors/opposite growth remain visible while
walking. Report approve or the specific adjustment wanted. This is the required
founder decision before merge; it is not a compiler-panel test request.

The Studio viewport gate is resolved. The draft remains open only for the visual
founder decision above. No repeated compiler or gameplay QA is requested.

Production supports six owners. Local Players.MaxPlayers still reads 60 and is
read-only to scripts. Before publishing, configure the intended hosted place
maximum to six in supported place settings; no publishing/live access changes
were made, and no seventh-player kick was added.
