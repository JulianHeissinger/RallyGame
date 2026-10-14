# Art and Audio

## Visual style

Low-poly, close to art of rally, with a sprinkle of old-school rally games.

### Old-school elements (in scope)
- **Bold 90s liveries:** sponsor-style decals, chunky race numbers.
- **PS1 look:** low-res textures, slight vertex wobble, dithering, done as a shader. It should be subtle so the art of rally base look stays.
- **Co-driver pace notes:** arrow icons on screen plus voiced calls ("left 4, don't cut!").
- **Era-specific cars:** boxy Group A/B silhouettes, pop-up headlights.

### Explicitly out
- Arcade-style HUD (big banners, "CHECKPOINT!" popups).

## HUD

Minimal. Stage timer, speed and gear, part condition display, mounted items with cooldowns, upgrade meter, pace notes. No arcade banners.

## Readability

The isometric camera must keep threats, road edges and height changes readable. Threats need clear silhouettes and colors against each country's palette.

## Asset pipeline

- Models are built with **Blender Python scripts**, run headless (`blender -b -P script.py`), exported as `.glb`. Preview renders are used to check proportions.
- Terrain, road and scattered props are generated in-engine.
- Early prototypes use placeholder primitives.
- CC0 packs (e.g. Kenney, Quaternius) are allowed as filler.

## Audio

Not discussed yet. Working assumptions: engine sound per car, surface sounds, co-driver voice for pace notes, silly sound effects for threats. See [open-questions.md](open-questions.md).
