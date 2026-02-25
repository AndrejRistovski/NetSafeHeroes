extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

const SPEED = 300.0
const JUMP_VELOCITY_FIRST_JUMP = -900.0
const JUMP_VELOCITY_SECOND_JUMP = -650.0
const STOMP_BOUNCE_VELOCITY = -800.0
const MAX_JUMPS = 2

var alive = true
var can_move = true
var jumps_left = 2

func _physics_process(delta: float) -> void:
	if !alive:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = MAX_JUMPS
	
	if can_move:
		if Input.is_action_just_pressed("jump") and jumps_left > 0:
			var jump_velocity = 0
			if (jumps_left == MAX_JUMPS):
				jump_velocity = JUMP_VELOCITY_FIRST_JUMP
			else:
				jump_velocity = JUMP_VELOCITY_SECOND_JUMP
			
			velocity.y = jump_velocity
			jumps_left -= 1
			jump_sound.play()

		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if direction == 1.0:
			animated_sprite_2d.flip_h = false
		elif direction == -1.0:
			animated_sprite_2d.flip_h = true
	else:
		velocity.x = 0
	
	move_and_slide()
	
	if not is_on_floor():
		animated_sprite_2d.animation = "jumping"
	elif abs(velocity.x) > 1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"

func _die() -> void:
	death_sound.play()
	animated_sprite_2d.animation = "dying"
	alive = false

func _jump() -> void:
	velocity.y = STOMP_BOUNCE_VELOCITY
	jumps_left = max(jumps_left, MAX_JUMPS - 1)
