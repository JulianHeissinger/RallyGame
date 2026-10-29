class_name FallenTree
extends StaticBody3D
## A trunk lying across the road from one road edge, picked by the seed, into the verge on that
## side, leaving a `gap` m wide on the other side. In group `solid`, so a fast hit is lethal. The
## trunk and its crown are built in `setup` from the road width at the placement.

@export var gap := 3.5
@export var radius := 0.4
## Trunk length in m beyond the road edge.
@export var overhang := 3.0
@export var crown_radius := 1.8

const BARK := Color(0.35, 0.22, 0.12)
const LEAVES := Color(0.18, 0.4, 0.15)


## Called by the stage before the tree enters the tree; its `transform` is already set.
func setup(_def: HazardDef, _car: Car, path: RoadPath, rng: RandomNumberGenerator) -> void:
	var width := path.widths[clampi(path.distances.bsearch(path.progress_at(transform.origin)), 0, path.widths.size() - 1)]
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var length := width + overhang - gap
	# The trunk runs from `side * (gap - width / 2)` to `side * (width / 2 + overhang)`.
	var centre := side * (gap + overhang) / 2.0
	# The cylinder axis is y; turn it across the road (x).
	var across := Basis(Vector3.BACK, PI / 2.0)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(across, Vector3(centre, radius, 0.0))
	add_child(collision)
	var trunk := CylinderMesh.new()
	trunk.top_radius = radius
	trunk.bottom_radius = radius
	trunk.height = length
	trunk.material = HazardVisuals.material(BARK)
	var trunk_visual := MeshInstance3D.new()
	trunk_visual.mesh = trunk
	trunk_visual.transform = collision.transform
	add_child(trunk_visual)
	var crown := SphereMesh.new()
	crown.radius = crown_radius
	crown.height = crown_radius * 2.0
	crown.material = HazardVisuals.material(LEAVES)
	var crown_visual := MeshInstance3D.new()
	crown_visual.mesh = crown
	crown_visual.position = Vector3(side * (width / 2.0 + overhang), crown_radius * 0.6, 0.0)
	add_child(crown_visual)
