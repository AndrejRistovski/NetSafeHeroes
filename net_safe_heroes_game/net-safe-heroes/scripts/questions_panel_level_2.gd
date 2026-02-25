extends Panel

@export var fade_in_time = 0.25
@export var fade_out_time = 0.2
@export var answers_container_path: NodePath = "VBoxContainer_2"
@export var correct_index = 1

signal answered(correct: bool)

var _buttons: Array[Button] = []
var _is_showing = false
var _tween: Tween

func _ready() -> void:
	visible = false
	modulate.a = 0.0

	var answers_container := get_node_or_null(answers_container_path)
	assert(answers_container != null, "answers_container_path is wrong. Expected 'VBoxContainer' under this panel.")

	_buttons.clear()
	for child in answers_container.get_children():
		if child is Button:
			var b := child as Button
			_buttons.append(b)
			b.pressed.connect(_on_button_pressed.bind(b))

	assert(_buttons.size() > 0, "No Buttons found inside the answers container.")
	assert(correct_index >= 0 and correct_index < _buttons.size(), "correct_index is out of range.")

func is_showing() -> bool:
	return _is_showing

func show_question() -> void:
	if _is_showing:
		return

	_is_showing = true
	for b in _buttons:
		b.disabled = false

	visible = true
	modulate.a = 0.0

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	await _tween.finished

func _hide_question() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "modulate:a", 0.0, fade_out_time)
	await _tween.finished

	visible = false
	_is_showing = false

func _on_button_pressed(button: Button) -> void:
	for b in _buttons:
		b.disabled = true

	var correct := (button == _buttons[correct_index])
	answered.emit(correct)
	await _hide_question()
