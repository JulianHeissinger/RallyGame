class_name FallingTree
extends ApproachHazard
## A tree standing at the road edge that falls across the road on approach, pivoting on its base
## in the verge, over `fall_time` seconds and speeding up as it falls. Once down it is a
## `FallenTree` (in group `solid`, lethal at speed) with its crown at the tip on the road.

const TREE_SCENE := preload("res://scenes/hazards/fallen_tree.tscn")

@export var fall_time := 1.2

var _pivot := Node3D.new()
var _tree: FallenTree
var _upright := 0.0
var _timer := 0.0


func _setup(def: HazardDef, rng: RandomNumberGenerator) -> void:
	_tree = TREE_SCENE.instantiate()
	_tree.transform = transform
	_tree.setup(def, car, path, rng)
	# The trunk runs from the gap end on the road to the base in the verge; the base is the end
	# farther from the origin, on the side of the trunk centre.
	var trunk: CollisionShape3D
	var crown: MeshInstance3D
	for child in _tree.get_children():
		if child is CollisionShape3D:
			trunk = child
		elif child is MeshInstance3D and child.mesh is SphereMesh:
			crown = child
	var length := (trunk.shape as CylinderShape3D).height
	var side := signf(trunk.position.x)
	var base := trunk.position.x + side * length / 2.0
	var tip := trunk.position.x - side * length / 2.0
	crown.position.x = tip
	_pivot.position = Vector3(base, 0.0, 0.0)
	_tree.transform = Transform3D(Basis.IDENTITY, Vector3(-base, 0.0, 0.0))
	# Rotating about the road direction (z) by -side * 90° stands the trunk up from its base.
	_upright = -side * PI / 2.0
	_pivot.rotation.z = _upright
	_pivot.add_child(_tree)
	add_child(_pivot)


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered or _timer >= fall_time:
		return
	_timer = minf(_timer + delta, fall_time)
	var t := _timer / fall_time
	_pivot.rotation.z = _upright * (1.0 - t * t)
