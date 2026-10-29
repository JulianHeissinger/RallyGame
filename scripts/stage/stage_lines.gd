class_name StageLines
## Start and finish lines across the road, each under a gantry (visual only), plus the finish trigger.

const START_LINE_DISTANCE := 8.0
## Road left after the finish line to brake on.
const FINISH_MARGIN := 20.0
const LINE_DEPTH := 1.0
## Lines sit this far above the road surface to avoid z-fighting.
const LINE_LIFT := 0.02
const CHECKER_COLUMNS := 8
const CHECKER_ROWS := 2
## Finish trigger reaches this far beyond each road edge, so cutting beside the road still counts.
const FINISH_AREA_SIDE := 10.0
const FINISH_AREA_HEIGHT := 10.0
const FINISH_AREA_DEPTH := 2.0
const POST_SIZE := Vector3(0.3, 5.0, 0.3)
const BANNER_HEIGHT := 0.8
## Gap between the bevel's outer edge and a gantry post.
const POST_GAP := 1.0
const START_COLOR := Color(0.9, 0.9, 0.9)
const FINISH_DARK := Color(0.1, 0.1, 0.1)
const FINISH_LIGHT := Color(0.9, 0.9, 0.9)
const GANTRY_COLOR := Color(0.25, 0.25, 0.3)
const START_BANNER := Color(0.2, 0.6, 0.2)
const FINISH_BANNER := Color(0.7, 0.15, 0.15)


static func finish_distance(path: RoadPath) -> float:
	return path.length - FINISH_MARGIN


## Node with "Start", "Finish" and the `Area3D` "FinishArea".
static func build(path: RoadPath, params: StageParams) -> Node3D:
	var root := Node3D.new()
	root.name = "StageLines"
	var start := _line("Start", path, START_LINE_DISTANCE)
	start.add_child(_box(Vector3(_width(path, START_LINE_DISTANCE), LINE_LIFT, LINE_DEPTH), Vector3.ZERO, START_COLOR))
	start.add_child(_gantry(path, START_LINE_DISTANCE, params, START_BANNER))
	root.add_child(start)

	var end := finish_distance(path)
	var finish := _line("Finish", path, end)
	var width := _width(path, end)
	var tile := Vector3(width / CHECKER_COLUMNS, LINE_LIFT, LINE_DEPTH / CHECKER_ROWS)
	for row in CHECKER_ROWS:
		for column in CHECKER_COLUMNS:
			var offset := Vector3((column + 0.5) * tile.x - width / 2.0, 0.0, (row + 0.5) * tile.z - LINE_DEPTH / 2.0)
			finish.add_child(_box(tile, offset, FINISH_DARK if (row + column) % 2 == 0 else FINISH_LIGHT))
	finish.add_child(_gantry(path, end, params, FINISH_BANNER))
	root.add_child(finish)

	var box := BoxShape3D.new()
	box.size = Vector3(width + 2.0 * FINISH_AREA_SIDE, FINISH_AREA_HEIGHT, FINISH_AREA_DEPTH)
	var collision := CollisionShape3D.new()
	collision.shape = box
	var area := Area3D.new()
	area.name = "FinishArea"
	area.transform = path.transform_at(end)
	area.add_child(collision)
	root.add_child(area)
	return root


static func _line(line_name: String, path: RoadPath, distance: float) -> Node3D:
	var line := Node3D.new()
	line.name = line_name
	line.transform = path.transform_at(distance).translated_local(Vector3.UP * LINE_LIFT / 2.0)
	return line


## Two posts beside the road and a banner across the top.
static func _gantry(path: RoadPath, distance: float, params: StageParams, banner_color: Color) -> Node3D:
	var gantry := Node3D.new()
	gantry.name = "Gantry"
	var half := _width(path, distance) / 2.0 + params.road_bevel + POST_GAP
	for side in [-1.0, 1.0]:
		gantry.add_child(_box(POST_SIZE, Vector3(side * half, POST_SIZE.y / 2.0 - params.road_sink, 0.0), GANTRY_COLOR))
	var banner := Vector3(2.0 * half + POST_SIZE.x, BANNER_HEIGHT, POST_SIZE.z)
	gantry.add_child(_box(banner, Vector3(0.0, POST_SIZE.y - params.road_sink - BANNER_HEIGHT / 2.0, 0.0), banner_color))
	return gantry


static func _width(path: RoadPath, distance: float) -> float:
	return path.widths[clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)]


static func _box(size: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = offset
	return instance
