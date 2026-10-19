class_name TerrainBody
extends StaticBody3D
## Terrain collider whose surface changes per area: each grid cell takes the off-road surface of
## the road section nearest to it.

var corner := Vector2.ZERO
var cell := 1.0
var nx := 0
var nz := 0
## Surface name per grid cell, row by row.
var cell_surfaces := PackedStringArray()


## Surface of the grid cell nearest to `point`.
func surface_at(point: Vector3) -> String:
	var i := clampi(roundi((point.x - corner.x) / cell), 0, nx - 1)
	var j := clampi(roundi((point.z - corner.y) / cell), 0, nz - 1)
	return cell_surfaces[j * nx + i]
