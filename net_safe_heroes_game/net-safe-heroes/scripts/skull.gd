extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var collision_shape_2d_hit: CollisionShape2D = $CollisionShape2D_hit
@onready var collision_shape_2d_die: CollisionShape2D = $Area2D/CollisionShape2D_die
@onready var stomp_area: Area2D = $Area2D

signal player_died

const SPEED = 50.0
const BIG_PHASE_SECONDS = 10.0
const SMALL_PHASE_SECONDS = 3.5
const MAX_HITS = 3
const STOMP_SKULL_Y = 20.0
const ANIMATION_BIG = "running"
const ANIMATION_SMALL = "idle"
const ANIMATION_HIT = "hit"
const ANIMATION_TO_SMALL = "transition_big"
const ANIMATION_TO_BIG = "transition_small"

enum Phase { BIG, TO_SMALL, SMALL, TO_BIG, DEAD }

var phase: Phase = Phase.BIG
var direction = 1.0
var hp = MAX_HITS
var dead = false
var can_take_damage = false
var in_hit_stun = false

func _ready() -> void:
	var frames = animated_sprite_2d.sprite_frames
	if frames:
		if frames.has_animation(ANIMATION_HIT): frames.set_animation_loop(ANIMATION_HIT, false)
		if frames.has_animation(ANIMATION_TO_SMALL): frames.set_animation_loop(ANIMATION_TO_SMALL, false)
		if frames.has_animation(ANIMATION_TO_BIG): frames.set_animation_loop(ANIMATION_TO_BIG, false)

	_enter_big_phase()

	_boss_phase_loop()

func _process(delta: float) -> void:
	if dead:
		return

	if phase == Phase.BIG or phase == Phase.SMALL:
		position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	if dead:
		return
	if phase == Phase.BIG or phase == Phase.SMALL:
		direction *= -1.0
		animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

func _boss_phase_loop() -> void:
	while not dead:
		await get_tree().create_timer(BIG_PHASE_SECONDS).timeout
		if dead:
			return
		if phase != Phase.BIG:
			continue

		await _enter_small_phase()
		
		if dead:
			return

		await get_tree().create_timer(SMALL_PHASE_SECONDS).timeout
		if dead:
			return
		if phase != Phase.SMALL:
			continue

		await _enter_big_transform_back()

func _enter_big_phase() -> void:
	phase = Phase.BIG
	can_take_damage = false
	in_hit_stun = false

	collision_shape_2d_hit.set_deferred("disabled", false)
	collision_shape_2d_die.set_deferred("disabled", true)
	stomp_area.set_deferred("monitoring", false)

	timer.start()
	animated_sprite_2d.play(ANIMATION_BIG)

func _enter_small_phase() -> void:
	phase = Phase.TO_SMALL
	
	collision_shape_2d_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", true)
	stomp_area.set_deferred("monitoring", false)

	animated_sprite_2d.play(ANIMATION_TO_SMALL)
	await animated_sprite_2d.animation_finished

	if dead:
		return
	phase = Phase.SMALL
	can_take_damage = true

	collision_shape_2d_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", false)
	stomp_area.set_deferred("monitoring", true)

	animated_sprite_2d.play(ANIMATION_SMALL)

func _enter_big_transform_back() -> void:
	phase = Phase.TO_BIG

	collision_shape_2d_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", true)
	stomp_area.set_deferred("monitoring", false)

	animated_sprite_2d.play(ANIMATION_TO_BIG)
	await animated_sprite_2d.animation_finished
	if dead: return

	_enter_big_phase()

func _die_boss() -> void:
	dead = true
	phase = Phase.DEAD
	timer.stop()

	collision_shape_2d_hit.set_deferred("disabled", true)
	collision_shape_2d_die.set_deferred("disabled", true)
	stomp_area.set_deferred("monitoring", false)

	animated_sprite_2d.play(ANIMATION_HIT)
	await animated_sprite_2d.animation_finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.name == "Player" and body.alive:
		if phase == Phase.BIG:
			emit_signal("player_died", body)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if dead or phase != Phase.SMALL or not can_take_damage or in_hit_stun:
		return
	if body.name != "Player" or not body.alive:
		return

	var y_delta = position.y - body.position.y
	if y_delta > STOMP_SKULL_Y:
		await _take_damage(body)
	else:
		emit_signal("player_died", body)

func _take_damage(player: Node2D) -> void:
	in_hit_stun = true
	can_take_damage = false

	hp -= 1
	animated_sprite_2d.play(ANIMATION_HIT)
	player._jump()

	await animated_sprite_2d.animation_finished
	in_hit_stun = false

	if hp <= 0:
		_die_boss()
		return

	can_take_damage = true
	if phase == Phase.SMALL and not dead:
		animated_sprite_2d.play(ANIMATION_SMALL)

func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
