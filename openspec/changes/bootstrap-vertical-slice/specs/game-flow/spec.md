# Spec Delta

## Purpose

Defines the screens and run lifecycle of the prototype: main menu, starting a stage, the stage timer and prize money, pausing, and the finish and game-over screens.

## ADDED Requirements

### Requirement: Main menu
The game SHALL start on a main menu with: Start Stage, a seed field (empty means random), a gearbox setting (automatic or manual), and Quit. The gearbox setting SHALL persist between game launches. The menu SHALL be fully usable with controller and keyboard.

#### Scenario: Start with random seed
- **WHEN** the player selects Start Stage with an empty seed field
- **THEN** a stage is generated with a random seed and loaded

#### Scenario: Start with entered seed
- **WHEN** the player enters seed 42 and selects Start Stage
- **THEN** the stage is generated with seed 42

#### Scenario: Gearbox setting persists
- **WHEN** the player sets the gearbox to manual and restarts the game
- **THEN** the menu shows manual and stages start with the manual gearbox

### Requirement: Stage start countdown
A stage SHALL begin with the car on the start line and a short countdown during which the car cannot move, followed by the timer starting.

#### Scenario: Countdown
- **WHEN** the stage finishes loading
- **THEN** a countdown runs and the stage timer starts at zero when it ends

### Requirement: Stage timer and penalties
The stage timer SHALL run from the end of the countdown until the car crosses the finish line, and time penalties (e.g. rollover recovery) SHALL be added to it.

#### Scenario: Penalty added
- **WHEN** a 5 second penalty is applied at 60 seconds elapsed
- **THEN** the timer shows 65 seconds

### Requirement: Prize money
Crossing the finish line SHALL award prize money that is higher for a faster final time, and the amount SHALL be shown on the finish screen.

#### Scenario: Faster earns more
- **WHEN** the same stage is finished once in 120 s and once in 150 s
- **THEN** the 120 s finish awards more prize money

### Requirement: In-stage HUD
During a stage the HUD SHALL show the timer, speed, gear, engine RPM with a shift light, the condition of each part, mounted active items with cooldowns, and the upgrade meter. The HUD SHALL stay minimal and SHALL NOT use arcade-style banners.

#### Scenario: Part breaks
- **WHEN** a tire breaks
- **THEN** the HUD part display shows that tire as broken

#### Scenario: Shift light
- **WHEN** engine RPM approaches the redline
- **THEN** the HUD shift light turns on

### Requirement: Finish screen
Crossing the finish line SHALL show a finish screen with final time, penalties, prize money, and options to retry the same seed, play a new random seed, or return to the main menu.

#### Scenario: Retry same seed
- **WHEN** the player selects retry on the finish screen
- **THEN** the same seed is generated again and a fresh car starts the stage

### Requirement: Game over
When the car is immobilized, the game SHALL show a game-over screen stating the cause (e.g. lethal impact, engine destroyed) and options to retry the same seed or return to the main menu.

#### Scenario: Lethal crash
- **WHEN** the car hits a tree above lethal impact speed
- **THEN** the game-over screen appears and states the cause

### Requirement: Pause
The pause action SHALL pause the stage and show a menu with resume, restart stage, and quit to main menu.

#### Scenario: Pause and resume
- **WHEN** the player pauses and then resumes
- **THEN** the stage continues from the same state and the timer did not advance while paused
