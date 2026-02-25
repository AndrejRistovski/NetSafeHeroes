extends Area2D

signal game_won
var triggered = false

func _on_body_entered(body: Node2D) -> void:
	print("END TOUCHED BY:", body.name)
	if triggered:
		return
	if body.name == "Player":
		triggered = true
		set_deferred("monitoring", false)
		emit_signal("game_won")
