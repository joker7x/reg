extends Node






const RANK_TIERS: Array = [
	["Trainee Clerk", 0], 
	["Registry Clerk", 150], 
	["Senior Clerk", 400], 
	["Records Officer", 800], 
	["Archivist", 1400], 
	["Chief Archivist", 2200], 
	["Madam Afaf", 3200], 
]


func get_tier_count() -> int:
	return RANK_TIERS.size()




func rank_for_exp(e: int, is_debtor: bool = false) -> String:
	if is_debtor:
		return "Debtor"
	var name: String = RANK_TIERS[0][0]
	for tier in RANK_TIERS:
		if e >= tier[1]:
			name = tier[0]
	return name


func rank_index_for_exp(e: int) -> int:
	var idx: = 0
	for i in RANK_TIERS.size():
		if e >= RANK_TIERS[i][1]:
			idx = i
	return idx


func rank_exp_requirement(idx: int) -> int:
	return RANK_TIERS[clampi(idx, 0, RANK_TIERS.size() - 1)][1]


func rank_progress(e: int) -> float:
	var cur: = rank_index_for_exp(e)
	if cur >= RANK_TIERS.size() - 1:
		return 1.0
	var lo: = rank_exp_requirement(cur)
	var hi: = rank_exp_requirement(cur + 1)
	return float(e - lo) / float(hi - lo)


func is_max_rank(idx: int) -> bool:
	return idx >= RANK_TIERS.size() - 1
