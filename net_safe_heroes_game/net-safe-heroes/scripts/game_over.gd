extends Node2D
@onready var game_over_panel: Panel = $GameOverPanel

signal new_game_requested

func _ready() -> void:
	game_over_panel.hide()

func show_game_over() -> void:
	game_over_panel.show()

func hide_game_over() -> void:
	game_over_panel.hide()

func _on_new_game_pressed() -> void:
	emit_signal("new_game_requested")
