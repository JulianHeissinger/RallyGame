# Agent notes

Project facts and working agreements for coding agents. The spec lives in `openspec/`, design notes in `docs/`.

## Workflow

- Apply OpenSpec tasks one at a time: show a short plan for the next task, wait for approval, implement, run tests, tick the checkbox in `tasks.md`, then commit on branch `dev`. Do not chain into the next task without a new plan and approval.
- Before planning a task, check `docs/roadmap.md` for tasks moved to a later point (3.8 waits for a real track) and work added to later tasks (8.6 cuts the engine on immobilize).
- If a verification step in `tasks.md` cannot work as written, pause, offer options, and update the task text once the user picks one.
- Folders created empty in task 1.1 hold a `.gitkeep`. When adding the first real file to such a folder, delete its `.gitkeep` in the same change.
- Commit the `.uid` files Godot creates next to scripts.
- Keep project knowledge in the repo (this file, `docs/`, `openspec/`), not in agent memory.

## Godot 4.7 headless

- Project check: `godot --headless --path . --import`. `--quit` hangs with "no main scene defined" until a main scene exists (task 8.2).
- Tests: `godot --headless --path . -s tests/run_tests.gd`. After adding a new `class_name` script, run `--import` once first, or the global class cache does not know the class.
- Editing the InputMap: generate it with a one-off script (outside the repo) that uses `ProjectSettings.set_setting` and `ProjectSettings.save()`, not by hand. Set key events to `device = -1` (the default is 16) to match editor output. `save()` drops settings equal to their defaults (e.g. `renderer/rendering_method="forward_plus"`); that is expected.
- New scripts and test files get their `.uid` only on the next `--import`; run it again before committing.
- Write `.tres` files that contain sub-resources (e.g. the torque `Curve` in `data/cars/prototype.tres`) with a one-off `ResourceSaver` script outside the repo, not by hand.
- Physics checks: the test runner calls test methods synchronously and cannot await physics frames. Verify handling with a one-off headless script outside the repo that instantiates `scenes/test/handling_test.tscn`, awaits `physics_frame`, and prints measurements.
- Run such scripts with `godot --headless --fixed-fps 120 --path . -s <script>`: each frame then advances exactly one 120 Hz physics tick and runs as fast as possible (~25x real time) instead of in real time.
- In such scripts, drive the car with `Input.action_press(action, strength)` (the car's `InputSource` reads the `Input` singleton). Give a start speed by setting `linear_velocity` and each wheel's `spin` (speed / `wheel_radius`). Tune stats in memory by editing the loaded `prototype.tres` resource's `stats` before instantiating the scene; nothing is saved.
- Test scene layout: a ramp sits at x=30 (60 m long, 10°, buried at its -z end and rising toward +z to a 10 m drop at z≈30; for a jump start at x=30 z=-40 heading +z at 25 m/s with throttle), a tree (group `solid`, r=0.4) at x=80 z=0, a grass strip (`surface = "grass"`) covers x=-40..-20 over the full length, the rest is gravel, and the ground ends at ±1000. Move the car to x=-60 for turning runs and turn left there: a right turn reaches the grass strip at x=-40 after about 2 s and spoils steady-state numbers. Start long full-throttle runs at z=900 (the car drives toward -z).
- Stage scene: `scenes/stage.tscn` builds the road from `stage_seed` (0 = random, printed on start with its surface sections; R reloads the scene and rolls a new seed; F2 steps the difficulty 1-2-3 and reloads, keeping it across reloads) and spawns the car 5 m along the road. Heightmap terrain (`TerrainBuilder`) meets the road's bevelled edge at road height − `road_sink`; falling below it hits a kill plane that puts the car back on the road and emits `car_respawned(penalty)`. One-off scripts read the built road from the stage's `path` (`RoadPath`) and can move the car with `Car.place(transform)`. The road is split into surface sections (`RoadPath.section_starts`/`section_defs`, one `Road/Section<i>` body each); the terrain is a `TerrainBody` that answers `surface_at(point)` from the nearest section, so off-road surface is not collider metadata there. The finish line sits at the stage's `finish_distance` (20 m before the road end); crossing it emits `car_finished` once. The car does not steer by itself, so finish runs in such scripts start a few metres before the line.
- To test one hazard on the stage, free the children of the stage's `Hazards` node, then spawn the hazard: `def.scene.instantiate()`, set its `transform` from `path.transform_at(distance)`, call `setup(def, car, path, RandomNumberGenerator.new())` before adding it under `Hazards`. Place the car 1 m above the road (`Car.place`, as the stage does): at 0.6 m the suspension launches it and it takes damage while standing. Let it settle about 120 ticks and reset `damage.condition` before measuring. Start runs 10 m or less before the hazard; the car does not steer and drifts off line on curves.
- One-off scripts that load or edit hazard scenes must `load("res://scenes/stage.tscn")` first: `StageParams` preloads the hazard defs, whose scenes use scripts that reference `StageParams` again, and loading a hazard scene first breaks that cycle (scripts go missing from saved scenes).
- Autoloads (e.g. `Settings`) are not registered yet when a `-s` script compiles. A one-off script that touches the car must not use the `Car` type statically; `await process_frame` in `_init` before loading the scene.
- A `-s` script that hits a script error never calls `quit()` and hangs at full CPU. Start each one-off script with a watchdog: `create_timer(90.0).timeout.connect(func(): print("WATCHDOG timeout"); quit(1))`. Hazard `class_name` types (`Person`, `Sheep`, ...) depend on `Car` too, so check with `has_method` instead of `is`.
- For runs longer than about 10 m, steer the car along the road each tick, or it leaves the road on curves and spoils distances: aim at `path.curve.sample_baked(path.progress_at(car.global_position) + 10.0)` in car space and press `steer_right`/`steer_left` with strength `clampf(aim.x / 3.0, -1.0, 1.0)`.

## Handling tuning

- Target feel: a mix of art of rally and DiRT, always in a light drift that stays controllable. Plain realistic grip felt floaty and not fun from the iso camera. If the feel is off, try in this order: more direct keyboard steering, the steering yaw assist (`yaw_assist_*` stats), more grip. Values and history are in `docs/roadmap.md` under "Handling tuning on a real track".
- Workflow: measure the current car first with a one-off headless script (step steer, steering tap, lift-off, 100-0 braking), show a small table of variants with one recommendation, apply only after approval (stats via a `ResourceSaver` script), and let the user drive `scenes/stage.tscn`. Commit after the user says it feels right. If two rounds do not fix a complaint, stop and ask what the car should feel like instead of tweaking further.
- Surface grip factors (`Surface.GRIP`) are a const and cannot be changed in memory. To measure a surface variant, scale the loaded `prototype.tres` `tire_friction` by the surface factor and run on the gravel test scene (gravel is 1.0).
- In zsh, a variable holding several script arguments needs `${=var}` to split into words.

## Watch-outs

- `IsoCameraRig` estimates target velocity from position change per frame. If the camera jitters once the 120 Hz car exists (task 3.2), use the car's `linear_velocity` instead.
- Godot's project default body damping (0.1) acts as fake drag and slows rotation. `car.tscn` overrides it with `linear_damp_mode`/`angular_damp_mode` = Replace and damping 0; keep it that way for any new car body.
- Collision layer 2 holds animals (sheep, and the 6.8 animals) and movable obstacles (`Knockable` props, the crashed car). Wheel rays scan only layer 1, so the car cannot stand on them; their mask (3) still hits the ground, each other and the car body.
- Bodies can tune the impact damage they deal to the car with metadata: `impact_scale` (multiplier, default 1) and `impact_once` (only the first impact counts). `solid` group membership makes a hit at `lethal_impact_speed` lethal.
- `Car` resets a rollover onto the nearest road point when its `road` is set (the stage sets it), otherwise in place (lifted 1 m, upright, same heading). Rollover and kill-plane respawn emit penalties that nothing adds to a timer until task 8.3.
- `project.godot` has an uncommitted `run/main_scene="res://scenes/stage.tscn"` set by the user for test driving. Leave it uncommitted; task 8.2 sets the real main scene.
