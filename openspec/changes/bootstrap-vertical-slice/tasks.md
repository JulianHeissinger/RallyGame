# Tasks

## 1. Project setup

- [x] 1.1 Create `project.godot` (Godot 4.7, Forward+, Jolt physics, 120 Hz physics tick), folder layout from design.md, and `.gitignore` for `.godot/`; verify `godot --headless --path . --import` exits 0 with no errors (`--quit` needs a main scene, which arrives in 8.2)
- [x] 1.2 Add headless test runner `tests/run_tests.gd` that discovers `tests/test_*.gd`, runs them, and exits non-zero on failure; verify with one passing and one deliberately failing sample test, then remove the failing one
- [x] 1.3 Define InputMap actions (steer, throttle, brake, handbrake, activate_item, pause, ui) with keyboard and joypad bindings; verify all actions appear in `project.godot`

## 2. Input and camera

- [x] 2.1 Implement `InputSource` (single-player source: keyboard + device 0, analog with deadzone, speed-dependent keyboard steering ramp); verify with `tests/test_input_source.gd` for ramp-up, return to center and slower ramp at speed
- [x] 2.2 Implement `IsoCameraRig` (fixed pitch/yaw, narrow FOV, damped follow, speed look-ahead, settable target); verify with `tests/test_iso_camera_rig.gd` that the camera does not rotate when a moving target turns and that the focus leads along velocity
- [x] 2.3 Add `shift_up` (Left Shift, RB) and `shift_down` (Left Ctrl, LB) InputMap actions and expose them as just-pressed flags in `InputSource`; verify both actions appear in `project.godot` and all tests pass

## 3. Car handling

- [x] 3.1 Create `CarStats` resource and `data/cars/prototype.tres`, plus `StatBlock` (base, additive, multiplicative, damage multipliers); verify with `tests/test_stat_block.gd` for stacking order and recompute on change
- [x] 3.2 Build `car.tscn` with placeholder box body, four raycast wheels, per-wheel spring/damper suspension; verify in a flat test scene that the car settles at rest on flat ground without endless bouncing, and on sloped ground the bounce dies out with all four wheels grounded (sliding allowed until tire grip in 3.3)
- [x] 3.3 Implement per-wheel spin integration and slip-based tire forces (slip angle, slip ratio, load, friction ellipse, low-speed blending); verify gentle turns grip and fast full-lock turns slide in the test scene, and the car parked across the test scene's slope holds still
- [x] 3.4 Implement engine and drivetrain: AWD torque split, torque curve, RPM from driven-wheel spin, automatic clutch at launch, engine braking, rev limiter with bounce, brakes, handbrake rear lock; verify in the test scene that wheelspin raises RPM, lift-off slows faster than neutral, holding a gear bounces off the limiter, handbrake rotates the car, and the car facing downhill on the slope holds still with the handbrake
- [x] 3.5 Implement gearbox (R, N, 1..n ratios, shift time with torque cut, `gear_shifted` signal) with automatic mode (RPM shift points, reverse by brake at standstill) and manual mode (shift up/down, N then R only at standstill, over-rev downshift refused), plus a `Settings` autoload for the mode (`user://settings.cfg`); verify with `tests/test_gearbox.gd` for both modes and in the test scene that a full-throttle automatic run shifts up and caps at top speed
- [x] 3.6 Implement surface grip lookup from collider `surface` metadata; verify wheels on a `grass` collider produce less grip than on `gravel` via the debug overlay
- [x] 3.7 Add basic HUD `scenes/ui/hud.tscn` (RPM, speed in km/h, gear R/N/1..n) with a settable `car` target, F1 debug overlay (per-wheel load, slip angle, slip ratio, surface), placeholder colors (car body, ground, ramp) and wheel meshes that follow suspension travel and spin; verify in the test scene that the HUD updates while driving, F1 toggles the overlay, and wheels visibly compress and spin
- [x] 3.8a Handling structural fixes found while preparing 3.8: lower centre of mass (`center_of_mass_y`), combined-slip tire model, speed-dependent max steer angle, brake torque that does not lock all wheels, rearward torque split against launch wheelspin, countersteer lock that follows body slip angle, shortened gearing (3rd gear from ~80 km/h); verify each step with a headless measurement script (launch, braking, steady turns at 40/70 km/h, handbrake turn)
- [ ] 3.8 Handling tuning pass in the test scene with controller and keyboard: lift-off rotation, Scandinavian flick and handbrake hairpin all work with only the steering yaw assist (off without steering input), and manual shifting feels responsive; also address the slow handbrake-hold settle on the slope (~1 s halving) and 1st-gear wheelspin to redline at full grip; record final values in `prototype.tres`

## 4. Car damage

