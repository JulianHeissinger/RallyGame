# Tasks

## 1. Project setup

- [ ] 1.1 Create `project.godot` (Godot 4.7, Forward+, Jolt physics, 120 Hz physics tick), folder layout from design.md, and `.gitignore` for `.godot/`; verify `godot --headless --path . --quit` exits 0 with no errors
- [ ] 1.2 Add headless test runner `tests/run_tests.gd` that discovers `tests/test_*.gd`, runs them, and exits non-zero on failure; verify with one passing and one deliberately failing sample test, then remove the failing one
- [ ] 1.3 Define InputMap actions (steer, throttle, brake, handbrake, activate_item, pause, ui) with keyboard and joypad bindings; verify all actions appear in `project.godot`

## 2. Input and camera

- [ ] 2.1 Implement `InputSource` (single-player source: keyboard + device 0, analog with deadzone, speed-dependent keyboard steering ramp); verify with `tests/test_input_source.gd` for ramp-up, return to center and slower ramp at speed
- [ ] 2.2 Implement `IsoCameraRig` (fixed pitch/yaw, narrow FOV, damped follow, speed look-ahead, settable target); verify in a test scene that the camera does not rotate when a moving target turns

## 3. Car handling

- [ ] 3.1 Create `CarStats` resource and `data/cars/prototype.tres`, plus `StatBlock` (base, additive, multiplicative, damage multipliers); verify with `tests/test_stat_block.gd` for stacking order and recompute on change
- [ ] 3.2 Build `car.tscn` with placeholder box body, four raycast wheels, per-wheel spring/damper suspension; verify in a flat test scene that the car settles at rest on flat and sloped ground without endless bouncing
- [ ] 3.3 Implement per-wheel spin integration and slip-based tire forces (slip angle, slip ratio, load, friction ellipse, low-speed blending); verify gentle turns grip and fast full-lock turns slide in the test scene
- [ ] 3.4 Implement AWD drivetrain with torque curve, automatic gearbox, brakes, reverse at standstill, and handbrake rear lock; verify full-throttle run shifts up and caps at top speed, brake at standstill reverses, handbrake rotates the car
- [ ] 3.5 Implement surface grip lookup from collider `surface` metadata; verify wheels on a `grass` collider produce less grip than on `gravel` via the debug overlay
- [ ] 3.6 Add F1 debug overlay (per-wheel load, slip angle, slip ratio, surface, gear, RPM, speed); verify it toggles in the test scene
- [ ] 3.7 Handling tuning pass in the test scene with controller and keyboard: lift-off rotation, Scandinavian flick and handbrake hairpin all work without yaw assist; record final values in `prototype.tres`

## 4. Car damage

- [ ] 4.1 Implement `CarDamage` with parts, conditions, accelerating degradation once damaged, and signals `part_damaged`, `part_broken`, `immobilized`; verify with `tests/test_car_damage.gd` (intact part stays 100, damaged part reaches 0, signals fire)
- [ ] 4.2 Connect part conditions to handling via `StatBlock` damage multipliers (tire grip and pull, per-wheel brake loss, engine power, suspension sag/stiffness); verify a broken front-left tire makes the car drift left and a broken brake gives no force on that wheel
- [ ] 4.3 Implement impact detection (contact normal speed, local zone, zone-to-parts damage) and lethal impact against `solid` bodies using the `lethal_impact_speed` stat; verify in the test scene: low-speed bump does little, fast tree hit immobilizes, raised stat survives the same hit
- [ ] 4.4 Implement immobilization rules (chassis 0, engine 0, 3+ broken tires) and rollover recovery (2 s upside down, reset upright with penalty signal); verify rules in `tests/test_car_damage.gd` and rollover by flipping the car in the test scene

## 5. Stage generation

