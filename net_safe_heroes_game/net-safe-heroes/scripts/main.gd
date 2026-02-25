extends Node2D

@export var hearts : Array[Node]

@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/Fade
@onready var game_over: Node2D = $HUD/GameOver
@onready var pause_menu := $HUD/Pause
@onready var description_panel: Panel = $HUD/Rules/DescriptionPanel
@onready var end_game_panel: Control = $HUD/EndGame/EndGamePanel
@onready var questions_root: Node = $HUD/Questions

var score: int = 0
var level: int = 1
var lives: int = 3
var current_level_root: Node = null
var _info_open = false

const MAX_LIVES = 3
const MAX_LEVEL = 5

func _ready() -> void:
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	
	game_over.new_game_requested.connect(_on_new_game_requested)
	
	pause_menu.new_game_requested.connect(_on_new_game_requested)
	pause_menu.reload_level_requested.connect(_on_reload_level_requested)
	
	end_game_panel.new_game_requested.connect(_on_new_game_requested)
	
	_update_hearts()
	await _load_level(level, true, false, true)

func _change_lives(delta: int) -> void:
	lives = clamp(lives + delta, 0, MAX_LIVES)
	_update_hearts()

func _get_question_panel_for_completed_level(completed_level: int) -> Node:
	return questions_root.get_node_or_null("QuestionsPanel_Level_%d" % completed_level)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_info"):
		get_viewport().set_input_as_handled()
		await _toggle_info_panel()

func _toggle_info_panel() -> void:
	if get_tree().paused:
		return

	if _info_open:
		if description_panel.has_method("request_dismiss"):
			description_panel.request_dismiss()
		return

	_info_open = true
	get_tree().paused = true
	await description_panel.show_for_level(level)
	get_tree().paused = false
	_info_open = false

func _on_reload_level_requested() -> void:
	get_tree().paused = false
	_info_open = false
	await _load_level(level, false, false, false)

func _load_level(level_number: int, first_load: bool, reset_score: bool, show_description: bool) -> void:
	_info_open = false
	
	if first_load:
		fade.modulate.a = 1.0
	else:
		await _fade(1.0)
	
	if show_description:
		get_tree().paused = true
		_info_open = true
		await description_panel.show_for_level(level_number)
		_info_open = false
		get_tree().paused = false
	
	if reset_score:
		score = 0
		score_label.text = "SCORE: 0"
	
	if current_level_root:
		current_level_root.queue_free()
		await current_level_root.tree_exited
	
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	
	_setup_level(current_level_root)
	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	# --- Level finish trigger: Exit if exists, otherwise End ---
	var finish := level_root.find_child("Exit", true, false)
	if finish == null:
		finish = level_root.find_child("End", true, false)

	if finish and finish.has_signal("body_entered") and not finish.body_entered.is_connected(_on_finish_body_entered):
		finish.body_entered.connect(_on_finish_body_entered)

	# Diamonds
	var diamonds = level_root.find_child("Diamonds", true, false)
	if diamonds:
		for diamond in diamonds.get_children():
			if diamond.has_signal("collected") and not diamond.collected.is_connected(_increase_score):
				diamond.collected.connect(_increase_score)

	# Enemies
	var enemies = level_root.find_child("Enemies", true, false)
	if enemies:
		for enemy in enemies.get_children():
			if enemy.has_signal("player_died") and not enemy.player_died.is_connected(_on_player_died):
				enemy.player_died.connect(_on_player_died)

	# Hole
	var hole = level_root.find_child("Hole", true, false)
	if hole and hole.has_signal("player_died") and not hole.player_died.is_connected(_on_player_died):
		hole.player_died.connect(_on_player_died)

func _on_finish_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	print("FINISH reached. Completed level:", level)

	var completed_level := level

	# --- Quiz happens AFTER completing the level (before next level loads) ---
	if completed_level < MAX_LEVEL + 1:
		var qp := _get_question_panel_for_completed_level(completed_level)
		if qp:
			get_tree().paused = true

			# show + wait for answer
			var correct := await _ask_question(qp)

			get_tree().paused = false

			if correct:
				_change_lives(+1)
			else:
				_change_lives(-1)

			if lives <= 0:
				_show_game_over()
				return
		else:
			print("No question panel found for level", completed_level, "(expected: QuestionsPanel_Level_%d)" % completed_level)

	# Advance level
	level += 1

	# End of game?
	if completed_level >= MAX_LEVEL:
		_on_game_won()
		return

	body.can_move = false
	await _load_level(level, false, false, true)

func _on_game_won() -> void:
	get_tree().paused = true
	_info_open = false
	end_game_panel.show_win()

func _on_player_died(body):
	body._die()
	_descrease_health()
	
	if lives <= 0:
		_show_game_over()
		return

	await _load_level(level, false, false, false)

func _on_exit_body_entered(body : Node2D) -> void:
	if body.name != "Player":
		return

	var completed_level = level
	level += 1

	if completed_level < MAX_LEVEL:
		var qp = _get_question_panel_for_completed_level(completed_level)
		if qp:
			var was_paused := get_tree().paused
			get_tree().paused = true

			var correct: bool = await _ask_question(qp)

			get_tree().paused = was_paused

			if correct:
				_change_lives(+1)
			else:
				_change_lives(-1)

			if lives <= 0:
				_show_game_over()
				return

	if level > MAX_LEVEL:
		_on_game_won()
		return

	body.can_move = false
	await _load_level(level, false, false, true)

func _ask_question(qp: Node) -> bool:
	qp.show_question()
	var correct: bool = await qp.answered
	return correct

func _increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" %score

func _fade(to_alpha: float) -> void:
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished

func _descrease_health():
	lives -= 1
	_update_hearts()

func _update_hearts() -> void:
	for i in range(hearts.size()):
		if i < lives:
			hearts[i].show()
		else:
			hearts[i].hide()

func _show_game_over() -> void:
	get_tree().paused = true
	_info_open = false
	game_over.show_game_over()

func _on_new_game_requested() -> void:
	get_tree().paused = false
	_info_open = false
	
	level = 1
	lives = MAX_LIVES
	score = 0
	score_label.text = "SCORE: 0"
	_update_hearts()
	
	game_over.hide_game_over()
	end_game_panel.hide_win()
	
	await _load_level(level, false, false, true)
