extends Resource
class_name DayCaseRecord




enum ResultTier{WRONG, CORRECT, PERFECT}

var case_data: CaseData
var correct: bool = false

var money_delta: int = 0



func result_tier() -> int:
	if not correct:
		return ResultTier.WRONG
	if is_perfect_marking():
		return ResultTier.PERFECT
	return ResultTier.CORRECT


func is_perfect_marking() -> bool:
	var actual: Array[MistakeData] = case_data.markable_mistakes()
	var marked: Array[MistakeData] = case_data.player_marked_items
	var correctly_marked: = 0
	var false_marks: = 0
	for m in marked:
		var found: = false
		for a in actual:
			if m.is_same(a):
				found = true
				break
		if found:
			correctly_marked += 1
		else:
			false_marks += 1
	var missed: = actual.size() - correctly_marked
	return missed == 0 and false_marks == 0
