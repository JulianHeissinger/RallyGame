# Rally Roguelite – System Specification

Working title: none yet.

This folder is the game-level specification: what the game is, how its systems fit together, and which decisions are made. It covers the full game vision. Implementation-level, testable requirements for individual changes live in `openspec/` (see `openspec/changes/` and `openspec/specs/`).

Source of decisions: `docs/questions.md` (raw Q&A record). If this spec and the Q&A disagree, the Q&A wins until this spec is updated.

## Vision

A rally roguelite. You drive point-to-point rally stages through real countries while random threats break your car piece by piece. Between and during stages you repair, upgrade and bolt silly gadgets onto the car until absurd synergies turn a dying hatchback into a sheep-launching, fire-trailing, drift-boosting monster.

## Inspirations

| Source | What we take |
|---|---|
| Risk of Rain 2 | Run structure with stages and a final boss, alternative endings, item stacking, cursed (lunar) items, unlocks that grow the item pool |
| Vampire Survivors | Constant drip of upgrades during play, slow-motion level-up pick, item evolutions, escalating threats |
| Dirt Rally | Semi-sim handling, part damage, service park with limited repair minutes, point-to-point stages |
| Sega Rally / Colin McRae (90s) | Bold liveries, Group A/B era cars, co-driver pace notes, PS1-era look |
| art of rally | Isometric camera, low-poly art style |

## Design pillars

1. **Driving is the skill.** Semi-sim handling where real rally technique (weight transfer, Scandinavian flick, handbrake) works. No yaw assists, no auto-drift.
2. **The car falls apart, and that is the game.** No health bar. Parts wear and break. Broken parts change handling and can enable synergies, so "repair or embrace it?" is always a real choice.
3. **Silly synergies.** Items stack, trigger off driving events, and combine into builds that get very powerful and very funny.
4. **Every run is different.** Seeded procedural stages, random countries, random threats, random offers.
5. **Readable chaos.** The isometric camera and minimal HUD keep the screen readable even when sheep, drones and meteorites are involved.

## Documents

| File | Content |
|---|---|
| [core-loop.md](core-loop.md) | Run structure, game modes, stages, difficulty |
| [vehicle.md](vehicle.md) | Handling model, parts, damage, immobilization, rollover |
| [threats.md](threats.md) | Threat categories, escalation, bosses |
| [items.md](items.md) | Item types, synergy mechanisms, mounts, example items |
| [economy.md](economy.md) | Prize money, scrap, upgrade picks, service park, shop |
| [world.md](world.md) | Procedural stage generation, countries, final endings |
| [meta-progression.md](meta-progression.md) | Unlocks and permanent progress between runs |
| [art-audio.md](art-audio.md) | Visual style, old-school elements, HUD, audio direction |
| [tech.md](tech.md) | Engine, language, architecture principles, asset pipeline, testing |
| [open-questions.md](open-questions.md) | Decisions still open |

## Status

Pre-production. The first implementation change is `openspec/changes/bootstrap-vertical-slice` (playable prototype of car, stage, hazards, items and menus).
