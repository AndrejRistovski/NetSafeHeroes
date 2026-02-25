extends Panel

@export var fade_in_time = 0.35
@export var fade_out_time = 0.25
@onready var labels_by_level = {
	1: $Label_Level_1,
	2: $Label_Level_2,
	3: $Label_Level_3,
	4: $Label_Level_4,
	5: $Label_Level_5,
}

signal dismissed
var _waiting_for_dismiss = false

func request_dismiss() -> void:
	if _waiting_for_dismiss:
		_waiting_for_dismiss = false
		dismissed.emit()

func show_for_level(level: int) -> void:
	for l in labels_by_level.values():
		l.visible = false
	if labels_by_level.has(level):
		labels_by_level[level].visible = true

	show()
	modulate.a = 0.0

	var t_in = create_tween()
	t_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t_in.tween_property(self, "modulate:a", 1.0, fade_in_time)
	await t_in.finished

	_waiting_for_dismiss = true
	await dismissed

	var t_out = create_tween()
	t_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t_out.tween_property(self, "modulate:a", 0.0, fade_out_time)
	await t_out.finished

	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("show_info"):
		request_dismiss()
		get_viewport().set_input_as_handled()
