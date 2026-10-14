# Rally Roguelite – Open Design Questions

Mix of Risk of Rain 2, Vampire Survivors and Sega Rally / Dirt Rally.
Procedural tracks, random threats that break car parts, upgrades with silly synergies.

## 1. Perspective
Do you want 3D chase cam (Sega Rally feel, larger scope) or top-down / isometric (2D or 3D; VS readability, easier procedural tracks)?

**Answer:** Isometric 3D like art of rally. Chase cam possibly later as an optional, unbalanced bonus view. Keep the world fully 3D and the camera rig swappable so that stays cheap.

## 2. Engine / tech
Do you have a preference (Godot, Unity, Bevy, web/Three.js, other)? Is this mainly a learning project or aimed at release?

**Answer:** Godot 4 (latest stable). Models likely built with Blender Python scripts (headless export to .glb), procedural meshes in-engine for terrain/track, primitives for early prototyping. Language: GDScript with static typing (user knows C#; hot spots could move to C#/GDExtension later if needed).

## 3. Threat sources
Where do threats come from: environment (rocks, potholes, weather, wildlife), enemies (rival cars, drones, angry farmers), random malfunctions, or a mix? VS-style hordes require enemies.

**Answer:** A mix, weighted toward environment:
- Many environmental dangers (main source).
- Rival cars: some you ram off the track, some you have to escape from.
- Random malfunctions.
- Crazy / hilarious ones: exploding drones, meteorites, etc.
- Threats are tiered by escalation, not by silliness: harmless-silly ones (e.g. a flock of sheep) can happen anytime, dangerous ones (e.g. suicide drones) unlock later as difficulty rises.

## 4. Upgrade acquisition
How do upgrades arrive: mid-stage level-up picks (VS), chests bought with scrap (RoR2), service park between stages (Dirt Rally), or a mix?

**Answer:** No chests. Upgrades come from:
- Distance driven (XP-like progress mid-stage).
- End of each stage.
- Possibly defeating a threat (e.g. running a rival off the track).

Mid-stage picks: slow motion with a quick choice (tentative), no full pause.
End of stage: service park with repair time plus a shop.
- Shop currency: mainly prize money (stage result), plus some scrap collected along the route.
- Repairs: Dirt Rally style time budget (~30 service minutes). Each repair costs minutes; the player has to choose what to fix.

## 5. Fail state
Does the run end when the car is immobile, when a stage timer runs out, or both? Anything else (e.g. driver health)?

**Answer:** Run ends when the car becomes immobile. This should mostly result from a crash, not from slowly accumulated malfunctions. No stage timer fail.
- Speed pressure comes from prize money tied to stage time (no RoR2 difficulty clock for this purpose; see Q9).
- Rollover / car on its roof: spectators push it back onto its wheels, at the cost of a time penalty (reduces prize money).

## 6. Handling model
Arcade (forgiving, chaos-friendly) or semi-sim (Dirt-like weight, harder to read under chaos)?

**Answer:** Semi-sim. Goal: feel better than art of rally.
- Sliding should behave like a real car: throwing the car into a corner (Scandinavian flick, handbrake, weight transfer) should be about as fast or slow as in real life, not an exaggerated arcade drift.
- Implies a slip-based tire model with weight transfer, so real rally techniques emerge naturally.
- Input: controller and keyboard (both first-class). Keyboard needs steering smoothing / light assists. No wheel support planned.

## 7. Damage model
Car has no HP bar, only breakable parts (tires x4, brakes x4, engine, gearbox, steering, lights, heater, radiator, suspension, ...). Do you agree? Should broken parts be able to enable synergies (e.g. no brakes + "Drift King" = drift boost)?

**Answer:** Yes. No HP bar, only breakable parts. Broken parts can enable synergies (e.g. no brakes + "Drift King" = drift boost), so "repair or embrace it?" becomes a real choice in the service park.
- Damage is wear-based (gradual, e.g. 0-100%), but parts degrade fairly quickly to broken once damaged.
- Immobilization, two paths:
  - Chassis/body integrity: hitting a solid obstacle (e.g. a tree) above a lethal impact speed kills the car instantly. Upgrades (roll cage, reinforced chassis, etc.) raise that speed threshold.
  - A crash that destroys enough critical parts at once (wheels, engine, suspension).

## 8. Run structure and length
Point-to-point stages with checkpoints, or one endless track? How long should a full run take (e.g. 15, 30, 60 min)? Is there a final boss / final stage?

**Answer:** Stage-based, with two modes:
- Campaign: a sequence of countries (rally-championship style). Each country is a set of stages and ends with a boss; the last country is the final one with the final boss. Countries double as biomes (surface, weather, threats).
- Endless mode: loops through countries with rising difficulty each loop. Service parks kept.
- Bosses: still to define. Idea: critical map conditions (e.g. extreme weather, collapsing road) instead of a classic boss enemy.
- Campaign run length: 40-60 min.

## 9. Difficulty scaling
Should difficulty scale with elapsed time (RoR2 clock), with distance/stage number, or both?

**Answer:** No RoR2 time clock. Difficulty mainly steps up between stages (and per country / per endless loop). Within long stages it may also rise slightly with distance driven.

## 10. Meta progression
Anything persisting between runs (unlockable cars, items, drivers, co-drivers)?

**Answer:** All of these:
- Unlockable cars (own handling and starting parts).
- Unlockable items/threats added to the pool (RoR2 style).
- Drivers / co-drivers with perks.
- Cosmetic liveries.
- Permanent stat upgrades (Rogue Legacy style).

## 11. Art style
Low-poly, pixel art, realistic, cartoon? Any reference games?

**Answer:** Low-poly, close to art of rally, with a sprinkle of old-school rally games. Old-school elements: bold 90s liveries (sponsor-style decals, chunky numbers), PS1 look (low-res textures, slight vertex wobble, dithering via shader), co-driver pace notes (arrow icons + calls), era-specific cars (boxy Group A/B silhouettes, pop-up headlights). No arcade-style HUD.

## 12. Multiplayer
Single player only, or co-op / versus later?

**Answer:** Single player first. Maybe couch co-op later (no online). Keep input handling per-device/per-player and the camera able to frame multiple cars so this stays possible.

## 13. Track generation
How are stages built?

**Answer:** Road as a procedurally generated spline. Terrain, props and hazards are also procedurally generated around it.
- Seeded: same seed = same stage (shareable, daily challenges, bug repro).
- Whole stage generated upfront before it starts (enables complete pace notes).
- Road features: jumps, crests, water splashes, hairpins, junctions with route choices (shortcut vs. safe line), narrow bridges. Height changes must stay readable from the isometric camera.

## 14. Countries
Which countries, and how are they picked per run?

**Answer:** Real countries. Each campaign picks 3-4 countries at random from the pool, then ends in a final country. Each country ends with a boss (critical map condition).

Pool:
- Finland: fast gravel, big crests and jumps. Threats: moose, reindeer herd, logging trucks. Boss: moose stampede (herd crossing in waves).
- Wales: mud, rain, fog, forest. Threats: sheep flocks, fallen trees, spectators on the road. Boss: flood (rising water cuts off low road sections).
- Kenya (Safari): dust, fesh-fesh, river crossings. Threats: zebras, charging rhino, dust storm hiding the road. Boss: great migration (wildebeest stampede).
- Monte Carlo: tarmac with ice/snow patches, night, cliffs. Threats: black ice, rockfall, paparazzi. Boss: avalanche chasing you downhill.
- Sweden: snow, snowbanks. Threats: snowmobilers, whiteouts. Boss: frozen lake cracking behind you.
- Australia: red dirt. Threats: kangaroos, road trains, dust. Boss: bushfire (wall of fire chasing you).

Finals (alternative endings, RoR2 Mithrix/Voidling style; one per run):
- Iceland (default): lava flows, meteorite shower, suicide drones.
- Nevada / Area 51 (secret/unlockable ending): UFO abductions, military drones, nuclear test site jokes. Unlock trigger still to define (e.g. hidden junction route, alien artifact).

## 15. Items and synergies
How do items and synergies work?

**Answer:**
- Item types: repairs (service minutes), part upgrades (engine, turbo, tires, brakes, lights, suspension, roll cage), gadgets (silly add-ons), cursed items.
- Cursed items: yes, with both a bonus and a drawback (e.g. Gearbox of Chaos: +50% power, each shift lands in a random gear).
- All synergy mechanisms:
  - Stacking (RoR2): duplicates stack.
  - Triggers: on drift, jump, near-miss, ram, part breaking, checkpoint, etc.
  - Broken-part enablers: item works only or better when a specific part is broken.
  - Evolutions (VS): maxed item + specific partner item = new evolved item.
- Limits:
  - Passive items: unlimited.
  - Active (triggered) items: limited, physically mounted on the car at mount points (e.g. roof, bumper, exhaust, trunk). 
    - Activation: both kinds. Some fire automatically on a trigger (jump, drift, ...), some on button press (with cooldown).
    - Mount points: 4 base (roof, front bumper, rear/exhaust, trunk) + 2 unlockable (e.g. trailer hitch; second one to define).

Example synergies (draft):
- Drift King: drifting fills a boost meter; with broken brakes it fills twice as fast.
- Backfire Exhaust: gear shifts shoot flames; with a leaking fuel tank (broken) it leaves a fire trail.
- Bullbar: sheep bounce off; with Wool Trader every sheep hit gives scrap.
- Moon Springs: airtime pays prize money; with broken suspension every bump becomes a jump.
- Spare Tire Launcher: fires tires at threats; auto-swaps a flat tire.
- Evolution: maxed Turbo + broken Radiator = Steam Locomotive (damaging steam cloud behind you, no engine heat limit).

## 16. Gearbox
Should the car have a manual gearbox option, and how real should engine RPM be?

**Answer:** Yes. Automatic or manual shifting, chosen in a menu setting that persists. Engine RPM follows the driven wheels, so wheelspin raises RPM; an automatic clutch prevents stalling. Gears R, N, 1..n; in manual, shifting down from 1st goes to N, then R (only at standstill). Shifts take a short time with no drive torque. Rev limiter bounces at redline. HUD shows RPM with a shift light.
