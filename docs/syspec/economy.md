# Economy

## Currencies

| Currency | Earned by | Spent on | Weight |
|---|---|---|---|
| Prize money | Finishing stages; faster time pays more; time penalties reduce it | Shop | Main currency |
| Scrap | Collected along the route; some items and defeated threats pay scrap | Shop | Secondary |
| Service minutes | Fixed budget per service park (~30 min) | Repairs only | Per service park, does not carry over |

No chests. Upgrades never come from opening containers.

## Upgrade sources

1. **Distance driven:** fills an upgrade meter during the stage.
2. **Defeating threats:** adds a bonus to the upgrade meter.
3. **End of stage:** service park shop.

## Mid-stage upgrade pick

- When the upgrade meter is full, time slows down (slow motion, no full pause) and three random items are offered.
- The player picks with the driving controls.
- If no pick is made within a few seconds, the first offer is taken.
- Status: slow motion is tentative. Fallback is a full pause (VS style) if slow motion feels bad.

## Service park

Between stages. Two parts:

### Repairs
- Dirt Rally style time budget: about 30 service minutes.
- Each repair costs minutes. The player cannot fix everything and must choose.
- Choosing not to repair a part can be deliberate (broken-part synergies, see [items.md](items.md)).

### Shop
- Buy items with prize money and scrap.
- Offer generation, prices and rerolls are not defined yet.

## Prize money formula (prototype)

`prize = base × clamp(par_time / final_time, 0.25, 2.0)`, with `par_time = stage_length / reference_speed`. To be tuned.

## Open points

Shop offer count, rerolls, price scaling per rarity and per country, scrap drop rates. See [open-questions.md](open-questions.md).