- [ ] 5.1 Implement seeded sub-stream helper and 2D road layout (segment table, clearance check, retries, derived-seed regeneration, target length); verify with `tests/test_road_layout.gd` (same seed identical, different seeds differ, no self-intersection, hairpin present, length within tolerance)
- [ ] 5.2 Add elevation with clamped gradient and crest features, `Curve3D` sampling with cumulative distance and progress query; verify crest present and progress at midpoint ≈ half length in `tests/test_road_layout.gd`
- [ ] 5.3 Build road ribbon mesh and collider with `surface` metadata; verify the car drives the full road from start to finish in `stage.tscn`
- [ ] 5.4 Build heightmap terrain blended to the road with `HeightMapShape3D` collider, bounds walls and kill plane respawn with penalty; verify driving off-road works without seams or falling through, and falling out respawns on the road
- [ ] 5.5 Scatter props (trees, rocks, fences) with road clearance and corner-outside density, `MultiMeshInstance3D` visuals and `solid` colliders; verify with a test that no prop overlaps the road and that props are identical for the same seed
- [ ] 5.6 Add start and finish lines with finish detection signal; verify crossing the finish emits the signal once

## 6. Hazards

- [ ] 6.1 Create `HazardDef` resource and seeded placement with difficulty gating and per-km scaling; verify with `tests/test_hazards.gd` (locked hazard never placed below min difficulty, more hazards at higher difficulty, same seed same placement)
- [ ] 6.2 Implement rock and pothole hazards with their damage profiles; verify in stage that a pothole at speed damages that wheel's tire and suspension
- [ ] 6.3 Implement sheep flock (trigger area, crossing sheep, front-zone damage, `hazard_defeated` when knocked off road); verify in stage that sheep cross on approach and knocking one away emits the event
- [ ] 6.4 Implement distance-scheduled malfunctions from the events sub-stream with HUD notification; verify in `tests/test_hazards.gd` that the same seed yields the same malfunction distances and parts

## 7. Items

- [ ] 7.1 Create `ItemDef`, `StatModifier`, `ItemEffect` base, and `ItemManager` (passive stacks, 4 mount slots with replace, cooldowns, condition evaluation, event fan-out); verify with `tests/test_items.gd` (stacking, mount replace, cooldown blocks activation, condition toggles on break/repair)
- [ ] 7.2 Add prototype passive items as `.tres` (grip, power, lethal impact speed) and Drift King with broken-brake condition; verify stat changes in tests and boost fill doubling with a broken brake
- [ ] 7.3 Add active items: nitro (button), flame exhaust (gear shift trigger), bullbar (collision trigger, reduced front damage, knock-away); verify in stage that nitro respects cooldown, exhaust fires on shifts, bullbar knocks a sheep away with less front damage
- [ ] 7.4 Add cursed Gearbox of Chaos (power bonus, random gear on shift); verify it is marked cursed in offers and shifts land in random gears
- [ ] 7.5 Implement upgrade meter (progress delta plus hazard-defeated bonus), slow motion pick UI with 3 seeded offers, real-time timeout picking the first offer, controller and keyboard selection; verify in stage that slow motion starts and ends correctly and timeout applies the first item

## 8. Game flow and UI

- [ ] 8.1 Implement `RunState` autoload (seed, difficulty, prize money, owned items, reset); verify with a test that reset clears items and money
- [ ] 8.2 Build main menu (Start Stage, seed field, Quit) with controller and keyboard navigation, set as main scene; verify empty seed starts a random stage and seed 42 reproduces the same stage
- [ ] 8.3 Implement stage lifecycle: generation before control, countdown with car frozen, timer, penalties added from rollover and respawn; verify timer starts at 0 after countdown and a penalty increases it
- [ ] 8.4 Build minimal HUD (timer, speed, gear, part conditions, mounted items with cooldowns, upgrade meter); verify a broken tire shows as broken
- [ ] 8.5 Implement prize money formula and finish screen (time, penalties, money, retry same seed, new seed, main menu); verify with a test that a faster time awards more money and in-game that retry regenerates the same seed
- [ ] 8.6 Implement game-over screen with immobilization cause (retry, main menu) and pause menu (resume, restart, quit); verify timer does not advance while paused and a lethal crash shows its cause

## 9. Integration

- [ ] 9.1 Run `godot --headless --path . -s tests/run_tests.gd` and confirm all tests pass
- [ ] 9.2 Full playtest on controller and keyboard: menu, seeded stage, hazards, item picks, finish screen, crash to game over; note feel issues as follow-up items in `docs/syspec/open-questions.md` or a new change

## Workflow follow-up

- Review handling feel with the user before archiving.
- Archive the change with `/opsx:archive` after review.
