extends Node

signal form_field_marked(mistake: MistakeData)
signal form_field_unmarked(mistake: MistakeData)
signal score_changed(bonus: int, correct_marks: int, quick_bonus: int, false_penalty: int, streak_bonus: int)
signal case_resolved(correct: bool)
signal day_started
signal new_card_clicked(card)
signal bell_ringed
signal card_given
signal stamped(approve: bool, global_pos: Vector2)
signal boss_stamped(approve: bool, global_pos: Vector2)
signal stamp_picked_up
signal stamp_released
signal request_marker_cancel
signal next_document_requested(screen_pos: Vector2)
signal bonus_score(amount: int, label: String)
