extends Node

@export_group("Speed Tier Bonus")
@export var fast_time_threshold: float = 10.0
@export var fast_bonus: int = 5
@export var normal_time_threshold: float = 20.0
@export var normal_bonus: int = 2

@export_group("Marking Penalty")
@export var false_mark_penalty: int = 1

@export_group("Streak Bonus")
@export var streak_start_from: int = 0
@export var streak_bonus: int = 3

@export_group("EXP & Rank")

@export var exp_per_correct: int = 20

@export var exp_per_wrong: int = 5

@export var exp_fast_bonus: int = 5

@export var exp_normal_bonus: int = 2

@export var exp_perfect_day_bonus: int = 25

@export var exp_endless_level_bonus: int = 30


func _apply_case_exp(correct: bool, elapsed: float) -> bool:
	var gain: = exp_per_correct if correct else exp_per_wrong
	if correct:
		if elapsed <= fast_time_threshold:
			gain += exp_fast_bonus
		elif elapsed <= normal_time_threshold:
			gain += exp_normal_bonus
	var promoted: = SaveSystem.add_exp(gain)
	if SaveSystem.is_endless:



		SaveSystem.save_progress(true)
	return promoted





func compute_score_delta(decision_correct: bool, correct_marks: int, false_marks: int, missed: int, elapsed: float, streak: int) -> Dictionary:
	var score_delta: = 0

	if decision_correct:
		score_delta += 5
	else:
		score_delta -= 5

	score_delta += correct_marks

	var quick_bonus: = 0
	if decision_correct:
		if elapsed <= fast_time_threshold:
			quick_bonus = fast_bonus
		elif elapsed <= normal_time_threshold:
			quick_bonus = normal_bonus
	score_delta += quick_bonus

	var false_penalty: = false_mark_penalty * false_marks
	score_delta -= false_penalty

	var streak_bonus: = 0
	if decision_correct and streak >= streak_start_from:
		streak_bonus = streak
	score_delta += streak_bonus

	return {
		"delta": score_delta, 
		"quick_bonus": quick_bonus, 
		"false_penalty": false_penalty, 
		"streak_bonus": streak_bonus, 
	}


func calculate_score(decision_correct: bool, correct_marks: int, false_marks: int, missed: int, elapsed: float, streak: int):
	var breakdown: = compute_score_delta(decision_correct, correct_marks, false_marks, missed, elapsed, streak)
	Signals.score_changed.emit(breakdown["delta"], correct_marks, breakdown["quick_bonus"], breakdown["false_penalty"], breakdown["streak_bonus"])
	return breakdown["delta"]
