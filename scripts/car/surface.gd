class_name Surface
extends RefCounted
## Surface grip table. Colliders name their surface with `surface` metadata; wheels scale tire
## friction by the matching grip.

const DEFAULT := "gravel"
const GRIP := {
	"tarmac": 1.2,
	"gravel": 1.0,
	"grass": 0.6,
	"snow": 0.5,
	"ice": 0.3,
}


## Surface name of `collider`, or `DEFAULT` when it has none or an unknown one.
static func name_of(collider: Object) -> String:
	if collider == null:
		return DEFAULT
	var surface: String = collider.get_meta("surface", DEFAULT)
	return surface if GRIP.has(surface) else DEFAULT


static func grip_of(collider: Object) -> float:
	return GRIP[name_of(collider)]
