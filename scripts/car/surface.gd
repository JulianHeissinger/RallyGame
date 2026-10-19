class_name Surface
extends RefCounted
## Surface grip table. Colliders name their surface with `surface` metadata, or answer per point
## with a `surface_at(point)` method; wheels scale tire friction by the matching grip.

const DEFAULT := "gravel"
const GRIP := {
	"tarmac": 1.2,
	"gravel": 1.0,
	"grass": 0.8,
	"snow": 0.6,
	"ice": 0.4,
}
## Placeholder colours for road and terrain meshes.
const COLOR := {
	"tarmac": Color(0.25, 0.25, 0.27),
	"gravel": Color(0.55, 0.5, 0.4),
	"grass": Color(0.3, 0.5, 0.22),
	"snow": Color(0.9, 0.92, 0.95),
	"ice": Color(0.75, 0.85, 0.95),
}


## Surface name of `collider` at world `point`, or `DEFAULT` when it has none or an unknown one.
static func name_of(collider: Object, point: Vector3 = Vector3.ZERO) -> String:
	if collider == null:
		return DEFAULT
	var surface: String = collider.surface_at(point) if collider.has_method("surface_at") \
			else collider.get_meta("surface", DEFAULT)
	return surface if GRIP.has(surface) else DEFAULT


static func grip_of(collider: Object, point: Vector3 = Vector3.ZERO) -> float:
	return GRIP[name_of(collider, point)]
