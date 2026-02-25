extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d_die: CollisionShape2D = $Area2D/CollisionShape2D_die
@onready var collision_shape_2d_2_hit: CollisionShape2D = $CollisionShape2D2_hit
@onready var timer: Timer = $Timer

signal player_died

const SPEED = 40
const GHOST_DIE_Y = 20

var hits_left = 2
var direction = -1.0
var dead = false
var hurt = false

func _process(delta: float) -> void:
	position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	direction *= -1.0
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

func _show_hit() -> void:
	hurt = true
	set_process(false)
	timer.paused = true
	animated_sprite_2d.play("hit")

func _die_ghost() -> void:
	if dead:
		return
	dead = true
	hurt = false
	
	set_process(false)
	timer.stop()
	collision_shape_2d_2_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", true)
	animated_sprite_2d.play("dying")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit" and not dead:
		hurt = false
		animated_sprite_2d.play("running")
		set_process(true)
		timer.paused = false
	elif animated_sprite_2d.animation == "dying" and dead:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if dead or hurt:
		return

	if(body.name == "Player" and body.alive):
		var y_delta = position.y - body.position.y
		if (y_delta > GHOST_DIE_Y):
			hits_left -= 1
			body._jump()
			
			if (hits_left <= 0):
				_die_ghost()
			else:
				_show_hit()
		else:
			emit_signal("player_died", body)
