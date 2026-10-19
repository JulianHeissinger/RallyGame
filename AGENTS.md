# Agent notes

Project facts and working agreements for coding agents. The spec lives in `openspec/`, design notes in `docs/`.

## Workflow

- Apply OpenSpec tasks one at a time: show a short plan for the next task, wait for approval, implement, run tests, tick the checkbox in `tasks.md`, then commit on branch `dev`. Do not chain into the next task without a new plan and approval.
- If a verification step in `tasks.md` cannot work as written, pause, offer options, and update the task text once the user picks one.
- Folders created empty in task 1.1 hold a `.gitkeep`. When adding the first real file to such a folder, delete its `.gitkeep` in the same change.
- Commit the `.uid` files Godot creates next to scripts.

## Godot 4.7 headless

- Project check: `godot --headless --path . --import`. `--quit` hangs with "no main scene defined" until a main scene exists (task 8.2).
- Tests: `godot --headless --path . -s tests/run_tests.gd`. After adding a new `class_name` script, run `--import` once first, or the global class cache does not know the class.
- Editing the InputMap: generate it with a one-off script (outside the repo) that uses `ProjectSettings.set_setting` and `ProjectSettings.save()`, not by hand. Set key events to `device = -1` (the default is 16) to match editor output. `save()` drops settings equal to their defaults (e.g. `renderer/rendering_method="forward_plus"`); that is expected.
- New scripts and test files get their `.uid` only on the next `--import`; run it again before committing.
- Write `.tres` files that contain sub-resources (e.g. the torque `Curve` in `data/cars/prototype.tres`) with a one-off `ResourceSaver` script outside the repo, not by hand.
- Physics checks: the test runner calls test methods synchronously and cannot await physics frames. Verify handling with a one-off headless script outside the repo that instantiates `scenes/test/handling_test.tscn`, awaits `physics_frame`, and prints measurements.
- Run such scripts with `godot --headless --fixed-fps 120 --path . -s <script>`: each frame then advances exactly one 120 Hz physics tick and runs as fast as possible (~25x real time) instead of in real time.
- In such scripts, drive the car with `Input.action_press(action, strength)` (the car's `InputSource` reads the `Input` singleton). Give a start speed by setting `linear_velocity` and each wheel's `spin` (speed / `wheel_radius`). Tune stats in memory by editing the loaded `prototype.tres` resource's `stats` before instantiating the scene; nothing is saved.
- Test scene layout: a ramp sits at x=30, a tree (group `solid`, r=0.4) at x=80 z=0, a grass strip (`surface = "grass"`) covers x=-40..-20 over the full length, the rest is gravel, and the ground ends at ±1000. Move the car to x=-60 for turning runs and start long full-throttle runs at z=900 (the car drives toward -z).
- Autoloads (e.g. `Settings`) are not registered yet when a `-s` script compiles. A one-off script that touches the car must not use the `Car` type statically; `await process_frame` in `_init` before loading the scene.

## Watch-outs

- `IsoCameraRig` estimates target velocity from position change per frame. If the camera jitters once the 120 Hz car exists (task 3.2), use the car's `linear_velocity` instead.
- Godot's project default body damping (0.1) acts as fake drag and slows rotation. `car.tscn` overrides it with `linear_damp_mode`/`angular_damp_mode` = Replace and damping 0; keep it that way for any new car body.
- `project.godot` has an uncommitted `run/main_scene="res://scenes/test/handling_test.tscn"` set by the user for test driving. Leave it uncommitted; task 8.2 sets the real main scene.
