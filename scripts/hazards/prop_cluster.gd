class_name PropCluster
extends Node3D
## A group of `Knockable` props on the road around the placement: a seeded count of `prop` copies
## on distinct cells of a `cell` m grid, `spread_side` m across and `spread_along` m along the
## road, each with a random heading. Relays each prop's `hazard_defeated`.

signal hazard_defeated(hazard: Node)

@export var prop: PackedScene
@export var count_range := Vector2i(2, 4)
@export var spread_side := 3.0
@export var spread_along := 3.0
@export var cell := 1.0
## Props spawn this far above the road and settle onto it.
@export var spawn_height := 0.1


## Called by the stage before the cluster enters the tree; its `transform` is already set.
func setup(_def: HazardDef, _car: Car, _path: RoadPath, rng: RandomNumberGenerator) -> void:
	var columns := maxi(floori(spread_side / cell), 1)
	var rows := maxi(floori(spread_along / cell), 1)
	var cells := range(columns * rows)
	# Seeded Fisher-Yates shuffle; `Array.shuffle` uses the global RNG.
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	for i in mini(rng.randi_range(count_range.x, count_range.y), cells.size()):
		var column: int = cells[i] % columns
		var row: int = cells[i] / columns
		var x := -spread_side / 2.0 + (column + rng.randf_range(0.2, 0.8)) * cell
		var z := -spread_along / 2.0 + (row + rng.randf_range(0.2, 0.8)) * cell
		var body: Knockable = prop.instantiate()
		body.transform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, spawn_height, z))
		body.hazard_defeated.connect(hazard_defeated.emit)
		add_child(body)
