class_name FogBank
extends Node3D
## A bank of fog over `length` m of road: stacked translucent layers that hide the car from the
## iso camera while it is inside. Visual only; built in `setup` from the road at the placement.

@export var length := 60.0
@export var height := 5.0
@export var layers := 8
## Extra width in m beyond each road edge.
@export var margin := 8.0
@export var color := Color(0.9, 0.92, 0.95, 0.35)
## Road samples per layer piece; the bank follows the road in straight pieces this long.
const PIECE := 10.0


func setup(_def: HazardDef, _car: Car, path: RoadPath, _rng: RandomNumberGenerator) -> void:
	var start := path.progress_at(transform.origin) - length / 2.0
	var to_local := transform.affine_inverse()
	var material := HazardVisuals.material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for piece in ceili(length / PIECE):
		var along := start + (piece + 0.5) * PIECE
		var road := path.transform_at(along)
		var width := path.widths[clampi(path.distances.bsearch(along), 0, path.widths.size() - 1)] + 2.0 * margin
		for layer in layers:
			var plane := PlaneMesh.new()
			plane.size = Vector2(width, PIECE)
			plane.material = material
			var visual := MeshInstance3D.new()
			visual.mesh = plane
			visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var y := height * (layer + 0.5) / layers
			visual.transform = to_local * Transform3D(road.basis, road.origin + Vector3.UP * y)
			add_child(visual)
