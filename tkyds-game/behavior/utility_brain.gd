class_name UtilityBrain
extends RefCounted

# One shared weighted-scoring pass (PRD FR1/FR85): filter to what the actor
# can attempt, score everything that survives in a single pass, pick the
# highest. Stateless — every actor's choice runs through this exact same
# arithmetic, so "why did they do that" always has one honest answer.

class Decision:
	extends RefCounted
	var chosen: ActionOption            # null when nothing was eligible
	var considered: Array[Dictionary] = []   # one per option, catalog order


# Deterministic: ties go to the earlier option in the array. No randomness —
# a rerun of the same stats always makes the same choice.
static func decide(store: StatStore, actor: Actor, options: Array[ActionOption]) -> Decision:
	var decision := Decision.new()
	var best: ActionOption = null
	var best_score := -INF
	for option in options:
		var can_go := option.can_attempt(store, actor)
		if not can_go:
			decision.considered.append({"option": option, "score": 0.0, "eligible": false})
			continue
		var score := option.score(store, actor)
		decision.considered.append({"option": option, "score": score, "eligible": true})
		if score > best_score:
			best_score = score
			best = option
	decision.chosen = best
	return decision
