# Items and Synergies

## Item types

| Type | Description |
|---|---|
| Repairs | Restore part condition. Bought with service minutes in the service park |
| Part upgrades | Better engine, turbo, tires, brakes, lights, suspension, roll cage, ... |
| Gadgets | Silly add-ons: bullbar, spare-tire launcher, flamethrower exhaust, wool trader, ... |
| Cursed items | Strong bonus with a permanent drawback for the rest of the run (RoR2 lunar style) |

## Passive vs. active

- **Passive items:** unlimited. Duplicates stack.
- **Active items:** limited, physically mounted on the car. One item per mount point.
  - Activation: either automatic on a trigger (jump, drift, gear shift, ram, ...) or on button press. Both respect a cooldown.
  - Mount points: 4 base (roof, front bumper, rear/exhaust, trunk) + 2 unlockable (e.g. trailer hitch; second one not defined yet).
  - Picking an active item for an occupied mount replaces the old one.
  - Mounted items are visible on the car model.

## Synergy mechanisms

All four are in the game:

1. **Stacking (RoR2):** duplicate passive items stack their effect.
2. **Triggers:** items react to driving and game events: drift, jump/landing, near-miss, ram/collision, gear shift, part damaged, part broken, threat defeated, checkpoint.
3. **Broken-part enablers:** an item works only, or works better, when a specific part is broken. This is the core design hook: damage can become a build.
4. **Evolutions (VS):** a maxed item plus a specific partner item turns into a new, stronger evolved item.

Cursed items always have both a bonus and a drawback.

## Example items (draft)

| Item | Type | Effect | Synergy |
|---|---|---|---|
| Drift King | Passive | Drifting fills a boost meter | Broken brake: fills twice as fast |
| Backfire Exhaust | Active (trigger: gear shift), exhaust mount | Gear shifts shoot flames | Leaking fuel tank (broken): leaves a fire trail |
| Bullbar | Active (trigger: ram), front bumper | Animals and debris bounce off, less front damage | Wool Trader: every sheep hit gives scrap |
| Wool Trader | Passive | Hitting sheep pays scrap | Bullbar |
| Moon Springs | Passive | Airtime pays prize money | Broken suspension: every bump becomes a jump |
| Spare Tire Launcher | Active (button), trunk | Fires tires at threats; auto-swaps a flat tire | Tire upgrades |
| Nitro | Active (button), trunk/roof | Short boost | Turbo |
| Roll Cage | Passive | Raises lethal impact speed | Stacks |
| Gearbox of Chaos | Cursed | +50% power | Drawback: each shift lands in a random gear |
| Steam Locomotive | Evolution | Damaging steam cloud behind you, no engine heat limit | Maxed Turbo + broken Radiator |

## Rarity and pricing

Not defined yet: rarity tiers, drop weights, shop prices, how rarity affects offers. See [open-questions.md](open-questions.md).

## Data

Every item is defined as data (name, description, type, stat modifiers per stack, mount, activation, trigger, cooldown, broken-part condition, effect). New items that combine existing effects need no code changes.
