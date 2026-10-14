# Spec Delta

## Purpose

Defines the upgrade items the player collects during a run: unlimited stacking passive items, a limited number of mounted active items, conditions tied to broken parts, and the mid-stage upgrade pick that makes synergies possible.

## ADDED Requirements

### Requirement: Data-driven item definitions
Each item SHALL be defined as data: name, description, kind (passive or active), stat modifiers per stack, optional mount point, optional trigger or button activation with cooldown, and optional broken-part condition. New items SHALL be addable without changing the item system.

#### Scenario: New item added
- **WHEN** a new passive item definition is added that raises engine power
- **THEN** it can be offered and applied without code changes to the item system

### Requirement: Passive item stacking
Passive items SHALL be unlimited, and multiple copies of the same passive item SHALL stack their effects.

#### Scenario: Two copies stack
- **WHEN** the player owns two copies of a +10% grip item
- **THEN** tire grip is higher than with one copy

### Requirement: Mounted active items
Active items SHALL occupy one of four mount points (roof, front bumper, rear/exhaust, trunk), at most one item per mount point. Picking an active item for an occupied mount point SHALL replace the old item.

#### Scenario: Mount point full
- **WHEN** the player picks a front-bumper item while one is already mounted there
- **THEN** the new item replaces the old one

### Requirement: Trigger and button activation
An active item SHALL activate either automatically on a game event (e.g. drift, jump, gear shift, ram, part broken) or when the player presses the activate button, and SHALL respect its cooldown in both cases.

#### Scenario: Button item on cooldown
- **WHEN** the player presses activate while the button item is on cooldown
- **THEN** nothing happens

#### Scenario: Trigger item fires
- **WHEN** the car lands a jump and a mounted item triggers on jumps
- **THEN** the item activates without player input

### Requirement: Broken-part conditions
An item effect SHALL be able to require a part state (e.g. "any brake broken"), and the effect SHALL turn on and off as that part breaks or is repaired.

#### Scenario: Drift King with broken brake
- **WHEN** the player owns Drift King and a brake breaks
- **THEN** drifting fills the boost meter twice as fast as before

### Requirement: Cursed items
Cursed items SHALL combine a strong bonus with a permanent drawback for the rest of the run, and SHALL be marked as cursed when offered.

#### Scenario: Cursed offer
- **WHEN** a cursed item appears in an upgrade pick
- **THEN** its bonus and drawback are both shown and it is marked cursed

### Requirement: Prototype item set
The prototype SHALL include at least: three passive stat items (grip, power, lethal impact speed), Drift King (passive with broken-brake condition), one button-activated item (nitro boost), two trigger items (a flame-shooting exhaust on gear shift and a bullbar that reduces front impact damage and knocks hazards away), and one cursed item (more power, random gear on each shift).

#### Scenario: Bullbar ram
- **WHEN** the car with a bullbar hits a sheep
- **THEN** the sheep is knocked away and front parts take less damage than without the bullbar

### Requirement: Mid-stage upgrade pick
Distance driven SHALL fill an upgrade meter, and defeating hazards SHALL add a small bonus. When full, the game SHALL slow time and offer three random items. The player SHALL pick one with the driving controls; if no pick is made within a few seconds, the first offer is taken.

#### Scenario: Meter fills
- **WHEN** the upgrade meter fills during a stage
- **THEN** time slows, three items are offered, and normal speed resumes after a pick

#### Scenario: No pick made
- **WHEN** the player makes no pick before the timer ends
- **THEN** the first offered item is applied and normal speed resumes

### Requirement: Item reactions to car events
Items SHALL be able to react to car and stage events: part damaged, part broken, drift, jump/landing, gear shift, collision, hazard defeated.

#### Scenario: Event reaches item
- **WHEN** the car shifts gear and a mounted item reacts to gear shifts
- **THEN** the item activates on that shift
