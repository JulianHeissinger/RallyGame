class_name Hud
extends CanvasLayer
## In-stage HUD: stage timer with penalties, gear, engine RPM with a shift light and speed of the
## target car, its part conditions (`PartsDisplay`), the upgrade meter, owned items with mount
## buttons and cooldowns, plus short notices such as malfunctions, and a white screen flash
## (paparazzi, fireworks).

## Seconds a notice stays on screen.
const NOTICE_TIME := 3.0
## Seconds a full-strength screen flash takes to fade out.
const FLASH_TIME := 1.5
const CORNERS := {"fl": "front-left", "fr": "front-right", "rl": "rear-left", "rr": "rear-right"}
## Item rows whose broken-part condition is not met are drawn in this colour.
const INACTIVE_COLOR := "#808080"
const SHIFT_LIGHT_ON := Color(1.0, 0.2, 0.15)
const SHIFT_LIGHT_OFF := Color(0.2, 0.2, 0.22, 0.6)

var car: Car
var meter: UpgradeMeter
var timer: StageTimer

var _notice_timer := 0.0

@onready var _label: Label = $Label
@onready var _notice: Label = $Notice
@onready var _flash: ColorRect = $Flash
@onready var _upgrade_bar: ProgressBar = $UpgradeBar
@onready var _items: RichTextLabel = $Items
@onready var _timer: Label = $Timer
@onready var _shift_light: ColorRect = $ShiftLight
@onready var _parts: PartsDisplay = $Parts


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
	_timer.visible = timer != null
	if timer:
		_timer.text = time_text(timer.total())
		if timer.penalties > 0.0:
			_timer.text += "\n+%.1f s penalty" % timer.penalties
	if car == null:
		return
	_parts.damage = car.damage
	_shift_light.color = SHIFT_LIGHT_ON if shift_light_on(car.drivetrain.rpm, car.stats) else SHIFT_LIGHT_OFF
	var gearbox := car.drivetrain.gearbox
	var gear := "R" if gearbox.gear == Gearbox.REVERSE \
		else "N" if gearbox.gear == Gearbox.NEUTRAL else str(gearbox.gear)
	_label.text = "%s\n%d rpm\n%d km/h" % [gear, roundi(car.drivetrain.rpm),
		roundi(car.linear_velocity.length() * 3.6)]
	_items.text = items_text(car.items, meter)
	_upgrade_bar.visible = meter != null
	if meter:
		_upgrade_bar.value = meter.value


## Stage time as m:ss.cc, e.g. 65.0 -> "1:05.00".
static func time_text(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	return "%d:%05.2f" % [minutes, seconds - minutes * 60.0]


## The shift light is on from the car's `shift_up_rpm`, just below the redline.
static func shift_light_on(rpm: float, stats: StatBlock) -> bool:
	return rpm >= stats.get_stat("shift_up_rpm")


## Next-pick distance, one row per mount slot (button key or "auto", item, cooldown) and one row
## per passive item with its count. Items whose condition is not met are greyed out.
static func items_text(items: ItemManager, upgrade_meter: UpgradeMeter) -> String:
	var lines := PackedStringArray()
	if upgrade_meter:
		lines.append("Next pick in %d m" % ceili(upgrade_meter.distance_left()))
	for mount: int in UpgradePick.MOUNT_NAMES:
		var def: ItemDef = items.mounts.get(mount)
		if def == null:
			lines.append("%s: –" % UpgradePick.MOUNT_NAMES[mount])
			continue
		var button := "[%d]" % (mount + 1) if def.activation == ItemDef.Activation.BUTTON else "auto"
		var cooldown: float = items.cooldowns.get(mount, 0.0)
		var state := "%.1f s" % cooldown if cooldown > 0.0 else "ready"
		lines.append(_row("%s %s: %s  %s" % [button, UpgradePick.MOUNT_NAMES[mount], def.name, state], def, items))
	for entry: Dictionary in items.passives.values():
		var def: ItemDef = entry["def"]
		var count := " ×%d" % entry["count"] if entry["count"] > 1 else ""
		lines.append(_row(def.name + count, def, items))
	return "\n".join(lines)


static func _row(text: String, def: ItemDef, items: ItemManager) -> String:
	if items.is_active(def):
		return text
	return "[color=%s]%s (needs broken %s)[/color]" % [INACTIVE_COLOR, text, def.condition_broken]
