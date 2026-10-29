class_name ItemPool
## Every item in `data/items/` and seeded upgrade offers drawn from them.

const ITEM_DIR := "res://data/items/"


## All item defs, sorted by file name so a seed always sees the same order.
static func load_all() -> Array[ItemDef]:
	var files := Array(ResourceLoader.list_directory(ITEM_DIR)).filter(
			func(file: String) -> bool: return file.ends_with(".tres"))
	files.sort()
	var pool: Array[ItemDef] = []
	for file: String in files:
		pool.append(load(ITEM_DIR + file))
	return pool


## `count` distinct items from `pool`, leaving out active items already mounted in `items`.
static func offer(pool: Array[ItemDef], items: ItemManager, rng: RandomNumberGenerator, count: int) -> Array[ItemDef]:
	var choices := pool.filter(func(def: ItemDef) -> bool:
		var mounted: ItemDef = items.mounts.get(def.mount)
		return def.kind == ItemDef.Kind.PASSIVE or mounted == null or mounted.id != def.id)
	var offers: Array[ItemDef] = []
	# Partial seeded Fisher-Yates; `Array.shuffle` uses the global RNG.
	for i in mini(count, choices.size()):
		var j := rng.randi_range(i, choices.size() - 1)
		var swap: ItemDef = choices[i]
		choices[i] = choices[j]
		choices[j] = swap
		offers.append(choices[i])
	return offers
