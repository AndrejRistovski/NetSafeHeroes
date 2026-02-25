extends Panel
@onready var new_game_button: Button = $VBoxContainer/NewGameButton

signal new_game_requested

func _ready() -> void:
	hide()

func show_win() -> void:
	show()
	new_game_button.grab_focus()

func hide_win() -> void:
	hide()

func _on_new_game_button_pressed() -> void:
	hide()
	emit_signal("new_game_requested")
