extends Node
@onready var pause_panel: Panel = $PausePanel

signal new_game_requested
signal reload_level_requested

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	get_tree().paused = true
	pause_panel.show()

func _resume() -> void:
	pause_panel.hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_resume()

func _on_new_game_pressed() -> void:
	_resume()
	new_game_requested.emit()

func _on_reload_level_pressed() -> void:
	_resume()
	reload_level_requested.emit()
