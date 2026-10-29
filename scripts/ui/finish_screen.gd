class_name FinishScreen
extends CanvasLayer
## Finish screen: stage time, penalties, total and prize money, with Retry (same seed), New stage
## (random seed) and Main menu. The buttons wait `INPUT_DELAY` s after opening, because Space is
## both the handbrake and `ui_accept` and a held handbrake would press Retry at once.

signal retry_pressed
signal new_stage_pressed
signal menu_pressed

const INPUT_DELAY := 0.75

@onready var _time: Label = %Time
@onready var _penalties: Label = %Penalties
@onready var _total: Label = %Total
@onready var _prize: Label = %Prize
@onready var _retry: Button = %Retry
@onready var _new_stage: Button = %NewStage
@onready var _menu: Button = %Menu


func _ready() -> void:
	visible = false
	_retry.pressed.connect(retry_pressed.emit)
	_new_stage.pressed.connect(new_stage_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)


func open(timer: StageTimer, prize: int) -> void:
	_time.text = Hud.time_text(timer.elapsed)
	_penalties.text = "+%.1f s" % timer.penalties
	_total.text = Hud.time_text(timer.total())
	_prize.text = "$%d" % prize
	visible = true
	_set_buttons_disabled(true)
	await get_tree().create_timer(INPUT_DELAY, true, false, true).timeout
	_set_buttons_disabled(false)
	_retry.grab_focus()


func _set_buttons_disabled(disabled: bool) -> void:
	for button in [_retry, _new_stage, _menu]:
		button.disabled = disabled
