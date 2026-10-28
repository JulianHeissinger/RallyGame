class_name Hud
extends CanvasLayer
## In-stage HUD: gear, engine RPM and speed of the target car, plus short notices such as
## malfunctions, and a white screen flash (paparazzi, fireworks).

## Seconds a notice stays on screen.
const NOTICE_TIME := 3.0
## Seconds a full-strength screen flash takes to fade out.
const FLASH_TIME := 1.5
const CORNERS := {"fl": "front-left", "fr": "front-right", "rl": "rear-left", "rr": "rear-right"}

var car: Car

var _notice_timer := 0.0

@onready var _label: Label = $Label
@onready var _notice: Label = $Notice
@onready var _flash: ColorRect = $Flash


func _ready() -> void:
	_notice.visible = false
	_flash.modulate.a = 0.0


## Shows which part a malfunction hit, e.g. "Malfunction: front-left tire".
func show_malfunction(part: String, _amount: float) -> void:
	show_notice("Malfunction: " + part_name(part))


func show_notice(text: String) -> void:
	_notice.text = text
	_notice.visible = true
	_notice_timer = NOTICE_TIME


## Whites out the screen at `strength` (0..1), fading to clear in `FLASH_TIME` per unit.
func flash(strength: float) -> void:
	_flash.modulate.a = maxf(_flash.modulate.a, strength)


## Readable part name: "tire_fl" -> "front-left tire", "engine" -> "engine".
static func part_name(part: String) -> String:
	var pieces := part.split("_")
	return part if pieces.size() < 2 else "%s %s" % [CORNERS[pieces[1]], pieces[0]]


func _process(delta: float) -> void:
	if _notice.visible:
		_notice_timer -= delta
		_notice.visible = _notice_timer > 0.0
	_flash.modulate.a = maxf(_flash.modulate.a - delta / FLASH_TIME, 0.0)
	if car == null:
		return
	var gearbox := car.drivetrain.gearbox
	var gear := "R" if gearbox.gear == Gearbox.REVERSE \
		else "N" if gearbox.gear == Gearbox.NEUTRAL else str(gearbox.gear)
	_label.text = "%s\n%d rpm\n%d km/h" % [gear, roundi(car.drivetrain.rpm),
		roundi(car.linear_velocity.length() * 3.6)]