- [x] 4.1 Implement `CarDamage` with parts, conditions, accelerating degradation once damaged, and signals `part_damaged`, `part_broken`, `immobilized`; verify with `tests/test_car_damage.gd` (intact part stays 100, damaged part reaches 0, signals fire)
- [x] 4.2 Connect part conditions to handling: engine power via `StatBlock` damage multipliers, and per-wheel factors on `Wheel` for tire grip and pull, brake loss, and suspension sag/stiffness (suspension split into four corner parts); verify a broken front-left tire makes the car drift left and a broken brake gives no force on that wheel
- [x] 4.3 Implement impact detection (contact normal speed, local zone, zone-to-parts damage) and lethal impact against `solid` bodies using the `lethal_impact_speed` stat; verify in the test scene: low-speed bump does little, fast tree hit immobilizes, raised stat survives the same hit
- [x] 4.4 Implement immobilization rules (chassis 0, engine 0, 3+ broken tires) and rollover recovery (2 s upside down, reset upright with penalty signal); verify rules in `tests/test_car_damage.gd` and rollover by flipping the car in the test scene

## 5. Stage generation

- [x] 5.1 Implement seeded sub-stream helper and 2D road layout (segment table, clearance check, retries, derived-seed regeneration, target length, per-sample road width with rare narrow pinches, tuning in `StageParams`); verify with `tests/test_road_layout.gd` (same seed identical, different seeds differ, no self-intersection, hairpin present, length within tolerance)
- [x] 5.2 Add elevation with clamped gradient and crest features, `Curve3D` sampling with cumulative distance and progress query; verify crest present and progress at midpoint ≈ half length in `tests/test_road_layout.gd`
- [x] 5.3 Build road ribbon mesh and collider with `surface` metadata; verify the car drives the full road from start to finish in `stage.tscn`
- [x] 5.4 Build heightmap terrain blended to the road with `HeightMapShape3D` collider, bounds walls and kill plane respawn with penalty; verify driving off-road works without seams or falling through, and falling out respawns on the road
- [x] 5.5 Scatter props (trees, rocks, fences) with road clearance and corner-outside density, `MultiMeshInstance3D` visuals and `solid` colliders; verify with a test that no prop overlaps the road and that props are identical for the same seed
- [x] 5.6 Add start and finish lines with finish detection signal; verify crossing the finish emits the signal once
- [x] 5.7 Add road surface sections: `StageParams` surface table (road surface, matching terrain surface, weight, section length range), sections drawn from a `"surfaces"` sub-stream, road mesh and collider split per section with `surface` metadata, terrain surface following the nearest road section; verify with `tests/test_road_layout.gd` that the same seed gives the same sections, and in `stage.tscn` that wheels report the section's surface on the road and beside it
- [x] 5.8 Make `IsoCameraRig` yaw follow the road direction ahead when given a `RoadPath` (smoothed, ignores the car's own yaw), flatten the pitch and widen the look-ahead; verify with `tests/test_iso_camera_rig.gd` that the camera keeps its rotation while the target spins, turns with the road through a corner, and stays fixed without a road

## 6. Hazards

- [x] 6.1 Create `HazardDef` resource and seeded placement with difficulty gating and per-km scaling; verify with `tests/test_hazards.gd` (locked hazard never placed below min difficulty, more hazards at higher difficulty, same seed same placement)
- [x] 6.2 Implement rock and pothole hazards with their damage profiles; verify in stage that a pothole at speed damages that wheel's tire and suspension
- [x] 6.3 Implement sheep flock (trigger area, crossing sheep, front-zone damage, `hazard_defeated` when knocked off road); verify in stage that sheep cross on approach and knocking one away emits the event
- [x] 6.4 Implement distance-scheduled malfunctions from the events sub-stream with HUD notification; verify in `tests/test_hazards.gd` that the same seed yields the same malfunction distances and parts
- [x] 6.5 Add a dev key (F2) that cycles stage difficulty 1-2-3 and rerolls the stage like R, keeping the difficulty across reloads; then add wheel-contact and surface-patch hazards: nails/spike strip, broken glass, log across the road, cattle grid and washboard section (on the 6.2 `WheelHazard`), plus a per-wheel grip/drag override for oil slick, puddle, mud patch, black ice patch, banana peel (grip loss plus yaw kick), water crossing (drag, engine damage above a speed), marbles on corner outsides and fresh tar (more grip, heavy drag), and surface-gated placement (a `HazardDef` lists the section surfaces it needs) for a snow drift on snow sections; verify that F2 changes the hazard count, each patch changes that wheel's grip or drag in the debug overlay while on it, nails damage every tire that crosses, a fast ford damages the engine, and snow drifts appear only on snow sections
- [ ] 6.6 Add obstacle and launch hazards: fallen tree (`solid`), crashed car (heavy pushable body), hay bales, traffic cones, wheelie bins and shopping trolleys, portable toilet (all light, `hazard_defeated` when knocked away), explosive barrel (blast impulse plus zone damage) and ramp; verify in stage that the fallen tree is lethal at speed, the crashed car can be pushed, a cone emits `hazard_defeated`, a barrel blast pushes and damages the car, and the ramp launches it
- [ ] 6.7 Add area and triggered hazards: fire patch (damage per second to tires and engine), burning crashed car, spectator on the road (dives clear on approach, never hit), crowd surge (fans step onto a corner and part at the last second), streaker (runs along the road ahead, then dives off), mascot chasing beside the road, meteorite and lightning strike (growing marker, then a strike with blast damage; the meteorite leaves a crater acting as pothole plus fire), rockfall, falling tree, rolling cheese wheel and runaway wheel, landmine (impulse plus damage), sinkhole (opens on approach, falling in respawns with penalty) and tumbleweed; verify in stage that each triggers on approach from the same seed, spectators and fans always clear, and a meteorite hit damages a car inside its blast radius
- [ ] 6.8 Add animal hazards as sheep-flock variants: cows (more front damage), chicken flock (tiny, scatter), moose (single, heavy, `solid`, stops on the road), kangaroo (hops across in big jumps) and marching band (column crossing slowly); verify in stage that each crosses on approach and knocked-away animals or musicians emit `hazard_defeated`
- [ ] 6.9 Add force-area, visibility and screen-flash hazards: wind gust zone, steam geyser (timed launch), dust devil (moving, lifts and spins the car) and TV helicopter downwash as force areas; fog bank as a visibility volume; paparazzi flashbang and fan fireworks as a white screen flash that fades (fireworks also give small spark damage); verify in stage that each force area pushes the car, the fog bank cuts visibility, and the flash fades out within 2 s
- [ ] 6.10 Add road-follower hazards: a kinematic body that drives along the `RoadPath` at a set speed and lateral offset, used for a rally car ahead (about 75% of the player's pace, dust trail that cuts visibility, `hazard_defeated` when overtaken), slow tractor, swaying caravan and wrong-way tourist (oncoming); verify in stage that overtaking the rally car emits `hazard_defeated` once, contact damages the car, and the tourist drives against the road direction

## 7. Items

- [ ] 7.1 Create `ItemDef`, `StatModifier`, `ItemEffect` base, and `ItemManager` (passive stacks, 4 mount slots with replace, cooldowns, condition evaluation, event fan-out); verify with `tests/test_items.gd` (stacking, mount replace, cooldown blocks activation, condition toggles on break/repair)
- [ ] 7.2 Add prototype passive items as `.tres` (grip, power, lethal impact speed) and Drift King with broken-brake condition; verify stat changes in tests and boost fill doubling with a broken brake
- [ ] 7.3 Add active items: nitro (button), flame exhaust (gear shift trigger), bullbar (collision trigger, reduced front damage, knock-away); verify in stage that nitro respects cooldown, exhaust fires on shifts, bullbar knocks a sheep away with less front damage
- [ ] 7.4 Add cursed Gearbox of Chaos (power bonus, random gear on shift); verify it is marked cursed in offers and shifts land in random gears
- [ ] 7.5 Implement upgrade meter (progress delta plus hazard-defeated bonus), slow motion pick UI with 3 seeded offers, real-time timeout picking the first offer, controller and keyboard selection; verify in stage that slow motion starts and ends correctly and timeout applies the first item

## 8. Game flow and UI

- [ ] 8.1 Implement `RunState` autoload (seed, difficulty, prize money, owned items, reset); verify with a test that reset clears items and money
- [ ] 8.2 Build main menu (Start Stage, seed field, gearbox setting, Quit) with controller and keyboard navigation, set as main scene; verify empty seed starts a random stage, seed 42 reproduces the same stage, and the gearbox setting persists after restart
- [ ] 8.3 Implement stage lifecycle: generation before control, countdown with car frozen, timer, penalties added from rollover and respawn; verify timer starts at 0 after countdown and a penalty increases it
- [ ] 8.4 Build minimal HUD (timer, speed, gear, RPM with shift light, part conditions, mounted items with cooldowns, upgrade meter); verify a broken tire shows as broken
- [ ] 8.5 Implement prize money formula and finish screen (time, penalties, money, retry same seed, new seed, main menu); verify with a test that a faster time awards more money and in-game that retry regenerates the same seed
- [ ] 8.6 Implement game-over screen with immobilization cause (retry, main menu) and pause menu (resume, restart, quit); verify timer does not advance while paused and a lethal crash shows its cause

## 9. Integration

- [ ] 9.1 Run `godot --headless --path . -s tests/run_tests.gd` and confirm all tests pass
- [ ] 9.2 Full playtest on controller and keyboard: menu, seeded stage, hazards, item picks, finish screen, crash to game over; note feel issues as follow-up items in `docs/syspec/open-questions.md` or a new change

## Workflow follow-up

- Review handling feel with the user before archiving.
- Archive the change with `/opsx:archive` after review.
