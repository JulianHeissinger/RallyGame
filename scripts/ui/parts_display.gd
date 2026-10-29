class_name PartsDisplay
extends Control
## Top-down car schematic for the HUD, front up. The body outline shows the chassis, the block at
## the front the engine, and each corner its tire, brake disc and suspension spring. Parts are
## coloured by condition from green (100) over yellow to red; a broken part pulses dark red under a
## cross. A part flashes white for a moment when it takes damage.

enum State { OK, WORN, DAMAGED, BROKEN }

const WORN_BELOW := 60.0
const DAMAGED_BELOW := 25.0
const GOOD_COLOR := Color(0.35, 0.85, 0.4)
const WORN_COLOR := Color(0.95, 0.8, 0.25)
const DAMAGED_COLOR := Color(0.9, 0.25, 0.15)
const BROKEN_COLOR := Color(0.4, 0.04, 0.04)
const CROSS_COLOR := Color(1.0, 0.92, 0.88)
const BODY_FILL := Color(0.06, 0.06, 0.08, 0.8)
const GLASS_COLOR := Color(0.55, 0.65, 0.75, 0.35)
const DISC_RIM := Color(0.05, 0.05, 0.06)
## Seconds a damage flash takes to fade.
const HIT_TIME := 0.4
## Pulse rate of broken parts in rad/s.
const PULSE_SPEED := 7.0

## Schematic sizes in px, around the control's centre.
const BODY_HALF := Vector2(32.0, 80.0)
const AXLE_Y := 50.0
const WHEEL_X := 52.0
const WHEEL_HALF := Vector2(9.0, 17.0)
const DISC_RADIUS := 6.0
const ENGINE_RECT := Rect2(-20.0, -72.0, 40.0, 34.0)
const CORNERS := {"fl": Vector2(-1, -1), "fr": Vector2(1, -1), "rl": Vector2(-1, 1), "rr": Vector2(1, 1)}

var damage: CarDamage:
	set = set_damage

## Remaining flash time per part.
var _hits := {}
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(2.0 * (WHEEL_X + WHEEL_HALF.x) + 16.0, 2.0 * BODY_HALF.y + 16.0)
	mouse_filter = MOUSE_FILTER_IGNORE


func set_damage(value: CarDamage) -> void:
	if damage == value:
		return
	if damage:
		damage.part_damaged.disconnect(_on_part_damaged)
	damage = value
	_hits.clear()
	if damage:
		damage.part_damaged.connect(_on_part_damaged)
	queue_redraw()


static func state(value: float) -> State:
	if value <= 0.0:
		return State.BROKEN
	if value < DAMAGED_BELOW:
		return State.DAMAGED
	if value < WORN_BELOW:
		return State.WORN
	return State.OK


## Condition colour: green to yellow above `WORN_BELOW`, yellow to red down to `DAMAGED_BELOW`,
## red below, dark red when broken.
static func color(value: float) -> Color:
	if value >= WORN_BELOW:
		return WORN_COLOR.lerp(GOOD_COLOR, (value - WORN_BELOW) / (100.0 - WORN_BELOW))
	if value >= DAMAGED_BELOW:
		return DAMAGED_COLOR.lerp(WORN_COLOR, (value - DAMAGED_BELOW) / (WORN_BELOW - DAMAGED_BELOW))
	return DAMAGED_COLOR if value > 0.0 else BROKEN_COLOR


func part_state(part: String) -> State:
	return state(damage.condition[part])


func _process(delta: float) -> void:
	if damage == null:
		return
	_time += delta
	for part in _hits.keys():
		_hits[part] -= delta
		if _hits[part] <= 0.0:
			_hits.erase(part)
	queue_redraw()


func _on_part_damaged(part: String, _amount: float) -> void:
	_hits[part] = HIT_TIME


func _draw() -> void:
	if damage == null:
		return
	var centre := size / 2.0
	for corner in CORNERS:
		_draw_corner(centre, corner, CORNERS[corner])
	var body := Rect2(centre - BODY_HALF, BODY_HALF * 2.0)
	draw_style_box(_box(BODY_FILL, _part_color("chassis"), 3, 18, 10), body)
	# Windscreen behind the engine, so the front reads at a glance.
	var glass_top := centre.y + ENGINE_RECT.end.y + 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(centre.x - 24.0, glass_top), Vector2(centre.x + 24.0, glass_top),
		Vector2(centre.x + 27.0, glass_top + 16.0), Vector2(centre.x - 27.0, glass_top + 16.0),
	]), GLASS_COLOR)
	var engine := Rect2(centre + ENGINE_RECT.position, ENGINE_RECT.size)
	draw_style_box(_box(_part_color("engine"), DISC_RIM, 1, 4, 4), engine)
	_draw_broken_cross("engine", engine)
	_draw_broken_cross("chassis", body.grow(-BODY_HALF.x * 0.4))


func _draw_corner(centre: Vector2, corner: String, side: Vector2) -> void:
	var wheel_centre := centre + Vector2(side.x * WHEEL_X, side.y * AXLE_Y)
	# Spring from the body side to the wheel's inner edge.
	var from := Vector2(centre.x + side.x * BODY_HALF.x, wheel_centre.y)
	var to := Vector2(wheel_centre.x - side.x * WHEEL_HALF.x, wheel_centre.y)
	var spring := PackedVector2Array([from])
	var coils := 4
	for i in range(1, coils * 2):
		var point := from.lerp(to, float(i) / (coils * 2))
		spring.append(point + Vector2(0.0, 5.0 if i % 2 else -5.0))
	spring.append(to)
	var suspension := "suspension_" + corner
	draw_polyline(spring, _part_color(suspension), 2.5, true)
	_draw_broken_cross(suspension, Rect2(Vector2(minf(from.x, to.x), from.y - 6.0), Vector2(absf(to.x - from.x), 12.0)))
	var tire := "tire_" + corner
	var wheel := Rect2(wheel_centre - WHEEL_HALF, WHEEL_HALF * 2.0)
	draw_style_box(_box(_part_color(tire), DISC_RIM, 1, 4, 4), wheel)
	var brake := "brake_" + corner
	draw_circle(wheel_centre, DISC_RADIUS, _part_color(brake), true, -1.0, true)
	draw_arc(wheel_centre, DISC_RADIUS, 0.0, TAU, 24, DISC_RIM, 1.5, true)
	_draw_broken_cross(tire, wheel)


## Condition colour with the broken pulse and the damage flash applied.
func _part_color(part: String) -> Color:
	var value: float = damage.condition[part]
	var result := color(value)
	if value <= 0.0:
		result = result.lerp(DAMAGED_COLOR, 0.5 + 0.5 * sin(_time * PULSE_SPEED))
	if _hits.has(part):
		result = result.lerp(Color.WHITE, _hits[part] / HIT_TIME)
	return result


func _draw_broken_cross(part: String, rect: Rect2) -> void:
	if part_state(part) != State.BROKEN:
		return
	var inset := rect.grow(-2.0)
	draw_line(inset.position, inset.end, CROSS_COLOR, 2.0, true)
	draw_line(Vector2(inset.end.x, inset.position.y), Vector2(inset.position.x, inset.end.y), CROSS_COLOR, 2.0, true)


func _box(fill: Color, border: Color, border_width: int, front_radius: int, rear_radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = front_radius
	box.corner_radius_top_right = front_radius
	box.corner_radius_bottom_left = rear_radius
	box.corner_radius_bottom_right = rear_radius
	box.anti_aliasing = true
	return box
