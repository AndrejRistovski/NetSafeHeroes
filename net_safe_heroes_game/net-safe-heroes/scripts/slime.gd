extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d_die: CollisionShape2D = $Area2D/CollisionShape2D_die
@onready var collision_shape_2d_2_hit: CollisionShape2D = $CollisionShape2D2_hit
@onready var timer: Timer = $Timer

signal player_died
const SPEED = 30
const SLIME_DIE_Y = 10
var direction = -1.0
var dead = false

func _process(delta: float) -> void:
	position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	direction *= -1.0
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

func _die_slime() -> void:
	if dead:
		return
	dead = true
	
	set_process(false)
	timer.stop()
	collision_shape_2d_2_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", true)
	animated_sprite_2d.play("dying")

func _on_animated_sprite_2d_animation_finished() -> void:
	if dead and animated_sprite_2d.animation == "dying":
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.name == "Player" and body.alive):
		var y_delta = position.y - body.position.y
		if (y_delta > SLIME_DIE_Y):
			_die_slime()
			body._jump()
		else:
			emit_signal("player_died", body)
