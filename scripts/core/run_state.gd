extends Node
## State of the current run (autoload `RunState`): stage seed, difficulty, prize money and the
## items picked so far. Survives scene reloads; `reset` starts a new run.

## 0: no seed chosen yet; the stage rolls one and stores it here.
var stage_seed := 0
var difficulty := 1
var prize_money := 0
## Picked items in pick order.
var items: Array[ItemDef] = []


## Starts a new run: no items, no money, the given seed (0 = random) and difficulty.
func reset(new_seed := 0, new_difficulty := 1) -> void:
	stage_seed = new_seed
	difficulty = new_difficulty
	prize_money = 0
	items.clear()


func add_item(def: ItemDef) -> void:
	items.append(def)
