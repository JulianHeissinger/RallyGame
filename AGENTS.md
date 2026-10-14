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

## Watch-outs

- `IsoCameraRig` estimates target velocity from position change per frame. If the camera jitters once the 120 Hz car exists (task 3.2), use the car's `linear_velocity` instead.
