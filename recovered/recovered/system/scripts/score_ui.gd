extends Control
class_name ScoreUI

@export var tp: TweenParameter
@export var correct_color_tp: TweenParameter
@export var false_color_tp: TweenParameter
@export var score_label_prefab: PackedScene

@export var correct_sfx: SFXClip
@export var wrong_sfx: SFXClip


@onready var total_score_label: Label = $ScoreValue
@onready var score_labels_parent: VBoxContainer = $"../../MarginContainer/ScoreLabelsParent"

var tween: Tween

func _ready():
	Signals.score_changed.connect(_on_score_changed)
	Signals.bonus_score.connect(_on_bonus_score)
	Signals.day_started.connect(_on_day_started)
	update_label()

func _exit_tree() -> void :
	Signals.score_changed.disconnect(_on_score_changed)
	Signals.bonus_score.disconnect(_on_bonus_score)
	Signals.day_started.disconnect(_on_day_started)

func _on_bonus_score(amount: int, text: String) -> void :
	update_label()
	var sl: ScoreLabel = score_label_prefab.instantiate()
	score_labels_parent.add_child(sl)
	sl.populate(text, correct_color_tp.from_value if amount > 0 else false_color_tp.from_value)
	SoundManager.play_sfx(correct_sfx if amount > 0 else wrong_sfx)

func _on_day_started() -> void :
	update_label()

func _on_score_changed(bonus: int, correct_marks: int, quick_bonus: int, false_penalty: int, streak_bonus: int):
	add_score(bonus, correct_marks, quick_bonus, false_penalty, streak_bonus)

func add_score(amount: int, correct_marks: int, quick_bonus: int, false_penalty: int, streak_bonus: int):
	var actual_amount = amount - correct_marks - quick_bonus - streak_bonus + false_penalty
	update_label()

	var pos: bool = actual_amount > 0
	var txt: String

	if pos:
		txt = "قرار صح +%s" % actual_amount if TranslationServer.get_locale() == "ar" else "Correct Judgment +%s" % actual_amount
		SoundManager.play_sfx(correct_sfx)
	else:
		txt = "قرار غلط %s" % actual_amount if TranslationServer.get_locale() == "ar" else "Wrong Judgment %s" % actual_amount
		SoundManager.play_sfx(wrong_sfx)

	var sl: ScoreLabel = score_label_prefab.instantiate()
	score_labels_parent.add_child(sl)
	sl.populate(txt, correct_color_tp.from_value if pos else false_color_tp.from_value)

	if correct_marks > 0:
		txt = "تأشير صح +%s" % correct_marks if TranslationServer.get_locale() == "ar" else "Correct Marks +%s" % correct_marks
		var sl2: ScoreLabel = score_label_prefab.instantiate()
		score_labels_parent.add_child(sl2)
		sl2.populate(txt, correct_color_tp.from_value)

	if quick_bonus > 0:
		txt = "ختم سريع +%s" % quick_bonus if TranslationServer.get_locale() == "ar" else "Quick Stamp +%s" % quick_bonus
		var sl3: ScoreLabel = score_label_prefab.instantiate()
		score_labels_parent.add_child(sl3)
		sl3.populate(txt, correct_color_tp.from_value)

	if false_penalty > 0:
		txt = "تأشير غلط -%s" % false_penalty if TranslationServer.get_locale() == "ar" else "False Mark -%s" % false_penalty
		var sl4: ScoreLabel = score_label_prefab.instantiate()
		score_labels_parent.add_child(sl4)
		sl4.populate(txt, false_color_tp.from_value)

	if streak_bonus > 0:
		txt = "صح ورا بعض +%s" % streak_bonus if TranslationServer.get_locale() == "ar" else "Streak +%s" % streak_bonus
		var sl5: ScoreLabel = score_label_prefab.instantiate()
		score_labels_parent.add_child(sl5)
		sl5.populate(txt, correct_color_tp.from_value)

	if tween:
		tween.kill()
	tween = create_tween()
	TweenUtils.apply_tween_preset(total_score_label, tp, tween, true, true)
	if pos:
		TweenUtils.apply_tween_preset(total_score_label, correct_color_tp, tween, true, true)
	else:
		TweenUtils.apply_tween_preset(total_score_label, false_color_tp, tween, true, true)


func update_label():
	total_score_label.text = "%d" % SaveSystem.score_today
