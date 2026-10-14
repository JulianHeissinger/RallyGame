# World

## Procedural stage generation

- Each stage is a point-to-point road built as a **procedurally generated spline**.
- **Terrain, props and hazards** around the road are also procedurally generated.
- **Seeded:** the same seed always produces the same stage (shareable seeds, daily challenges, bug reproduction). Separate random sub-streams per subsystem (road, terrain, props, hazards, events), so changing one does not change the others.
- **Generated upfront:** the whole stage exists before the start. This enables complete co-driver pace notes.
- **Road features:** straights, fast corners, tight corners, hairpins, crests, jumps, water splashes, junctions with route choices (shortcut vs. safe line), narrow bridges.
- **Readability:** height changes must stay readable from the isometric camera, so gradients are limited.
- **Off-road:** terrain beside the road is drivable but grips less. Solid props (trees, rocks) on corner outsides create real crash risk.
- **Stage length:** about 3-4 minutes of driving for regular stages (to be tuned). The prototype uses about 2 km.

## Countries

Real countries. Each campaign picks 3-4 at random from the pool, then a final country. Each country sets surfaces, weather, props, threats and its boss.

| Country | Surface / setting | Country threats | Boss |
|---|---|---|---|
| Finland | Fast gravel, big crests and jumps, forest | Moose, reindeer herd, logging trucks | Moose stampede |
| Wales | Mud, rain, fog, forest | Sheep flocks, fallen trees, spectators on the road | Flood |
| Kenya (Safari) | Dust, fesh-fesh, river crossings, savanna | Zebras, charging rhino, dust storm | Great migration |
| Monte Carlo | Tarmac with ice/snow patches, night, mountain cliffs | Black ice, rockfall, paparazzi | Avalanche |
| Sweden | Snow, snowbanks, frozen lakes | Snowmobilers, whiteouts | Frozen lake cracking |
| Australia | Red dirt, outback | Kangaroos, road trains, dust | Bushfire |

## Final countries (alternative endings)

One final per run, RoR2 Mithrix/Voidling style.

| Final | Role | Content |
|---|---|---|
| Iceland | Default ending | Volcanic terrain, lava flows, meteorite shower, suicide drones |
| Nevada / Area 51 | Secret / unlockable ending | UFO abductions, military drones, nuclear test site jokes |

The trigger for the Area 51 ending is not defined yet (ideas: hidden junction route, alien artifact item). See [open-questions.md](open-questions.md).

## Endless mode

Loops through the country pool with rising difficulty each loop. Service parks are kept.
