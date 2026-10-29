class_name UpgradePick
extends CanvasLayer
## Upgrade pick overlay: one card per offered item. Steering moves the highlight, `activate_item`
## or `throttle` takes it, and when the real-time timer runs out the highlighted card is taken
## (the first one unless the player moved). Slow motion does not stretch the timer.

signal picked(def: ItemDef)

const CARD_WIDTH := 300.0
const MOUNT_NAMES := {
	ItemDef.Mount.ROOF: "Roof", ItemDef.Mount.FRONT_BUMPER: "Front bumper",
	ItemDef.Mount.REAR: "Rear", ItemDef.Mount.TRUNK: "Trunk",
}
const CURSED_COLOR := Color(0.85, 0.15, 0.15)
const HIGHLIGHT_COLOR := Color(1.0, 0.8, 0.2)
const CARD_COLOR := Color(0.1, 0.1, 0.12, 0.92)

var _offers: Array[ItemDef] = []
var _cards: Array[PanelContainer] = []
var _selected := 0
var _deadline_msec := 0
var _time_msec := 0

var _row: HBoxContainer
var _timer_bar: ProgressBar


func _ready() -> void:
	layer = 10
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	var title := Label.new()
	title.text = "Pick an upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 24)
	root.add_child(_row)
	_timer_bar = ProgressBar.new()
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(0.0, 12.0)
	root.add_child(_timer_bar)
	visible = false


## Shows `offers` for `time` seconds of real time. `items` tells which mounts an active item replaces.
func open(offers: Array[ItemDef], items: ItemManager, time: float) -> void:
	_offers = offers
	for card in _cards:
		card.free()
	_cards.clear()
	for def in offers:
		var card := _card(def, items)
		_row.add_child(card)
		_cards.append(card)
	_selected = 0
	_time_msec = roundi(time * 1000.0)
	_deadline_msec = Time.get_ticks_msec() + _time_msec
	_highlight()
	visible = true


func _process(_delta: float) -> void:
	if not visible:
		return
	var left := _deadline_msec - Time.get_ticks_msec()
	_timer_bar.value = 100.0 * left / _time_msec
	if Input.is_action_just_pressed("steer_left"):
		_selected = maxi(_selected - 1, 0)
		_highlight()
	elif Input.is_action_just_pressed("steer_right"):
		_selected = mini(_selected + 1, _offers.size() - 1)
		_highlight()
	if left <= 0 or Input.is_action_just_pressed("activate_item") or Input.is_action_just_pressed("throttle"):
		_take()


func _take() -> void:
	visible = false
	picked.emit(_offers[_selected])


func _highlight() -> void:
	for i in _cards.size():
		var style: StyleBoxFlat = _cards[i].get_theme_stylebox("panel")
		style.border_color = HIGHLIGHT_COLOR if i == _selected else CARD_COLOR


func _card(def: ItemDef, items: ItemManager) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_border_width_all(4)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(_label(def.name, 24))
	if def.cursed:
		box.add_child(_label("CURSED", 18, CURSED_COLOR))
	box.add_child(_label(_kind_text(def), 16, Color(0.7, 0.7, 0.7)))
	var description := _label(def.description, 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var mounted: ItemDef = items.mounts.get(def.mount) if def.kind == ItemDef.Kind.ACTIVE else null
	if mounted:
		box.add_child(_label("Replaces " + mounted.name, 16, HIGHLIGHT_COLOR))
	return card


## "Passive", or e.g. "Roof · button · 10 s cooldown" and "Trunk · on part_broken · 60 s cooldown".
static func _kind_text(def: ItemDef) -> String:
	if def.kind == ItemDef.Kind.PASSIVE:
		return "Passive"
	var parts := PackedStringArray([MOUNT_NAMES[def.mount]])
	if def.activation == ItemDef.Activation.BUTTON:
		parts.append("button")
	elif def.activation == ItemDef.Activation.TRIGGER:
		parts.append("on " + def.trigger_event.replace("_", " "))
	if def.cooldown > 0.0:
		parts.append("%s s cooldown" % String.num(def.cooldown))
	return " · ".join(parts)


static func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
